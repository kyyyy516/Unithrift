import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:unithrift/explore/explore.dart';
//import 'package:unithrift/explore/feature.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'navigation bar/bottom_navbar.dart';
import 'chatlist.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
        leading: Padding(
          padding: const EdgeInsets.only(
              top: 5, left: 10), // Adjust padding for the left side
          child: IconButton(
            icon: const Icon(
              Icons.exit_to_app_outlined,
              color: Colors.black,
            ),
            iconSize: 25,
            // Wrap the signOut function in a callback to ensure it runs on button press
            onPressed: signOut,
          ),
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
                if (user != null)
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
                              (doc['unreadCount'][user!.uid] ?? 0) as int;
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
      ),
      body: Center(
        child: pages[_selectedIndex],
      ),
      bottomNavigationBar: mainBottomNavBar(_selectedIndex, _onItemTapped),
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Container(
        height: 60,
        width: 65,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF808569) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.black,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 10),
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}
