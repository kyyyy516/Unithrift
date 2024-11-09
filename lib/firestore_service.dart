import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Get messages from a specific chat
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Send a message to a specific chat with an optional image URL
  Future<void> sendMessage(String chatId, String userId, String messageText,
      {String? imageUrl}) async {
    try {
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
        'imageUrl': imageUrl, // Add imageUrl to the message if available
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Upload an image to Firebase Storage and return the URL
  Future<String> uploadImage(String imagePath) async {
    try {
      // Create a reference to Firebase Storage with a unique file path
      final storageRef =
          _storage.ref().child('chat_images').child(DateTime.now().toString());

      // Upload the image to Firebase Storage
      final uploadTask = storageRef.putFile(File(imagePath));
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL for the uploaded image
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      rethrow; // Throw error again if needed for further handling
    }
  }

  // Create a chat room if it doesn't already exist
  Future<void> createChatRoom(String chatId, String user1, String user2) async {
    try {
      await _db.collection('chats').doc(chatId).set({
        'users': [user1, user2],
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error creating chat room: $e");
    }
  }
}
