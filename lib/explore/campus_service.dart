import 'package:flutter/material.dart';
import 'package:unithrift/navigation%20bar/bottom_navbar.dart';
import 'package:unithrift/navigation%20bar/common_appbar.dart';

class CampusService extends StatefulWidget {
  const CampusService({super.key});

  @override
  State<CampusService> createState() => _CampusServiceState();
}

class _CampusServiceState extends State<CampusService> {
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
      body: const SingleChildScrollView(child: Text("Campus service")),
      //mok for bottomNav bar
      bottomNavigationBar: mainBottomNavBar(_selectedIndex, _onItemTapped),
    );
  }
}
