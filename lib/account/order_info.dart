import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderDetailsPage extends StatelessWidget {
  final String orderId;
  const OrderDetailsPage({Key? key, required this.orderId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFFE5E8D9),
      ),
      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .collection('orders')
            .doc(orderId)
            .get(),
        builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Order not found.'));
          }

          final order = snapshot.data!.data() as Map<String, dynamic>;
          final bool isCancelled = order['status'] == 'Cancelled';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(order['imageUrl'], height: 200),
                const SizedBox(height: 20),
                Text('Product: ${order['name']}',
                    style: const TextStyle(fontSize: 18)),
                Text('Order ID: ${order['orderId']}'),
                Text('Total Amount: RM${order['totalAmount']}'),
                Text('Status: ${order['status']}'),
                Text('Seller: ${order['sellerName']}'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: isCancelled
                      ? null
                      : () {
                          _showCancelConfirmation(context, order['orderId']);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCancelled
                        ? Colors.grey
                        : Colors.redAccent,
                  ),
                  child: Text(
                    isCancelled ? 'Order Cancelled' : 'Cancel Order',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: const Text(
              'Are you sure you want to cancel this order? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();  // Close dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () {
                _updateOrderStatus(orderId, 'Cancelled');
                Navigator.of(dialogContext).pop();  // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Order Cancelled Successfully!'),
                  ),
                );
              },
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .collection('orders')
        .doc(orderId)
        .update({'status': newStatus});
  }
}
