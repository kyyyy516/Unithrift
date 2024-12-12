import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/login.dart';
import 'package:unithrift/signup/verification.dart'; //yyyyyyyyyyyyyyyyyyy

void main() {
  runApp(MaterialApp(
    initialRoute: '/', // Set your initial screen
    routes: {
      '/': (context) => const Register(), // Register route
      '/verify': (context) => const VerifyUTMEmail(),
      '/login': (context) => const Login(), // Login route 
    },
    onUnknownRoute: (settings) {
      return MaterialPageRoute(builder: (context) => const Register());
    },
  ));
}

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController fullName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController matricNo = TextEditingController();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController password = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  register() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    isLoading = true;
  });

  try {
    // Create the user with Firebase Authentication
    final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.text.trim(),
      password: password.text.trim(),
    );

    // Get the user's UID from Firebase Authentication
    String uid = user.user!.uid;

    // Send email verification
    await user.user?.sendEmailVerification();

    // Save user information to Firestore, including the userId
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'email': email.text.trim(),
      'userId': uid, // Add the userId here
      'fullName': fullName.text.trim(), // Save the full name
      'phoneNumber': phoneNumber.text.trim(), // Save the phone number
    });

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please check your email for verification.')),
    );

    // Navigate to verify page
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VerifyUTMEmail()));
  } on FirebaseAuthException catch (e) {
    String errorMessage = 'Registration failed. Please try again.';

    if (e.code == 'email-already-in-use') {
      errorMessage = 'This email is already in use. Please use another one.';
    } else if (e.code == 'weak-password') {
      errorMessage = 'Your password is too weak. Please use a stronger password.';
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
                  "Create your\nAccount",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA3A98A),
                  ),
                ),
                const SizedBox(height: 20),
                RichText(
                  text: TextSpan(
                    text: "Already have an account? ",
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
                                builder: (context) => const Login(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign In",
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
          // Register Form Section
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
                          _buildFormLabel("Full Name"),
                          _buildFormField(controller: fullName),
                          const SizedBox(height: 20),
                          _buildFormLabel("Email"),
                          _buildFormField(
                            controller: email,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              } else if (!RegExp(
                                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildFormLabel("Matric No"),
                          _buildFormField(controller: matricNo),
                          const SizedBox(height: 20),
                          _buildFormLabel("Phone Number"),
                          _buildFormField(
                            controller: phoneNumber,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              } else if (!RegExp(r'^\d{10,15}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildFormLabel("Password"),
                          _buildFormField(
                            controller: password,
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              } else if (value.length < 6) {
                                return 'Password must be at least 6 characters long';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isLoading ? null : register,
                      child: isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text("Register"),
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
    return Container(
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
