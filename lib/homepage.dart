import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  // List of screens for each BottomNavigationBar item
  static const List<Widget> _pages = <Widget>[
    Text('Explore Page'),
    Text('Updates Page'),
    Text('Sell Page'),
    Text('Cart Page'),
    Text('Account Page'),
  ];

  // Method to handle item tap
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
        title: const Text("Homepage"),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: signOut,
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
        height: 60, // Set a fixed height for the background container
        width: 65, // Set a fixed width for the background container
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF808569) : Colors.transparent,
          borderRadius:
              BorderRadius.circular(8), // Rounded corners for the background
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.4),
                      blurRadius: 6,
                      offset: Offset(0, 3))
                ]
              : [],
        ),
        padding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 8), // Reduce horizontal padding to adjust spacing
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center items vertically
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center items horizontally
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.black, size: 24),
            const SizedBox(height: 4), // Adjust spacing between icon and text
            Text(
              label,
              style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontSize: 10), // Adjust font size for consistency
            ),
          ],
        ),
      ),
      label: '',
    );
  }
}
