import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'order_info.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryPage> createState() =>
      _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transaction History',
        style: TextStyle(
          fontSize: 15,  // Adjust this to a smaller size (default is around 20-22)
          //fontWeight: FontWeight.w500,  // Optional: Adjust weight if needed
          ),
        ),
        backgroundColor: const Color(0xFFE5E8D9),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No transactions found.'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              var order = orders[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  leading: Image.network(
                    order['imageUrl'] ?? '',
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                  title: Text(order['name'] ?? 'Unknown Product'),
                  subtitle: Text(
                      'Total: RM${order['totalAmount']} • Status: ${order['status']}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailsPage(orderId: order['orderId']),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
