const express = require('express');
const cors = require('cors');
const mysql = require('mysql2');
const app = express();
const nodemailer = require('nodemailer');
app.use(cors());
app.use(express.json());

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'jerinshaji455',
    database: 'AMS'
});

db.connect((err) => {
    if (err) {
        console.error('Database connection failed: ' + err.stack);
        return;
    }
    console.log('Connected to database.');
});

let isAttendanceActive = false;
let attendanceTimer = null;
let timeRemaining = 70;

const ipAttendance = {};

app.post('/login', (req, res) => {
    const { email, password, selectedRole } = req.body;
    db.query('SELECT NAME, mail_id, roll_number, role, has_marked FROM AMS WHERE mail_id = ? AND password = ?', [email, password], (err, results) => {
        if (err) {
            console.error('Database query failed: ' + err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }
        if (results.length > 0) {
            const user = results[0];
            if (user.role === selectedRole) {
                res.status(200).json({
                    message: 'Login successful',
                    userData: {
                        name: user.NAME,
                        mail_id: user.mail_id,
                        roll_number: user.roll_number,
                        role: user.role
                    }
                });
            } else {
                res.status(403).json({ message: 'Access denied. Invalid role selected.' });
            }
        } else {
            res.status(401).json({ message: 'Invalid login credentials' });
        }
    });
});

app.post('/attendance', (req, res) => {
    const { mail_id } = req.body;
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    console.log(`Received mail_id: ${mail_id}`);

    if (!clientIp) {
        return res.status(400).json({ message: 'Unable to track device IP.' });
    }

    if (ipAttendance[clientIp]) {
        console.log(`Warning: Proxy attempt detected from IP ${clientIp}`);
        return res.status(400).json({
            message: 'Warning: You are attempting to mark attendance for multiple accounts from the same device. This may be considered as proxy attendance and is not allowed.',
            isProxy: true
        });
    }

    if (!isAttendanceActive) {
        return res.status(400).json({ message: 'Attendance not active.' });
    }

    db.query('SELECT * FROM AMS WHERE mail_id = ?', [mail_id], (err, results) => {
        if (err) {
            console.error('Database query failed: ' + err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }

        console.log(results);

        if (results.length === 0) {
            return res.status(404).json({ message: 'Student not found or attendance not active.' });
        }

        if(results[0].has_marked){
            return res.status(400).json({ message: 'You have already marked your attendance.' });
        }

        db.query('UPDATE AMS SET has_marked = 1 WHERE mail_id = ?', [mail_id], (err, updateResults) => {
            if (err) {
                console.error('Database update failed: ' + err.stack);
                return res.status(500).json({ message: 'Internal server error' });
            }
            ipAttendance[clientIp] = mail_id;
            console.log(`${results[0].NAME} (ID: ${results[0].roll_number}) marked present from IP ${clientIp}.`);
            res.status(200).json({ message: `Thank you ${results[0].NAME}, your attendance has been registered.` });
        });
    });
});

app.post('/trigger-attendance', (req, res) => {
    if (isAttendanceActive) {
        return res.status(400).json({ message: 'Attendance process is already active.' });
    }

    // Clear the AttendanceHistory table
    db.query('DELETE FROM AttendanceHistory', (err) => {
        if (err) {
            console.error('Error clearing AttendanceHistory table:', err);
            return res.status(500).json({ message: 'Internal server error' });
        }
        
        // Reset has_marked to 0 for all students in AMS table
        db.query('UPDATE AMS SET has_marked = 0', (err) => {
            if (err) {
                console.error('Error resetting has_marked in AMS table:', err);
                return res.status(500).json({ message: 'Internal server error' });
            }
            
            // Reset IP tracking
            for (let ip in ipAttendance) {
                delete ipAttendance[ip];
            }

            isAttendanceActive = true;
            timeRemaining = 70;
            console.log("Starting attendance process...");

            attendanceTimer = setInterval(() => {
                if (timeRemaining > 0) {
                    timeRemaining--;
                } else {
                    clearInterval(attendanceTimer);
                    isAttendanceActive = false;
                    console.log("Attendance process ended.");
                    
                    // Move data from AMS to AttendanceHistory
                    db.query('INSERT INTO AttendanceHistory (date, NAME, mail_id, roll_number, status) SELECT CURDATE(), NAME, mail_id, roll_number, has_marked FROM AMS', (err, results) => {
                        if (err) {
                            console.error('Error saving attendance history:', err);
                        } else {
                            console.log('Attendance history saved successfully');
                        }
                    });
                }
            }, 1000);

            res.status(200).json({ message: 'Attendance process started.' });
        });
    });
});

app.post('/edit-attendance', (req, res) => {
    const { roll_number, status } = req.body;
    
    db.query('UPDATE AttendanceHistory SET status = ? WHERE roll_number = ?', [status ? 1 : 0, roll_number], (err, result) => {
      if (err) {
        console.error('Error updating attendance:', err);
        return res.status(500).json({ message: 'Internal server error' });
      }
      
      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Student not found' });
      }
      
      // Update the AMS table as well
      db.query('UPDATE AMS SET has_marked = ? WHERE roll_number = ?', [status ? 1 : 0, roll_number], (err, result) => {
        if (err) {
          console.error('Error updating AMS table:', err);
          return res.status(500).json({ message: 'Internal server error' });
        }
        
        res.status(200).json({ message: 'Attendance updated successfully' });
      });
    });
  });
  
  app.get('/attendance-status', (req, res) => {
    res.status(200).json({ 
        isActive: isAttendanceActive, 
        timeRemaining: isAttendanceActive ? timeRemaining : 0 
    });
});

app.post('/send-attendance-email', (req, res) => {
    const { adminUsername } = req.body;

    // First, retrieve the admin's email from the database
    db.query('SELECT mail_id FROM AMS WHERE NAME = ?', [adminUsername], (err, results) => {
        if (err || results.length === 0) {
            console.error('Error retrieving admin email:', err);
            return res.status(500).json({ message: 'Failed to retrieve admin email' });
        }

        const adminEmail = results[0].mail_id;

        // Now proceed with sending the email
        db.query('SELECT NAME, roll_number, status FROM AttendanceHistory', (err, results) => {
            if (err) {
                console.error('Database query failed: ' + err.stack);
                return res.status(500).json({ message: 'Internal server error' });
            }

            let csv = 'Name,Roll Number,Attendance\n';
            results.forEach(row => {
                csv += `${row.NAME},${row.roll_number},${row.status ? 'Present' : 'Absent'}\n`;
            });

            // Configure email transporter (replace with your SMTP settings)
            let transporter = nodemailer.createTransport({
                host: "smtp.gmail.com",
                port: 587,
                secure: false,
                auth: {
                    user: "nitcrig@gmail.com",
                    pass: "wimu gjsm glan uiij"
                }
            });

            // Send email
            transporter.sendMail({
                from: '"Attendance System" <jerin_b220336ec@nitc.ac.in>',
                to: adminEmail,
                subject: "Attendance Report",
                text: "Please find the attendance report attached.",
                attachments: [
                    {
                        filename: 'attendance.csv',
                        content: csv
                    }
                ]
            }, (error, info) => {
                if (error) {
                    console.error('Error sending email:', error);
                    res.status(500).json({ message: 'Failed to send email' });
                } else {
                    console.log('Email sent:', info.response);
                    res.status(200).json({ message: 'Attendance report sent successfully' });
                }
            });
        });
    });
});

app.get('/attendance-csv', (req, res) => {
    db.query('SELECT NAME, roll_number, status FROM AttendanceHistory', (err, results) => {
        if (err) {
            console.error('Database query failed:', err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }

        // Handle empty results
        if (results.length === 0) {
            return res.status(200).send('Name,Roll Number,Attendance\n'); // Send an empty CSV with headers
        }

        let csv = 'Name,Roll Number,Attendance\n';
        results.forEach(row => {
            csv += `${row.NAME},${row.roll_number},${row.status ? 'Present' : 'Absent'}\n`;
        });

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename=attendance.csv');
        res.status(200).send(csv);
    });
});

app.get('/attendance-availability', (req, res) => {
    db.query('SELECT COUNT(*) as count FROM AttendanceHistory', (err, results) => {
        if (err) {
            console.error('Database query failed:', err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }
        res.json({ dataAvailable: results[0].count > 0 });
    });
});


const PORT = 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
