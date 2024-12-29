
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/checkout/cimb/cimblogin.dart';
import 'package:unithrift/checkout/cimb/cimbredirect.dart';
import 'package:unithrift/checkout/cimb/cimbtransaction.dart';
import 'package:unithrift/checkout/hongleong/hongleonglogin.dart';
import 'package:unithrift/checkout/hongleong/hongleongredirect.dart';
import 'package:unithrift/checkout/hongleong/hongleongtransaction.dart';
import 'package:unithrift/checkout/maybank/maybanklogin.dart';
import 'package:unithrift/checkout/maybank/maybankredirect.dart';
import 'package:unithrift/checkout/maybank/maybanktransaction.dart';
import 'package:unithrift/checkout/ordersuccess.dart';
import 'package:unithrift/checkout/payment.dart';

class CheckoutPage extends StatefulWidget {
  final double totalAmount;
  final int itemCount;
  final List<Map<String, dynamic>> cartItems;
  final String sellerName;

  // Update constructor
  const CheckoutPage({
    Key? key,
    required this.totalAmount,
    required this.itemCount,
    required this.cartItems,
    required this.sellerName,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String selectedDealMethod = '';
  final TextEditingController addressController = TextEditingController();
  String? selectedPaymentMethod;
  Map<String, dynamic>? selectedBank;
  Map<String, dynamic>? cardDetails;
  final double processingFee = 1.00;
  final double deliveryFee = 5.00;
  late double finalTotal;

  bool get isFormValid =>
      selectedDealMethod.isNotEmpty &&
      addressController.text.trim().isNotEmpty &&
      selectedPaymentMethod != null;

// Add this method to your _CheckoutPageState class
  IconData getPaymentIcon(String method) {
    switch (method) {
      case 'credit_card':
        return Icons.credit_card;
      case 'fpx':
        return Icons.account_balance;
      case 'tng':
        return Icons.wallet;
      default:
        return Icons.payment;
    }
  }

  Future<void> _handlePayment() async {
  if (selectedDealMethod == 'delivery' && addressController.text.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a delivery address')),
    );
    return;
  }

  final user = FirebaseAuth.instance.currentUser;

  if (selectedPaymentMethod == 'fpx') {
    if (selectedBank?['name'] == 'CIMB') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CIMBRedirectPage(amount: finalTotal),
        ),
      );

      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CIMBLoginPage(amount: finalTotal),
        ),
      );

      if (loginResult == true) {
        final transactionResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CIMBTransactionPage(
              amount: finalTotal,
              userEmail: user?.email ?? '',
            ),
          ),
        );

        if (transactionResult == true) {
          await _processOrder();
        }
      }
    } else if (selectedBank?['name'] == 'Maybank') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => maybankRedirectPage(amount: finalTotal),
        ),
      );

      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => maybankLoginPage(amount: finalTotal),
        ),
      );

      if (loginResult == true) {
        final transactionResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => maybankTransactionPage(
              amount: finalTotal,
              userEmail: user?.email ?? '',
            ),
          ),
        );

        if (transactionResult == true) {
          await _processOrder();
        }
      }
    } else if (selectedBank?['name'] == 'HongLeong') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => hongleongRedirectPage(amount: finalTotal),
        ),
      );

      final loginResult = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => hongleongLoginPage(amount: finalTotal),
        ),
      );

      if (loginResult == true) {
        final transactionResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => hongleongTransactionPage(
              amount: finalTotal,
              userEmail: user?.email ?? '',
            ),
          ),
        );

        if (transactionResult == true) {
          await _processOrder();
        }
      }
    }
  } else if (selectedPaymentMethod == 'credit_card' || selectedPaymentMethod == 'tng') {
    await _processOrder();
  }
}



