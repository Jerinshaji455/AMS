const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

// Dummy data for attendance
let students = {
    "john": 0,
    "jane": 0,
    "alice": 0,
    "bob": 0
};

let isAttendanceActive = false;
let attendanceTimer = null;
let timeRemaining = 30; // 30 seconds

// Endpoint to mark attendance
app.post('/attendance', (req, res) => {
    const { student } = req.body;

    if (student in students && isAttendanceActive && students[student] === 0) {
        students[student] = 1;
        console.log(`${student} marked present.`);
        res.status(200).json({ message: `Thank you ${student}, your attendance has been registered.` });
    } else if (students[student] === 1) {
        res.status(400).json({ message: 'You have already marked your attendance.' });
    } else {
        res.status(404).json({ message: 'Student not found or attendance not active.' });
    }
});

// Endpoint to trigger attendance
app.post('/trigger-attendance', (req, res) => {
    if (isAttendanceActive) {
        return res.status(400).json({ message: 'Attendance process is already active.' });
    }

    // Reset all students' attendance to 0
    for (let student in students) {
        students[student] = 0;
    }

    isAttendanceActive = true;
    timeRemaining = 30; // Reset timer to 30 seconds
    console.log("Starting attendance process...");

    // Start countdown timer
    attendanceTimer = setInterval(() => {
        if (timeRemaining > 0) {
            timeRemaining--;
        } else {
            clearInterval(attendanceTimer);
            isAttendanceActive = false;
            console.log("Attendance process ended. Final attendance summary:");
            console.log(students);
            // Reset attendance after displaying
            for (let student in students) {
                students[student] = 0;
            }
        }
    }, 1000);

    res.status(200).json({ message: 'Attendance process started.' });
});

// Endpoint to check if attendance is active and get remaining time
app.get('/attendance-status', (req, res) => {
    res.status(200).json({ isActive: isAttendanceActive, timeRemaining });
});

const PORT = 5000;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
