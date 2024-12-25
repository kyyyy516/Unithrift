import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart';
import '../services/cloudinary_service.dart';
import '../sell/publish_success.dart';
import '../sell/preview_video.dart';
import '../sell/video_thumbnail.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class UploadServicePage extends StatefulWidget {
  final Map<String, String>? prefillData;

  const UploadServicePage({
    super.key,
    this.prefillData,
  });

  @override
  State<UploadServicePage> createState() => _UploadServicePageState();
}

class _UploadServicePageState extends State<UploadServicePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _priceDetailsController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();

  // Support up to 5 medias
  List<File> _mediaFiles = [];
  List<String> _mediaUrls = [];
  bool _isUploading = false;
  static const int maxMedia = 5;
  static const int maxVideo = 1;  

  @override
  void initState() {
    super.initState();
    
    if (widget.prefillData != null) {
      _nameController.text = widget.prefillData!['name'] ?? '';
      _priceController.text = widget.prefillData!['price'] ?? '';
      _priceDetailsController.text = widget.prefillData!['pricingDetails'] ?? '';
      _detailsController.text = widget.prefillData!['details'] ?? '';
      _availabilityController.text = widget.prefillData!['availability'] ?? '';

      // Create a List<String> for media URLs
      List<String> mediaUrls = [];
      
      // Collect all non-null image URLs with null check
      for (int i = 1; i <= 5; i++) {
        String? imageUrl = widget.prefillData!['imageUrl$i'];
        if (imageUrl != null) {
          mediaUrls.add(imageUrl.toString());
        }
      }

      if (mediaUrls.isNotEmpty) {
        _downloadAndSetMediaFiles(mediaUrls);
      }
    }
  }

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
        
        // Categorize files based on extension
        String filePath = url.toLowerCase();
        if (filePath.endsWith('.mp4') || filePath.endsWith('.mov')) {
        if (videoFiles.isEmpty) { // Only add if no video exists yet
            videoFiles.add(tempFile);
          }
        } else if (filePath.endsWith('.jpg') || 
                  filePath.endsWith('.jpeg') || 
                  filePath.endsWith('.png')) {
          imageFiles.add(tempFile);
        }
      }
    }

  // Combine files ensuring video is first
  List<File> allFiles = [...videoFiles, ...imageFiles];
  
  // Respect maximum media limit
  if (allFiles.length > maxMedia) {
    allFiles = allFiles.take(maxMedia).toList();
  }

  setState(() {
    _mediaFiles = allFiles;
  });
}

  // Enhanced product validation method
  bool _validateProductDetails() {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return false;
    }

    // Check if there's at least one image
    bool hasImage = false;
    int videoCount = 0;
    
    for (var file in _mediaFiles) {
      if (file.path.toLowerCase().endsWith('.jpg') || 
          file.path.toLowerCase().endsWith('.jpeg') || 
          file.path.toLowerCase().endsWith('.png')) {
        hasImage = true;
      } else if (file.path.toLowerCase().endsWith('.mp4') || 
                file.path.toLowerCase().endsWith('.mov')) {
        videoCount++;
      }
    }

    if (!hasImage) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please include at least one image')),
      );
      return false;
    }

    if (videoCount > maxVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one video is allowed')),
      );
      return false;
    }

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
            content: Text('Product details must be less than 500 characters.')),
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

  // New method to show media preview
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

  Future<String> fetchUsername(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc.data()?['username'] ?? 'Unknown Seller';
    } catch (e) {
      print('Error fetching username: $e');
      return 'Unknown Seller';
    }
  }

  Future<void> _uploadProduct() async {
    try {
      if (!_validateProductDetails()) {
        return;
      }

      if (!_formKey.currentState!.validate()) return;

      setState(() {
        _isUploading = true;
      });

      // Show loading dialog 
    showDialog( 
      context: context, 
      barrierDismissible: false, 
      builder: (BuildContext context) { 
        return const Center( 
          child: Dialog( 
            backgroundColor: Colors.transparent, 
            elevation: 0, 
            child: Column( 
              mainAxisSize: MainAxisSize.min, 
              children: [ 
                CircularProgressIndicator( 
                  color: Color(0xFF808569), 
                ), 
                SizedBox(height: 16), 
                Text( 
                  'Publishing...', 
                  style: TextStyle(color: Colors.white), 
                ), 
              ], 
            ), 
          ), 
        ); 
      }, 
    );

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      // Upload medias to Cloudinary
      _mediaUrls = await Future.wait(
          _mediaFiles.map((mediaFile) => uploadToCloudinary(mediaFile)));

      // Prepare product data with null safety
      final productData = {
        'name': _nameController.text
            .trim(), // removes any leading and trailing whitespace from a string.
        'price': double.parse(
            double.parse(_priceController.text.trim()).toStringAsFixed(2)),
        'pricingDetails': _priceDetailsController.text.trim(),
        'details': _detailsController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'type': 'service',
        'userId': currentUser.uid,
        'username': await fetchUsername(currentUser.uid),
        'userEmail': currentUser.email ?? 'no-email',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch, //yyyyyyyyyyyyyy
      };

      // Add image URLs
      for (var i = 0; i < _mediaUrls.length; i++) {
        productData['imageUrl${i + 1}'] = _mediaUrls[i]; //yy
      }

      // Upload to Firestore and get the document reference
      DocumentReference productDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .add(productData);

      // Add debug prints here
      // print('Navigating to success page with:');
      // print('Product ID: ${productDoc.id}');
      // print('User ID: ${currentUser.uid}');

      // Update the document with its own ID
      await productDoc.update({'productId': productDoc.id});

      if (mounted) {
        // Before successful navigation, dismiss the loading dialog
        Navigator.pop(context); 
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PublishSuccessfulPage(
              productID: productDoc.id,
              userID: currentUser.uid,

            )

          ),
        );

        if (_formKey.currentState != null) {
          _formKey.currentState!.reset();
        }
        _nameController.clear();
        _priceController.clear();
        _priceDetailsController.clear();
        _detailsController.clear();
        _availabilityController.clear();

        setState(() {
          _mediaFiles.clear();
          _mediaUrls.clear();
          _isUploading = false;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        print('Error details: $e');
        print('Stack trace: $stackTrace');

        Navigator.pop(context); // Dismiss loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
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

    // Show messages only when limits are exceeded
    if (pickedFiles.length > maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only 1 video and 4 images can be uploaded in total.')),
      );
    }

    // Show message when multiple videos are selected
    int selectedVideoCount = pickedFiles.where((file) => 
      file.path.toLowerCase().endsWith('.mp4') || 
      file.path.toLowerCase().endsWith('.mov')
    ).length;

    if (selectedVideoCount > maxVideo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only one video is allowed.')),
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);

      // Reorder files if needed to keep video first
    if (_mediaFiles.isNotEmpty) {
      List<File> videos = _mediaFiles.where((file) => 
        file.path.toLowerCase().endsWith('.mp4') || 
        file.path.toLowerCase().endsWith('.mov')
      ).toList();
      
      List<File> images = _mediaFiles.where((file) => 
        !file.path.toLowerCase().endsWith('.mp4') && 
        !file.path.toLowerCase().endsWith('.mov')
      ).toList();

      _mediaFiles = [...videos, ...images];
    }

    });
  }

  @override
  Widget build(BuildContext context) {
    // return (widget.noAppBar)
    // ? Scaffold(
    //   body: SizedBox.shrink(), // Empty space, no UI elements
    // )
    // :
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "What's your service?",
          style: TextStyle(
              //fontWeight: FontWeight.bold,
              //fontSize: 28.0,
              ),
        ),
        //centerTitle: true,
      ),
      body: 
          SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor:
                            const Color(0xFF808569), // Button background color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        elevation: 3, // Shadow elevation
                      ),
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                          'Select Medias (${_mediaFiles.length}/$maxMedia)'),
                      onPressed: _mediaFiles.length < maxMedia
                          ? _pickMediaFiles
                          : null,
                    ),
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
                                      child: mediaFile.path.endsWith('.jpg') ||
                                              mediaFile.path.endsWith('.png') ||
                                              mediaFile.path.endsWith('.jpeg')
                                          ? Image.file(
                                              mediaFile,
                                              width: 120,
                                              height: 120,
                                              fit: BoxFit.cover,
                                            )
                                          : VideoThumbnail(
        videoFile: mediaFile,
        width: 120,
        height: 120,
      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () => _removeMedia(index),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter product name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _priceDetailsController,
                      decoration: const InputDecoration(
                        labelText:
                            'Pricing Details (price per page/kg/hour/km)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please specify price per page/kg/hour/km(unit)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _availabilityController,
                      decoration: const InputDecoration(
                        labelText: 'Availability Time',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter availability time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white, // Text color
                        backgroundColor:
                            const Color(0xFF808569), // Button background color
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        elevation: 3, // Shadow elevation
                      ),
                      onPressed: _uploadProduct,
                      child: const Text('Publish Now'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _priceController.dispose();
    _priceDetailsController.dispose();
    _detailsController.dispose();
    _availabilityController.dispose();
    super.dispose();
  }
}
