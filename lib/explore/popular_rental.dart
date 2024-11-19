import 'package:flutter/material.dart';
import 'package:unithrift/navigation%20bar/common_appbar.dart';
import '../navigation bar/bottom_navbar.dart';

class PopularRental extends StatefulWidget {
  const PopularRental({super.key});

  @override
  State<PopularRental> createState() => _PopularRentalState();
}

class _PopularRentalState extends State<PopularRental> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      commonNavigate(context, index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: mainAppBar(context),
      body: const SingleChildScrollView(child: Text("Rental")),
      //mok for bottomNav bar
      bottomNavigationBar: mainBottomNavBar(_selectedIndex, _onItemTapped),
    );
  }
}
