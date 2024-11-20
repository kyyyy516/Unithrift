import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../chatlist.dart';

PreferredSizeWidget mainAppBar(BuildContext context) {
  final user = FirebaseAuth.instance.currentUser;

  return AppBar(
    backgroundColor: Colors.white,
    title: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 0),
          child: Image.asset(
            'assets/logo.png',
            height: 50,
          ),
        ),
      ],
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(top: 5, right: 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(
                Icons.message_outlined,
                color: Colors.black,
              ),
              iconSize: 25,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatList(),
                  ),
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('unreadCount.${user!.uid}', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadMessageCount = 0;
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    unreadMessageCount +=
                        (doc['unreadCount'][user.uid] ?? 0) as int;
                  }
                }
                return unreadMessageCount > 0
                    ? Positioned(
                        right: 5,
                        top: 5,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadMessageCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    ],
  );
}
