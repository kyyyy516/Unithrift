import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:unithrift/cart/cart.dart';
import 'package:unithrift/homepage.dart';
import 'package:unithrift/notification_page.dart';
import 'package:unithrift/sell/account_test.dart';
import 'package:unithrift/sell/product_test.dart';
//import 'package:unithrift/sell/try_upload.dart';
//import 'package:unithrift/sell/upload_main.dart';
import '../explore/explore.dart';
import '../sell/upload_main.dart';


const List<Widget> pages = <Widget>[
  Explore(),
  NotificationPage(),
  MainUploadPage(),
  Cart(true),
  //Text('Account Page'),
  AccountInfo(),
];

void commonNavigate(BuildContext context, int index) {
  switch (index) {
    case 0: // Explore
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
        (route) => false, // Remove all other routes from the stack
      );
      break;
    case 1: // Notification
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotificationPage()),
      );
      break;
    case 2: // Sell
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MainUploadPage()),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Cart(false),
        ),
      );
      break;
    case 4: // Account
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const AccountInfo(), // Replace with your account page;
        ),
      );
      break;
  }
}

Widget mainBottomNavBar(int selectedIndex, Function(int) onItemTapped) {
  final user = FirebaseAuth.instance.currentUser;

  return BottomNavigationBar(
    items: <BottomNavigationBarItem>[
      _buildBottomNavigationBarItem(
        selectedIndex,
        icon: Icons.explore_outlined,
        label: 'Explore',
        index: 0,
      ),
      _buildBottomNavigationBarItem(
        selectedIndex,
        icon: Icons.notifications_outlined,
        label: 'Update',
        index: 1,
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid) // Reference the correct user document
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .snapshots(),
      ),
      _buildBottomNavigationBarItem(
        selectedIndex,
        icon: Icons.add_circle_outline,
        label: 'Sell',
        index: 2,
      ),
      _buildBottomNavigationBarItem(
        selectedIndex,
        icon: Icons.shopping_cart_outlined,
        label: 'Cart',
        index: 3,
      ),
      _buildBottomNavigationBarItem(
        selectedIndex,
        icon: Icons.account_circle_outlined,
        label: 'Account',
        index: 4,
      ),
    ],
    currentIndex: selectedIndex,
    selectedItemColor: Colors.white,
    unselectedItemColor: Colors.black,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    onTap: onItemTapped,
    backgroundColor: Colors.white,
    type: BottomNavigationBarType.fixed,
  );
}

BottomNavigationBarItem _buildBottomNavigationBarItem(
  int selectedIndex, {
  required IconData icon,
  required String label,
  required int index,
  Stream<QuerySnapshot>? stream,
}) {
  bool isSelected = selectedIndex == index;

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
                      offset: const Offset(0, 3),
                    ),
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
        if (stream != null)
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (context, snapshot) {
              int unreadCount =
                  snapshot.hasData ? snapshot.data!.docs.length : 0;

              return unreadCount > 0
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
                          unreadCount.toString(),
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
    label: '',
  );
}
