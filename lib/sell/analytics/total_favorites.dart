import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/navigation%20bar/bottom_navbar.dart';
import 'package:unithrift/sell/listing_details.dart';

class TotalFavoritesDetails extends StatefulWidget {
  const TotalFavoritesDetails({super.key});

  @override
  State<TotalFavoritesDetails> createState() => _TotalFavoritesDetailsState();
}

class _TotalFavoritesDetailsState extends State<TotalFavoritesDetails> {
  int _selectedTabIndex = 0;
  int _selectedIndex = 3;



  Stream<List<Map<String, dynamic>>> getProductItems() {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // If no user is logged in, return empty stream
    if (currentUser == null) {
      return Stream.value([]);
    }

    // First get all your products
  return FirebaseFirestore.instance
      .collection('users')
      .doc(currentUser.uid)
      .collection('products')
      .snapshots()
      .asyncMap((productsSnapshot) async {
        List<Map<String, dynamic>> results = [];
        
        // For each of your products
        for (var productDoc in productsSnapshot.docs) {
          var productData = productDoc.data();
          productData['productID'] = productDoc.id;
          
          // Get all users
          QuerySnapshot usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .get();
          
          int favoriteCount = 0;
          
          // Check each user's favorites collection
          for (var userDoc in usersSnapshot.docs) {
            QuerySnapshot favoriteSnapshot = await FirebaseFirestore.instance
                .collection('users')
                .doc(userDoc.id)
                .collection('favorites')
                .where('productID', isEqualTo: productDoc.id)
                .get();
                
            favoriteCount += favoriteSnapshot.docs.length;
          }
          
          productData['favorites'] = favoriteCount;
          results.add(productData);
        }
        
        return results;
      });
}

String? getFirstValidImage(Map<String, dynamic> product) {//yy
  List<dynamic> images = [
    product['imageUrl1'],
    product['imageUrl2'],
    product['imageUrl3'],
    product['imageUrl4'],
    product['imageUrl5'],
  ].where((url) => 
    url != null && 
    url != 'https://via.placeholder.com/50' && 
    !url.toLowerCase().endsWith('.mp4')
  ).toList();

  return images.isNotEmpty ? images[0] : null;
}


  


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
            title: const Text(
              'Total favorites',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
            body: SafeArea(
              child: Column(
                children: [
                  _buildTabRow(),
                  //const SizedBox(height: 10),
                  Expanded(
                    child: _buildContentSection()
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildTabRow() {
    return Row(
      children: [
        _buildTab(0, 'Items'),
        _buildTab(1, 'Rentals'),
        _buildTab(2, 'Services'),
      ],
    );
  }

  Widget _buildTab(int index, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: BoxDecoration(
            color: _selectedTabIndex == index
                ? const Color(0xFFE5E8D9)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedTabIndex == index ? Colors.black : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildContentSection() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: getProductItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No listing'));  // zx
        }

        // Group items by type and seller
        Map<String, Map<String, List<Map<String, dynamic>>>> groupedItems = {
          'feature': {},
          'rental': {},
          'service': {}
        };

        for (var item in snapshot.data!) {
          String type = item['type'] ?? 'feature';
          String seller = item['sellerName'] ?? 'Unknown Seller';
          groupedItems[type]!.putIfAbsent(seller, () => []).add(item);
        }

        // Determine which items to show based on selected tab
        String selectedType;
        String sectionTitle;

        switch (_selectedTabIndex) {
          case 0:
            selectedType = 'feature';
            sectionTitle = 'Items';
            break;
          case 1:
            selectedType = 'rental';
            sectionTitle = 'Rentals';
            break;
          case 2:
            selectedType = 'service';
            sectionTitle = 'Services';
            break;
          default:
            selectedType = 'feature';
            sectionTitle = 'Items';
        }

        if (groupedItems[selectedType]!.isEmpty) {
          return Center(
            child: Text(
              'No ${sectionTitle.toLowerCase()}.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          );
        }

        // Flatten the grouped items for grid view
        final List<Map<String, dynamic>> flattenedItems = [];
        groupedItems[selectedType]!.forEach((seller, items) {
          flattenedItems.addAll(items);
        });

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7, // Adjust this value to control item height
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: flattenedItems.length,
          itemBuilder: (context, index) {
            final item = flattenedItems[index];
            return _buildGridItem(item);
          },
        );
      },
    );
  }

  Widget _buildGridItem(Map<String, dynamic> item) {
  Widget buildPriceText() {
    if (_selectedTabIndex == 1) {
      return RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'RM ${(double.parse(item['price'].toString())).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            TextSpan(
              text: ' /day',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    } else {
      return Text(
        'RM ${(double.parse(item['price'].toString())).toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      );
    }
  }

  return Card(
    elevation: 2,
    color: const Color(0xFFF2F3EC),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
    child: GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListingPage(product: item),
          ),
        );
      },
      child: Column(
        children: [
          // Image container
          SizedBox(
            height: 130,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: Image.network(
                getFirstValidImage(item) ?? 'https://via.placeholder.com/200',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image_not_supported, size: 40),
                  );
                },
              ),
            ),
          ),
          
          // Content container
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Product Name
                  Flexible(
                    child: Text(
                      item['name'] ?? 'Unknown Item',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Description
                  if (item['details'] != null && item['details'].toString().isNotEmpty)
                    Flexible(
                      child: Text(
                        item['details'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  
                  // Price
                  buildPriceText(),
                  const SizedBox(height: 4),
                  
                  // Favorites count
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        '${item['favorites'] ?? 0} favorites',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

}