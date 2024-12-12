import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:unithrift/chatscreen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';

class ItemServicePage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ItemServicePage({super.key, required this.product});

  @override
  State<ItemServicePage> createState() => _ItemServicePageState();
}

class _ItemServicePageState extends State<ItemServicePage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isVideo = false;
  List<Map<String, dynamic>> ratings = [];
  double averageRating = 0;
  bool showAllComments = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  double globalAverageRating = 0.0;
  List<dynamic> globalRatings = [];

  DateTime? selectedDate;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
    _initializeVideo();
    fetchGlobalSellerRatings();
  }

  Future<void> fetchGlobalSellerRatings() async {
    try {
      final sellerId = widget.product['userId'];
      List<double> allRatings = [];
      List<dynamic> allComments = [];

      // Get user document reference
      DocumentReference userRef =
          FirebaseFirestore.instance.collection('users').doc(sellerId);

      // Get all products from user's products subcollection
      QuerySnapshot productsSnapshot =
          await userRef.collection('products').get();

      // Process each product's ratings
      for (var product in productsSnapshot.docs) {
        Map<String, dynamic> productData =
            product.data() as Map<String, dynamic>;

        // Get ratings for each product regardless of type
        QuerySnapshot ratingSnapshot = await userRef
            .collection('products')
            .doc(product.id)
            .collection('rating')
            .get();

        // Process ratings
        for (var rating in ratingSnapshot.docs) {
          Map<String, dynamic> ratingData =
              rating.data() as Map<String, dynamic>;
          var ratingValue = ratingData['rating'];

          if (ratingValue != null) {
            double ratingDouble;
            if (ratingValue is String) {
              ratingDouble = double.parse(ratingValue);
            } else {
              ratingDouble = (ratingValue as num).toDouble();
            }
            allRatings.add(ratingDouble);
            allComments.add(ratingData);
          }
        }
      }

      // Update state with combined ratings
      setState(() {
        globalRatings = allComments;
        globalAverageRating = allRatings.isNotEmpty
            ? allRatings.reduce((a, b) => a + b) / allRatings.length
            : 0.0;
      });
    } catch (e) {
      print('Error fetching global ratings: $e');
    }
  }

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

  void _showServiceBottomSheet() async {
    // Check if item exists in cart first
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart')
          .where('productID', isEqualTo: widget.product['productID'])
          .get();

      if (cartSnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product['name']} already exists in cart'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
        return;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            double totalPrice =
                quantity * double.parse(widget.product['price'].toString());

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Service Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Color(0xFF808569),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'To ensure the best purchase experience, we encourage you to chat with the seller first to discuss your needs.',
                              style: TextStyle(
                                color: Color(0xFF808569),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Date Selection
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFF808569), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2025),
                              builder: (context, child) {
                                return Theme(
                                  data: ThemeData.light().copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF424632),
                                      onPrimary: Colors.white,
                                      surface: Color(0xFFF2F3EC),
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today,
                                    color: Color(0xFF808569)),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Service Date',
                                      style: TextStyle(
                                        color: Color(0xFF808569),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      selectedDate != null
                                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                                          : 'Select date',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Quantity Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity', style: TextStyle(fontSize: 16)),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                if (quantity > 1) {
                                  setState(() => quantity--);
                                }
                              },
                            ),
                            Text('$quantity',
                                style: const TextStyle(fontSize: 16)),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                setState(() => quantity++);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Total Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          'RM ${totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Confirm Button
                    ElevatedButton(
                      onPressed: selectedDate != null
                          ? () {
                              Navigator.pop(context);
                              // Add to cart with the selected options
                              Map<String, dynamic> serviceProduct = {
                                ...widget.product,
                                'serviceDate': selectedDate,
                                'quantity': quantity,
                              };
                              _addToCart(serviceProduct, 'service');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF808569),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Add this helper method to match ChatList's ID generation
  String _generateChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  Future<void> _initializeVideo() async {
    if (widget.product['videoUrl'] != null) {
      String videoUrl = widget.product['videoUrl'];
      // Modify Google Drive URL for video
      videoUrl =
          videoUrl.replaceAll('view?usp=sharing', 'uc?export=download&id=');
      _videoController = VideoPlayerController.network(videoUrl);
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        placeholder: const Center(child: CircularProgressIndicator()),
        autoInitialize: true,
      );
      setState(() {});
    }
  }

  Future<void> _fetchRatings() async {
    try {
      // Use document ID directly
      final sellerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product['userId'])
          .get();

      if (sellerDoc.exists) {
        final ratingsSnapshot = await sellerDoc.reference
            .collection('products')
            .doc(widget.product['productID'])
            .collection('rating')
            .get();

        final List<Map<String, dynamic>> ratingsList = [];
        double totalRating = 0;

        for (var doc in ratingsSnapshot.docs) {
          final data = doc.data();
          // Get buyer info using document ID
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(data['buyerID'])
              .get();

          final userEmail =
              userDoc.data()?['email'] ?? 'unknown@graduate.com.my';
          final maskedEmail = '${userEmail[0]}****@${userEmail.split('@')[1]}';

          ratingsList.add({
            'buyerId': data['buyerID'],
            'comment': data['comment'],
            'rating': double.parse(data['rating'].toString()),
            'createdAt': data['createdAt'],
            'userEmail': maskedEmail,
          });
          totalRating += double.parse(data['rating'].toString());
        }

        setState(() {
          ratings = ratingsList;
          averageRating = ratings.isEmpty ? 0 : totalRating / ratings.length;
        });
      }
    } catch (e) {
      print('Error fetching ratings: $e');
    }
  }

  void _addToCart(Map<String, dynamic> product, String type) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      // Check if product already exists in cart
      final cartSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart')
          .where('productID', isEqualTo: product['productID'])
          .get();

      if (cartSnapshot.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item already exists in cart')),
          );
        }
        return;
      }

      // Add new item to cart
      final cartItem = {
        'productID': product['productID'],
        'name': product['name'],
        'price': product['price'],
        'imageUrl1': product['imageUrl1'],
        'condition': product['condition'],
        'type': type,
        'addedAt': FieldValue.serverTimestamp(),
        'sellerUserId': product['userId'],
        'sellerName': product['username'],
        'sellerEmail': product['userEmail'],
        'category': product['category'],
        // Add service-specific fields
        if (type == 'service') ...{
          'serviceDate': product['serviceDate'],
          'quantity': product['quantity'] ?? 1,
        }
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('cart')
          .add(cartItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product['name']} added to cart'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'No date';

    // Handle both Timestamp and Map cases
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is Map) {
      date = DateTime.fromMillisecondsSinceEpoch(timestamp['_seconds'] * 1000 +
          (timestamp['_nanoseconds'] ~/ 1000000));
    } else {
      return 'Invalid date';
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSellerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 6, bottom: 4),
          child: Text(
            'Seller Info',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            color: Color(0xFFD8DCC6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 20),
              Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 50,
                    child: Text(
                      widget.product['username']?[0].toUpperCase() ?? 'S',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF808569),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product['username'] ?? 'Seller Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${globalAverageRating.toStringAsFixed(1)}-Star Seller',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        globalAverageRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(
                        Icons.star,
                        size: 18,
                        color: Color(0xFF808569),
                      ),
                    ],
                  ),
                  const SizedBox(
                      width: 120, // Increased width
                      child: Divider(thickness: 1, color: Colors.black38)),
                  const Text(
                    'Reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${globalRatings.length}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        ' Comments',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                      width: 120, // Increased width
                      child: Divider(thickness: 1, color: Colors.black38)),
                  const Text(
                    'Sell For',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '3',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        ' years',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection() {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEEE2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Overall Rating',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          averageRating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averageRating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFF808569),
                              size: 22,
                            );
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${ratings.length} Reviews',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Divider(height: 40, thickness: 1),
          // User Comments Section
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                showAllComments ? ratings.length : min(1, ratings.length),
            itemBuilder: (context, index) {
              final rating = ratings[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFF808569),
                          radius: 22,
                          child: Text(
                            rating['userEmail'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rating['userEmail'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimestamp(rating['createdAt']),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < rating['rating']
                              ? Icons.star
                              : Icons.star_border,
                          color: const Color(0xFF808569),
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rating['comment'],
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (ratings.length > 1)
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    showAllComments = !showAllComments;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  showAllComments
                      ? 'Show Less'
                      : 'View All ${ratings.length} Reviews',
                  style: const TextStyle(
                    color: Color(0xFF808569),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
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

    images.removeWhere((image) => image == 'https://via.placeholder.com/50');

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
                        "RM ${widget.product['price'] ?? '0'}",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                "Pricing Details",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF808569),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Color(0xFF808569),
                              ),
                            ],
                          ),
                          Text(
                            "${widget.product['pricingDetails'] ?? 'N/A'}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),
                      RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: "Availability\n",
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF808569),
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.product['availability'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
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
                                  "${widget.product['details'] ?? 'No Details Available'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Rating Section
                      const SizedBox(height: 30),
                      _buildRatingSection(),
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.black26,
                      ),
                      _buildSellerSection(),
                    ],
                  ),
                ),
                // Bottom padding for navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8.0),
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
                children: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFavorite = !_isFavorite;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () async {
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        final sellerUserId = widget.product['userId'];
                        final chatId =
                            _generateChatId(currentUser.uid, sellerUserId);

                        // Check if the chat room exists
                        final chatDoc = await FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chatId)
                            .get();

                        // Create or update the chat room with product-specific details
                        if (!chatDoc.exists) {
                          // Create chat room if it doesn't exist
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .set({
                            'users': [currentUser.uid, sellerUserId],
                            'createdAt': FieldValue.serverTimestamp(),
                            'contextType':
                                'product', // Indicates chat initiated from product page
                            'productId': widget.product['productID'],
                            'productName': widget.product['name'],
                            'productImage': widget.product['imageUrl1'],
                          });
                        } else {
                          // Update product details in the chat room
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(chatId)
                              .update({
                            'contextType': 'product', // Ensure correct context
                            'productId': widget.product['productID'],
                            'productName': widget.product['name'],
                            'productImage': widget.product['imageUrl1'],
                          });
                        }

                        // Send a message indicating interest in the product
                        await FirestoreService().sendMessage(
                          chatId,
                          currentUser.uid,
                          "I'm interested in your product: ${widget.product['name']} (RM ${widget.product['price']}).",
                        );

                        // Navigate to the chat screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(chatId: chatId),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please log in to chat.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        // Buy now functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB1BA8E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                      ),
                      child: const Text(
                        'Buy Now',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        _showServiceBottomSheet();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF808569),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                      ),
                      child: const Text(
                        'Add to Cart',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
