import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/navigation%20bar/bottom_navbar.dart';
import '../sell/edit/edit_rental.dart';
import '../sell/edit/edit_feature.dart';
import 'listing_details.dart';

class AllProductPage extends StatefulWidget {
  const AllProductPage({super.key});

  @override
  State<AllProductPage> createState() => _AllProductPageState();
}

class _AllProductPageState extends State<AllProductPage> {
  int _selectedTabIndex = 0;
  int _selectedIndex = 3;

  final Set<String> _deletingItems = {};

  Stream<List<Map<String, dynamic>>> getProductItems() {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // If no user is logged in, return empty stream
    if (currentUser == null) {
      return Stream.value([]);
    }

    // Get products only from current user's collection
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('products')
        //.where('type', isEqualTo: 'feature')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            var data = doc.data();
            data['productID'] = doc.id;
            data['userId'] = currentUser.uid;
            data['userEmail'] = currentUser.email;
            data['isAvailable'] = data['isAvailable'] ?? true; // Add this line
            return data;
          }).toList();
        });
}


  String _getRateType(String? category) {
    switch (category?.toLowerCase()) {
      case 'Laundry Service':
        return '/ piece';
      case 'Delivery Service':
        return '/ km';
      case 'Tutoring Service':
        return '/ hour';
      case 'Printing Service':
        return '/ piece';
      default:
        return '/ service';
    }
  }

  void _removeItem(String productID) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in first')),
        );
        return;
      }

      setState(() {
        _deletingItems.add(productID);
      });

      // Use productID directly
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('products')
          .doc(productID)
          .delete();

      setState(() {
        _deletingItems.remove(productID);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            // content: Text('Item removed.'),
            content: Text('Deleted successfully.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _deletingItems.remove(productID);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation(String productID) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Delete', 
            //style: TextStyle(color: Colors.red)
          ),
            onPressed: () {
              Navigator.of(context).pop();
              _removeItem(productID);
            },
          ),
        ],
      );
    },
  );
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
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.black,
                    size: 24,
                  ),
                  SizedBox(width: 8),
                  Text('My Listing'),
                ],
              ),
              centerTitle: true,
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
          return const Center(child: Text('Your cart is empty'));
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
            childAspectRatio: 0.75, // Adjust this value to control item height
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
    // Add this debug print
    // print('Item description: ${item['details']}');   
    // print('Item data: $item');

    final bool isAvailable = item['isAvailable'] ?? true;

     // Helper function to build price text
  Widget buildPriceText() {
    if (_selectedTabIndex == 1) { // Rental tab
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

    } else { // Other tabs (Items and Services)
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
      //color: const Color(0xFFE5E8D9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),  // circular(8)
      ),
      child: Stack(  // Move Stack inside Card
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailsPage(product: item),  // Show details when click 
                ),
              );
            }, 

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image container with fixed height
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: Image.network(
                      item['imageUrl1'] ?? 'https://via.placeholder.com/200',
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product Name
                          Text(
                            item['name'] ?? 'Unknown Item',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          
                          // Description 
                          if (item['details'] != null && item['details'].toString().isNotEmpty)
                            Text(
                              item['details'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          const Spacer(),

                          // Price and Remove Button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              buildPriceText(),
                              // Row(
                              //   children: [
                              //     // Edit Button
                              //     GestureDetector(
                              //       onTap: () => Navigator.push(
                              //         context,
                              //         MaterialPageRoute(
                              //           builder: (context) => EditFeaturePage(
                              //             productID: item['productID'],
                              //             userID: item['userId'],
                              //           ),
                              //         ),
                              //       ),
                              //       child: const Icon(
                              //         Icons.edit,
                              //         color: Color(0xFF808569),
                              //         size: 18,
                              //       ),
                              //     ),
                              //     const SizedBox(width: 8), // Space between icons

                              //     GestureDetector(
                              //       onTap: () => _showDeleteConfirmation(item['productID']),
                              //       child: const Icon(
                              //         Icons.delete,
                              //         color: Color(0xFF808569),
                              //         size: 18,
                              //       ),
                              //     ),
                              //   ],
                              // ),    
                            ],
                          ),
                        ],
                      ),
                  ),
              ),
            ],
          ),
          ),

          if (!isAvailable)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ListingDetailsPage(product: item),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF808569),
                      child: Icon(Icons.close, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Make Available?',
                      style: TextStyle(
                        color: const Color(0xFF808569),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),    
        ],
      ),
    );
  }
}