import 'package:flutter/material.dart';
import 'package:unithrift/checkout/bank.dart';
import 'package:unithrift/checkout/card.dart';

class PaymentMethodPage extends StatefulWidget {
  final double amount;
  final String? initialMethod;
  final Map<String, dynamic>? initialBank;
  final Map<String, dynamic>? initialCardDetails;

  const PaymentMethodPage({
    Key? key,
    required this.amount,
    this.initialMethod,
    this.initialBank,
    this.initialCardDetails,
  }) : super(key: key);

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  String? selectedMethod;
  Map<String, dynamic>? selectedBank;
  Map<String, dynamic>? cardDetails;

  @override
  void initState() {
    super.initState();
    selectedMethod = widget.initialMethod;
    selectedBank = widget.initialBank;
    cardDetails = widget.initialCardDetails;
  }

String formatCardNumber(String number) {
  if (number.length >= 4) {
    return '**** **** **** ${number.substring(number.length - 4)}';
  }
  return number;
}

  @override
  Widget build(BuildContext context) {
    // Add this boolean check
    bool canProceed = selectedMethod != null &&
        ((selectedMethod == 'fpx' && selectedBank != null) ||
            (selectedMethod == 'credit_card' && cardDetails != null) ||
            selectedMethod == 'tng');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Method'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  _buildPaymentOption(
                    'credit_card',
                    Icons.credit_card,
                    'Credit/Debit Card',
                  ),
                  const SizedBox(height: 30), // Increased gap to 30
                  _buildPaymentOption(
                    'fpx',
                    Icons.account_balance,
                    'Online Banking (FPX)',
                  ),
                  const SizedBox(height: 30), // Increased gap to 30
                  _buildPaymentOption(
                    'tng',
                    Icons.wallet,
                    'Touch n Go eWallet',
                  ),
                  const SizedBox(height: 30), // Added gap after last option
                  // Replace the Total Amount Text widget with:
                  Container(
                    width: double.infinity, // Takes full width
                    alignment: Alignment.center, // Centers the child
                    child: Text(
                      'Total Amount: RM ${widget.amount.toStringAsFixed(2)}',
                      textAlign: TextAlign.center, // Centers the text
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canProceed
                    ? () {
                        // Create a result map with all payment details
                        final paymentResult = {
                          'method': selectedMethod,
                          'bank': selectedBank,
                          'cardDetails': cardDetails,
                        };
                        // Pop and return the result map
                        Navigator.pop(context, paymentResult);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF808569),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Choose Payment',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String method, IconData icon, String title) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          selectedMethod = method;
        });

        if (method == 'fpx') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BankSelectionPage()),
          );
          if (result != null) {
            setState(() {
              selectedBank = result;
            });
          }
        } else if (method == 'credit_card') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CardDetailsPage()),
          );
          if (result != null) {
            setState(() {
              cardDetails = result;
            });
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color:
              selectedMethod == method ? const Color(0xFFE5E8D9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon),
                    const SizedBox(width: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (method == 'fpx' || method == 'credit_card')
                  const Icon(Icons.arrow_forward_ios),
              ],
            ),
            if (selectedMethod == method) ...[
              if (method == 'credit_card' && cardDetails != null)
                Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        formatCardNumber(cardDetails!['cardNumber']), // Use cardNumber instead of last4
        style: TextStyle(color: Colors.grey[600]),
      ),
    ),
              if (method == 'fpx' && selectedBank != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Image.asset(
                        selectedBank!['icon'],
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        selectedBank!['name'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
