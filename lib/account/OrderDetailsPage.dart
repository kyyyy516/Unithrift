import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderDetailsPage extends StatelessWidget {
  final Map<String, dynamic> sale;

  const OrderDetailsPage({Key? key, required this.sale}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'Product Information',
              icon: Icons.shopping_bag,
              child: _buildProductInfo(),
            ),
            _buildSection(
              title: 'Buyer Information',
              icon: Icons.person,
              child: _buildBuyerInfo(),
            ),
            _buildSection(
              title: 'Order Details',
              icon: Icons.receipt_long,
              child: _buildOrderDetails(),
            ),
            if (sale['type'] == 'rental') ...[
              _buildSection(
                title: 'Rental Details',
                icon: Icons.calendar_today,
                child: _buildRentalDetails(),
              ),
            ] else if (sale['type'] == 'service') ...[
              _buildSection(
                title: 'Service Details',
                icon: Icons.build_circle,
                child: _buildServiceDetails(),
              ),
            ],
            if (sale['isMeetup'] == true) ...[
              _buildSection(
                title: 'Meetup Information',
                icon: Icons.location_on,
                child: _buildMeetupDetails(),
              ),
            ] else if (!sale['isMeetup'] && sale['address'] != null) ...[
              _buildSection(
                title: 'Delivery Information',
                icon: Icons.local_shipping,
                child: _buildDeliveryDetails(),
              ),
            ],
            _buildSection(
              title: 'Status History',
              icon: Icons.history,
              child: _buildStatusHistory(sale['orderId']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          sale['imageUrl1'] ?? 'https://via.placeholder.com/100',
          width: 80,
          height: 80,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(
        sale['name'] ?? 'Unknown Product',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Condition: ${sale['condition'] ?? 'N/A'}'),
          Text('Price: RM ${sale['price']?.toStringAsFixed(2) ?? '0.00'}'),
        ],
      ),
    );
  }

  Widget _buildBuyerInfo() {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: sale['buyerProfileImage'] != null
            ? NetworkImage(sale['buyerProfileImage'])
            : null,
        backgroundColor: Colors.grey[300],
        child: sale['buyerProfileImage'] == null
            ? Text(
                sale['buyerName']?.substring(0, 1).toUpperCase() ?? 'B',
                style: const TextStyle(color: Colors.black),
              )
            : null,
      ),
      title: Text(
        sale['buyerName'] ?? 'Unknown Buyer',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(sale['buyerEmail'] ?? 'No Email'),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      children: [
        _buildDetailRow('Order ID', sale['orderId']),
        _buildDetailRow(
          'Order Date',
          DateFormat.yMMMd()
              .add_jm()
              .format((sale['orderDate'] as Timestamp).toDate()),
        ),
        _buildDetailRow('Total Amount',
            'RM ${sale['totalAmount']?.toStringAsFixed(2) ?? '0.00'}'),
        _buildDetailRow('Quantity', '${sale['quantity'] ?? 1}'),
      ],
    );
  }

  Widget _buildRentalDetails() {
    return Column(
      children: [
        _buildDetailRow('Start Date', sale['startRentalDate']),
        _buildDetailRow('End Date', sale['endRentalDate']),
      ],
    );
  }

  Widget _buildServiceDetails() {
    return Column(
      children: [
        _buildDetailRow('Service Date', sale['serviceDate']),
      ],
    );
  }

  Widget _buildMeetupDetails() {
    return Column(
      children: [
        _buildDetailRow(
          'Meetup Location',
          sale['meetingDetails']?['location'] ??
              sale['address'] ??
              'Not specified',
        ),
        if (sale['meetingDetails']?['time'] != null)
          _buildDetailRow('Date & Time', sale['meetingDetails']?['time']),
      ],
    );
  }

  Widget _buildDeliveryDetails() {
    return _buildDetailRow('Delivery Address', sale['address']);
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(String orderId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .collection('sales')
          .doc(orderId)
          .collection('statusHistory')
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No status history available.");
        }

        final statusHistory = snapshot.data!.docs;

        return Column(
          children: statusHistory.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final details = data['details'] as Map<String, dynamic>?;

            return ListTile(
              leading: const Icon(Icons.circle, color: Colors.blue, size: 12),
              title: Text(data['status'] ?? "Unknown Status"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format((data['timestamp'] as Timestamp).toDate()),
                  ),
                  if (details != null) ...[
                    if (details['location'] != null)
                      Text('Location: ${details['location']}'),
                    if (details['time'] != null)
                      Text('Date & Time: ${details['time']}'),
                  ],
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
