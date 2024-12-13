import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:unithrift/chatscreen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';
import '../sell/edit/edit_feature.dart';
import '../sell/edit/edit_rental.dart';
import '../sell/edit/edit_service.dart';
import '../services/cloudinary_service.dart';

class ListingPage extends StatefulWidget {
  final Map<String, dynamic?> product;  // Make it optional with ?

  const ListingPage({
    super.key, 
    required this.product
  });

  @override
  State<ListingPage> createState() => _ListingPageState();
}

class _ListingPageState extends State<ListingPage> {
  int _currentImageIndex = 0;
  bool _isVideo = false;
  List<Map<String, dynamic>> ratings = [];
  ChewieController? _chewieController;
  VideoPlayerController? _videoController;


  @override
  void initState() {
    super.initState();
    print('All Product Data: ${widget.product}'); // Add this line to check what data is coming in, debug
    print('Brand/Edition value: ${widget.product['brand']}');
     _initializeVideo();

  }


 Future<void> _initializeVideo() async {//yy
  if (widget.product['imageUrl1'] != null && 
      widget.product['imageUrl1'].toString().toLowerCase().endsWith('.mp4')) {
    setState(() => _isVideo = true);
    
    try {
      _videoController = VideoPlayerController.network(widget.product['imageUrl1']);
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

  List<String> getMediaUrls(Map<String, dynamic> product) {
  List<String> urls = [];
  for (int i = 1; i <= 3; i++) {
    String? url = product['mediaUrl$i'];
    print('mediaUrl$i: $url'); // Debug print
    if (url != null && url.isNotEmpty) {
      urls.add(url);
    }
  }
  print('Total URLs found: ${urls.length}'); // Debug print
  return urls;
}

String extractPublicId(String cloudinaryUrl) {
  print('Extracting public ID from: $cloudinaryUrl'); // Debug print
  Uri uri = Uri.parse(cloudinaryUrl);
  List<String> pathSegments = uri.pathSegments;
  print('Path segments: $pathSegments'); // Debug print

  // Simply get the last segment (filename with extension)
  String publicId = pathSegments.last;
  print('Extracted public ID: $publicId');
  return publicId;
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
            child: const Text('Delete'), 
            //style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    

    // First delete the media from Cloudinary
    print('Starting deletion process'); // Debug print
    List<String> mediaUrls = getMediaUrls(widget.product);
    print('Found media URLs: $mediaUrls'); // Debug print

    // Delete each media from Cloudinary
    for (String url in mediaUrls) {
    String publicId = extractPublicId(url);
    print('Processing deletion for URL: $url'); // Debug print
    if (publicId.isNotEmpty) {
      try {
        //await deleteFromCloudinary(publicId);
        bool success = await deleteFromCloudinary(publicId);
        print('Cloudinary deletion result for $publicId: $success'); // Debug print
      } catch (e) {
        print('Failed to delete media: $url - Error: $e');
      }
    }
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

void _editProduct() async {
  String itemType = widget.product['type'] ?? ''; 
  String? productId = widget.product['productID']?.toString();
  String? userId = widget.product['userId']?.toString();

  // Verify required data exists
  if (productId == null || userId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Missing product or user information')),
    );
    return;
  }

  final Map<String, Widget Function()> editPages = {
    'rental': () => EditRentalPage(
          productID: productId,
          userID: userId,
        ),
    'feature': () => EditProductPage(
          productID: productId,
          userID: userId,
        ),
    'service': () => EditServicePage(
          productID: productId,
          userID: userId,
        ),        
  };

  if (editPages.containsKey(itemType)) {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => editPages[itemType]!(),
      ),
    );


    if (result == true) {
      final updatedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('products')
          .doc(productId)
          .get();

      if (updatedDoc.exists) {
        setState(() {
          widget.product.addAll(updatedDoc.data()!);
        });
      }
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unknown product type: $itemType')),
    );
  }
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
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.product['userId'])
          .collection('products')
          .doc(widget.product['productID'])
          .update({'isAvailable': !currentAvailability});

      // Notify parent page of the change
      Navigator.pop(context, true);

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.visibility_off),
              color: const Color(0xFF808569),
              onPressed: _toggleAvailability,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              color: const Color(0xFF808569),
              onPressed: _deleteItem,
            ),
          ],
        ),
      ),
    ],
    
      ],
    ),
  );
}

