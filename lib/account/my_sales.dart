import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:unithrift/chatscreen.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class MySalesPage extends StatefulWidget {
  const MySalesPage({super.key});

  @override
  State<MySalesPage> createState() => _MySalesPageState();
}

class _MySalesPageState extends State<MySalesPage> {
  int _selectedTabIndex = 0;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<Map<String, dynamic>>> getSalesData() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('sales')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> salesData = [];

      for (var doc in snapshot.docs) {
        var data = doc.data();
        data['orderId'] = doc.id;

        // Fetch buyer's profile image
        if (data['buyerId'] != null) {
          final buyerDoc =
              await _db.collection('users').doc(data['buyerId']).get();
          if (buyerDoc.exists) {
            data['buyerProfileImage'] = buyerDoc.data()?['profileImage'];
          }
        }
        salesData.add(data);
      }
      return salesData;
    });
  }

  void _updateOrderStatus(String orderId, String status,
      {String? location, String? time}) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final sellerId = currentUser.uid;

      // Update order status in Firestore
      final Map<String, dynamic> updateData = {'status': status};

      if (status == 'Meeting Scheduled') {
        updateData['meetingDetails'] = {
          'location': location ?? 'Not set',
          'time': time ?? 'Not set',
        };
      }

      // Update seller's sales subcollection
      await _db
          .collection('users')
          .doc(sellerId)
          .collection('sales')
          .doc(orderId)
          .update(updateData);

      // Fetch the order details from Firestore
      final orderSnapshot = await _db
          .collection('users')
          .doc(sellerId)
          .collection('sales')
          .doc(orderId)
          .get();

      if (!orderSnapshot.exists) return;

      final orderData = orderSnapshot.data();
      if (orderData == null) return;

      final buyerId = orderData['buyerId'];

      if (buyerId != null) {
        // Update buyer's orders subcollection
        await _db
            .collection('users')
            .doc(buyerId)
            .collection('orders')
            .doc(orderId)
            .update(updateData);

        // Notify buyer of status update
        await _addNotification(
          userId: buyerId,
          title: 'Order Status Updated',
          message: 'Your order status has been updated to "$status".',
          productImageUrl: orderData['imageUrl1'],
          type: 'track',
        );

        // If the order is completed, prompt for a review
        if (status == 'Completed') {
          _promptForReview(
            orderId,
            sellerId,
            buyerId,
            {
              'productId': orderData['productID'], // Ensure correct field names
              'productName': orderData['name'],
              'productImage': orderData['imageUrl1'],
              'productPrice': orderData['price'],
            },
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  void _promptForReview(
    String orderId,
    String reviewerId,
    String userId,
    Map<String, dynamic> productDetails,
  ) {
    final reviewController = TextEditingController();
    double selectedRating = 5.0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(labelText: 'Write a review'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Rating:'),
                  const SizedBox(width: 10),
                  RatingBar.builder(
                    initialRating: selectedRating,
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 30.0, // Adjust size to make the stars smaller
                    itemBuilder: (context, _) => const Icon(
                      Icons.star,
                      color: Colors.amber,
                    ),
                    onRatingUpdate: (rating) {
                      selectedRating = rating;
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (reviewController.text.isNotEmpty) {
                  _addReview(
                    reviewerId,
                    userId,
                    orderId,
                    productDetails,
                    selectedRating,
                    reviewController.text,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please add a review text')),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addReview(
    String reviewerId,
    String userId,
    String orderId,
    Map<String, dynamic> productDetails,
    double rating,
    String reviewText,
  ) async {
    try {
      // Fetch the reviewer's name from the Firestore 'users' collection
      String reviewerName = 'Anonymous'; // Default fallback
      final reviewerDoc = await _db.collection('users').doc(reviewerId).get();
      if (reviewerDoc.exists) {
        reviewerName = reviewerDoc.data()?['username'] ?? 'Anonymous';
      }

      final reviewRef =
          _db.collection('users').doc(userId).collection('reviews');

      // Add review to Firestore
      await reviewRef.add({
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'orderId': orderId,
        'productId': productDetails['productId'],
        'productName': productDetails['productName'],
        'productImage': productDetails['productImage'],
        'productPrice': productDetails['productPrice'],
        'rating': rating,
        'reviewText': reviewText,
        'role': 'seller', // Specify role of reviewer
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Calculate the new average rating
      final reviewsSnapshot = await reviewRef.get();
      double totalRating = 0;
      for (var review in reviewsSnapshot.docs) {
        totalRating += (review.data()['rating'] as double);
      }
      final averageRating = totalRating / reviewsSnapshot.docs.length;

      // Update the user's rating field in their profile
      await _db.collection('users').doc(userId).update({
        'rating': averageRating,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    }
  }

  Future<void> _addNotification({
    required String userId,
    required String title,
    required String message,
    String? productImageUrl, // Optional parameter for product image URL
    required String type, // Add type to categorize notifications
  }) async {
    await _db.collection('users').doc(userId).collection('notifications').add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
      'productImageUrl': productImageUrl, // Add product image URL
      'type': type, // Specify notification type
    });
  }

  void _showMeetingDetailsDialog(String orderId) {
    final locationController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set Meeting Details'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: locationController,
                    decoration:
                        const InputDecoration(labelText: 'Meeting Location'),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? DateFormat.yMMMd().format(selectedDate!)
                                : 'Select Date',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Select Time',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.access_time),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDate == null ||
                        selectedTime == null ||
                        locationController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please provide all meeting details')),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    _updateOrderStatus(
                      orderId,
                      'Meeting Scheduled',
                      location: locationController.text,
                      time:
                          '${DateFormat.yMMMd().format(selectedDate!)} ${selectedTime!.format(context)}',
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _navigateToChat(Map<String, dynamic> sale) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && sale['buyerId'] != null) {
      final buyerId = sale['buyerId'];
      final chatId = _generateChatId(currentUser.uid, buyerId);

      // Check if the chat room exists
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();

      // Create or update the chat room with order-specific details
      if (!chatDoc.exists) {
        await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
          'users': [currentUser.uid, buyerId],
          'createdAt': FieldValue.serverTimestamp(),
          'contextType': 'sales', // Indicates this chat is from sales page
          'orderId': sale['orderId'],
          'productName': sale['name'],
          'productImage': sale['imageUrl1'],
        });
      } else {
        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .update({
          'contextType': 'sales',
          'orderId': sale['orderId'],
          'productName': sale['name'],
          'productImage': sale['imageUrl1'],
        });
      }

      // Navigate to the chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(chatId: chatId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start chat.')),
      );
    }
  }

  String _generateChatId(String userId1, String userId2) {
    return (userId1.compareTo(userId2) < 0)
        ? '$userId1\_$userId2'
        : '$userId2\_$userId1';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront, color: Colors.black),
            SizedBox(width: 8),
            Text(
              "My Sales",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabRow(),
          const SizedBox(height: 10),
          Expanded(child: _buildContentSection()),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Row(
      children: [
        _buildTab(0, 'All'),
        _buildTab(1, 'Ongoing'),
        _buildTab(2, 'Completed'),
      ],
    );
  }

  Widget _buildTab(int index, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? const Color(0xFFE5E8D9)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _selectedTabIndex == index ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getSalesData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              'No sales data available.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        // Filter data by selected tab
        List<Map<String, dynamic>> filteredData;
        switch (_selectedTabIndex) {
          case 1:
            filteredData = snapshot.data!
                .where((sale) => sale['status'] != 'Completed')
                .toList();
            break;
          case 2:
            filteredData = snapshot.data!
                .where((sale) => sale['status'] == 'Completed')
                .toList();
            break;
          default:
            filteredData = snapshot.data!;
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: filteredData.length,
          itemBuilder: (context, index) {
            final sale = filteredData[index];
            return _buildSalesCard(sale);
          },
        );
      },
    );
  }

  Widget _buildSalesCard(Map<String, dynamic> sale) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: const EdgeInsets.all(15), // Increased padding for the container
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buyer Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20, // Slightly larger for better visibility
                backgroundImage: sale['buyerProfileImage'] != null
                    ? NetworkImage(sale['buyerProfileImage'])
                    : null,
                backgroundColor: const Color(0xFF808569),
                child: sale['buyerProfileImage'] == null
                    ? Text(
                        sale['buyerName']?.substring(0, 1).toUpperCase() ?? 'B',
                        style: const TextStyle(color: Colors.white),
                      )
                    : null,
              ),
              const SizedBox(width: 15), // Increased spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale['buyerName'] ?? 'Unknown Buyer',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (sale['buyerEmail'] != null)
                      Text(
                        sale['buyerEmail'],
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_outlined),
                onPressed: () => _navigateToChat(sale),
              ),
            ],
          ),
          const SizedBox(height: 15), // Space between sections

          // Product Section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  sale['imageUrl1'] ?? 'https://via.placeholder.com/100',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.image_not_supported, size: 50),
                ),
              ),
              const SizedBox(width: 15), // Increased spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sale['name'] ?? 'Unknown Product',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 5), // Space between product details
                    Text(
                      'RM ${sale['price']?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 5), // Space between product details
                    if (sale['orderId'] != null)
                      Text(
                        'Order ID: ${sale['orderId']}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    if (sale['orderDate'] != null)
                      Text(
                        'Order Date: ${DateFormat.yMMMd().format((sale['orderDate'] as Timestamp).toDate())}',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15), // Space between sections

          // Meeting Details Section
          if (sale['status'] == 'Meeting Scheduled' &&
              sale['meetingDetails'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(), // Divider for better visual separation
                const Text(
                  'Meeting Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 5), // Space between title and details
                Text(
                  'Location: ${sale['meetingDetails']['location']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  'Date & Time: ${sale['meetingDetails']['time']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          const SizedBox(height: 15), // Space between sections

          // Order Status Section
          DropdownButtonFormField<String>(
            value: sale['status'],
            decoration: const InputDecoration(
              labelText: 'Order Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
              DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
              DropdownMenuItem(
                  value: 'Meeting Scheduled', child: Text('Meeting Scheduled')),
              DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
              DropdownMenuItem(
                  value: 'In Progress', child: Text('In Progress')),
              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
              DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              if (value == 'Meeting Scheduled') {
                _showMeetingDetailsDialog(sale['orderId']);
              } else {
                _updateOrderStatus(sale['orderId'], value!);
              }
            },
          ),
        ],
      ),
    );
  }
}
