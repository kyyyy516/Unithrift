import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/checkout/cimb/cimbtransaction.dart';

class CIMBLoginPage extends StatefulWidget {
  final double amount;
  
  const CIMBLoginPage({Key? key, required this.amount}) : super(key: key);

  @override
  State<CIMBLoginPage> createState() => _CIMBLoginPageState();
}
class _CIMBLoginPageState extends State<CIMBLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _login() async {
    try {
      // Sign in with Firebase
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      // Get the current user's email
      String? userEmail = userCredential.user?.email;
      
      if (userEmail != null) {
        // Navigate to transaction page with email
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CIMBTransactionPage(
              amount: widget.amount,
              userEmail: userEmail,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get user email')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
  backgroundColor: Color(0xFFEE3124),
  leading: IconButton(
    icon: Icon(Icons.arrow_back, color: Colors.white),
    onPressed: () => Navigator.pop(context),
  ),
  title: Image.asset(
    'assets/cimb2.png',
    height: 50,
    fit: BoxFit.contain,
  ),
  centerTitle: true,
),

    body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // FPX Logo
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Image.asset(
                'assets/fpx.jpg',
                height: 40,
                fit: BoxFit.contain,
              ),
            ),
            
            // Welcome Box
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(vertical: 20),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Log in to CIMB Clicks Online Banking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    child: Text('Login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:Color(0xFFEE3124),
                      minimumSize: Size(double.infinity, 45),
                    ),
                  ),
                ],
              ),
            ),
            
            // Security Note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'This is provided for illustration purposes only',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
