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

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Chat List"),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text(
            "You are not logged in. Please log in to view your chat list.",
            style: TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat List"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No users found.",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            final users = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data != null && data['userId'] != currentUser.uid;
            }).toList();

            if (users.isEmpty) {
              return const Center(
                child: Text(
                  "No other users available.",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(left: 10),
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index].data() as Map<String, dynamic>;
                  final userId = user['userId'] ?? '';
                  final userEmail = user['email'] ?? 'Unknown Email';
                  final profilePic = user['profilePic'] ?? '';
                  final chatId = _generateChatId(currentUser.uid, userId);

                  if (userId.isEmpty) {
                    return Container();
                  }

                  return StreamBuilder<DocumentSnapshot>(
                    stream: _db.collection('chats').doc(chatId).snapshots(),
                    builder: (context, chatSnapshot) {
                      if (chatSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const SizedBox.shrink();
                      }
                      if (chatSnapshot.hasError) {
                        return Center(
                            child: Text("Error: ${chatSnapshot.error}"));
                      }

                      final chatData =
                          chatSnapshot.data?.data() as Map<String, dynamic>?;

                      final lastMessage =
                          chatData?['lastMessage'] ?? 'No messages yet';
                      final lastMessageTime =
                          chatData?['lastMessageTime']?.toDate();
                      final unreadCount =
                          chatData?['unreadCount']?[currentUser.uid] ?? 0;

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
                            if (lastMessageTime != null)
                              Text(
                                  "${lastMessageTime.hour.toString().padLeft(2, '0')}:${lastMessageTime.minute.toString().padLeft(2, '0')}"),
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
                          final chatId =
                              _generateChatId(currentUser.uid, userId);

                          // Check if the chat room exists
                          final chatDoc =
                              await _db.collection('chats').doc(chatId).get();
                          if (!chatDoc.exists) {
                            // Create the chat room only if it doesn't exist
                            await _firestoreService.createChatRoom(
                                chatId, currentUser.uid, userId);
                          }

                          // Fetch the latest chat data
                          final chatData =
                              await _db.collection('chats').doc(chatId).get();
                          final chatMap = chatData.data();

                          // Determine the receiver's ID
                          final users =
                              List<String>.from(chatMap?['users'] ?? []);
                          final receiverId =
                              users.firstWhere((id) => id != currentUser.uid);
                          final lastMessageSenderId =
                              chatMap?['lastMessageSenderId'];

                          // Only reset unread count if the current user is the receiver
                          // and the last message was not sent by the current user
                          if (lastMessageSenderId != currentUser.uid &&
                              (chatMap?['unreadCount']?[currentUser.uid] ?? 0) >
                                  0) {
                            await _db.collection('chats').doc(chatId).update({
                              'unreadCount.${currentUser.uid}': 0,
                            });
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(chatId: chatId),
                            ),
                          );
                        },
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

  String _generateChatId(String userId1, String userId2) {
    return userId1.hashCode <= userId2.hashCode
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }
}
