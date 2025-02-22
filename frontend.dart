import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:file_saver/file_saver.dart';

import 'package:shared_preferences/shared_preferences.dart';
import './store_ip.dart';
import 'dart:typed_data';
void main() {
  runApp(MyApp());
}
 

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,

    );
    
  }
  
}

enum UserRole { student, admin, operator }

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  UserRole _selectedRole = UserRole.student;
  bool _isPasswordVisible = false;
  String? _serverIPAddress;

  @override
  void initState() {
    super.initState();
    _loadIPAddress();
  }

  Future<void> _loadIPAddress() async {
    _serverIPAddress = await IPAddressManager.getIPAddress();
    setState(() {});
  }

  void _login() async {
    final email = _usernameController.text.toLowerCase();
    final password = _passwordController.text;
    final selectedRole = _selectedRole == UserRole.student ? 'S' : 'A';

    if (_serverIPAddress == null || _serverIPAddress!.isEmpty) {
      setState(() {
        _errorMessage = 'Server IP address is not set. Please contact operator.';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://$_serverIPAddress:5000/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'selectedRole': selectedRole
      }),
    );

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body)['userData'];
      if (userData['role'] == selectedRole) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => selectedRole == 'S'
                ? StudentDashboard(userData: userData, serverIPAddress: _serverIPAddress!)
                : AdminDashboard(username: userData['name'], userData: userData, serverIPAddress: _serverIPAddress!),
          ),
        );
      }
      
  if (_selectedRole == UserRole.operator) {
    if (email == "subin" && password == "1234") {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OperatorPage()),
      ).then((_) => _loadIPAddress());
   
    return;
  }}
    
      
      
       else {
        setState(() {
          _errorMessage = 'Access denied. Invalid role selected.';
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Invalid login credentials';
      });
    }
  }

Widget _buildSetIPButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OperatorPage()),
        ).then((value) => _loadIPAddress()); // Reload IP after returning
      },
      child: Text('Set Server IP'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3EDF7),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(32),
            width: 400,
            decoration: BoxDecoration(
              color: Color(0xFFF5F9FE),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFE6EEF8),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Attendance Management System',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(900),
                  child: Image.network(
                    'https://d3qitl7jlh2z9v.cloudfront.net/media/nit_calicut_logo.png',
                    width: 200,
                    height: 200,
                    fit: BoxFit.contain,
                    loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                              : null,
                        ),
                      );
                    },
                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 50),
                          Text('Failed to load logo', style: TextStyle(color: Colors.red)),
                        ],
                      );
                    },
                  ),
                ),
                SizedBox(height: 32),
                _buildInputField(
                  label: 'Email Address',
                  icon: Icons.mail_outline,
                  hintText: 'Username@gmail.com',
                  controller: _usernameController,
                ),
                SizedBox(height: 16),
                _buildPasswordField(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  hintText: '············',
                  controller: _passwordController,
                ),
                SizedBox(height: 16),
                _buildRoleSelector(),
                 SizedBox(height: 16),
                _buildSetIPButton(),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 255, 255, 255),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 20),
                    child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

   Widget _buildRoleSelector() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Radio(
        value: UserRole.student,
        groupValue: _selectedRole,
        onChanged: (UserRole? value) {
          setState(() {
            _selectedRole = value!;
          });
        },
      ),
      Text('Student'),
      Radio(
        value: UserRole.admin,
        groupValue: _selectedRole,
        onChanged: (UserRole? value) {
          setState(() {
            _selectedRole = value!;
          });
        },
      ),
      Text('Admin'),
      Radio(
        value: UserRole.operator,
        groupValue: _selectedRole,
        onChanged: (UserRole? value) {
          setState(() {
            _selectedRole = value!;
          });
        },
      ),
      Text('Operator'),
    ],
  );
}


 Widget _buildPasswordField({
    required String label,
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE6EEF8),
            blurRadius: 20,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF4D4D4D))),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: Color(0xFF4D4D4D)),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: !_isPasswordVisible, // Use _isPasswordVisible
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                ),
              ),
               GestureDetector( // Use GestureDetector
                  onTap: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                    });
                  },
                  child: Icon(
                    _isPasswordVisible ? Icons.visibility : Icons.visibility_off, // Change icon
                    color: Color(0xFF4D4D4D),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

 Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFE6EEF8),
            blurRadius: 20,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Color(0xFF4D4D4D))),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(icon, color: Color(0xFF4D4D4D)),
              SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                   decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
class ChangePasswordPage extends StatefulWidget {
  final String userId;
  final String serverIPAddress;

