import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';

class EditProductPage extends StatefulWidget {
  //final Map<String, dynamic> product;
  final String productID;
  final String userID;

  const EditProductPage({
    super.key, 
    required this.productID,
    required this.userID,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _productData;

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
    _fetchProductData();
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
          SnackBar(content: Text('Error loading product: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  bool _hasChanges() {
    return _nameController.text != _initialName ||
        _priceController.text != _initialPrice ||
        _detailsController.text != _initialDetails ||
        _brandController.text != _initialBrand ||
        _category != _initialCategory ||
        _condition != _initialCondition;
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Check if any changes were made
    if (!_hasChanges()) {
      Navigator.pop(context);
      return;
    }

    try {
      setState(() => _isLoading = true);

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('products')
          .doc(widget.productID)
          .update({
        'name': _nameController.text.trim(),
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'details': _detailsController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _category,
        'condition': _condition,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
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
