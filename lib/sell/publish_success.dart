import 'package:flutter/material.dart';
import '../homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listing_details.dart';
import 'my_listing.dart';


class PublishSuccessfulPage extends StatefulWidget {
  final String productID;
  final String userID;

  const PublishSuccessfulPage({
    super.key,
    required this.productID,
    required this.userID,
    });

  @override
  State<PublishSuccessfulPage> createState() => _PublishSuccessfulPageState();
}

class _PublishSuccessfulPageState extends State<PublishSuccessfulPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/checkmark.png', width: 130, height: 130),
          SizedBox(height: 20),
          Text(
            'Publish Successful!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF808569), // Add this line
              
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Thank you for choosing our app.',
            style: TextStyle(
              fontSize: 16,
              //fontWeight: FontWeight.bold,
              color: Color(0xFFA8A9A8), // Add this line
              
            ),
          ),


          SizedBox(height: 70),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF808569),
              foregroundColor: Colors.white, // Add this for text color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20), // Adjust radius value as needed
              ),
              minimumSize: Size(300, 45), // Adjust width (200) and height (45) as needed
            ),
            onPressed: () async {

              // print('Attempting to view product...');
              // print('Product ID: ${widget.productID}');
              // print('User ID: ${widget.userID}');

              // Fetch the product data
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userID)
                  .collection('products')
                  .doc(widget.productID)
                  .get();

                  // print('Document exists: ${docSnapshot.exists}');
                  // print('Document data: ${docSnapshot.data()}');

              if (mounted && docSnapshot.exists) {
    // First replace current route with AllProductPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AllProductPage()),
    );

                // Navigate to ListingPage
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ListingPage(
                        product: {
                        ...docSnapshot.data()!,
                        'userId': widget.userID,
                        'productID': widget.productID,
                        //fromPublishSuccessful: true, // Set this to true
                        }
                      ),
                    ),
                  );
                }
              } 

            },
            child: Text('View Listing'),
            
          ),
          
          //SizedBox(height: 0),
          TextButton(
            onPressed: () {
              // Navigate to the home page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Homepage()),
                (route) => false,
              );
            },
            child: Text('Back To Home',
              style: TextStyle(
                color: Color(0xFFA4AA8B),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}