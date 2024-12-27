import 'package:flutter/material.dart';
import 'package:unithrift/checkout/maybank/maybanklogin.dart';

class maybankRedirectPage extends StatefulWidget {
  final double amount;

  const maybankRedirectPage({Key? key, required this.amount}) : super(key: key);

  @override
  State<maybankRedirectPage> createState() => _maybankRedirectPageState();
}

class _maybankRedirectPageState extends State<maybankRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirectAfterDelay();
  }

  void _redirectAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => maybankLoginPage(amount: widget.amount),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF808569)),
            SizedBox(height: 20),
            Text(
              'You are being redirected to\nMaybank secure payment page',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
