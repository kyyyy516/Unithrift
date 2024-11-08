import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart'; // Import your Register page
import 'verification.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/register': (context) => const Register(),
        '/verification': (context) => const VerificationPage(),
        '/login': (context) => const Login(), // Add your LoginPage route here
      },
      home: const Register(), // Home page
    );
  }
}