  ChangePasswordPage({required this.userId, required this.serverIPAddress});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _errorMessage = '';

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'New passwords do not match';
      });
      return;
    }

    final response = await http.post(
      Uri.parse('http://${widget.serverIPAddress}:5000/change-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': widget.userId,
        'currentPassword': _currentPasswordController.text,
        'newPassword': _newPasswordController.text,
      }),
    );

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password changed successfully')),
      );
    } else {
      setState(() {
        _errorMessage = 'Failed to change password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Change Password')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current Password'),
            ),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _changePassword,
              child: Text('Change Password'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}


class OperatorPage extends StatefulWidget {
  @override
  _OperatorPageState createState() => _OperatorPageState();
}

class _OperatorPageState extends State<OperatorPage> {
  final _codeController = TextEditingController();
  final _ipAddressController = TextEditingController();
  String _errorMessage = '';
  String? _currentIP;

  @override
  void initState() {
    super.initState();
    _loadCurrentIP();
  }

  Future<void> _loadCurrentIP() async {
    _currentIP = await IPAddressManager.getIPAddress();
    setState(() {});
  }

  Future<void> _setIPAddress() async {
    if (_codeController.text == "NITC") {
      final ipAddress = _ipAddressController.text;
      await IPAddressManager.setIPAddress(ipAddress);
      _loadCurrentIP();
      setState(() {
        _errorMessage = 'IP Address updated successfully';
        _codeController.clear();
        _ipAddressController.clear();
      });
    } else {
      setState(() {
        _errorMessage = 'Invalid Code';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Operator Settings')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current IP: ${_currentIP ?? "Not set"}', style: TextStyle(fontSize: 18)),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(labelText: 'Enter Code'),
              obscureText: true,
            ),
            TextField(
              controller: _ipAddressController,
              decoration: InputDecoration(labelText: 'Enter New Server IP Address'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _setIPAddress,
              child: Text('Update IP Address'),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}


class StudentDashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String serverIPAddress; // Added

  StudentDashboard({Key? key, required this.userData, required this.serverIPAddress}) : super(key: key);

  @override
  _StudentDashboardState createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  bool _hasMarkedAttendance = false;
  String _statusMessage = '';
  int _timeRemaining = 70;
  Timer? _timer;
  bool _isAttendanceActive = false;

  @override
  void initState() {
    super.initState();
    _listenForAttendanceTrigger();
  }

  void _listenForAttendanceTrigger() {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      final response = await http.get(Uri.parse('http://${widget.serverIPAddress}:5000/attendance-status'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _isAttendanceActive = data['isActive'];
          _timeRemaining = data['timeRemaining'];
          if (!_isAttendanceActive) {
            _hasMarkedAttendance = false;
          }
        });
      }
    });
  }

  void _markAttendance() async {
  if (_isAttendanceActive && !_hasMarkedAttendance) {
    final response = await http.post(
      Uri.parse('http://${widget.serverIPAddress}:5000/attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mail_id': widget.userData['mail_id']}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Thank you, your attendance has been registered.';
        _hasMarkedAttendance = true;
      });
    } else {
      setState(() {
        final errorData = jsonDecode(response.body);
        _statusMessage = 'Failed to mark attendance. ${errorData['message']}';
      });
    }
  } else if (!_isAttendanceActive) {
    setState(() {
      _statusMessage = 'Attendance marking is not active at the moment.';
    });
  }
}

  void clearText() {
  setState(() {
    _statusMessage = '';
  });
}


  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
             clearText();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
            );
          },
        ),
      ),
      
      body: Center(
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
 CircleAvatar( 
              radius: 50,
              backgroundColor: Colors.blue,
              child: Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
 SizedBox(height: 20),
            Text(
              'Welcome, ${widget.userData['name']}',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            Text(
              'Roll Number: ${widget.userData['roll_number']}',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 40),
            _buildDashboardButton(
              label: 'Give Attendance',
              onPressed:
               
               _isAttendanceActive ? _markAttendance : null,
            ),
            _buildDashboardButton(
              label:'Change Password',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordPage(
        userId: widget.userData['mail_id'],
        serverIPAddress: widget.serverIPAddress,
      )),
    );
  },
  
),

            _buildDashboardButton(
              label: 'Logout',
              onPressed: _logout,
            ),
            if (_statusMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(_statusMessage),
              ),
            if (_isAttendanceActive)
              Text('Time Remaining: $_timeRemaining seconds', style: TextStyle(fontSize: 18, color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardButton({required String label, required VoidCallback? onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 250,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 3,
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: onPressed != null ? Colors.blueAccent : Colors.grey,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20),
          ),
          onPressed: onPressed,
          child: Text(
            label,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}




class AdminDashboard extends StatefulWidget {
  final String username;
  final Map<String, dynamic> userData;
  final String serverIPAddress;   // Added


  AdminDashboard({required this.username,required this.userData, required this.serverIPAddress});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _statusMessage = '';
  String _csvData = '';
  bool _isAttendanceActive = false;
  int _timeRemaining = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPollingAttendanceStatus();
  }

  void _startPollingAttendanceStatus() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _checkAttendanceStatus();
    });
  }

  void _checkAttendanceStatus() async {
    final response = await http.get(Uri.parse('http://${widget.serverIPAddress}:5000/attendance-status'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _isAttendanceActive = data['isActive'];
        _timeRemaining = data['timeRemaining'];
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _triggerAttendance() async {
    setState(() {
      _statusMessage = ''; // Clear previous status message
      _csvData = ''; // Clear previous CSV data
    });

    final response = await http.post(
      Uri.parse('http://${widget.serverIPAddress}:5000/trigger-attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'admin': widget.username}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Attendance process started successfully.';
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to start attendance process. Error: ${response.body}';
      });
    }
  }

 void _fetchAttendanceCSV() async {
  setState(() {
    _statusMessage = '';
    _csvData = '';
  });

  // Check if attendance data is available
  final availabilityResponse = await http.get(Uri.parse('http://${widget.serverIPAddress}:5000/attendance-availability'));
  if (availabilityResponse.statusCode == 200) {
    final availabilityData = jsonDecode(availabilityResponse.body);
    if (!availabilityData['dataAvailable']) {
      setState(() {
        _statusMessage = 'No attendance data available yet.';
      });
      return;
    }
  } else {
    setState(() {
      _statusMessage = 'Failed to check attendance data availability.';
    });
    return;
  }

  // Fetch attendance data
  final response = await http.get(Uri.parse('http://${widget.serverIPAddress}:5000/attendance-csv'));
  if (response.statusCode == 200) {
    setState(() {
      _csvData = response.body;
    });
  } else {
    setState(() {
      _statusMessage = 'Failed to fetch attendance data.';
    });
  }
}

  void _editAttendance(String rollNumber, bool newStatus) async {
  final response = await http.post(
    Uri.parse('http://${widget.serverIPAddress}:5000/edit-attendance'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'roll_number': rollNumber,
      'status': newStatus,
    }),
  );

  if (response.statusCode == 200) {
    setState(() {
      _statusMessage = 'Attendance updated successfully.';
      _fetchAttendanceCSV(); // Refresh the attendance data
    });
  } else {
    setState(() {
      _statusMessage = 'Failed to update attendance.';
    });
  }
}

 void _sendAttendanceEmail() async {
  final response = await http.post(
    Uri.parse('http://${widget.serverIPAddress}:5000/send-attendance-email'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'adminUsername': widget.username}),
  );

  if (response.statusCode == 200) {
    setState(() {
      _statusMessage = 'Attendance report sent successfully.';
    });
  } else {
    setState(() {
      _statusMessage = 'Failed to send attendance report.';
    });
  }
}


  List<List<String>> _parseCSV(String csvData) {
    return csvData.split('\n')
        .where((row) => row.trim().isNotEmpty)
        .map((line) => line.split(','))
        .toList();
  }

