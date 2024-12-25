import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../analytics/total_view.dart';
import '../analytics/total_favorites.dart';
import '../analytics/total_addtocart.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {

  Future<Map<String, dynamic>> getAnalyticsData() async {
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // First check if user has any products
    final productsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('products')
        .get();

    // If no products, return null to indicate no data
    if (productsSnapshot.docs.isEmpty) {
      return {};
    }

    int totalViews = 0;
    int totalFavorites = 0;
    int totalCartAdds = 0;

    // For each product, count favorites, views, and cart additions
    for (var product in productsSnapshot.docs) {
      // Get product views
      totalViews += (product.data()['views'] as num?)?.toInt() ?? 0;  // Cast to integer

      // Query all users' favorites collections
      final favoritesQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      // Check each user's favorites collection
      for (var userDoc in favoritesQuery.docs) {
        final favoriteDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('favorites')
            .where('productID', isEqualTo: product.id)
            .get();

        totalFavorites += favoriteDoc.docs.length;

        // Count cart additions
        final cartDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userDoc.id)
            .collection('cart')
            .where('productID', isEqualTo: product.id)
            .get();
        totalCartAdds += cartDoc.docs.length;
      }
    }

    return {
      'views': totalViews, 
      'favorites': totalFavorites,
      'cartAdds': totalCartAdds,
      'hasProducts': true,
    };

    
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        foregroundColor: Colors.white, // Text color
        backgroundColor: const Color(0xFF808569),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getAnalyticsData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF808569)),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "Just a moment—\nwe're gathering the insights you need.\nIt won't be long!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;

          // Check if user has no products
          if (data.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'No listings available for analytics.',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TotalViewDetails(),
                      ),
                    );
                  },
                  child: _buildStatCard(
                    'Total Views',
                    data['views'].toString(),  
                    Icons.visibility,
                    Colors.blue,
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TotalFavoritesDetails(),
                        ),
                      );
                    },
                    child: _buildStatCard(
                    'Total Favorites',
                    data['favorites'].toString(),
                    Icons.favorite,
                    Colors.red,
                  ),
                ),
                const SizedBox(height: 16),

                GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TotalAddedtoCart(),
                          ),
                        );
                      },
                      child: _buildStatCard(
                        'Added to Cart',
                        data['cartAdds'].toString(),
                        Icons.shopping_cart,
                        Colors.green,
                      ),
                ),
              const SizedBox(height: 24),
              _buildChart(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> data) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: math.max(math.max(
            data['views'].toDouble(), 
            data['favorites'].toDouble()),
            data['cartAdds'].toDouble()
        ),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  switch (value.toInt()) {
                    case 0:
                    return const Text('Views');
                    case 1:
                      return const Text('Favorites');
                    case 2:
                      return const Text('Cart');
                    default:
                      return const Text('');
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: data['views'].toDouble(),
                color: Colors.blue,
                width: 25,
                borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: data['favorites'].toDouble(),
                  color: Colors.red,
                  width: 25,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
            BarChartGroupData(
              x: 2,
              barRods: [
                BarChartRodData(
                  toY: data['cartAdds'].toDouble(),
                  color: Colors.green,
                  width: 25,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
