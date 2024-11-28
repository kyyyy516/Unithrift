import 'package:flutter/material.dart';
import 'package:unithrift/sell/upload_product.dart';
import 'package:unithrift/sell/upload_rental.dart';
import 'package:unithrift/sell/upload_service.dart';

class MainUploadPage extends StatefulWidget {
  const MainUploadPage({super.key});

  @override
  State<MainUploadPage> createState() => _MainUploadPageState();
}

class _MainUploadPageState extends State<MainUploadPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to Sell?',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            // const SizedBox(height: 8),
            // const Text(
            //   'Choose what you want to offer now!',
            //   style: TextStyle(
            //     fontSize: 16,
            //     color: Colors.grey,
            //   ),
            // ),
            const SizedBox(height: 25),

            // Sell Products Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProductUploadPage()),
                );
              },
              child: sellerOptionCard(
                icon: Icons.store,
                title: "Sell Products",
                description: "Turn your pre-loved items into profit!",
                gradientColors: const [Color(0xFFD8DCC6), Color(0xFFD8DCC6)],
              ),
            ),

            const SizedBox(height: 20),

            // Offer Rentals Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RentalUploadPage()),
                );
              },
              child: sellerOptionCard(
                icon: Icons.access_time,
                title: "Offer Rentals",
                description: "Help make everyone's campus life easier!",
                gradientColors: const [Color(0xFFEFCDCE), Color(0xFFEFCDCE)],
              ),
            ),

            const SizedBox(height: 20),

            // Provide Services Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ServiceUploadPage()),
                );
              },
              child: sellerOptionCard(
                icon: Icons.handyman,
                title: "Provide Services",
                description: "Offer your expertise to the campus!",
                gradientColors: const [Color(0xFFB8DAFF), Color(0xFFB8DAFF)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget sellerOptionCard({
  required IconData icon,
  required String title,
  required String description,
  required List<Color> gradientColors,
}) {
  return Container(
    height: 100, 
    width: 350,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(9),
      boxShadow: [
        BoxShadow(
          color: gradientColors[0].withOpacity(0.3),
          blurRadius: 5,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 35,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF424632),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
}