////////////////////////////////////////////////////////////////////////////////////////////////////////////////
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/company/tabBarPage.dart';
import 'package:snowplow/company/agencProfile.dart';
// import your pages as before

class AgentHomeScreen extends StatefulWidget {
  @override
  _AgentHomeScreenState createState() => _AgentHomeScreenState();
}

String? profiledetail = '';

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  int _currentIndex = 0;

  Future profileid() async {
    final prefs = await SharedPreferences.getInstance();
    profiledetail = prefs.getString('agency_id');
  }

  final List<Widget> _pages = [RequestsTabScreen(), AgencyProfile()];

  final List<String> _titles = ["Requests", "Profile"];

  Color get _mainBgColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF212B36)
          : Color(0xFFE8F1F9);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: _mainBgColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(2),
            ),
            child: AppBar(
              title: Text(
                _titles[_currentIndex],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color.fromARGB(255, 2, 68, 100),
              elevation: 5,
              centerTitle: true,
            ),
          ),
        ),
        body: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          child: _pages[_currentIndex],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B263B).withOpacity(0.85),
                      Color(0xFF406081).withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: Offset(0, 12),
                    ),
                  ],
                  border: Border.all(color: Colors.white.withOpacity(0.16)),
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  currentIndex: _currentIndex,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.white70,
                  onTap: (index) => setState(() => _currentIndex = index),
                  showSelectedLabels: true,
                  showUnselectedLabels: false,
                  type: BottomNavigationBarType.fixed,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.list_rounded, size: 28),
                      label: 'Requests',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded, size: 28),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
