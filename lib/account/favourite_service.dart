import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class FavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Add to favorites
  Future<bool> toggleFavorite(Map<String, dynamic> product) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final favoriteRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(product['productID']);

    final doc = await favoriteRef.get();

    if (doc.exists) {
      // Remove from favorites
      await favoriteRef.delete();
      return false;
    } else {
      // Add to favorites
      await favoriteRef.set({
        'productID': product['productID'],
        'name': product['name'],
        'price': product['price'],
        'imageUrl1': product['imageUrl1'],
        'details': product['details'],
        'category': product['category'],
        'type': product['type'],
        'sellerUserId': product['userId'],
        'sellerName': product['username'],
        'addedAt': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }

  // Check if item is favorited
  Stream<bool> isFavorite(String productId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }
  // Add this method to your existing FavoriteService class
Future<bool> isItemFavorited(String productId) async {
  final user = _auth.currentUser;
  if (user == null) return false;

  final doc = await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('favorites')
      .doc(productId)
      .get();

  return doc.exists;
}

}

