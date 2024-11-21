import 'package:flutter/material.dart';
import 'package:unithrift/homepage.dart';
import 'package:unithrift/login.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/success', // Set your initial screen
    routes: {
      //'/': (context) => const Register(), // Register route
      '/homepage': (context) => const Homepage(),
      '/login': (context) => const Login(),
      '/success': (context) => const RegisterSuccessPage(),
    },
  ));
}

class RegisterSuccessPage extends StatelessWidget {
  const RegisterSuccessPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7EB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF808569)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            const SizedBox(height: 50),
            const Icon(
              Icons.check_circle_outline,
              size: 70,
              color: Color(0xFF808569),
            ),
            const SizedBox(height: 20),
            const Text(
              "Register Successful!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF808569),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "You have successfully registered and verified your account! Welcome! Start exploring our features now.",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFA5AA8C),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
  onPressed: () {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Homepage()),
      (route) => false, // Clear all previous routes
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF808569),
    minimumSize: const Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
  child: const Text(
    "Explore Now",
    style: TextStyle(fontSize: 16, color: Colors.white),
  ),
),
          ],
        ),
      ),
    );
  }
}
