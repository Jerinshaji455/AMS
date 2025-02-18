const express = require('express');
const cors = require('cors');
const mysql = require('mysql2'); // Require mysql
const app = express();

app.use(cors());
app.use(express.json());

// Database Configuration

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
let timeRemaining = 30;

const ipAttendance = {};
app.post('/login', (req, res) => {
    const { email, password } = req.body;
    db.query('SELECT * FROM AMS WHERE mail_id = ? AND password = ?', [email, password], (err, results) => {
        if (err) {
            console.error('Database query failed: ' + err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }
        if (results.length > 0) {
            res.status(200).json({ 
                message: 'Login successful',
                userData: {
                    name: results[0].NAME,
                    mail_id: results[0].mail_id,
                    roll_number: results[0].roll_number
                }
            });
        } else {
            res.status(401).json({ message: 'Invalid login credentials' });
        }
    });
});


// Endpoint to mark attendance
app.post('/attendance', (req, res) => {
    const { mail_id } = req.body; // Use mail_id for identification
    const clientIp = req.headers['x-forwarded-for'] || req.socket.remoteAddress;

    console.log(`Received mail_id: ${mail_id}`); // Log received mail_id

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

    // Use mail_id for checking student existence
    db.query('SELECT * FROM AMS WHERE mail_id = ?', [mail_id], (err, results) => {
        if (err) {
            console.error('Database query failed: ' + err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }

        console.log(results); // Log query results

        if (results.length === 0) {
            return res.status(404).json({ message: 'Student not found or attendance not active.' });
        }

        if(results[0].has_marked){
            return res.status(400).json({ message: 'You have already marked your attendance.' });
        }

        // Update attendance count. Set to zero after process ends
        db.query('UPDATE AMS SET has_marked = 1 WHERE mail_id = ?', [mail_id], (err, updateResults) => {
            if (err) {
                console.error('Database update failed: ' + err.stack);
                return res.status(500).json({ message: 'Internal server error' });
            }
            ipAttendance[clientIp] = mail_id; // Mark this IP as used for attendance
            console.log(`${results[0].NAME} (ID: ${results[0].roll_number}) marked present from IP ${clientIp}.`);
            res.status(200).json({ message: `Thank you ${results[0].NAME}, your attendance has been registered.` });
        });
    });
});

// Endpoint to trigger attendance
app.post('/trigger-attendance', (req, res) => {
    if (isAttendanceActive) {
        return res.status(400).json({ message: 'Attendance process is already active.' });
    }

    // Reset all students' has_marked to 0 in the database
    db.query('UPDATE AMS SET has_marked = 0', (err, results) => {
        if (err) {
            console.error('Database update failed: ' + err.stack);
            return res.status(500).json({ message: 'Internal server error' });
        }

        // Reset IP tracking
        for (let ip in ipAttendance) {
            delete ipAttendance[ip];
        }

        isAttendanceActive = true;
        timeRemaining = 30;
        console.log("Starting attendance process...");

        // Start countdown timer
        attendanceTimer = setInterval(() => {
            if (timeRemaining > 0) {
                timeRemaining--;
            } else {
                clearInterval(attendanceTimer);
                isAttendanceActive = false;
                console.log("Attendance process ended.");
                // Get attendance counts
                db.query('SELECT NAME, has_marked FROM AMS', (err, results) => {
                    if (err) {
                        console.error('Database query failed: ' + err.stack);
                        return;
                    }

                    console.log("Final attendance summary:");
                    for (const row of results) {
                        console.log(`${row.NAME}: ${row.has_marked}`);
                    }

                    // Reset has_marked status for next attendance
                    db.query('UPDATE AMS SET has_marked = 0', (err, resetResults) => {
                        if (err) {
                            console.error('Database update failed: ' + err.stack);
                        }
                    });
                });
            }
        }, 1000);

        res.status(200).json({ message: 'Attendance process started.' });
    });
});

// Endpoint to check if attendance is active and get remaining time
app.get('/attendance-status', (req, res) => {
    res.status(200).json({ isActive: isAttendanceActive, timeRemaining });
});

const PORT = 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
