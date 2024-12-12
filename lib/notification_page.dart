import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  String selectedCategory = "All"; // Default to show all notifications

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(child: Text("User not logged in!"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Padding(
          padding: EdgeInsets.only(left: 10.0), // Add left padding
          child: Text("Notifications"),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton(
                    label: "All Notifications",
                    isSelected: selectedCategory == "All",
                    onTap: () {
                      setState(() {
                        selectedCategory = "All";
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildFilterButton(
                    label: "Manage Orders",
                    isSelected: selectedCategory == "orders",
                    onTap: () {
                      setState(() {
                        selectedCategory = "orders";
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildFilterButton(
                    label: "Track Orders",
                    isSelected: selectedCategory == "track",
                    onTap: () {
                      setState(() {
                        selectedCategory = "track";
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: _buildNotificationList(currentUser.uid, selectedCategory),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 35, // Fixed height for consistency
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5E8D9) : Colors.white,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11, // Font size for labels
            color: isSelected ? Colors.black : Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(String userId, String category) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications');

    // Adjust filtering logic based on category
    final filteredQuery = category == "All"
        ? query.orderBy('timestamp', descending: true)
        : query
            .where('type', isEqualTo: category == "orders" ? "manage" : "track")
            .orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: filteredQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading notifications: ${snapshot.error}"),
          );
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Text(
              category == "All"
                  ? "No notifications available."
                  : category == "orders"
                      ? "No order management notifications."
                      : "No order tracking notifications.",
            ),
          );
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification =
                notifications[index].data() as Map<String, dynamic>;

            // Format the timestamp
            final Timestamp? timestamp =
                notification['timestamp'] as Timestamp?;
            final String formattedTime = timestamp != null
                ? DateFormat('MMM dd, yyyy | hh:mm a')
                    .format(timestamp.toDate())
                : 'Unknown time';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: notification['productImageUrl'] != null
                        ? Image.network(
                            notification['productImageUrl'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image),
                  ),
                  title: Text(
                    notification['title'],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: notification['isRead']
                          ? FontWeight.w400
                          : FontWeight.w600, // Bold for unread
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification['message'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formattedTime,
                        style:
                            const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  trailing: notification['isRead']
                      ? const Icon(Icons.check_circle,
                          color: Colors.green, size: 20)
                      : IconButton(
                          icon: const Icon(Icons.circle,
                              color: Colors.red, size: 20),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .collection('notifications')
                                .doc(notifications[index].id)
                                .update({'isRead': true});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Notification marked as read"),
                              ),
                            );
                          },
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
