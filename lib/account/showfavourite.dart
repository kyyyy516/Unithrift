import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/account/favourite_service.dart';

class ShowFavorites extends StatefulWidget {
  const ShowFavorites({Key? key}) : super(key: key);

  @override
  State<ShowFavorites> createState() => _ShowFavoritesState();
}

class _ShowFavoritesState extends State<ShowFavorites> {
  int _selectedTabIndex = 0;
  final FavoriteService _favoriteService = FavoriteService();

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
              color: _selectedTabIndex == index ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getFavoriteItems() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('My Favorites'),
      centerTitle: true,
    ),
    body: Column(
      children: [
        _buildTabRow(),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: getFavoriteItems(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No favorites yet'));
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

              // Filter items by type
              final filteredItems = snapshot.data!
                  .where((item) => item['type'] == selectedType)
                  .toList();

              if (filteredItems.isEmpty) {
                return Center(
                  child: Text(
                    'No ${sectionTitle.toLowerCase()} in favorites',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildFavoriteItem(item);
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}
Widget _buildFavoriteItem(Map<String, dynamic> item) {
  return Card(
    margin: const EdgeInsets.all(8),
    elevation: 2,
    child: ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          item['imageUrl1'] ?? '',
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 60,
              height: 60,
              color: Colors.grey[200],
              child: const Icon(Icons.image_not_supported),
            );
          },
        ),
      ),
      title: Text(
        item['name'] ?? 'Unnamed Item',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        'RM ${item['price'] ?? '0'}',
        style: const TextStyle(
          color: Color(0xFF808569),
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.favorite, color: Colors.red),
        onPressed: () => _favoriteService.toggleFavorite(item),
      ),
      onTap: () {
        // Navigate to item details page
        Navigator.pushNamed(
          context,
          '/item-details',
          arguments: item,
        );
      },
    ),
  );
}

}
