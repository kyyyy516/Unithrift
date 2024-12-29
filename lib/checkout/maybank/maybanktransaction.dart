import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:unithrift/checkout/ordersuccess.dart';

class maybankTransactionPage extends StatefulWidget {
  final double amount;
  final String userEmail;

  const maybankTransactionPage({
    Key? key,
    required this.amount,
    required this.userEmail, // Add this
  }) : super(key: key);

  @override
  State<maybankTransactionPage> createState() => _maybankTransactionPageState();
}

class _maybankTransactionPageState extends State<maybankTransactionPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    // Configure EmailOTP
    EmailOTP.config(
      appName: 'UniThrift',
      otpLength: 6,
      otpType: OTPType.numeric,
      expiry: 300000, // 5 minutes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 252, 204, 4),
          title: Image.asset(
            'assets/maybank2.png',
            height: 100,
            fit: BoxFit.contain,
          ),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
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
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ),

                // Information Box
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 20),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('From Account', 'XXXX-XXXX-1234'),
                      SizedBox(height: 12),
                      _buildInfoRow('Merchant Name', 'UniThrift'),
                      SizedBox(height: 12),
                      _buildInfoRow('Payment Reference',
                          'UTH${DateTime.now().millisecondsSinceEpoch}'),
                      SizedBox(height: 12),
                      _buildInfoRow('FPX Transaction',
                          'FPX${DateTime.now().millisecondsSinceEpoch}'),
                      SizedBox(height: 12),
                      _buildInfoRow(
                          'Amount', 'RM ${widget.amount.toStringAsFixed(2)}'),
                      SizedBox(height: 12),
                      _buildInfoRow('Fee Amount', 'RM 0.00'),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              'Secure verification required',
                              style:
                                  TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Confirm Transaction Button
                // Update the confirm button
               Padding(
  padding: EdgeInsets.symmetric(horizontal: 40),
  child: ElevatedButton(
    onPressed: _isLoading ? null : () => _showOTPDialog(context),
    child: _isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2,
            ),
          )
        : Text('Confirm', style: TextStyle(color: Colors.black)),
    style: ElevatedButton.styleFrom(
      backgroundColor: Color.fromARGB(255, 252, 204, 4),
      minimumSize: Size(200, 45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
),
              ],
            ),
          ),
        ));
  }

  // Add this helper method in the class
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        Text(
          ':',
          style: TextStyle(color: Colors.grey[600]),
        ),
        SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _showOTPDialog(BuildContext context) async {
    setState(() {
    _isLoading = true;
  });

    try {
      // Use the user's email from widget
      await EmailOTP.sendOTP(email: widget.userEmail);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OTP sent to ${widget.userEmail}')),
      );
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: Text('Enter Email OTP'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _otpController,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit OTP',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Please enter the OTP sent to your email',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  // In the verify button onPressed callback:
                  TextButton(
                    onPressed: () async {
                      bool isValid =
                          await EmailOTP.verifyOTP(otp: _otpController.text);
                      if (isValid) {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        // Simulate transaction processing
                        await Future.delayed(const Duration(seconds: 2));

                        // Return true to indicate successful transaction
                        Navigator.of(context).pop(); // Remove loading dialog
                        Navigator.of(context).pop(); // Remove OTP dialog
                        Navigator.of(context)
                            .pop(true); // Return true to previous page
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid OTP')),
                        );
                      }
                    },
                    child: const Text('Verify'),
                  ),
                ],
              ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send OTP: $e')),
      );
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
