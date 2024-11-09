import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'homepage.dart';
//import 'otp_from.dart';
import 'wrapper.dart';
import 'login.dart';
import 'Register.dart';

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
            measurementId: "G-G6ZR5F2CF3"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
      '/register': (context) => const Register(),
      '/login': (context) => const Login(),
      '/homepage': (context) => const Homepage(), // Add Homepage route
      },
      home: const Wrapper(), // Home page
    );
  }
}
