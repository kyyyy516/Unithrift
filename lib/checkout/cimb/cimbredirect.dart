import 'package:flutter/material.dart';

class CIMBRedirectPage extends StatefulWidget {
  final double amount;

  const CIMBRedirectPage({Key? key, required this.amount}) : super(key: key);

  @override
  State<CIMBRedirectPage> createState() => _CIMBRedirectPageState();
}

class _CIMBRedirectPageState extends State<CIMBRedirectPage> {
  @override
  void initState() {
    super.initState();
    _redirectAfterDelay();
  }

  void _redirectAfterDelay() {
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Simply pop back to trigger the next navigation
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
              'You are being redirected to\nCIMB Clicks secure payment page',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
