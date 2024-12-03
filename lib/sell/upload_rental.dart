import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RentalUploadPage extends StatefulWidget {
  const RentalUploadPage({super.key});

  @override
  State<RentalUploadPage> createState() => _RentalUploadPageState();
}

class _RentalUploadPageState extends State<RentalUploadPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();

  // Support up to 3 images
  List<File> _imageFiles = [];
  List<String> _imageUrls = [];
  bool _isUploading = false;
  static const int MAX_IMAGES = 3;

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

    // Condition validation
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a condition.')),
      );
      return false;
    }

    return true;
  }

  // New method to show image preview
  void _showImagePreview(File imageFile) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Center(
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<String> uploadToImgbb(File imageFile) async {
    final apiKey = '0682e041094cb93036299a0fbe3223dd';
    final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

    final request = http.MultipartRequest('POST', url)
      ..files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(responseData.body);
      return jsonData['data']['url'];
    } else {
      throw Exception(
          'Failed to upload image to imgbb: ${responseData.statusCode} - ${responseData.body}');
    }
  }

  Future<void> _uploadProduct() async {
    try {
      // Validate all required fields first
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a category')),
        );
        return;
      }

      if (_selectedCondition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a condition')),
        );
        return;
      }

      if (!_validateProductDetails()) {
        return;
      }

      if (!_formKey.currentState!.validate()) return;

      if (_imageFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one image')),
        );
        return;
      }

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

      // Upload images to imgbb
      _imageUrls = await Future.wait(
          _imageFiles.map((imageFile) => uploadToImgbb(imageFile)));

      // Prepare product data with null safety
      final productData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'details': _detailsController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _selectedCategory!,
        'condition': _selectedCondition!,
        'type': 'rental',
        'userId': currentUser.uid,
        'username': currentUser.displayName ?? 'Anonymous',
        'userEmail': currentUser.email ?? 'no-email',
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': DateTime.now().millisecondsSinceEpoch, //yyyyyyyyyyyyyy
      };

      // Add image URLs
      for (var i = 0; i < _imageUrls.length; i++) {
        productData['imageUrl${i + 1}'] = _imageUrls[i];
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

        _formKey.currentState!.reset();
        _nameController.clear();
        _priceController.clear();
        _detailsController.clear();
        _brandController.clear();

        setState(() {
          _imageFiles.clear();
          _imageUrls.clear();
          _isUploading = false;
          _selectedCategory = null;
          _selectedCondition = null;
        });
      }
    } catch (e) {
      if (mounted) {
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
  void _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null) {
      // Limit to MAX_IMAGES (3)
      final limitedFiles = pickedFiles.take(MAX_IMAGES).toList();

      setState(() {
        _imageFiles = limitedFiles.map((file) => File(file.path)).toList();
      });

      // Show a message if more than MAX_IMAGES were selected
      if (pickedFiles.length > MAX_IMAGES) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only $MAX_IMAGES images can be uploaded')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 5.0),
                      child: Text(
                        "What's your item?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.0,
                        ),
                      ),
                    ),
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
                          'Select Images (${_imageFiles.length}/$MAX_IMAGES)'),
                      onPressed:
                          _imageFiles.length < MAX_IMAGES ? _pickImages : null,
                    ),
                    if (_imageFiles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _imageFiles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final imageFile = entry.value;
                              return Stack(
                                children: [
                                  GestureDetector(
                                    onTap: () => _showImagePreview(imageFile),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Image.file(
                                        imageFile,
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
                                      icon: const Icon(Icons.close,
                                          color: Colors.red),
                                      onPressed: () => _removeImage(index),
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