// In CheckoutPage, modify _processOrder to just handle navigation
Future<void> _processOrder() async {
  await Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => OrderSuccessPage(
        isMeetup: selectedDealMethod == 'meetup',
        totalAmount: finalTotal,
        cartItems: widget.cartItems.map((item) {
          return {
            ...item,
            'address': selectedDealMethod == 'delivery'
                ? addressController.text
                : 'Meetup Address',
          };
        }).toList(),
      ),
    ),
  );
}


  String formatCardNumber(String number) {
    if (number.length >= 4) {
      return '**** **** **** ${number.substring(number.length - 4)}';
    }
    return number;
  }

  Future<void> saveOrderAndSale(Map<String, dynamic> orderData) async {
    final user = FirebaseAuth.instance.currentUser;
    final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';

    // Save to user's orders
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('orders')
        .doc(orderId)
        .set(orderData);

    // Save to seller's sales
    await FirebaseFirestore.instance
        .collection('users')
        .doc(orderData['sellerUserId'])
        .collection('sales')
        .doc(orderId)
        .set(orderData);
  }

  Future<List<Map<String, dynamic>>> _getCartItems() async {
    final user = FirebaseAuth.instance.currentUser;
    final cartSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('cart')
        .get();

    return cartSnapshot.docs.map((doc) => doc.data()).toList();
  }

// Add this method to get formatted payment method text
  String getPaymentText(String method) {
    switch (method) {
      case 'credit_card':
        return 'Credit/Debit Card';
      case 'fpx':
        return 'Online Banking (FPX)';
      case 'tng':
        return 'Touch n Go eWallet';
      default:
        return 'Payment Method';
    }
  }

  @override
  void initState() {
    super.initState();
    _updateFinalTotal(); // Add this
    // Add listener to rebuild when address changes
    addressController.addListener(() {
      setState(() {});
    });
  }

  void _updateFinalTotal() {
    finalTotal = widget.totalAmount +
        processingFee +
        (selectedDealMethod == 'delivery' ? deliveryFee : 0);
  }

  @override
  void dispose() {
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Deal Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedDealMethod = 'meetup';
                      _updateFinalTotal(); // Add this
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedDealMethod == 'meetup'
                            ? const Color(0xFFE5E8D9)
                            : Colors.white,
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
                        children: const [
                          Icon(Icons.people),
                          SizedBox(height: 8),
                          Text('Meet/Pickup'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() {
                      selectedDealMethod = 'delivery';
                      _updateFinalTotal(); // Add this
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selectedDealMethod == 'delivery'
                            ? const Color(0xFFE5E8D9)
                            : Colors.white,
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
                        children: const [
                          Icon(Icons.local_shipping),
                          SizedBox(height: 8),
                          Text('Delivery'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
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
              child: TextField(
                controller: addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                  border: InputBorder.none,
                  hintText: 'Enter your address...',
                ),
              ),
            ),
            const SizedBox(height: 30),
            // In the CheckoutPage class, update the payment method GestureDetector:

            GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentMethodPage(
                        amount: finalTotal,
                        initialMethod: selectedPaymentMethod,
                        initialBank: selectedBank,
                        initialCardDetails: cardDetails,
                      ),
                    ),
                  );

                  if (result != null) {
                    setState(() {
                      selectedPaymentMethod = result['method'];
                      selectedBank = result['bank'];
                      cardDetails = result['cardDetails'];
                    });
                  }
                },
                // Replace the existing payment method GestureDetector child
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                              Icon(selectedPaymentMethod == null
                                  ? Icons.payment
                                  : getPaymentIcon(selectedPaymentMethod!)),
                              const SizedBox(width: 12),
                              Text(selectedPaymentMethod == null
                                  ? 'Payment Method'
                                  : getPaymentText(selectedPaymentMethod!)),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios),
                        ],
                      ),
                      if (selectedPaymentMethod != null) ...[
                        const SizedBox(height: 8),
                        _buildPaymentMethodDetails(),
                      ],
                    ],
                  ),
                )),

            const SizedBox(height: 30),
            _buildPriceRow('${widget.itemCount} items', widget.totalAmount),
            if (selectedDealMethod == 'delivery')
              _buildPriceRow('Delivery Fee', deliveryFee),
            _buildPriceRow('Processing Fee', processingFee),
            const Divider(),
            _buildPriceRow('Total Price', finalTotal, isTotal: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isFormValid ? _handlePayment : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isFormValid ? const Color(0xFF808569) : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Submit Order',
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

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodDetails() {
    if (selectedPaymentMethod == null) return const SizedBox.shrink();

    if (selectedPaymentMethod == 'credit_card' && cardDetails != null) {
      return Text(
        formatCardNumber(cardDetails!['cardNumber']),
        style: TextStyle(color: Colors.grey[600]),
      );
    }

    if (selectedPaymentMethod == 'fpx' && selectedBank != null) {
      return Row(
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
      );
    }

    return const SizedBox.shrink();
  }
}





