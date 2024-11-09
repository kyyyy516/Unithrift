import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'chatscreen.dart';

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat List"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white, // Set the background color to white
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            // Filter out the current user from the list
            final users = snapshot.data!.docs
                .where((doc) => doc['userId'] != currentUser!.uid)
                .toList();

            return Padding(
              padding: const EdgeInsets.only(left: 10), // Add left padding here
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final userId = user['userId'];
                  final userEmail = user['email'];
                  final profilePic = user['profilePic'] ?? '';
                  final lastMessage = user['lastMessage'] ?? '';
                  final unreadCount = user['unreadCount'] ?? 0;
                  final timestamp = user['lastMessageTime']?.toDate();

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    title: Text(userEmail),
                    subtitle: Text(lastMessage),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (timestamp != null)
                          Text("${timestamp.hour}:${timestamp.minute}"),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    onTap: () async {
                      final chatId = _generateChatId(currentUser!.uid, userId);
                      await _firestoreService.createChatRoom(
                          chatId, currentUser.uid, userId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(chatId: chatId),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  // Generate a unique chat ID by combining the two user IDs
  String _generateChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}
