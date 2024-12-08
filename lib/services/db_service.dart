import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cloudinary_service.dart';

class DbService {
  User? user = FirebaseAuth.instance.currentUser;

  // save files links to firestore
  Future<void> saveUploadedFilesData(Map<String, String> data) async {
    return FirebaseFirestore.instance
        .collection("user-files")
        .doc(user!.uid)
        .collection("uploads")
        .doc()
        .set(data);
  }

  // read all uploaded files
  Stream<QuerySnapshot> readUploadedFiles() {
    return FirebaseFirestore.instance
        .collection("user-files")
        .doc(user!.uid)
        .collection("uploads")
        .snapshots();
  }

  // delete a specific document
  Future<bool> deleteFile(String docId, String publicId) async {
    // delete file from cloudinary
    final result = await deleteFromCloudinary(publicId);

    if (result) {
      await FirebaseFirestore.instance
          .collection("user-files")
          .doc(user!.uid)
          .collection("uploads")
          .doc(docId)
          .delete();
      return true;
    }
    return false;
  }
}