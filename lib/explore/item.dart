import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class ItemDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ItemDetailPage({super.key, required this.product});

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideo = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
                                fontSize: 14,
                                color: Color(
                                    0xFF808569), // 808569 color for "Category: "
                              ),
                            ),
                            TextSpan(
                              text: "${widget.product['category'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors
                                    .black, // Black color for the actual category
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
                                fontSize: 14,
                                color: Color(
                                    0xFF808569), // 808569 color for "Category: "
                              ),
                            ),
                            TextSpan(
                              text: "${widget.product['contidion'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors
                                    .black, // Black color for the actual category
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
                                fontSize: 14,
                                color: Color(
                                    0xFF808569), // 808569 color for "Category: "
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.product['brand/edition'] ?? 'N/A'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors
                                    .black, // Black color for the actual category
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
                                fontSize: 14,
                                color: Color(
                                    0xFF808569), // 808569 color for "Category: "
                              ),
                            ),
                            TextSpan(
                              text:
                                  "${widget.product['details'] ?? 'No Details Available'}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors
                                    .black, // Black color for the actual category
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Add extra padding at bottom for navigation bar
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
                      // Add favorite functionality
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat),
                    onPressed: () {
                      // Add chat functionality
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
                        foregroundColor: Colors.white, // Makes text white
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(4), // Less rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Adjusted padding
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
                        // Add to cart functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF808569),
                        foregroundColor: Colors.white, // Makes text white
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(4), // Less rounded corners
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16), // Adjusted padding
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
