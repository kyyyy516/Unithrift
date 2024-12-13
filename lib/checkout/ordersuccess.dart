import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/account/myorder.dart';


class OrderSuccessPage extends StatefulWidget {
  final bool isMeetup;
  final double totalAmount;
  final List<Map<String, dynamic>> cartItems;

  const OrderSuccessPage({
    Key? key,
    required this.isMeetup,
    required this.totalAmount,
    required this.cartItems,
  }) : super(key: key);

  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  @override
  void initState() {
    super.initState(); 
    _saveOrderAndClearCart();
  }

 Future<void> _saveOrderAndClearCart() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    for (var item in widget.cartItems) {
      double itemTotal = calculateItemTotal(item);
      
      Map<String, dynamic> orderData = {
        'userId': user.uid,
        'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
        'trackingNo': 'TRK${DateTime.now().millisecondsSinceEpoch}',
        'imageUrl': [
          item['imageUrl1'],
          item['imageUrl2'],
          item['imageUrl3']
        ].firstWhere(
          (url) => url != null && 
                   url.isNotEmpty && 
                   !url.toLowerCase().endsWith('.mp4'),
          orElse: () => '',
        ),
        'imageUrl1': item['imageUrl1'] ?? '',
        'imageUrl2': item['imageUrl2'] ?? '',
        'imageUrl3': item['imageUrl3'] ?? '',
        'name': item['name'],
        'totalAmount': itemTotal,
        'status': 'processing',
        'type': item['type'] ?? 'feature',
        'condition': item['condition'] ?? '',
        // Add rental dates
        'startRentalDate': item['startRentalDate'],
        'endRentalDate': item['endRentalDate'],
        'serviceDate': item['serviceDate'],
        'quantity': item['quantity'] ?? 1,
        'timestamp': FieldValue.serverTimestamp(),
        'isMeetup': widget.isMeetup,
        'sellerName': item['sellerName'],
        'sellerUserId': item['sellerUserId'],
      };

      // Save to user's orders
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('orders')
          .add(orderData);

      // Save to seller's sales
      await FirebaseFirestore.instance
          .collection('users')
          .doc(item['sellerUserId'])
          .collection('sales')
          .add(orderData);

      // Delete from cart if not direct buy
      if (item['docId'] != 'direct-buy') {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('cart')
            .doc(item['docId'])
            .delete();
      }
    }
  }
}



double calculateItemTotal(Map<String, dynamic> item) {
  if (item['type'] == 'rental') {
    final startDate = item['startRentalDate'].split('/');
    final endDate = item['endRentalDate'].split('/');
    
    DateTime start = DateTime(
      int.parse(startDate[2]), 
      int.parse(startDate[1]), 
      int.parse(startDate[0])
    );
    DateTime end = DateTime(
      int.parse(endDate[2]), 
      int.parse(endDate[1]), 
      int.parse(endDate[0])
    );
        
    int days = end.difference(start).inDays + 1;
    return double.parse(item['price'].toString()) * days;
  } else if (item['type'] == 'service') {
    return double.parse(item['price'].toString()) * (item['quantity'] ?? 1);
  }
  return double.parse(item['price'].toString());
}



void addToOrders(List<Map<String, dynamic>> items, double totalAmount) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  for (var item in items) {
    await FirebaseFirestore.instance.collection('orders').add({
      'userId': user.uid,
      'orderId': 'ORD${DateTime.now().millisecondsSinceEpoch}',
      'trackingNo': 'TRK${DateTime.now().millisecondsSinceEpoch}',
      'imageUrl': item['imageUrl1'],
      'name': item['name'],
      'totalAmount': totalAmount,
      'status': 'processing',
      'type': item['type'] ?? 'item',
      'condition': item['condition'],
      'startDate': item['startRentalDate'],
      'endDate': item['endRentalDate'],
      'serviceDate': item['serviceDate'],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/success.png',
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 20),
              const Text(
                'Order successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF808569),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isMeetup
                    ? 'You can now message the seller to confirm on a time and place for the meet-up.'
                    : 'You can now message the seller to arrange delivery details.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) =>  MyOrders(),
    ),
  );
},

    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF808569),
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    child: const Text(
      'View Order',
      style: TextStyle(color: Colors.white),
    ),
  ),
),

              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text(
                  'Back To Home',
                  style: TextStyle(
                    color: Color(0xFFA4AA8B),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
