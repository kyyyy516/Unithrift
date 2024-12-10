import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/login.dart'; // Adjust this import path for your Login screen.
import 'package:unithrift/signup/auth_service.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/forgot-password',
    routes: {
      '/forgot-password': (context) => const ForgotPassword(),
      '/login': (context) => const Login(),
    },
  ));
}

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    final authService =
        AuthService(); // Use AuthService for reset functionality

    try {
      await authService.sendPasswordResetEmail(emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
        ),
      );

      // Navigate to login screen with a success flag
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const Login(
              successMessage: "Please log in with your new password."),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found with this email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email address.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header Section
          Container(
            color: const Color(0xFFE5E8D9),
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 128,
                  height: 46,
                  fit: BoxFit.fill,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Forgot Password",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA3A98A),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Enter your UTM email to receive a password reset link.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFA5AA8C),
                  ),
                ),
              ],
            ),
          ),

          // Forgot Password Form Section
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 40),
                          _buildFormLabel("Student Email"),
                          _buildFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!value.endsWith('@graduate.utm.my')) {
                                return 'Please use your UTM graduate email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : sendPasswordResetEmail,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(327, 50),
                        backgroundColor: const Color(0xFF808569),
                        elevation: 10,
                        shadowColor: const Color(0xFFFFFFFF).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text("Reset Password"),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const Login()), // Replace with your Login page
                          (Route<dynamic> route) =>
                              false, // Removes all routes from the stack
                        );
                      },
                      child: const Text(
                        "Back to Login",
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFA5AA8C),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Padding _buildFormLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 40, right: 40, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    String hintText = '',
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 327,
      height: 46,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        validator: validator,
      ),
    );
  }
}
