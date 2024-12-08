import 'package:flutter/material.dart';
import '../sell/listing_test.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'dart:math' show min; // Add this import at the top
import 'package:unithrift/firestore_service.dart';
import '../sell/edit_test.dart';
import '../sell/all_product.dart';



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
            // Map<String, dynamic> productData = {
            //   'name': 'Product Name',
            //   'price': '100',
            //   // Add other required product fields
            // };
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