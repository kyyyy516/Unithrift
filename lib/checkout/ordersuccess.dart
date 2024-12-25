import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/account/myorder.dart';
import 'package:unithrift/account/transaction.dart';

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
      // Fetch buyer's name from Firestore
      final buyerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final buyerName = buyerDoc.data()?['username'] ?? 'Unknown Buyer';

      for (var item in widget.cartItems) {
        // Calculate total amount for the item
        double itemTotal = calculateItemTotal(item);

        // Prepare rental dates if applicable
        String? startRentalDate;
        String? endRentalDate;

        if (item['type'] == 'rental') {
          startRentalDate = item['startRentalDate'];
          endRentalDate = item['endRentalDate'];

          // Debug log to verify
          print('Rental Dates: $startRentalDate to $endRentalDate');
        }

        // Prepare service date if applicable
        String formattedServiceDate = '';
        if (item['serviceDate'] != null) {
          if (item['serviceDate'] is DateTime) {
            DateTime date = item['serviceDate'];
            formattedServiceDate = '${date.day}/${date.month}/${date.year}';
          } else if (item['serviceDate'] is String) {
            formattedServiceDate = item['serviceDate'];
          }
        }

        // Create a unique orderId and trackingNo
        String orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}';
        String trackingNo = 'TRK${DateTime.now().millisecondsSinceEpoch}';

        // Prepare the order data
        Map<String, dynamic> orderData = {
          'orderId': orderId,
          'trackingNo': trackingNo,
          'productID': item['productID'] ?? '',
          'name': item['name'] ?? 'Unknown Product',
          'price': item['price'] ?? 0.0,
          'quantity': item['quantity'] ?? 1,
          'totalAmount': itemTotal,
          'imageUrl': [item['imageUrl1'], item['imageUrl2'], item['imageUrl3']]
              .firstWhere(
            (url) =>
                url != null &&
                url.isNotEmpty &&
                !url.toLowerCase().endsWith('.mp4'),
            orElse: () => '',
          ),
          'imageUrl1': item['imageUrl1'] ?? '',
          'imageUrl2': item['imageUrl2'] ?? '',
          'imageUrl3': item['imageUrl3'] ?? '',
          'condition': item['condition'] ?? 'Unknown',
          'type': item['type'] ?? 'item',
          'serviceDate': formattedServiceDate,
          'startRentalDate': startRentalDate,
          'endRentalDate': endRentalDate,
          'orderDate': FieldValue.serverTimestamp(),
          'status': 'Pending',
          'isMeetup': widget.isMeetup,
          'address': widget.isMeetup ? 'Meetup Address' : item['address'] ?? '',
          'buyerId': user.uid,
          'buyerName': buyerName,
          'buyerEmail': user.email ?? 'No Email',
          'sellerUserId': item['sellerUserId'] ?? '',
          'sellerName': item['sellerName'] ?? 'Unknown Seller',
          'sellerEmail': item['sellerEmail'] ?? '',
          'timestamp': FieldValue.serverTimestamp(),
        };

        // Save to buyer's orders
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .doc(orderId)
            .set(orderData);

        // Save to seller's sales
        await FirebaseFirestore.instance
            .collection('users')
            .doc(item['sellerUserId'])
            .collection('sales')
            .doc(orderId)
            .set(orderData);

        // Send notifications
        await Future.wait([
          _addNotification(
            userId: user.uid,
            title: "Order Placed",
            message:
                "Your order for ${item['name']} has been successfully placed.",
            productImageUrl: item['imageUrl1'],
            type: "track",
          ),
          _addNotification(
            userId: item['sellerUserId'],
            title: "New Sale",
            message: "You have a new sale for ${item['name']}.",
            productImageUrl: item['imageUrl1'],
            type: "manage",
          ),
        ]);

        // Remove from cart if it's not a direct buy
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

  Future<void> _addNotification({
    required String userId,
    required String title,
    required String message,
    String? productImageUrl,
    required String type,
  }) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'productImageUrl': productImageUrl,
      'type': type,
    });
  }

  double calculateItemTotal(Map<String, dynamic> item) {
    if (item['type'] == 'rental') {
      final startDate = item['startRentalDate'].split('/');
      final endDate = item['endRentalDate'].split('/');

      DateTime start = DateTime(int.parse(startDate[2]),
          int.parse(startDate[1]), int.parse(startDate[0]));
      DateTime end = DateTime(
          int.parse(endDate[2]), int.parse(endDate[1]), int.parse(endDate[0]));

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
                        builder: (context) => MyOrders(),
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
              SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const TransactionHistoryPage(),
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
      'View Transaction History',
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
