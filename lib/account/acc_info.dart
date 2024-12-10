import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:unithrift/account/edit_info.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add this import

class AccountInfo extends StatefulWidget {
  const AccountInfo({super.key});

  @override
  State<AccountInfo> createState() => _AccountInfoState();
}

class _AccountInfoState extends State<AccountInfo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  void updateUserData(Map<String, dynamic> updatedData) {
    setState(() {
      userData = updatedData; // Update the userData locally
    });
  }

  // Upload Image to ImgBB
  Future<String> _uploadToImgBB(String filePath) async {
    try {
      const String apiKey = '44e4667dd04c729f269534849d10f50f'; // Your ImgBB API key
      final Uri uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

      // Prepare multipart request
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      // Send request
      var response = await request.send();

      // Handle response
      if (response.statusCode == 200) {
        final responseData =
            json.decode(await response.stream.bytesToString());
        return responseData['data']['url']; // ImgBB image URL
      } else {
        throw Exception(
            "ImgBB upload failed: ${response.reasonPhrase} (status code: ${response.statusCode})");
      }
    } catch (e) {
      print("Error uploading to ImgBB: $e");
      throw Exception("ImgBB upload error: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
        return;
      }

      final String filePath = pickedFile.path;
      print("Selected file path: $filePath");

      // Upload to ImgBB
      final String imgbbUrl = await _uploadToImgBB(filePath);

      // Store the image URL in Firestore
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': imgbbUrl,
        });

        setState(() {
          userData!['profileImage'] = imgbbUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareOnWhatsApp() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      const String message = "Check out my profile on UniThrift!";
      final String whatsappURL = "https://wa.me/?text=${Uri.encodeComponent(message)}";
      _launchURL(whatsappURL);
    }
  }

  void _shareOnTelegram() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      const String message = "Check out my profile on UniThrift!";
      final String telegramURL = "https://t.me/share/url?url=${Uri.encodeComponent("https://unithrift.com")}&text=${Uri.encodeComponent(message)}";

      _launchURL(telegramURL);
    }
  }

  Future<void> _launchURL(String url) async {
  print("Launching URL: $url"); // Debugging line
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the link')),
    );
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      title: const Text(
        'Account',
        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black),
          onPressed: () {
            // Show options for sharing
            showModalBottomSheet(
              context: context,
              builder: (context) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                    title: const Text("Share on WhatsApp"),
                    onTap: () {
                      _shareOnWhatsApp();
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const FaIcon(FontAwesomeIcons.telegram, color: Colors.blue),
                    title: const Text("Share on Telegram"),
                    onTap: () {
                      _shareOnTelegram();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        ),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfilePage(),
                ),
              );
            },
          ),
        ],
    ),
    body: StreamBuilder<DocumentSnapshot>(
      stream: FirebaseAuth.instance.currentUser != null
          ? _firestore
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text('No user data found'));
        }

        // Get the real-time user data from Firestore
        final userData = snapshot.data!.data() as Map<String, dynamic>;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.green[100],
              child: Column(
                children: [
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (userData['profileImage'] != null) {
                            _showFullScreenImage(userData['profileImage']);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No profile picture to display'),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: userData['profileImage'] != null
                              ? NetworkImage(userData['profileImage'])
                              : const AssetImage('assets/profile.png')
                                  as ImageProvider,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickAndUploadImage,
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData['username'] ?? 'User Name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.yellow, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        userData['rating']?.toString() ?? '0.0',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData['address'] ?? 'Location Unknown',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    userData['bio'] ?? 'No bio added',
                    style: const TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag),
                          SizedBox(width: 8),
                          Text('My Order'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {},
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite),
                          SizedBox(width: 8),
                          Text('My Likes'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Listing',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Review',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'About',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[300], thickness: 1),
          ],
        );
      },
    ),
  );
}
}