import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:unithrift/account/favourite_service.dart';
import 'package:unithrift/explore/feature/item_feature.dart';
import 'package:unithrift/explore/rental/item_rental.dart';
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
  final FavoriteService _favoriteService = FavoriteService();

  DateTime? _startDate;
  DateTime? _endDate;

  String selectedCategory = 'All';
  List<String> categoryList = [
    'All',
    'Books and Study Materials',
    'Electronics and Gadgets',
    'Furniture and Household',
    'Clothing and Accessories',
    'Sports and Fitness Equipment',
    'Transportation',
    'Other Essentials'
  ];

  List<IconData> categoryIcons = [
    Icons.select_all,
    Icons.book,
    Icons.devices,
    Icons.chair,
    Icons.dry_cleaning,
    Icons.sports_basketball,
    Icons.car_rental,
    Icons.more
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      setState(() {
        nameQuery = _nameController.text.toLowerCase();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
    });
  }

  Stream<List<Map<String, dynamic>>> getRentalProducts() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .asyncMap((usersSnapshot) async {
      List<Map<String, dynamic>> allProducts = [];

      for (var userDoc in usersSnapshot.docs) {
        var productsSnapshot = await userDoc.reference
            .collection('products')
            .where('type', isEqualTo: 'rental')
            .get();

        for (var productDoc in productsSnapshot.docs) {
          var productData = productDoc.data();
          productData['productID'] = productDoc.id;
          productData['userId'] = userDoc.id;
          productData['userEmail'] = userDoc['email'];
          productData['username'] = userDoc.data()['username'];
          allProducts.add(productData);
        }
      }

      return allProducts;
    });
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(categoryList.length, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedCategory = categoryList[index];
                      _categoryController.text = selectedCategory;
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          categoryIcons[index],
                          color: const Color(0xFF424632),
                          size: 40,
                        ),
                        const SizedBox(width: 10),
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
              }),
            ),
          ),
        );
      },
    );
  }

  String truncateName(String name) {
    const maxLength = 15;
    return name.length > maxLength
        ? '${name.substring(0, maxLength)}...'
        : name;
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF424632),
              onPrimary: Colors.white,
              surface: Color(0xFFF2F3EC),
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
          Container(
            height: 180.0,
            width: double.infinity,
            color: const Color(0xFF808569),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search filters container
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
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  onTap: _showDateRangePicker,
                                  decoration: InputDecoration(
                                    hintText: 'Start Date',
                                    filled: true,
                                    fillColor: const Color(0xFFF2F3EC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _startDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_startDate!)
                                        : '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  readOnly: true,
                                  onTap: _showDateRangePicker,
                                  decoration: InputDecoration(
                                    hintText: 'Return Date',
                                    filled: true,
                                    fillColor: const Color(0xFFF2F3EC),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  controller: TextEditingController(
                                    text: _endDate != null
                                        ? DateFormat('dd/MM/yyyy')
                                            .format(_endDate!)
                                        : '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Padding(
                    padding:
                        EdgeInsets.only(top: 10.0, bottom: 15.0, left: 16.0),
                    child: Row(
                      children: [
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
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: getRentalProducts(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                            child: Text('No rental items found.'));
                      }

                      final products = snapshot.data!;

                      // Filter products based on search, category, and dates
                      final filteredProducts = products.where((product) {
                        final name =
                            (product['name'] ?? '').toString().toLowerCase();
                        final category = (product['category'] ?? '')
                            .toString()
                            .toLowerCase();
                        final details =
                            (product['details'] ?? '').toString().toLowerCase();

                        bool categoryMatch = selectedCategory == 'All' ||
                            category.contains(selectedCategory.toLowerCase());

                        bool searchMatch = nameQuery.isEmpty ||
                            name.contains(nameQuery) ||
                            category.contains(nameQuery) ||
                            details.contains(nameQuery);

                        bool dateMatch = true;
                        if (_startDate != null && _endDate != null) {
                          DateTime? productStartDate =
                              product['startRentalDate'] != null
                                  ? (product['startRentalDate'] as Timestamp)
                                      .toDate()
                                  : null;
                          DateTime? productEndDate = product['endRentalDate'] !=
                                  null
                              ? (product['endRentalDate'] as Timestamp).toDate()
                              : null;

                          if (productStartDate != null &&
                              productEndDate != null) {
                            dateMatch =
                                !(_endDate!.isBefore(productStartDate) ||
                                    _startDate!.isAfter(productEndDate));
                          }
                        }

                        return categoryMatch && searchMatch && dateMatch;
                      }).toList();

                      if (filteredProducts.isEmpty) {
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(), // Use if inside a scrollable parent
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // Number of items per row
                              crossAxisSpacing:
                                  16, // Spacing between items horizontally
                              mainAxisSpacing:
                                  10, // Spacing between items vertically
                              childAspectRatio: itemWidth /
                                  itemHeight, // Adjust aspect ratio dynamically
                            ),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              return _rentalItem(
                                  filteredProducts[index], itemWidth);
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

  Widget _rentalItem(Map<String, dynamic> product, double width) {
    List<dynamic> images = [
      product['imageUrl1'],
      product['imageUrl2'],
      product['imageUrl3'],
      product['imageUrl4'],
      product['imageUrl5'],
    ]
        .where((url) =>
            url != null &&
            url != 'https://via.placeholder.com/50' &&
            !url.toLowerCase().endsWith('.mp4'))
        .toList();

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
            builder: (context) => ItemRentalPage(product: product),
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
                    truncateName(product['name'] ?? 'No Name'),
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
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: "RM${product['price'] ?? '0'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: " /day",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      StatefulBuilder(
                        builder: (context, setInnerState) {
                          return Container(
                            margin: const EdgeInsets.only(right: 5),
                            height: 35,
                            width: 35,
                            decoration: const BoxDecoration(
                              color: Color(0xFF424632),
                              shape: BoxShape.circle,
                            ),
                            child: StreamBuilder<bool>(
                                stream: _favoriteService
                                    .isFavorite(product['productID']),
                                builder: (context, snapshot) {
                                  final isFavorited = snapshot.data ?? false;

                                  return IconButton(
                                    padding: EdgeInsets.zero,
                                    iconSize: 20,
                                    icon: Icon(
                                      isFavorited
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorited
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                    onPressed: () async {
                                      final success = await _favoriteService
                                          .toggleFavorite(product);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(success
                                              ? 'Added to likes'
                                              : 'Removed from likes'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  );
                                }),
                          );
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
