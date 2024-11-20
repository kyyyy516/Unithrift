import 'package:flutter/material.dart';
import 'package:unithrift/explore/campus_service.dart';
import 'package:unithrift/explore/feature.dart';
import 'package:unithrift/explore/popular_rental.dart';

class Explore extends StatefulWidget {
  const Explore({super.key});

  @override
  State<Explore> createState() => _ExploreState();
}

class _ExploreState extends State<Explore> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 24.0, vertical: 30.0), // Increased padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What are you looking for today?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 15), // Increased space

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeaturePage()),
                );
              },
              child: featureBox(
                color: const Color(0xFFD8DCC6),
                header: "Featured Items",
                description: "Discover great deals on second-hand items!",
                textColor: Colors.white,
                descriptionColor: const Color(0xFF424632),
                imageUrl: 'assets/feature.png',
              ),
            ),

            const SizedBox(height: 15), // Increased space between boxes

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PopularRental()),
                );
              },
              child: featureBox(
                color: const Color(0xFFEFCDCE),
                header: "Popular Rentals",
                description: "Rent, use, and return with ease!",
                textColor: Colors.white,
                descriptionColor: const Color(0xFF424632),
                imageUrl: 'assets/rental_logo.png',
              ),
            ),

            const SizedBox(height: 15), // Increased space between boxes

            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CampusService()),
                );
              },
              child: featureBox(
                color: const Color(0xFFB8DAFF),
                header: "Campus Services",
                description: "Find the help you need, right on campus!",
                textColor: Colors.white,
                descriptionColor: const Color(0xFF424632),
                imageUrl: 'assets/campus_service_logo.png',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget featureBox({
    required Color color,
    required String header,
    required String description,
    required Color textColor,
    required Color descriptionColor,
    required String imageUrl,
  }) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 30.0, top: 10.0, right: 5.0), // Add padding for image
          child: Container(
            width: 290, // Shortened width
            height: 100, // Smaller height
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.only(
                left: 50.0, right: 10.0, top: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    header,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                      color: descriptionColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0, // Move image more to the left
          top: 0,
          bottom: 0,
          child: Center(
            child: Image.asset(
              imageUrl,
              height: 90, // Slightly larger image
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
