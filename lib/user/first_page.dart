import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/company/agency_home.dart';
import 'package:snowplow/user/homescrren.dart';

import 'package:snowplow/user/landing_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to Landpage after 2 seconds
    // Future.delayed(Duration(seconds: 2), () {
    //   Navigator.pushReplacement(
    //     context,
    //     MaterialPageRoute(builder: (context) => Landpage()),
    //   );
    // });
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? companyId = prefs.getString("agency_id");
    String? userId = prefs.getString("userId");

    await Future.delayed(Duration(seconds: 2)); // Simulating splash delay

    if (companyId != null && companyId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AgentHomeScreen()),
      );
    } else if (userId != null && userId.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => BottomNavScreen()),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => Landpage()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight), // Set height of AppBar
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade200,
              ], // Winter gradient for AppBar
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            backgroundColor:
                Colors
                    .transparent, // Make AppBar background transparent to show gradient
            elevation: 0, // Remove AppBar shadow
          ),
        ),
      ),
      // Winter-themed background gradient
      backgroundColor: Colors.blue.shade100,

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade200,
            ], // Winter gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Snowflake Icon for winter theme
              Icon(
                Icons.ac_unit, // Snowflake icon
                color: Colors.white,
                size: 100.0, // Larger size for prominence
              ),
              SizedBox(height: 20),
              // Title Text for the splash screen
              Text(
                'Snow Plow',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text for contrast
                ),
              ),
              SizedBox(height: 10),
              // Subtitle text
              Text(
                'Snow Remover',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white, // White text for better visibility
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
