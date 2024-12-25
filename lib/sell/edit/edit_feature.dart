import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:unithrift/services/cloudinary_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:unithrift/sell/video_thumbnail.dart';
import 'package:unithrift/sell/preview_video.dart';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;
  final String productID;
  final String userID;

  const EditProductPage({
    super.key, 
    required this.productID,
    required this.userID,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _productData;

  // Add these properties
  List<File> _mediaFiles = [];
  List<String> _mediaUrls = [];
  static const int maxMedia = 5;
  static const int maxVideo = 1;
  bool _isUploading = false;
  

  // Categories list
  final List<String> _categories = [
    'Books',
    'Clothes',
    'Furniture',
    'Electronics',
    'Others'  // zx
  ];

  // Condition
  final List<String> _conditions = [
    'New',
    'Like New',
    'Gently Used',
    'Well-Worn',
    'Repair'
  ];



  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _detailsController;
  late TextEditingController _brandController;
  late String _category = 'Uncategorized';
  late String _condition = 'Unknown';
  
  late String _initialName;
  late String _initialPrice;
  late String _initialDetails;
  late String _initialBrand;
  late String _initialCategory;
  late String _initialCondition;
  

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _detailsController = TextEditingController();
    _brandController = TextEditingController();

    // Initialize media URLs from existing product
    List<String> mediaUrls = [];
    for (int i = 1; i <= 5; i++) {
      String? imageUrl = widget.product['imageUrl$i'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        mediaUrls.add(imageUrl);
      }
    }
    
    if (mediaUrls.isNotEmpty) {
      _mediaUrls = mediaUrls;
      _downloadAndSetMediaFiles(mediaUrls);
    }

    _fetchProductData();
  }

  // Add media picking method
  void _pickMediaFiles() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultipleMedia();

    int currentVideoCount = _mediaFiles.where((file) => 
      file.path.toLowerCase().endsWith('.mp4') || 
      file.path.toLowerCase().endsWith('.mov')
    ).length;

    List<File> newFiles = [];
    List<File> imageFiles = [];
    File? videoFile;

    for (var file in pickedFiles) {
      String path = file.path.toLowerCase();
      if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
        imageFiles.add(File(file.path));
      } else if (path.endsWith('.mp4') || path.endsWith('.mov') && currentVideoCount < maxVideo && videoFile == null) {
        videoFile = File(file.path);
      }
    }

    // Arrange files with video first
    if (videoFile != null) {
      newFiles = [videoFile];
    }
    newFiles.addAll(imageFiles);

    if (_mediaFiles.length + newFiles.length > maxMedia) {
      newFiles = newFiles.take(maxMedia - _mediaFiles.length).toList();
    }

    setState(() {
      if (_mediaFiles.isEmpty) {
        _mediaFiles = newFiles;
      } else {
        List<File> allVideos = [
          ..._mediaFiles.where((file) => 
            file.path.toLowerCase().endsWith('.mp4') || 
            file.path.toLowerCase().endsWith('.mov')
          ),
          ...newFiles.where((file) => 
            file.path.toLowerCase().endsWith('.mp4') || 
            file.path.toLowerCase().endsWith('.mov')
          )
        ];
        
        List<File> allImages = [
          ..._mediaFiles.where((file) => 
            file.path.toLowerCase().endsWith('.jpg') || 
            file.path.toLowerCase().endsWith('.jpeg') || 
            file.path.toLowerCase().endsWith('.png')
          ),
          ...newFiles.where((file) => 
            file.path.toLowerCase().endsWith('.jpg') || 
            file.path.toLowerCase().endsWith('.jpeg') || 
            file.path.toLowerCase().endsWith('.png')
          )
        ];

        _mediaFiles = [...allVideos, ...allImages];
      }
    });
  }

  // Add media download method
  Future<void> _downloadAndSetMediaFiles(List<String> urls) async {
    List<File> videoFiles = [];
    List<File> imageFiles = [];

    for (String url in urls) {
      if (url.isNotEmpty) {
        final response = await http.get(Uri.parse(url));
        final bytes = response.bodyBytes;
        final fileName = path.basename(url);
        final tempFile = File('${Directory.systemTemp.path}/$fileName');
        await tempFile.writeAsBytes(bytes);
        
        String filePath = url.toLowerCase();
        if (filePath.endsWith('.mp4') || filePath.endsWith('.mov')) {
          if (videoFiles.isEmpty) {
            videoFiles.add(tempFile);
          }
        } else if (filePath.endsWith('.jpg') || 
                  filePath.endsWith('.jpeg') || 
                  filePath.endsWith('.png')) {
          imageFiles.add(tempFile);
        }
      }
    }

    List<File> allFiles = [...videoFiles, ...imageFiles];
    
    if (allFiles.length > maxMedia) {
      allFiles = allFiles.take(maxMedia).toList();
    }

    if (mounted) {
      setState(() {
        _mediaFiles = allFiles;
      });
    }
  }

  bool _validateDetails() {

    // Name length validation
    final name = _nameController.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item name must be at least 3 characters long.')),
      );
      return false;
    }

    if (name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item name must be less than 100 characters.')),
      );
      return false;
    }

    // Details length validation
    final details = _detailsController.text.trim();
    if (details.isNotEmpty && details.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Item details must be less than 500 characters.')),
      );
      return false;
    }


    // Price validation with more specific conditions
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Invalid price. Please enter a valid number.')),
      );
      return false;
    }

    // Price range validation
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Price must be greater than 0.')),
      );
      return false;
    }

    if (price > 1000000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Price is too high. Maximum price is 1,000,000.')),
      );
      return false;
    }

    return true;
  }

  void _showMediaPreview(File mediaFile) async {
    if (mediaFile.path.endsWith('.jpg') ||
        mediaFile.path.endsWith('.png') ||
        mediaFile.path.endsWith('.jpeg')) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Center(
                      child: InteractiveViewer(
                        child: Image.file(
                          mediaFile,
                          fit: BoxFit.contain,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon:
                          const Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Video preview
      final videoController = VideoPlayerController.file(mediaFile);
      await videoController.initialize();

      showDialog(
        context: context,
        builder: (context) => VideoPreviewDialog(videoController: videoController),
      );
    }
  }

    Future<void> _fetchProductData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('products')
          .doc(widget.productID)
          .get();

      if (doc.exists) {
        setState(() {
          _productData = doc.data();
          _nameController.text = _productData?['name'] ?? '';
          _priceController.text = (_productData?['price'] ?? 0.0).toStringAsFixed(2);
          _detailsController.text = _productData?['details'] ?? '';
          _brandController.text = _productData?['brand'] ?? '';
          _category = _productData?['category'] ?? 'Uncategorized';
          _condition = _productData?['condition'] ?? 'Unknown';

          // Set initial values after data is loaded
          _initialName = _nameController.text;
          _initialPrice = _priceController.text;
          _initialDetails = _detailsController.text;
          _initialBrand = _brandController.text;
          _initialCategory = _category;
          _initialCondition = _condition;

          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product not found')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  // bool _hasChanges() {
  //   return _nameController.text != _initialName ||
  //       _priceController.text != _initialPrice ||
  //       _detailsController.text != _initialDetails ||
  //       _brandController.text != _initialBrand ||
  //       _category != _initialCategory ||
  //       _condition != _initialCondition;
  // }

  Future<void> _updateProduct() async {
    if (!_validateDetails()) {
        return;
    }

    if (!_formKey.currentState!.validate()) return;

    // Check if any changes were made
    // if (!_hasChanges()) {
    //   Navigator.pop(context);
    //   return;
    // }

    try {
      setState(() => _isLoading = true);

      // Upload new media files to Cloudinary if any
      List<String> newMediaUrls = [];
      if (_mediaFiles.isNotEmpty) {
        newMediaUrls = await Future.wait(
          _mediaFiles.map((mediaFile) => uploadToCloudinary(mediaFile))
        );
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      Map<String, dynamic> updateData = {
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'details': _detailsController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _category,
        'condition': _condition,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add media URLs to update data
      for (int i = 0; i < newMediaUrls.length; i++) {
        updateData['imageUrl${i + 1}'] = newMediaUrls[i];
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('products')
          .doc(widget.productID)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} updated successfully'),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [

                // Add media section
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF808569),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                    ),
                    icon: const Icon(Icons.upload_file),
                    label: Text('Select Medias (${_mediaFiles.length}/$maxMedia)'),
                    onPressed: _mediaFiles.length < maxMedia ? _pickMediaFiles : null,
                  ),
                  
                  // Media preview
                  if (_mediaFiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _mediaFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final mediaFile = entry.value;
                            return Stack(
                              children: [
                                GestureDetector(
                                    onTap: () => _showMediaPreview(mediaFile),
                                    child: Padding(
                                      padding: 
                                        const EdgeInsets.only(right: 8.0),
                                      child: mediaFile.path.endsWith('.mp4') ||
                                              mediaFile.path.endsWith('.mov')
                                          ? VideoThumbnail(
                                              videoFile: mediaFile,
                                              width: 120,
                                              height: 120,
                                            )
                                          : Image.file(
                                              mediaFile,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            ),
                                      ),
                                    ),
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red),
                                    onPressed: () async {
      // Remove from Firestore first
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('products')
          .doc(widget.productID)
          .update({
        'imageUrl${index + 1}': '',
      });

      // Then remove from UI
      setState(() {
        _mediaFiles.removeAt(index);
        _mediaUrls.removeAt(index);
      });
    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                DropdownButtonFormField<String>(
                  value: _category,
                  iconEnabledColor: Color(0xFF808569), // Add this line to change arrow color
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _category = newValue ?? 'Uncategorized';
                    });
                  },
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: _condition,
                  iconEnabledColor: Color(0xFF808569), 
                  decoration: const InputDecoration(
                    labelText: 'Condition',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)),
                    ),
                    labelStyle: TextStyle(color: Colors.grey),
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)),
                  ),
                  items: _conditions.map((String condition) {
                    return DropdownMenuItem<String>(
                      value: condition,
                      child: Text(condition),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _condition = newValue ?? 'Unknown';
                    });
                  },
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: _nameController,
                  cursorColor: Color(0xFF808569),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), // Your custom color
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                    
                  ),

                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), // Your custom color
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a price' : null,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), // Your custom color
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                    
                  
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand/Edition',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), // Your custom color
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                  
                  
                  ),
                  maxLines: 3,
                ),
                // Add more fields as needed
                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                      const Color(0xFF808569),
                  ),
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _detailsController.dispose();
    _brandController.dispose();
    super.dispose();
  }
}
