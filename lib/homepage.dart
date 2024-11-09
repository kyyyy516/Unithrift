import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chatlist.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    Text('Explore Page'),
    Text('Updates Page'),
    Text('Sell Page'),
    Text('Cart Page'),
    Text('Account Page'),
  ];

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
              top: 5, left: 10), // Adjust padding for left side
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
      backgroundColor: Colors.white,
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
