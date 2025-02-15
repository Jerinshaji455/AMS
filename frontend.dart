import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';

  void _login() async {
    final username = _usernameController.text.toLowerCase();
    final password = _passwordController.text;

    if (password == '1234' && (username == 'john' || username == 'jane' || username == 'alice' || username == 'bob')) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardPage(username: username),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Invalid login credentials';
      });
    }
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
              children:  [
                Text('Attendance Management System',style: TextStyle(fontSize:20,fontWeight: FontWeight.bold,color: Colors.blueAccent,),textAlign: TextAlign.center,
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
                      if (loadingProgress == null) {
                        return child;
                      }
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
                          Text(
                            'Failed to load logo',
                            style: TextStyle(color: Colors.red),
                          ),
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
                _buildInputField(
                  label: 'Password',
                  icon: Icons.lock_outline,
                  hintText: '············',
                  isPassword: true,
                  controller: _passwordController,
                ),
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
                    child: Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required IconData icon,
    required String hintText,
    bool isPassword = false,
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
                  obscureText: isPassword,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.black),
                  ),
                ),
              ),
              if (isPassword) Icon(Icons.visibility_outlined, color: Color(0xFF4D4D4D)),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final String username;

  DashboardPage({required this.username});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _statusMessage = '';

  void _pressButton() async {
    final response = await http.post(
      Uri.parse('http://172.21.44.180:5000/attendance'), // Replace with your actual backend URL
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'student': widget.username}),
    );

    if (response.statusCode == 200) {
      setState(() {
        _statusMessage = 'Thank you, your attendance has been registered.';
      });
    } else {
      setState(() {
        _statusMessage = 'Failed to mark attendance. Error: ${response.body}';
      });
    }
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
      title: Text('Dashboard'),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10),
              Text(
                'Welcome, ${widget.username}',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 40),
          _buildDashboardButton(
            label: 'Attendance Status',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AttendanceStatusPage()),
              );
            },
          ),
          _buildDashboardButton(
            label: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage(username: widget.username)),
              );
            },
          ),
          _buildDashboardButton(
            label: 'Give Attendance',
            onPressed: _pressButton,
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
        ],
      ),
    ),
  );
}

Widget _buildDashboardButton({required String label, required VoidCallback onPressed}) {
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
          backgroundColor: Colors.blueAccent,
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
}}

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
