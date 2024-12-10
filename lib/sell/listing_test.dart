import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:chewie/chewie.dart';
// Add this import at the top
import '../sell/edit_test.dart';
import '../services/cloudinary_service.dart';

class ListingPage extends StatefulWidget {
  final Map<String, dynamic> product; // Make it optional with ?

  const ListingPage({super.key, required this.product});

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  int _currentImageIndex = 0;
  bool _isVideo = false;
  List<Map<String, dynamic>> ratings = [];
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    print(
        'All Product Data: ${widget.product}'); // Add this line to check what data is coming in, debug
    print('Brand/Edition value: ${widget.product['brand']}');
  }

  // Add this method to get formatted time
  String getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return 'Recently';

    DateTime uploadTime;
    if (timestamp is Timestamp) {
      uploadTime = timestamp.toDate();
    } else if (timestamp is int) {
      uploadTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return 'Recently';
    }

    Duration difference = DateTime.now().difference(uploadTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 365) {
      int months = (difference.inDays / 30).floor();
      return '$months months ago';
    } else {
      int years = (difference.inDays / 365).floor();
      return '$years years ago';
    }
  }

  Future<void> _deleteItem() async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Deletion'),
              content: const Text('Are you sure you want to delete this item?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) return;

      // First delete the media from Cloudinary
      String publicId = widget.product['mediaUrl']; // store the public_id
      bool cloudinaryDeleteSuccess = await deleteFromCloudinary(publicId);

      if (!cloudinaryDeleteSuccess) {
        throw Exception('Failed to delete the media.');
      }

      // Then delete product from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product['userId'])
          .collection('products')
          .doc(widget.product['productID'])
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deleted successfully')),
        );
        Navigator.pop(context); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting item: $e')),
        );
      }
    }
  }

  void _editProduct() {
    // Navigate to edit product page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductPage(
          productID: widget.product['productID'],
          userID: widget.product['userId'],
        ),
      ),
    );
  }

// Add this method to toggle availability
  Future<void> _toggleAvailability() async {
    try {
      final currentAvailability = widget.product['isAvailable'] ?? true;

      // Add confirmation dialog
      bool? confirm = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Confirm Change'),
            content: Text(currentAvailability
                ? 'Mark this item as unavailable?'
                : 'Make this item available again?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Confirm'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      // Only proceed if confirmed
      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.product['userId'])
            .collection('products')
            .doc(widget.product['productID'])
            .update({'isAvailable': !currentAvailability});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(currentAvailability
                  ? 'Item marked as unavailable'
                  : 'Item marked as available'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating availability: $e')),
        );
      }
    }
  }

  Widget _buildActionButtons() {
    final isAvailable = widget.product['isAvailable'] ?? true;

    return Container(
      padding: const EdgeInsets.all(8.0),
      height: 60, // Add fixed height
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Show different content based on availability
          if (isAvailable) ...[
            // Edit button
            IconButton(
              icon: const Icon(Icons.edit),
              color: const Color(0xFF808569),
              onPressed: () {
                _editProduct();
              },
            ),
            // Visibility toggle
            IconButton(
              icon: const Icon(Icons.visibility),
              color: const Color(0xFF808569),
              onPressed: _toggleAvailability,
            ),
            // Delete button
            IconButton(
              icon: const Icon(Icons.delete),
              color: const Color(0xFF808569),
              onPressed: _deleteItem,
            ),
          ] else ...[
            // Message and toggle for unavailable items
            Expanded(
              child: GestureDetector(
                onTap: _toggleAvailability,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.visibility_off,
                      color: Color(0xFF808569),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Make it available?',
                      style: TextStyle(
                        color: Color(0xFF808569),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = [
      widget.product['imageUrl1'] ?? 'https://via.placeholder.com/50',
      widget.product['imageUrl2'] ?? 'https://via.placeholder.com/50',
      widget.product['imageUrl3'] ?? 'https://via.placeholder.com/50',
    ];

    // Filter out placeholder images
    images.removeWhere((image) => image == 'https://via.placeholder.com/50');

    final isAvailable = widget.product['isAvailable'] ?? true;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['name'] ?? 'Product Details'),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Media section (Images and Video)
                if (images.isNotEmpty ||
                    widget.product['videoUrl'] != null) ...[
                  Stack(
                    children: [
                      if (!_isVideo) ...[
                        // Image carousel
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 300,
                            enlargeCenterPage: true,
                            viewportFraction: 1.0,
                            enableInfiniteScroll: images.length > 1,
                            onPageChanged: (index, reason) {
                              setState(() {
                                _currentImageIndex = index;
                              });
                            },
                          ),
                          items: images.map((imageUrl) {
                            return Image.network(
                              imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        // Video player
                        if (_chewieController != null)
                          SizedBox(
                            height: 300,
                            child: Chewie(controller: _chewieController!),
                          ),
                      ],
                      // Media toggle button
                      if (widget.product['videoUrl'] != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FloatingActionButton.small(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            child: Icon(
                              _isVideo ? Icons.image : Icons.play_circle,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isVideo = !_isVideo;
                              });
                            },
                          ),
                        ),
                    ],
                  ),
                  // Dot indicators for images
                  if (!_isVideo && images.length > 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: images.asMap().entries.map((entry) {
                        return Container(
                          width: 8.0,
                          height: 8.0,
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.withOpacity(
                                _currentImageIndex == entry.key ? 0.9 : 0.4),
                          ),
                        );
                      }).toList(),
                    ),
                ],

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['name'] ?? 'No Name',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Add this where you display product details
                      Text(
                        "Posted ${getTimeAgo(widget.product['timestamp'] ?? widget.product['createdAt'])}",
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 5),
                      Text(
                        //"RM ${widget.product['price'] ?? '0'}",
                        "RM ${(double.parse(widget.product['price'].toString())).toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Category\n",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF808569),
                              ),
                            ),
                            TextSpan(
                              text: "${widget.product['category'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Condition\n",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF808569),
                              ),
                            ),
                            TextSpan(
                              text: "${widget.product['condition'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Brand\n",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF808569),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.product['brand']?.toString().isEmpty ?? true ? 'N/A' : widget.product['brand']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Description\n",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF808569),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.product['details']?.toString().isEmpty ?? true ? 'N/A' : widget.product['details']}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                // Bottom padding for navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
          Positioned(
            // Add this at the end of Stack children
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionButtons(),
          ),

          // Unavailable overlay that stops before action buttons
          if (!isAvailable)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              // Bottom position stops above action buttons
              bottom:
                  60, // Adjust this value based on your action buttons height
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.grey.withOpacity(0.9), // 0.7
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.not_interested,
                        color: Colors.white,
                        size: 50,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TEMPORARILY UNAVAILABLE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF808569),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
