import 'package:flutter/material.dart';
import 'package:unithrift/homepage.dart';

import '../explore/explore.dart';

const List<Widget> pages = <Widget>[
  Explore(),
  Text('Updates Page'),
  Text('Sell Page'),
  Text('Cart Page'),
  Text('Account Page'),
];

commonNavigate(BuildContext context, int index) {
  switch (index) {
    case 0:
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Homepage(),
        ),
      );
      break;
    case 1:
      break;
    case 2:
      break;
    case 3:
      break;
  }
}

Widget mainBottomNavBar(int selectedIndex, Function(int) onItemTapped) {
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
}) {
  bool isSelected = selectedIndex == index;

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
                color: isSelected ? Colors.white : Colors.black, fontSize: 10),
          ),
        ],
      ),
    ),
    label: '',
  );
}
