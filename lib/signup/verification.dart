import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/signup/successful_page.dart'; // The success page to show once the email is verified

void main() {
  runApp(MaterialApp(
    initialRoute: '/verify', // Set your initial screen
    routes: {
      '/verify': (context) => const VerifyUTMEmail(),
    },
  ));
}

class VerifyUTMEmail extends StatefulWidget {
  const VerifyUTMEmail({Key? key}) : super(key: key);

  @override
  _VerifyUTMEmailState createState() {
    print("VerifyUTMEmail screen is being created");
    return _VerifyUTMEmailState();
  }
}

class _VerifyUTMEmailState extends State<VerifyUTMEmail> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Optionally check verification status immediately
    checkEmailVerificationOnReopen();
  }

  // Automatically check email verification on page load
  Future<void> checkEmailVerificationOnReopen() async {
    User? user = _auth.currentUser;
    await user?.reload(); // Reload user data to get the latest status

    if (user != null && user.emailVerified) {
      navigateToSuccessPage();
    }
  }

  // Navigate to the successful account creation page
  void navigateToSuccessPage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const RegisterSuccessPage()),
    );
  }

  // Check email verification manually
  Future<void> checkEmailVerification() async {
    setState(() {
      isLoading = true;
    });

    User? user = _auth.currentUser;
    await user?.reload(); // Ensure the user data is up to date

    if (user != null && user.emailVerified) {
      navigateToSuccessPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Email not verified yet. Please check your inbox."),
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7EB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.email_outlined,
              size: 100,
              color: Color(0xFF808569),
            ),
            const SizedBox(height: 20),
            const Text(
              "Waiting for Email Verification",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF808569),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            const Text(
              "Please check your email and click the verification link. Then return here to complete registration.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFFA5AA8C)),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: checkEmailVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF808569),
                      minimumSize: const Size(200, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      "Check Verification Status",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}