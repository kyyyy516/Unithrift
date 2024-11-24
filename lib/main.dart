import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:unithrift/cart/cart.dart';
import 'package:unithrift/explore/feature/feature.dart';
import 'package:unithrift/explore/rental/popular_rental.dart';
import 'package:unithrift/explore/service/campus_service.dart';
import 'package:unithrift/wrapper.dart';
//import 'populate_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB05amp4j-PV4Wfyy1bQwiEDdFbaTPHefY",
        authDomain: "unithrift-b2282.firebaseapp.com",
        projectId: "unithrift-b2282",
        storageBucket: "unithrift-b2282.firebasestorage.app",
        messagingSenderId: "381941062209",
        appId: "1:381941062209:web:588230cd0d4741819484c0",
        measurementId: "G-G6ZR5F2CF3",
      ),
    );
  } else {
    await Firebase.initializeApp();
    //await populateFirestore();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UnitThrift',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        useMaterial3: false,
      ),
      home: const FeaturePage(),
    );
  }
}