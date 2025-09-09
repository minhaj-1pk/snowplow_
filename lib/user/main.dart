import 'package:flutter/material.dart';

import 'package:snowplow/user/first_page.dart';
import 'package:snowplow/user/landing_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snowplow App',
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/mainPage': (context) => Landpage(),
      },
    );
  }
}