Widget _buildProductContent() {
 String type = widget.product['type'] ?? '';

 if (type == 'service') {
   return _buildServiceContent();
 } else {
   return _buildRegularContent(); // For rental and feature types
 }
}

Widget _buildServiceContent() {
 return Padding(
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
       Text(
         "Posted ${getTimeAgo(widget.product['timestamp'] ?? widget.product['createdAt'])}",
         style: const TextStyle(
           fontSize: 13,
           color: Colors.grey,
         ),
       ),
       const SizedBox(height: 5),
       Text(
         "RM ${(double.parse(widget.product['price'].toString())).toStringAsFixed(2)}",
         style: const TextStyle(
           fontSize: 20,
           fontWeight: FontWeight.bold,
           color: Color.fromARGB(255, 0, 0, 0),
         ),
       ),
       const SizedBox(height: 20),
       _buildInfoField("Pricing Details", widget.product['pricingDetails']),
       _buildInfoField("Availability", widget.product['availability']),
       _buildInfoField("Description", widget.product['details']),
      
       const SizedBox(height: 20),
       const Divider(
         height: 20,
         thickness: 1,
         color: Colors.black26,
       ),
     ],
   ),
 );
}

Widget _buildInfoField(String label, dynamic value) {
 String displayValue = value?.toString().trim().isEmpty ?? true ? 'N/A' : value.toString();

 return Padding(
   padding: const EdgeInsets.only(bottom: 20),
   child: RichText(
     text: TextSpan(
       children: [
         TextSpan(
           text: "$label\n",
           style: const TextStyle(
             fontSize: 13,
             color: Color(0xFF808569),
           ),
         ),
         TextSpan(
           text: displayValue,
           style: const TextStyle(
             fontSize: 14,
             color: Colors.black,
           ),
         ),
       ],
     ),
   ),
 );
}

Widget _buildRegularContent() {
 return Padding(
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
       Text(
         "Posted ${getTimeAgo(widget.product['timestamp'] ?? widget.product['createdAt'])}",
         style: const TextStyle(
           fontSize: 13,
           color: Colors.grey,
         ),
       ),
       const SizedBox(height: 5),
       Text(
         "RM ${(double.parse(widget.product['price'].toString())).toStringAsFixed(2)}",
         style: const TextStyle(
           fontSize: 20,
           fontWeight: FontWeight.bold,
           color: Color.fromARGB(255, 0, 0, 0),
         ),
       ),
       const SizedBox(height: 20),
       _buildInfoField("Category", widget.product['category']),
       _buildInfoField("Condition", widget.product['condition']),
       _buildInfoField("Brand", widget.product['brand']),
       _buildInfoField("Description", widget.product['details']),
      
       const SizedBox(height: 20),
       const Divider(
         height: 20,
         thickness: 1,
         color: Colors.black26,
       ),
     ],
   ),
 );
}
  

  @override
  Widget build(BuildContext context) {

    List<String> images = [];//yy
if (widget.product['imageUrl1'] != null && 
    !widget.product['imageUrl1'].toString().toLowerCase().endsWith('.mp4')) {
  images.add(widget.product['imageUrl1']);
}
if (widget.product['imageUrl2'] != null) {
  images.add(widget.product['imageUrl2']);
}
if (widget.product['imageUrl3'] != null) {
  images.add(widget.product['imageUrl3']);
}


images.removeWhere((image) => 
  image == 'https://via.placeholder.com/50' || 
  image.isEmpty
);

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
                             // In the build method, replace the existing media section with:
if (images.isNotEmpty || widget.product['imageUrl1']?.toString().toLowerCase().endsWith('.mp4') == true) ...[
  Container(
    height: 300,
    child: Stack(
      children: [
        if (_isVideo && _chewieController != null)
          Chewie(controller: _chewieController!)
        else if (images.isNotEmpty)
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


        // Image indicators
        if (!_isVideo && images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((entry) {
                return Container(
                  width: 8.0,
                  height: 8.0,
                  margin: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 4.0,
                  ),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(
                      _currentImageIndex == entry.key ? 0.9 : 0.4,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    ),
  ),
],


                 _buildProductContent(),
                // Bottom padding for navigation bar
                const SizedBox(height: 80),
              ],
            ),
          ),
            Positioned(  // Add this at the end of Stack children
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
            bottom: 60, // Adjust this value based on your action buttons height
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.grey.withOpacity(0.9),  // 0.7
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
                        color:Colors.white,
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
                          horizontal: 24,
                          vertical: 12
                        ),
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
          