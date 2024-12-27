import 'package:flutter/material.dart';
import 'package:unithrift/checkout/hongleong/hongleonglogin.dart';

class hongleongRedirectPage extends StatefulWidget {
  final double amount;

  const hongleongRedirectPage({Key? key, required this.amount}) : super(key: key);

  @override
  State<hongleongRedirectPage> createState() => _hongleongRedirectPageState();
}

class _hongleongRedirectPageState extends State<hongleongRedirectPage> {
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
          builder: (context) => hongleongLoginPage(amount: widget.amount),
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
              'You are being redirected to\nHLB secure payment page',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
