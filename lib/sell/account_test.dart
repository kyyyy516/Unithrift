import 'package:flutter/material.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'my_listing.dart';



class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) { 
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                //builder: (context) => ListingPage(product: productData),
                builder: (context) => AllProductPage(),
              
              ),
            );
          },
          child: const Text('Go to My Listings'),
        ),
      ),

    );
  }
}