import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unithrift/explore/feature/item_feature.dart';
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
  Map<String, bool> favoriteStatus = {}; //favourite

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
    });
  }

  Stream<List<Map<String, dynamic>>> getFeatureProducts() {
    return FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .asyncMap((usersSnapshot) async {
      List<Map<String, dynamic>> allProducts = [];

      for (var userDoc in usersSnapshot.docs) {
        var productsSnapshot = await userDoc.reference
            .collection('products')
            .where('type', isEqualTo: 'feature')
            .get();

        for (var productDoc in productsSnapshot.docs) {
          var productData = productDoc.data();
          // Include all necessary user and product information
          productData['productID'] = productDoc.id;
          productData['userId'] = userDoc.id;
          productData['userEmail'] = userDoc.data()['email'];
          productData['username'] = userDoc.data()['username'];
          allProducts.add(productData);
        }
      }

      return allProducts;
    });
  }

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
              ? const Color(0xFF424632)
              : const Color(0xFFF2F3EC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: selectedCategory == category
                ? Colors.white
                : const Color(0xFF424632),
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
            // Search Bar
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

            // How to Shop Section
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
                    categoryBox('Electronics'),
                  ],
                ),
              ),
            ),

            // Feature Items Header
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

            // Feature Products Grid
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: getFeatureProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No feature items found.'));
                }

                final products = snapshot.data!;

                // Filter products based on search and category
                final filteredProducts = products.where((product) {
                  final name = (product['name'] ?? '').toString().toLowerCase();
                  final category =
                      (product['category'] ?? '').toString().toLowerCase();
                  final details =
                      (product['details'] ?? '').toString().toLowerCase();

                  bool categoryMatch = selectedCategory == 'All' ||
                      category.contains(selectedCategory.toLowerCase());

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
                    final itemWidth = (constraints.maxWidth - 30) / 2;
                    const itemHeight = 280;

                    return GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: itemWidth / itemHeight,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return _featureItem(filteredProducts[index], itemWidth);
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
            builder: (context) => ItemFeaturePage(product: product),
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
            Stack(
              alignment: Alignment.center,
              children: [
                CarouselSlider(
                  options: CarouselOptions(
                    height: 150,
                    enableInfiniteScroll: false,
                    viewportFraction: 1.0,
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
                      StatefulBuilder(//favourittttttttttee
                          builder: (context, setInnerState) {
                        return Container(
                          margin: const EdgeInsets.only(right: 5),
                          height: 35,
                          width: 35,
                          decoration: const BoxDecoration(
                            color: Color(0xFF424632),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            iconSize: 20,
                            icon: Icon(
                              favoriteStatus[product['productID']] ?? false
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  favoriteStatus[product['productID']] ?? false
                                      ? Colors.red
                                      : Colors.white,
                            ),
                            onPressed: () {
                              setInnerState(() {
                                favoriteStatus[product['productID']] =
                                    !(favoriteStatus[product['productID']] ??
                                        false);
                              });
                            },
                          ),
                        );
                      })
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
