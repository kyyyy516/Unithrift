import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_service.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  Future<void> _sendMessage(String text, [String? imageUrl]) async {
    await _firestoreService.sendMessage(
      widget.chatId,
      currentUser!.uid,
      text,
      imageUrl: imageUrl,
    );
    _controller.clear();
  }

  Future<void> _sendImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageUrl = await _firestoreService.uploadImage(pickedFile.path);
      _sendMessage('', imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _firestoreService.getMessages(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final messages = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: messages.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final message = messages[index].data();
                        final messageText = message['text'] ?? '';
                        final imageUrl = message['imageUrl'];
                        final timestamp =
                            message['timestamp']?.toDate() ?? DateTime.now();
                        final isCurrentUser =
                            message['userId'] == currentUser?.uid;

                        return Align(
                          alignment: isCurrentUser
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? const Color(0xFFA4AA8B)
                                  : const Color(0xFFF2F3EC),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (imageUrl != null)
                                  GestureDetector(
                                    onTap: () {
                                      // Show enlarged image in full screen
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.black,
                                          child: Stack(
                                            children: [
                                              InteractiveViewer(
                                                child: Image.network(imageUrl),
                                              ),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: IconButton(
                                                  icon: const Icon(Icons.close,
                                                      color: Colors.white),
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10.0),
                                      child: Image.network(
                                        imageUrl,
                                        width:
                                            180, // Set your desired max width
                                        height:
                                            240, // Set your desired max height
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                if (messageText.isNotEmpty)
                                  Text(
                                    messageText,
                                    style: TextStyle(
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 5.0), // Add top padding
                                  child: Text(
                                    "${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}",
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: isCurrentUser
                                            ? Colors.white
                                            : Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _sendImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: "Type your message...",
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.all(10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.0),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.blue),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            _sendMessage(_controller.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
