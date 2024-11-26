import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/signup/forget_pw.dart';
import 'package:unithrift/signup/register.dart';

void main() {
  runApp(MaterialApp(
    initialRoute: '/login', // Set your initial screen
    routes: {
      '/': (context) => const Register(),
      '/forgot-password': (context) => const ForgotPassword(),
      '/login': (context) => const Login(),
    },
  ));
}

class Login extends StatefulWidget {
  const Login({Key? key, this.successMessage}) : super(key: key);
  final String? successMessage; // Add this to show a message

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();

  signIn() async {
    // Check if the email ends with @graduate.utm.my
    if (!email.text.endsWith('@graduate.utm.my')) {
      // Show an error message if the email doesn't match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please use your UTM graduate email address.')),
      );
      return; // Stop the sign-in process
    }

    try {
      // Attempt to sign in with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text,
        password: password.text,
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase-specific errors and show a simplified message
      String errorMessage = 'Invalid email or password. Please try again.';

      // If it's a FirebaseAuthException, log and show a general error message
      print("FirebaseAuthException caught: ${e.code}, message: ${e.message}");

      // Show the simplified error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      // Catch any other exceptions (e.g., network issues, etc.)
      print("General error caught: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing in: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors
          .white, // Set the background color for the whole screen to white
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Make Scaffold background transparent
        resizeToAvoidBottomInset:
            true, // Ensures UI resizes to avoid keyboard overlap
        body: Column(
          children: [
            // First Part: Background and Title Section (non-scrollable)
            Container(
              color:
                  const Color(0xFFE5E8D9), // First container with the new color
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(vertical: 65, horizontal: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Image.asset(
                    'assets/logo.png',
                    width: 128, // Desired width on screen
                    height: 46, // Desired height on screen
                    fit: BoxFit
                        .fill, // Stretches the image to exactly fit the dimensions
                  ),
                  const SizedBox(height: 20),
                  // Title
                  const Text(
                    "Sign in to your\nAccount",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFA3A98A),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 20),
                  // Sign Up Link
                  RichText(
                    text: TextSpan(
                      text: "Don't have an account? ",
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFA5AA8C),
                      ),
                      children: [
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Register(),
                                ),
                              );
                            },
                            child: const Text(
                              "Sign up",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA5AA8C),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Second Part: Login Form Section
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.only(
                      top: 10, left: 10, right: 10, bottom: 10),
                  decoration: const BoxDecoration(
                    color:
                        Colors.white, // White background for the second section
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Title for Email
                      const Padding(
                        padding: EdgeInsets.only(
                            top: 40, left: 40, right: 40, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              "UTM Student Email",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey, // Grey color for the title
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Email Input Field
                      SizedBox(
                        width: 327,
                        height: 46,
                        child: TextField(
                          controller: email,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title for Password
                      const Padding(
                        padding:
                            EdgeInsets.only(left: 40, right: 40, bottom: 8),
                        child: Row(
                          children: [
                            Text(
                              "Password",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey, // Grey color for the title
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Password Input Field
                      SizedBox(
                        width: 327,
                        height: 46,
                        child: TextField(
                          controller: password,
                          obscureText: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      // Forgot Password link at the bottom right of the input field
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 0, top: 8), // Align with Password column
                        child: RichText(
                          text: TextSpan(
                            text: "Forgot Password? ",
                            style: const TextStyle(
                              fontSize: 12,
                              color:
                                  Color(0xFFA5AA8C), // Match your color style
                            ),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const ForgotPassword()),
                                    );
                                  },
                                  child: const Text(
                                    "Reset here",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFA5AA8C),
                                      decoration: TextDecoration
                                          .underline, // Underline for link-like style
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login Button
                      ElevatedButton(
                        onPressed: () => signIn(),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(327,
                              50), // Set the button width same as input field
                          backgroundColor:
                              const Color(0xFF808569), // Green color
                          elevation: 10, // Add drop shadow
                          shadowColor: Colors.black
                              .withOpacity(0.3), // Drop shadow color
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(20), // Rounded corners
                          ),
                        ),
                        child: const Text(
                          "Log In",
                          style: TextStyle(
                              color:
                                  Colors.white), // White color for button text
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
