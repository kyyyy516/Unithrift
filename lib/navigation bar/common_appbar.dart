import 'package:flutter/material.dart';

import '../chatlist.dart';

PreferredSizeWidget mainAppBar(BuildContext context) {
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
        child: IconButton(
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
      ),
    ],
  );
}
