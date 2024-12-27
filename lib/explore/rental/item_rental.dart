import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:unithrift/account/favourite_service.dart';
import 'package:unithrift/account/view_user_profile.dart';
import 'package:unithrift/chatscreen.dart';
import 'package:unithrift/checkout/chekout.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';

class ItemRentalPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ItemRentalPage({super.key, required this.product});

  @override
  State<ItemRentalPage> createState() => _ItemRentalPageState();
}

class _ItemRentalPageState extends State<ItemRentalPage> {
  int _currentImageIndex = 0;
  bool _isVideo = false;
  List<Map<String, dynamic>> reviews = [];
  double averagereview = 0;
  bool showAllComments = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  double globalAveragereview = 0.0;
  List<dynamic> globalreviews = [];
  final FavoriteService _favoriteService = FavoriteService();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _fetchreviews();
    _initializeVideo();
    _initializeMediaContent();
    fetchGlobalSellerreviews();
    fetchSellerProfile();
    _incrementProductViews(); // zx
  }

  // zx
  Future<void> _incrementProductViews() async {
    try {
      // Get current user ID
      final currentUser = FirebaseAuth.instance.currentUser;

      // Only increment if the viewer is not the product owner
      if (currentUser != null && currentUser.uid != widget.product['userId']) {
        DocumentReference productRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.product['userId'])
            .collection('products')
            .doc(widget.product['productID']);

        // Get current views count
        DocumentSnapshot productDoc = await productRef.get();
        int currentViews =
            (productDoc.data() as Map<String, dynamic>)['views'] ?? 0;

        // Then increment it
        await productRef.update({
          'views': currentViews + 1,
        });
      }
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  String? sellerProfileImage;

  Future<void> fetchSellerProfile() async {
    final sellerDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.product['userId'])
        .get();

    if (mounted && sellerDoc.exists) {
      setState(() {
        sellerProfileImage = sellerDoc.data()?['profileImage'];
      });
    }
  }

  Future<void> fetchGlobalSellerreviews() async {
    try {
      final sellerId = widget.product['userId'];
      List<double> allReviews = [];
      List<dynamic> allComments = [];

      // Get seller's global reviews from the correct collection
      QuerySnapshot reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(sellerId)
          .collection('reviewsglobal')
          .orderBy('timestamp', descending: true)
          .get();

      for (var reviewDoc in reviewsSnapshot.docs) {
        Map<String, dynamic> reviewData =
            reviewDoc.data() as Map<String, dynamic>;

        // Parse rating value
        double rating = 0.0;
        var ratingValue = reviewData['rating'];
        if (ratingValue != null) {
          if (ratingValue is String) {
            rating = double.tryParse(ratingValue) ?? 0.0;
          } else if (ratingValue is num) {
            rating = ratingValue.toDouble();
          }
        }

        // Only add valid reviews
        if (rating > 0) {
          allReviews.add(rating);
          allComments.add({
            'reviewerId': reviewData['reviewerId'] ?? '',
            'reviewerName': reviewData['reviewerName'] ?? 'Anonymous',
            'reviewText': reviewData['reviewText'] ?? '',
            'rating': rating,
            'timestamp': reviewData['timestamp'] ?? Timestamp.now(),
            'productName': reviewData['productName'] ?? '',
            'productPrice': (reviewData['productPrice'] ?? 0.0).toDouble(),
            'role': reviewData['role'] ?? 'buyer',
          });
        }
      }

      if (mounted) {
        setState(() {
          globalreviews = allComments;
          globalAveragereview = allReviews.isNotEmpty
              ? allReviews.reduce((a, b) => a + b) / allReviews.length
              : 0.0;
        });
      }
    } catch (e) {
      print('Error fetching global reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading seller reviews: $e')),
        );
      }
    }
  }

