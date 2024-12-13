import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:email_otp/email_otp.dart';
import 'package:unithrift/checkout/ordersuccess.dart';

class CIMBTransactionPage extends StatefulWidget {
  final double amount;
  final String userEmail;

  const CIMBTransactionPage({
    Key? key,
    required this.amount,
    required this.userEmail, // Add this
  }) : super(key: key);

  @override
  State<CIMBTransactionPage> createState() => _CIMBTransactionPageState();
}

class _CIMBTransactionPageState extends State<CIMBTransactionPage> {
  final TextEditingController _otpController = TextEditingController();

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
          backgroundColor: Color(0xFFEE3124), // CIMB red color
          title: Image.asset(
            'assets/cimb2.png',
            height: 50,
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
                    onPressed: () => _showOTPDialog(context),
                    child: Text('Confirm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFEE3124),
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
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(),
                          ),
                        );

                        await Future.delayed(Duration(seconds: 2));

                        final user = FirebaseAuth.instance.currentUser;
                        final cartSnapshot = await FirebaseFirestore.instance
                            .collection('users')
                            .doc(user?.uid)
                            .collection('cart')
                            .get();

                        final cartItems = cartSnapshot.docs.map((doc) {
                          var data = doc.data();
                          data['docId'] = doc.id; // Add document ID to the data
                          return data;
                        }).toList();

                        // Create orders
                        for (var item in cartItems) {
                          await FirebaseFirestore.instance
                              .collection('orders')
                              .add({
                            'userId': user?.uid,
                            'orderId':
                                'ORD${DateTime.now().millisecondsSinceEpoch}',
                            'trackingNo':
                                'TRK${DateTime.now().millisecondsSinceEpoch}',
                            'imageUrl': item['imageUrl1'],
                            'name': item['name'],
                            'totalAmount': widget.amount,
                            'status': 'processing',
                            'type': item['type'] ?? 'item',
                            'condition': item['condition'],
                            'startDate': item['startRentalDate'],
                            'endDate': item['endRentalDate'],
                            'serviceDate': item['serviceDate'],
                            'timestamp': FieldValue.serverTimestamp(),
                            'sellerName': item['sellerName'],
                          });

                          // Clear item from cart
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user?.uid)
                              .collection('cart')
                              .doc(item['docId'])
                              .delete();
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderSuccessPage(
                              isMeetup: false,
                              totalAmount: widget.amount,
                              cartItems: cartItems,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invalid OTP')),
                        );
                      }
                    },
                    child: Text('Verify'),
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
