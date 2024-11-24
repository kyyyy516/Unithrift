import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unithrift/cart/cart.dart';
import 'package:unithrift/explore/item.dart';
import 'package:unithrift/navigation%20bar/bottom_navbar.dart';
import 'package:unithrift/navigation%20bar/common_appbar.dart';

class FeaturePage extends StatefulWidget {
  const FeaturePage({super.key});

  @override
  State<FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<FeaturePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String selectedCategory = 'All';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  //mok for bottomNav bar
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
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
        .where('name', isEqualTo: product['name'])
        .get();

    // If product already in cart, increment quantity instead of adding a duplicate
    if (existingProductQuery.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product['name']} already exist in cart.')),
      );
      return;
    }

    // Add new product to cart
    await cartCollection.add({
      ...product,
      'sourceCollection': sourceCollection,  // Add source collection identifier
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


  // Category Box Widget
  Widget categoryBox(String category) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selectedCategory == category
              ? const Color(0xFF424632) // dark color when selected
              : const Color(0xFFF2F3EC), // F2F3EC for unselected
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.bold, // Making text bold

            color: selectedCategory == category
                ? Colors.white
                : const Color(
                    0xFF424632), // text color when selected or unselected
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: mainAppBar(context),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar (existing code remains the same)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 25.0, vertical: 8.0),
              child: SizedBox(
                height: 50,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF2F3EC),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),

            // How to Shop Section (existing code remains the same)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 16.0, horizontal: 30.0),
              child: Container(
                width: 300,
                height: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFF424632),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.3),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "How to Shop Smart with UniThrift",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "Click on Me to Turn Your Pre-loved Items into Cash!",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFFA8A9A8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Featured Slider')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SizedBox.shrink();
                }

                final sliderItems = snapshot.data!.docs;

                return CarouselSlider(
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    aspectRatio: 16 / 9,
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enableInfiniteScroll: true,
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    viewportFraction: 0.8,
                  ),
                  items: sliderItems.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    // Get both image URLs
                    String imageUrl1 =
                        data['imageUrl1'] ?? 'https://via.placeholder.com/350';
                    String imageUrl2 =
                        data['imageUrl2'] ?? 'https://via.placeholder.com/350';

                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Show first image
                                Image.network(
                                  imageUrl1,
                                  fit: BoxFit.cover,
                                ),
                                // Show second image as overlay (or next to the first image)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Image.network(
                                    imageUrl2,
                                    fit: BoxFit.cover,
                                    height:
                                        100, // You can adjust the size of the second image
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),

            // Category Row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 13.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    categoryBox('All'),
                    categoryBox('Books'),
                    categoryBox('Clothes'),
                    categoryBox('Furniture'),
                    categoryBox('Mobile'),
                  ],
                ),
              ),
            ),
            // Feature Items Section
            const Padding(
              padding: EdgeInsets.only(top: 10.0, bottom: 15.0, left: 16.0),
              child: Row(
                children: [
                  SizedBox(width: 1),
                  Text(
                    'Feature Items',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),

            // Staggered Products Layout
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Feature item')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No items found.'));
                }

                final products = snapshot.data!.docs;

                // Filter products based on search query and selected category
                final filteredProducts = products.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final category =
                      (data['category'] ?? '').toString().toLowerCase();
                  final details =
                      (data['details'] ?? '').toString().toLowerCase();

                  // Check category filter
                  bool categoryMatch = selectedCategory == 'All' ||
                      category.contains(selectedCategory.toLowerCase());

                  // Check search query
                  bool searchMatch = searchQuery.isEmpty ||
                      name.contains(searchQuery) ||
                      category.contains(searchQuery) ||
                      details.contains(searchQuery);

                  return categoryMatch && searchMatch;
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(child: Text('No matching items found.'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth - 30) /
                        2; // Adjust width dynamically
                    const itemHeight =
                        280; // Calculate height based on aspect ratio

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Use if inside a scrollable parent
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // Number of items per row
                        crossAxisSpacing:
                            10, // Spacing between items horizontally
                        mainAxisSpacing: 10, // Spacing between items vertically
                        childAspectRatio: itemWidth /
                            itemHeight, // Adjust aspect ratio dynamically
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index].data()
                            as Map<String, dynamic>;
                        return _featureItem(product, itemWidth);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: mainBottomNavBar(_selectedIndex, _onItemTapped),
    );
  }

  Widget _featureItem(Map<String, dynamic> product, double width) {
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
                        "RM${product['price'] ?? '0'}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          _addToCart(product,'feature_items');
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
