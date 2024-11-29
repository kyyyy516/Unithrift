import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> populateFirestore() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Mock user IDs
  const String deniesUserId = "yM3jUpoXDzauyHprj8K8Vm7ssTV2";
  const String buyer1UserId = "ELoD4InpgoOyEn42jNuhEVCjwON2";
  const String buyer2UserId = "UtthiVR5DShpnrNJQKkqc7EGozW2";
  const String buyer3UserId = "iGTdEK6T37h29s1OmCKg4Ti4t6A2";

  // Common timestamp
  final timestamp = DateTime.now();

  // Mock products
  final List<Map<String, dynamic>> products = [
    {
      'productId': 'book123',
      'title': 'Second-hand Book',
      'description': 'A used book in good condition.',
      'price': 20,
      'type': 'sell',
      'sellerId': deniesUserId,
      'createdAt': timestamp,
    },
    {
      'productId': 'camera456',
      'title': 'Camera for Rent',
      'description': 'High-quality DSLR camera available for rent.',
      'price': 50,
      'type': 'rent',
      'sellerId': deniesUserId,
      'createdAt': timestamp,
    },
    {
      'productId': 'service789',
      'title': 'Printing Service',
      'description': 'Fast and reliable printing service.',
      'price': 5,
      'type': 'service',
      'sellerId': deniesUserId,
      'createdAt': timestamp,
    },
  ];

  // Mock orders
  final List<Map<String, dynamic>> orders = [
    {
      'productId': 'book123',
      'sellerId': deniesUserId,
      'buyerId': buyer1UserId,
      'type': 'sell',
      'status': 'placed',
      'timestamp': timestamp,
    },
    {
      'productId': 'camera456',
      'sellerId': deniesUserId,
      'buyerId': buyer2UserId,
      'type': 'rent',
      'status': 'placed',
      'timestamp': timestamp,
    },
    {
      'productId': 'service789',
      'sellerId': deniesUserId,
      'buyerId': buyer3UserId,
      'type': 'service',
      'status': 'placed',
      'timestamp': timestamp,
    },
  ];

  // Mock notifications
  final List<Map<String, dynamic>> notifications = [
    // Seller notifications
    {
      'title': 'New Order: Second-hand Book',
      'message': 'Buyer has placed an order for your book.',
      'orderId': 'order1',
      'isRead': false,
      'type': 'sell',
      'timestamp': timestamp,
    },
    {
      'title': 'New Order: Camera Rental',
      'message': 'Buyer has placed an order to rent your camera.',
      'orderId': 'order2',
      'isRead': false,
      'type': 'rent',
      'timestamp': timestamp,
    },
    {
      'title': 'New Order: Printing Service',
      'message': 'Buyer has requested your printing service.',
      'orderId': 'order3',
      'isRead': false,
      'type': 'service',
      'timestamp': timestamp,
    },
    // Buyer notifications
    {
      'title': 'Order Confirmed: Second-hand Book',
      'message': 'Your order for the Second-hand Book has been confirmed.',
      'orderId': 'order1',
      'isRead': false,
      'type': 'buyer',
      'timestamp': timestamp,
    },
    {
      'title': 'Order Shipped: Camera Rental',
      'message': 'Your camera rental order has been shipped.',
      'orderId': 'order2',
      'isRead': false,
      'type': 'buyer',
      'timestamp': timestamp,
    },
    {
      'title': 'Order Completed: Printing Service',
      'message': 'Your printing service order has been completed.',
      'orderId': 'order3',
      'isRead': false,
      'type': 'buyer',
      'timestamp': timestamp,
    },
  ];

  try {
    // Add products
    for (var product in products) {
      final docRef = firestore.collection('products').doc(product['productId']);
      await docRef.set(product);
      print("Added product: ${product['title']}");
    }

    // Add orders
    for (var i = 0; i < orders.length; i++) {
      final orderId = 'order${i + 1}';
      final docRef = firestore.collection('orders').doc(orderId);
      await docRef.set(orders[i]);
      print("Added order for product: ${orders[i]['productId']}");
    }

    // Add notifications
    for (var i = 0; i < notifications.length; i++) {
      final targetUser = i < 3 ? deniesUserId : orders[i - 3]['buyerId'];
      await firestore
          .collection('notifications')
          .doc(targetUser)
          .collection('notifications')
          .add(notifications[i]);
      print("Added notification: ${notifications[i]['title']}");
    }

    print("Firestore populated successfully!");
  } catch (e) {
    print("Error populating Firestore: $e");
  }
}
