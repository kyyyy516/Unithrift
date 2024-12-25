import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:unithrift/firestore_service.dart';

class EditRentalPage extends StatefulWidget {
  final String productID;
  final String userID;
  final Map<String, dynamic> product;

  const EditRentalPage({
    super.key, 
    required this.productID,
    required this.userID,
    required this.product,
  });

  @override
  State<EditRentalPage> createState() => _EditRentalPageState();
}

class _EditRentalPageState extends State<EditRentalPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  Map<String, dynamic>? _productData;

  final List<String> _categories = [
    'Books and Study Materials', // rental
    'Electronics and Gadgets',
    'Furniture and Household',
    'Clothing and Accessories',
    'Sports and Fitness Equipment',
    'Transportation',
    'Other Essentials'
  ];

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
        _detailsController.text != _initialDetails ||
        _brandController.text != _initialBrand ||
        _category != _initialCategory ||
        _condition != _initialCondition;
  }

  Future<void> _updateProduct() async {
    if (!_validateDetails()) {
        return;
      }

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
        'price': double.parse(double.parse(_priceController.text.trim()).toStringAsFixed(2)),
        'details': _detailsController.text.trim(),
        'brand': _brandController.text.trim(),
        'category': _category,
        'condition': _condition,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.product['name']} updated successfully'),
          ),
        );
        // Refresh the parent page
        Navigator.pop(context, true);
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
                // Add these widgets in the ListView children
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
                  controller: _detailsController,
                  decoration: const InputDecoration(
                    labelText: 'Details',
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF808569)), 
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
    _detailsController.dispose();
    _brandController.dispose();
    super.dispose();
  }
}
