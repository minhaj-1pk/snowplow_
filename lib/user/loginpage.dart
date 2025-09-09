import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:snowplow/user/homescrren.dart';

import 'package:snowplow/user/registerpage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('email & password are required')));
      return;
    }
    try {
      var url = Uri.parse('https://snowplow.celiums.com/api/customers/login');
      var responce = await http.post(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'api_mode': "test",
        }),
      );
      if (responce.statusCode == 200) {
        var responcedata = jsonDecode(responce.body);
        //   if (responcedata["message"] == "Customer Logged In") {
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(builder: (_) => BottomNavScreen()),
        //     );
        //     final responsedata = jsonDecode(responce.body);
        //     final userIdFromResponse =
        //         responsedata['data']['customer_id'].toString();
        //     print('userid:$userIdFromResponse');

        //     final prefs = await SharedPreferences.getInstance();
        //     await prefs.setString('tokenn', '7161092a3ab46fb924d464e65c84e35');
        //     await prefs.setString(
        //       'userId',
        //       userIdFromResponse,
        //     ); // Consistent key name
        //     ScaffoldMessenger.of(
        //       context,
        //     ).showSnackBar(SnackBar(content: Text('login successful')));
        //   }
        //   print('login successfull:$responcedata');
        // } else {
        //   print('login failed:${responce.body}');
        //   ScaffoldMessenger.of(
        //     context,
        //   ).showSnackBar(SnackBar(content: Text('invalid email or password')));
        // }
        if (responcedata["message"] == "Customer Logged In") {
          final userIdFromResponse =
              responcedata['data']['customer_id'].toString();

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('tokenn', '7161092a3ab46fb924d464e65c84e35');
          await prefs.setString('userId', userIdFromResponse);
          if (!mounted) return;

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Login successful')));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => BottomNavScreen()),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responcedata["message"] ?? 'Invalid Login')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong, please try again')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade200],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: Text('LOGIN PAGE'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Icon(Icons.ac_unit, color: Colors.white, size: 60.0),
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.blue.shade100,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.blue.shade100,
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 32, 71, 241),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text('Login', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterPage()),
                      );
                    },
                    child: Text(
                      "Don't have an account? Create one",
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
