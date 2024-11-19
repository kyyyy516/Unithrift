import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chatlist.dart';
import 'notification_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;
  int _unreadMessageCount = 0;
  int _unreadOrderCount = 0; // Count of unread notifications

  static const List<Widget> _pages = <Widget>[
    Text('Explore Page'),
    NotificationPage(), // Notifications Page
    Text('Sell Page'),
    Text('Cart Page'),
    Text('Account Page'),
  ];

  @override
  void initState() {
    super.initState();
    _listenToUnreadMessages();
    _listenToUnreadOrders();
  }

  void _listenToUnreadMessages() {
    final currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('chats')
        .where('unreadCount.${currentUser!.uid}', isGreaterThan: 0)
        .snapshots()
        .listen((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        count += (doc['unreadCount'][currentUser.uid] ?? 0) as int;
      }
      setState(() {
        _unreadMessageCount = count;
      });
    });
  }

  void _listenToUnreadOrders() {
    final currentUser = FirebaseAuth.instance.currentUser;
    FirebaseFirestore.instance
        .collection('notifications')
        .doc(currentUser!.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _unreadOrderCount = snapshot.docs.length;
      });
    });
  }

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
          padding: const EdgeInsets.only(top: 5, left: 10),
          child: IconButton(
            icon: const Icon(
              Icons.exit_to_app_outlined,
              color: Colors.black,
            ),
            iconSize: 25,
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
                if (_unreadMessageCount > 0)
                  Positioned(
                    right: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        _unreadMessageCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Center(
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          _buildBottomNavigationBarItem(
            icon: Icons.explore_outlined,
            label: 'Explore',
            index: 0,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.notifications_outlined,
            label: 'Update',
            index: 1,
            badgeCount: _unreadOrderCount,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.add_circle_outline,
            label: 'Sell',
            index: 2,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.shopping_cart_outlined,
            label: 'Cart',
            index: 3,
          ),
          _buildBottomNavigationBarItem(
            icon: Icons.account_circle_outlined,
            label: 'Account',
            index: 4,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
      backgroundColor: Colors.white,
    );
  }

  BottomNavigationBarItem _buildBottomNavigationBarItem({
    required IconData icon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    bool isSelected = _selectedIndex == index;

    return BottomNavigationBarItem(
      icon: Stack(
        children: [
          Container(
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
          if (badgeCount > 0)
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
      label: '',
    );
  }
}