// Add this helper method to match ChatList's ID generation
  String _generateChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  Future<void> _initializeMediaContent() async {
    // Reset state
    setState(() {
      _isVideo = false;
      _videoController = null;
      _chewieController = null;
    });

    // Find video URL if exists
    String? videoUrl = _findFirstVideoUrl();

    if (videoUrl != null) {
      setState(() => _isVideo = true);
      try {
        _videoController = VideoPlayerController.network(videoUrl);
        await _videoController!.initialize();

        if (mounted) {
          setState(() {
            _chewieController = ChewieController(
              videoPlayerController: _videoController!,
              autoPlay: false,
              looping: false,
              showControls: true,
              aspectRatio: _videoController!.value.aspectRatio,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorBuilder: (context, errorMessage) {
                return Center(
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.white)),
                );
              },
            );
          });
        }
      } catch (e) {
        print('Video initialization error: $e');
        setState(() => _isVideo = false);
      }
    }
  }

  String? _findFirstVideoUrl() {
    final urls = [
      widget.product['imageUrl1'],
      widget.product['imageUrl2'],
      widget.product['imageUrl3']
    ];

    return urls.firstWhere(
      (url) => url != null && url.toString().toLowerCase().endsWith('.mp4'),
      orElse: () => null,
    );
  }

  List<String> _getImageUrls() {
    List<String> images = [];
    final urls = [
      widget.product['imageUrl1'],
      widget.product['imageUrl2'],
      widget.product['imageUrl3'],
      widget.product['imageUrl4'],
      widget.product['imageUrl5']
    ];

    for (String? url in urls) {
      if (url != null &&
          url.isNotEmpty &&
          !url.toString().toLowerCase().endsWith('.mp4') &&
          url != 'https://via.placeholder.com/50') {
        images.add(url);
      }
    }

    return images;
  }

  Future<void> _initializeVideo() async {
    if (widget.product['imageUrl1'] != null &&
        widget.product['imageUrl1'].toString().toLowerCase().endsWith('.mp4')) {
      setState(() => _isVideo = true);

      try {
        _videoController =
            VideoPlayerController.network(widget.product['imageUrl1']);
        await _videoController!.initialize();
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoController!,
            autoPlay: false,
            looping: false,
            showControls: true,
            aspectRatio: _videoController!.value.aspectRatio,
            placeholder: const Center(child: CircularProgressIndicator()),
            errorBuilder: (context, errorMessage) {
              return Center(
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          );
        });
      } catch (e) {
        print('Video initialization error: $e');
        setState(() => _isVideo = false);
      }
    }
  }

  Future<void> _fetchreviews() async {
    try {
      // Get reference to the product's reviews collection
      final reviewsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product['userId'])
          .collection('products')
          .doc(widget.product['productID'])
          .collection('reviews')
          .orderBy('timestamp', descending: true)
          .get();

      final List<Map<String, dynamic>> reviewsList = [];
      double totalreview = 0;

      for (var doc in reviewsSnapshot.docs) {
        final data = doc.data();

        if (data['rating'] != null) {
          double reviewValue = 0.0;

          // Handle different rating types
          if (data['rating'] is String) {
            reviewValue = double.tryParse(data['rating']) ?? 0.0;
          } else if (data['rating'] is num) {
            reviewValue = (data['rating'] as num).toDouble();
          }

          if (reviewValue > 0) {
            Map<String, dynamic> review = {
              'reviewerId': data['reviewerId'] ?? '',
              'reviewerName': data['reviewerName'] ?? 'Anonymous',
              'reviewText': data['reviewText'] ?? '',
              'rating': reviewValue,
              'timestamp': data['timestamp'] ?? Timestamp.now(),
              'productName': data['productName'] ?? '',
              'productPrice': (data['productPrice'] ?? 0.0).toDouble(),
              'role': data['role'] ?? 'buyer',
            };

            reviewsList.add(review);
            totalreview += reviewValue;
          }
        }
      }

      setState(() {
        reviews = reviewsList;
        averagereview = reviews.isEmpty ? 0 : totalreview / reviews.length;
      });
    } catch (e) {
      print('Error fetching reviews: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reviews: $e')),
        );
      }
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

  String getValidImageUrl(Map<String, dynamic> product) {
    // List of possible image URLs in priority order
    final imageUrls = [
      product['imageUrl1'],
      product['imageUrl2'],
      product['imageUrl3']
    ];

    // Find first valid image URL
    for (String? url in imageUrls) {
      if (url != null &&
          url.isNotEmpty &&
          !url.toLowerCase().endsWith('.mp4') &&
          url != 'https://via.placeholder.com/50') {
        return url;
      }
    }

    return 'https://via.placeholder.com/100';
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

      // Format dates for rental items
      String? formattedStartDate;
      String? formattedEndDate;

      if (type == 'rental' && _startDate != null && _endDate != null) {
        formattedStartDate =
            '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}';
        formattedEndDate =
            '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}';
      }

      // Add new item to cart
      final cartItem = {
        'productID': product['productID'],
        'name': product['name'],
        'price': product['price'],
        'imageUrl1': getValidImageUrl(product),
        'condition': product['condition'],
        'type': type,
        'quantity': 1,
        'addedAt': FieldValue.serverTimestamp(),
        'sellerUserId': product['userId'],
        'sellerName': product['username'],
        'sellerEmail': product['userEmail'],
        // Add rental dates if type is rental
        if (type == 'rental') ...{
          'startRentalDate': formattedStartDate,
          'endRentalDate': formattedEndDate,
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

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'No date';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Add this method to show the bottom sheet
  void _showRentalBottomSheet() async {
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
    int rentalDays = 0;
    double totalPrice = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (_startDate != null && _endDate != null) {
              rentalDays = _endDate!.difference(_startDate!).inDays + 1;
              totalPrice = rentalDays *
                  (double.parse(widget.product['price'].toString()));
            }

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
                          'Select Rental Period',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 35), // For balance
                      ],
                    ),
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
                    const SizedBox(height: 10),
                    // Date Selection Container with green outline
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
                            DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2025),
                              initialDateRange:
                                  _startDate != null && _endDate != null
                                      ? DateTimeRange(
                                          start: _startDate!, end: _endDate!)
                                      : null,
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
                                _startDate = picked.start;
                                _endDate = picked.end;
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
                                      'From - To',
                                      style: TextStyle(
                                        color: Color(0xFF808569),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _startDate != null && _endDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Select dates',
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
                    const SizedBox(height: 30),
                    // Rental Duration and Total
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rental Duration',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '$rentalDays days',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              Navigator.pop(context);
                              _addToCart(widget.product, 'rental');
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

  void _showBuyNowBottomSheet() async {
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

    int rentalDays = 0;
    double totalPrice = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (_startDate != null && _endDate != null) {
              rentalDays = _endDate!.difference(_startDate!).inDays + 1;
              totalPrice = rentalDays *
                  (double.parse(widget.product['price'].toString()));
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Select Rental Period',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 35),
                      ],
                    ),
                    // Info Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3EC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.info_outline, color: Color(0xFF808569)),
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
                            DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2025),
                              initialDateRange:
                                  _startDate != null && _endDate != null
                                      ? DateTimeRange(
                                          start: _startDate!, end: _endDate!)
                                      : null,
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
                                _startDate = picked.start;
                                _endDate = picked.end;
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
                                      'From - To',
                                      style: TextStyle(
                                        color: Color(0xFF808569),
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      _startDate != null && _endDate != null
                                          ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year} - ${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                          : 'Select dates',
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
                    const SizedBox(height: 30),
                    // Price Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rental Duration',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          '$rentalDays days',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
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
                    const SizedBox(height: 30),
                    // Buy Now Button
                    ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    totalAmount: totalPrice,
                                    itemCount: 1,
                                    cartItems: [
                                      {
                                        ...widget.product,
                                        'startRentalDate':
                                            '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                                        'endRentalDate':
                                            '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                                        'type': 'rental',
                                        'sellerUserId':
                                            widget.product['userId'],
                                        'sellerName':
                                            widget.product['username'],
                                        'sellerEmail':
                                            widget.product['userEmail'],
                                      }
                                    ],
                                    sellerName:
                                        widget.product['username'] ?? 'Seller',
                                  ),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF808569),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text(
                        'Buy Now',
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
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfilePage(
                  userId: widget.product['userId'],
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFD8DCC6),
              borderRadius: BorderRadius.circular(15),
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
                      backgroundImage: sellerProfileImage != null &&
                              sellerProfileImage!.isNotEmpty
                          ? NetworkImage(sellerProfileImage!)
                          : null,
                      child: sellerProfileImage == null ||
                              sellerProfileImage!.isEmpty
                          ? Text(
                              widget.product['username']?[0].toUpperCase() ??
                                  'S',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF808569),
                              ),
                            )
                          : null,
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
                      '${globalAveragereview.toStringAsFixed(1)}-Star Seller', // Updated to use globalAveragereview
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
                      'Overall Rating',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          globalAveragereview.toStringAsFixed(
                              1), // Updated to use globalAveragereview
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
                      width: 120,
                      child: Divider(thickness: 1, color: Colors.black38),
                    ),
                    const Text(
                      'Overall Review',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${globalreviews.length}', // Updated to use globalreviews
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
                      width: 120,
                      child: Divider(thickness: 1, color: Colors.black38),
                    ),
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
        ),
      ],
    );
  }

  Widget _buildreviewSection() {
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
                      'Product Review',
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
                          averagereview.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < averagereview
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
                    '${reviews.length} Reviews',
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount:
                showAllComments ? reviews.length : min(1, reviews.length),
            itemBuilder: (context, index) {
              final review = reviews[index];
              final reviewerName = review['reviewerName'] ?? 'Anonymous';
              final reviewerId = review['reviewerId'];

              //ky add reviewer profile image
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(reviewerId)
                    .get(),
                builder: (context, snapshot) {
                  String? profileImageUrl;

                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData &&
                      snapshot.data!.exists) {
                    profileImageUrl = snapshot.data!.get('profileImage');
                  }

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
                              radius: 22,
                              backgroundImage: profileImageUrl != null
                                  ? NetworkImage(profileImageUrl)
                                  : null,
                              backgroundColor: const Color(0xFF808569),
                              child: profileImageUrl == null
                                  ? Text(
                                      reviewerName[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reviewerName,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(review['timestamp']),
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
                              index < (review['rating'] ?? 0)
                                  ? Icons.star
                                  : Icons.star_border,
                              color: const Color(0xFF808569),
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          review['reviewText'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          if (reviews.length > 1)
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
                      : 'View All ${reviews.length} Reviews',
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

  // ky line 1315 to line 1476
  String getFirstValidImage(Map<String, dynamic> product) {
    List<dynamic> images = [
      product['imageUrl1'],
      product['imageUrl2'],
      product['imageUrl3'],
      product['imageUrl4'],
      product['imageUrl5'],
    ]
        .where((url) =>
            url != null &&
            url != 'https://via.placeholder.com/50' &&
            !url.toLowerCase().endsWith('.mp4'))
        .toList();

    return images.isNotEmpty ? images[0] : 'https://via.placeholder.com/100';
  }

  Stream<List<Map<String, dynamic>>> getSimilarProducts() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .asyncMap((usersSnapshot) async {
      List<Map<String, dynamic>> allProducts = [];

      for (var userDoc in usersSnapshot.docs) {
        var productsSnapshot = await userDoc.reference
            .collection('products')
            .where('type', isEqualTo: 'rental')
            .where('category', isEqualTo: widget.product['category'])
            .get();

        for (var productDoc in productsSnapshot.docs) {
          if (productDoc.id != widget.product['productID']) {
            var productData = productDoc.data();
            // Ensure productID is set correctly
            productData['productID'] =
                productDoc.id; // Changed from productId to productID
            productData['userId'] = userDoc.id;
            productData['userEmail'] = userDoc.data()['email'];
            productData['username'] = userDoc.data()['username'];
            allProducts.add(productData);
          }
        }
      }

      return allProducts;
    });
  }

  Widget _buildSimilarListings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Similar Items',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: getSimilarProducts(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No similar items found'));
              }

              final products = snapshot.data!;

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final validImageUrl = getFirstValidImage(product);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ItemRentalPage(product: product),
                        ),
                      );
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8)),
                            child: Image.network(
                              validImageUrl,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 160,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.image_not_supported,
                                      color: Colors.grey),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'RM ${product['price']?.toString() ?? '0'}',
                                  style: const TextStyle(
                                    color: Color(0xFF808569),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> images = [];
    if (widget.product['imageUrl1'] != null &&
        !widget.product['imageUrl1']
            .toString()
            .toLowerCase()
            .endsWith('.mp4')) {
      images.add(widget.product['imageUrl1']);
    }
    if (widget.product['imageUrl2'] != null) {
      images.add(widget.product['imageUrl2']);
    }
    if (widget.product['imageUrl3'] != null) {
      images.add(widget.product['imageUrl3']);
    }
    if (widget.product['imageUrl4'] != null) {
      images.add(widget.product['imageUrl4']);
    }
    if (widget.product['imageUrl5'] != null) {
      images.add(widget.product['imageUrl5']);
    }

    images.removeWhere(
        (image) => image == 'https://via.placeholder.com/50' || image.isEmpty);

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
                // In the build method, replace the existing media section with:
                if (images.isNotEmpty ||
                    widget.product['imageUrl1']
                            ?.toString()
                            .toLowerCase()
                            .endsWith('.mp4') ==
                        true) ...[
                  Container(
                    height: 300,
                    child: Stack(
                      children: [
                        if (_isVideo && _chewieController != null)
                          Chewie(controller: _chewieController!)
                        else ...[
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
                            items: _getImageUrls().map((imageUrl) {
                              return Image.network(
                                imageUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                      child: CircularProgressIndicator());
                                },
                              );
                            }).toList(),
                          ),
                        ],

                        // Media toggle button
                        if (_videoController != null && images.isNotEmpty)
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
                                  if (_isVideo) {
                                    _videoController?.play();
                                  } else {
                                    _videoController?.pause();
                                  }
                                });
                              },
                            ),
                          ),

                        // Toggle button for video/images
                        if (_videoController != null &&
                            _getImageUrls().isNotEmpty)
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
                                  if (_isVideo) {
                                    _videoController?.play();
                                  } else {
                                    _videoController?.pause();
                                  }
                                });
                              },
                            ),
                          ),
                      ],
                    ),
                  )
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
                      // Add this where you display product details
                      const SizedBox(height: 5),
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
                      // Replace this part in your ItemRentalPage
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
                      // For brand
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
                              text: "${widget.product['brand'] ?? 'N/A'}",
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
                                  "${widget.product['details'] ?? 'No Details Available'}",
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // review Section
                      const SizedBox(height: 30),
                      _buildreviewSection(),
                      const Divider(
                        height: 20,
                        thickness: 1,
                        color: Colors.black26,
                      ),
                      _buildSellerSection(),
                    ],
                  ),
                ),
                _buildSimilarListings(), //ky
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
                  StreamBuilder<bool>(
                    stream: FavoriteService()
                        .isFavorite(widget.product['productID']),
                    builder: (context, snapshot) {
                      bool isFavorited = snapshot.data ?? false;

                      return IconButton(
                        icon: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? Colors.red : null,
                        ),
                        onPressed: () async {
                          bool success = await FavoriteService()
                              .toggleFavorite(widget.product);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Added to likes'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Removed from likes'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      );
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
                      onPressed: () => _showBuyNowBottomSheet(),
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
                      onPressed: () => _showRentalBottomSheet(),
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
