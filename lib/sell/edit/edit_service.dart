import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';

class EditServicePage extends StatefulWidget {
  final String productID;
  final String userID;

  const EditServicePage({
    super.key, 
    required this.productID,
    required this.userID,
  });

  @override
  State<EditServicePage> createState() => _EditServicePageState();
}

class _EditServicePageState extends State<EditServicePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _productData;


  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _priceDetailsController;
  late TextEditingController _availabilityController;
  late TextEditingController _detailsController;
  
  // Initialize with empty strings
  String _initialName = '';
  String _initialPrice = '';
  String _initialPriceDetails = '';
  String _initialAvailability = '';
  String _initialDetails = '';
  //late String _initialCategory;

  

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _priceDetailsController = TextEditingController();
    _availabilityController = TextEditingController();
    _detailsController = TextEditingController();
    _fetchProductData();
  }

  // Enhanced product validation method
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
          _priceDetailsController.text = _productData?['pricingDetails'] ?? '';
          _availabilityController.text = _productData?['availability'] ?? '';
          _detailsController.text = _productData?['details'] ?? '';


          // Set initial values after data is loaded
          _initialName = _nameController.text;
          _initialPrice = _priceController.text;
          _initialPriceDetails = _priceDetailsController.text;
          _initialAvailability = _availabilityController.text;
          _initialDetails = _detailsController.text;


          _isLoading = false;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item not found')),
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

  bool _hasChanges() {
    return _nameController.text != _initialName ||
        _priceController.text != _initialPrice ||
        _priceDetailsController.text != _initialPriceDetails ||
        _availabilityController.text != _initialAvailability ||
        _detailsController.text != _initialDetails;

  }

  Future<void> _updateProduct() async {
    if (!_validateDetails()) {
        return;
      }

    if (!_formKey.currentState!.validate()) return;


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

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userID)
          .collection('products')
          .doc(widget.productID)
          .update({
        'name': _nameController.text.trim(),
        'price': double.parse(double.parse(_priceController.text.trim()).toStringAsFixed(2)),
        'pricingDetails': _priceDetailsController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'details': _detailsController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update the initial values to match the new values
      setState(() {
        _initialName = _nameController.text;
        _initialPrice = _priceController.text;
        _initialPriceDetails = _priceDetailsController.text;
        _initialAvailability = _availabilityController.text;
        _initialDetails = _detailsController.text;
        _isLoading = false;
      });


      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updated successfully')),
        );
        // Refresh the parent page
        Navigator.pop(context, true); // Pass true to indicate successful update
      }
    } catch (e) {
      print('Error updating product: $e'); // Add this line for detailed logging
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
                
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  cursorColor: Color(0xFF808569),
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), 
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
                      borderSide: BorderSide(color: Color(0xFF808569)), 
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
                  controller: _priceDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'Pricing Details',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), 
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                    
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please specify price per page/kg/hour/km(unit)' : null,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _availabilityController,
                  decoration: const InputDecoration(
                    labelText: 'Availability Time',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), 
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter availability time' : null,
                  maxLines: 3,
                ),

                const SizedBox(height: 20),
                TextFormField(
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), 
                    ),
                    labelStyle: TextStyle(color: Colors.grey), // Normal label color
                    floatingLabelStyle: TextStyle(color: Color(0xFF808569)), // Focused label color
                    
                  
                  ),
                  maxLines: 3,
                ),
                // Add more fields as needed
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                      const Color(0xFF808569),
                    foregroundColor: Colors.white, // Text color
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Rounded corners
                    ),
                    elevation: 3, // Shadow elevation
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
    _priceDetailsController.dispose();
    _availabilityController.dispose();
    _detailsController.dispose();
    super.dispose();
  }
}
