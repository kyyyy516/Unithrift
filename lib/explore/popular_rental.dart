import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:unithrift/explore/item.dart';
import 'package:unithrift/navigation%20bar/bottom_navbar.dart';
import 'package:unithrift/navigation%20bar/common_appbar.dart';

class PopularRentalPage extends StatefulWidget {
  const PopularRentalPage({super.key});

  @override
  State<PopularRentalPage> createState() => _PopularRentalPageState();
}

class _PopularRentalPageState extends State<PopularRentalPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  int _selectedIndex = 0;
  String nameQuery = '';

  DateTime? _startDate;
  DateTime? _endDate;

  String selectedCategory = '';
  List<String> categoryList = [
    'All',
    'Books',
    'Study Materials',
    'Gadgets',
    'Furniture',
    'Sports Equipment',
    'Others'
  ];

  List<IconData> categoryIcons = [
    Icons.select_all,
    Icons.book,
    Icons.school,
    Icons.devices,
    Icons.chair,
    Icons.sports_basketball,
    Icons.more
  ];

  //mok for bottomNav bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
    });
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        nameQuery = _nameController.text.toLowerCase();
      });
    });
  }



void _addToCart(Map<String, dynamic> product, String sourceCollection) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    final cartCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('cart');

    // Check if a similar product already exists in the cart
    final existingProductQuery = await cartCollection
        .where('id', isEqualTo: product['id'])
        .get();

    // If product already in cart, increment quantity instead of adding a duplicate
    if (existingProductQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} already exists in cart.')),
      );
      return;
    }

    // Add new product to cart with 'type' set to 'rental'
    await cartCollection.add({
      ...product,
      'sourceCollection': sourceCollection, // Add source collection identifier
      'quantity': 1,
      'addedAt': FieldValue.serverTimestamp(),
      'seller': product['seller'] ?? 'Unknown Seller'
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product['name']} added to cart')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error adding to cart: $e')),
    );
  }
}

  void _showCategoryBottomSheet() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: categoryList.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categoryList[index];
                      _categoryController.text = selectedCategory;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(categoryIcons[index],
                            color: const Color(0xFF424632), size: 40),
                        const SizedBox(height: 8),
                        Text(
                          categoryList[index],
                          style: const TextStyle(
                            color: Color(0xFF424632),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        });
  }

  void _showDateRangePicker() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2025),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF424632),
              onPrimary: Colors.white,
              surface: const Color(0xFFF2F3EC),
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
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: mainAppBar(context),
    body: Stack(
      children: [
        // Green Background
        Container(
          height: 180.0, // Adjust the height as needed
          width: double.infinity, // Ensures it spans the full width
          color: const Color(0xFF808569),
        ),
        // Main Content
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Search Bar Section
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Name Search TextField
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Search by Name',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: const Color(0xFFF2F3EC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Category Selection
                        TextField(
                          controller: _categoryController,
                          readOnly: true,
                          onTap: _showCategoryBottomSheet,
                          decoration: InputDecoration(
                            hintText: 'Select Category',
                            suffixIcon: const Icon(Icons.category),
                            filled: true,
                            fillColor: const Color(0xFFF2F3EC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Date Range Selection
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                onTap: _showDateRangePicker,
                                decoration: InputDecoration(
                                  hintText: 'Start Date',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF2F3EC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                ),
                                controller: TextEditingController(
                                    text: _startDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_startDate!)
                                        : ''),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                readOnly: true,
                                onTap: _showDateRangePicker,
                                decoration: InputDecoration(
                                  hintText: 'Return Date',
                                  hintStyle: const TextStyle(color: Colors.grey),
                                  filled: true,
                                  fillColor: const Color(0xFFF2F3EC),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 15),
                                ),
                                controller: TextEditingController(
                                    text: _endDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_endDate!)
                                        : ''),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Search Button
                        ElevatedButton(
                          onPressed: () {
                            // Implement search functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF808569),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Search',
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
                const SizedBox(height: 16),
              // Popular Retal Section
              const Padding(
                padding: EdgeInsets.only(top: 10.0, bottom: 15.0, left: 16.0),
                child: Row(
                  children: [
                    SizedBox(width: 1),
                    Text(
                      'Popular Rentals',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.black,
                      size: 24,
                    ),
                  ],
                ),
              ),

              // Rental Items Stream
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('popular_rental')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text('No rental items available'));
                  }

                  final filteredItems = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Name filter
                    bool nameMatch = _nameController.text.isEmpty ||
                        (data['name'] as String)
                            .toLowerCase()
                            .contains(_nameController.text.toLowerCase());

                    // Category filter
                    bool categoryMatch = selectedCategory.isEmpty ||
                        selectedCategory == 'All' ||
                        (data['category'] as String).toLowerCase() ==
                            selectedCategory.toLowerCase();

                    // Date range filter
                    bool dateMatch = true;
                    if (_startDate != null && _endDate != null) {
                      // Assuming you have 'availableFrom' and 'availableTo' fields in your Firestore document
                      DateTime availableFrom =
                          (data['startRentalDate'] as Timestamp).toDate();
                      DateTime availableTo =
                          (data['endRentalDate'] as Timestamp).toDate();

                      dateMatch = (_startDate!.isBefore(availableTo) ||
                              _startDate == availableTo) &&
                          (_endDate!.isAfter(availableFrom) ||
                              _endDate == availableFrom);
                    }

                    return nameMatch && categoryMatch && dateMatch;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return const Center(
                        child: Text('No matching items found.'));
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = (constraints.maxWidth - 40) /
                          2; // Adjust width dynamically
                      const itemHeight =
                          250; // Calculate height based on aspect ratio

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(), // Use if inside a scrollable parent
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of items per row
                          crossAxisSpacing:
                              16, // Spacing between items horizontally
                          mainAxisSpacing:
                              10, // Spacing between items vertically
                          childAspectRatio: itemWidth /
                              itemHeight, // Adjust aspect ratio dynamically
                        ),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final product = filteredItems[index].data()
                              as Map<String, dynamic>;
                          return _builRentalItem(product, itemWidth);
                          }, // End of Grid itemBuilder
                        );
                      }, // End of LayoutBuilder builder
                    );
                  }, // End of StreamBuilder builder
                ),
              ], // End of Column children
            ),
          ), // End of Padding
        ),
      ],
    ), // End of Stack children
    bottomNavigationBar: mainBottomNavBar(_selectedIndex, _onItemTapped),
  ); // End of Scaffold
} // End of build method






               
  Widget _builRentalItem(Map<String, dynamic> product, double width) {
    List<String> images = [
      product['imageUrl1'] ?? 'https://via.placeholder.com/50',
      product['imageUrl2'] ?? 'https://via.placeholder.com/50',
      product['imageUrl3'] ?? 'https://via.placeholder.com/50',
      product['imageUrl4'] ?? 'https://via.placeholder.com/50',
      product['imageUrl5'] ?? 'https://via.placeholder.com/50',
    ];

    // Filter out empty image URLs (if any)
    images.removeWhere((image) => image == 'https://via.placeholder.com/50');

    String truncateDescription(String description) {
      const maxLength = 18;
      return description.length > maxLength
          ? '${description.substring(0, maxLength)}...'
          : description;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailPage(product: product),
          ),
        );
      },
      child: Container(
        width: width,
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E8D9),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carousel Slider with custom indicator
            Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 150,
                    enableInfiniteScroll: false,
                    viewportFraction: 1.0,
                    onPageChanged: (index, reason) {
                      // Add state management for dot indicator if needed
                    },
                  ),
                  items: images.map((imageUrl) {
                    return ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    );
                  }).toList(),
                ),
                // Dot indicator
                Positioned(
                  bottom: 10,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(images.length, (index) {
                      return Container(
                        width: 8.0,
                        height: 8.0,
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'] ?? 'No Name',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    truncateDescription(product['details'] ?? 'No Details'),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "RM${product['price'] ?? '0'} /day",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _addToCart(product,'popular_rental');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFF424632),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
