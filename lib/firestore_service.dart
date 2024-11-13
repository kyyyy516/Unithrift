import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  Future<void> sendMessage(String chatId, String senderId, String messageText,
      {String? imageUrl}) async {
    try {
      // Add message to the messages collection
      await _db.collection('chats').doc(chatId).collection('messages').add({
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': senderId,
        'imageUrl': imageUrl,
      });

      // Get chat data to find out the receiver ID
      final chatDoc = await _db.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      if (chatData == null) return;

      // Find the receiver's ID (the other user in the chat)
      final users = List<String>.from(chatData['users']);
      final receiverId = users.firstWhere((id) => id != senderId);

      // Update the last message and increment unread count for the receiver
      await _db.collection('chats').doc(chatId).update({
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
        'lastMessageSenderId': senderId, // Track the last message sender
      });
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  // Upload an image using ImgBB API and return the image URL
  Future<String> uploadImage(String imagePath) async {
    try {
      // Replace this URL with your ImgBB API URL
      final apiUrl =
          'https://api.imgbb.com/1/upload?key=fc9f999af3a441ea33b1f537072ea749'; // Your ImgBB API key

      // Prepare the file for upload
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // Send the request
      var response = await request.send();

      // Check if the request was successful
      if (response.statusCode == 200) {
        // If the upload is successful, extract the URL from the response
        final responseData = await http.Response.fromStream(response);
        final Map<String, dynamic> data = json.decode(responseData.body);

        if (data['success']) {
          return data['data']['url']; // Return the uploaded image URL
        } else {
          throw Exception(
              'Failed to upload image: ${data['error']['message']}');
        }
      } else {
        throw Exception('Failed to upload image.');
      }
    } catch (e) {
      print("Error uploading image: $e");
      throw Exception('Failed to upload image. Please try again later.');
    }
  }

  // Create a chat room if it doesn't already exist
  Future<void> createChatRoom(String chatId, String user1, String user2) async {
    try {
      await _db.collection('chats').doc(chatId).set({
        'users': [user1, user2],
        'createdAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          user1: 0,
          user2: 0,
        },
        'lastMessageSenderId': null, // Track the last message sender
      }, SetOptions(merge: true));
    } catch (e) {
      print("Error creating chat room: $e");
    }
  }
}