Widget _buildAttendanceTable() {
  List<List<String>> parsedData = _parseCSV(_csvData);

  // Check if data is empty
  if (parsedData.isEmpty || parsedData.length < 2) {
    return Text('No attendance data available.');
  }

  // Ensure all rows have the same number of columns as the header
  int columnCount = parsedData[0].length;
  parsedData = parsedData.where((row) => row.length == columnCount).toList();

  return Container(
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(10),
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.blue[100]),
          columns: [
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Roll Number')),
            DataColumn(label: Text('Attendance')),
            DataColumn(label: Text('Edit')),
          ],
          rows: parsedData.skip(1).map((row) {
            // Handle missing or invalid data gracefully
            String name = row.length > 0 ? row[0] : 'N/A';
            String rollNumber = row.length > 1 ? row[1] : 'N/A';
            String attendanceStatus = row.length > 2 ? row[2] : 'Absent';

            return DataRow(
              cells: [
                DataCell(Text(name)),
                DataCell(Text(rollNumber)),
                DataCell(Text(attendanceStatus)),
                DataCell(
                  Switch(
                    value: attendanceStatus == 'Present',
                    onChanged: (bool value) {
                      if (rollNumber != 'N/A') {
                        _editAttendance(rollNumber, value);
                      }
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    ),
  );
}

Widget _buildDashboardButton({required String label, required VoidCallback? onPressed}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.assignment_ind,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Text('Welcome, Admin ${widget.username}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 40),
               if (_isAttendanceActive)
              Text(
                'Time Remaining: $_timeRemaining seconds',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              _buildDashboardButton(
                label:'Trigger Attendance',
                onPressed: _triggerAttendance,
                
              ),
              SizedBox(height: 20),
              _buildDashboardButton(
                label:'Fetch Attendance Data',
                onPressed: _fetchAttendanceCSV,
                
              ),
               _buildDashboardButton(
                label:'Change Password',
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChangePasswordPage(
        userId: widget.userData['mail_id'],
        serverIPAddress: widget.serverIPAddress,
      )),
    );
  },
 
),

             SizedBox(height: 20),
              _buildDashboardButton(
                label:'Send Attendance Report',

                onPressed: _sendAttendanceEmail,
               
              ),
              if (_statusMessage.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Text(_statusMessage),
                ),
              if (_csvData.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: _buildAttendanceTable(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}



class AttendanceStatusPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Status'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Back to Dashboard'),
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final String username;

  ProfilePage({required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Name: $username', style: TextStyle(fontSize: 24)),
            SizedBox(height: 10),
            Text('Date of Birth: 01/01/2000', style: TextStyle(fontSize: 20)),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
