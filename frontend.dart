import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

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

enum UserRole { student, admin }

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  UserRole _selectedRole = UserRole.student;

  void _login() async {
    final username = _usernameController.text.toLowerCase();
    final password = _passwordController.text;

    if (password == '1234' && (username == 'john' || username == 'jane' || username == 'alice' || username == 'bob')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => _selectedRole == UserRole.student
              ? StudentDashboard(username: username)
              : AdminDashboard(username: username),
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
