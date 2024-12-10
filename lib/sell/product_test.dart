import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import '../services/cloudinary_service.dart';

class TestPage extends StatefulWidget {
  //const TestPage(this.noAppBar, {super.key});
  //final bool noAppBar;
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  // Support up to 3 images
  List<File> _mediaFiles = [];
  //List<FilePickerResult?> _mediaFiles = [];
  List<String> _mediaUrls = [];
  bool _isUploading = false;
  static const int maxMedia = 3;

  // Product Condition Options
  final List<String> _conditionOptions = [
    'New',
    'Like New',
    'Gently Used',
    'Well-Worn',
    'Repair'
  ];
  String? _selectedCondition;

  // Categories list
  final List<String> _categories = [
    'Books',
    'Clothes',
    'Electronics',
    'Furniture',
    'Mobile Phones & Gadgets',
    'Beauty & Personal Care',
    'Tickets',
    'Stationary',
    'Other'
  ];
  // Selected category
  String? _selectedCategory;

  // Enhanced product validation method
  bool _validateProductDetails() {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image/video')),
      );
      return false;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return false;
    }

    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition')),
      );
      return false;
    }

    // Name length validation
    final name = _nameController.text.trim();
    if (name.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Product name must be at least 3 characters long.')),
      );
      return false;
    }

    if (name.length > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Product name must be less than 100 characters.')),
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
                          const Icon(Icons.close, color: Colors.red, size: 30),
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
        builder: (BuildContext context) {
          return PopScope(
            canPop: true,
            child: Dialog(
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
                      onTap: () {
                        // Pause the video when tapped
                        if (videoController.value.isPlaying) {
                          videoController.pause();
                        } else {
                          // Play the video when tapped
                          videoController.play();
                        }
                      },
                      child: Center(
                        child: InteractiveViewer(
                          child: AspectRatio(
                            aspectRatio: videoController.value.aspectRatio,
                            child: VideoPlayer(videoController),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.red, size: 30),
                        onPressed: () {
                          // Dispose the video controller and close the dialog
                          videoController.dispose();
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: IconButton(
                        icon: Icon(
                          videoController.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.red,
                          size: 30,
                        ),
                        onPressed: () {
                          if (videoController.value.isPlaying) {
                            videoController.pause();
                          } else {
                            videoController.play();
                          }
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
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

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
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
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'details': _detailsController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory, // 'category': _selectedCategory!,
        'condition': _selectedCondition,
        'type': 'feature',
        'userId': currentUser.uid,
        'username': currentUser.displayName ?? 'Anonymous',
        'userEmail': currentUser.email ?? 'no-email',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch, //yyyyyyyyyyyyyy
      };

      // Add image URLs
      for (var i = 0; i < _mediaUrls.length; i++) {
        productData['mediaUrl${i + 1}'] = _mediaUrls[i];
      }

      // Upload to Firestore and get the document reference
      DocumentReference productDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .add(productData);

      // Update the document with its own ID
      await productDoc.update({'productId': productDoc.id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${_nameController.text} uploaded successfully!')),
        );

        //_formKey.currentState!.reset();
        // With this safer version
        if (_formKey.currentState != null) {
          _formKey.currentState!.reset();
        }
        _nameController.clear();
        _priceController.clear();
        _detailsController.clear();
        _brandController.clear();

        setState(() {
          _mediaFiles.clear();
          _mediaUrls.clear();
          _isUploading = false;
          _selectedCategory = null;
          _selectedCondition = null;
        });
      }
    } catch (e, stackTrace) {
      if (mounted) {
        print('Error details: $e');
        print('Stack trace: $stackTrace');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  // Replace the _pickImages method with this:
  void _pickMediaFiles() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultipleMedia();

    // Limit to MAX_IMAGES (3)
    final limitedFiles = pickedFiles.take(maxMedia).toList();

    setState(() {
      _mediaFiles = limitedFiles.map((file) {
        if (file.path.endsWith('.jpg') ||
            file.path.endsWith('.png') ||
            file.path.endsWith('.jpeg')) {
          return File(file.path);
        } else {
          return File(file.path);
        }
      }).toList();
    });

    // Show a message if more than MAX_IMAGES were selected
    if (pickedFiles.length > maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $maxMedia media files can be uploaded')),
      );
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
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
          "What's your item?",
          style: TextStyle(
              //fontWeight: FontWeight.bold,
              //fontSize: 28.0,
              ),
        ),
        //centerTitle: true,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // const SizedBox(height: 1),
                    // const Padding(
                    //   padding: EdgeInsets.symmetric(vertical: 5.0),

                    // ),
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
                                          : const SizedBox(
                                              width: 120,
                                              height: 120,
                                              child: Center(
                                                child: Icon(Icons.videocam,
                                                    size: 40),
                                              ),
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
                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategory,
                      hint: const Text('Select a Category'),
                      items: _categories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a category';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCondition,
                      hint: const Text('Select a Condition'),
                      items: _conditionOptions.map((String condition) {
                        return DropdownMenuItem<String>(
                          value: condition,
                          child: Text(condition),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCondition = newValue;
                        });
                      },
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
                      controller: _detailsController,
                      decoration: const InputDecoration(
                        labelText: 'Details',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(
                        labelText: 'Brand/Edition',
                        border: OutlineInputBorder(),
                      ),
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
                      child: const Text('Upload Product'),
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
    _detailsController.dispose();
    _brandController.dispose();
    super.dispose();
  }
}
