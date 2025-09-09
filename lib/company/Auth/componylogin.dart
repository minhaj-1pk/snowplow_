import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:snowplow/company/agency_home.dart';
//import 'package:snowplow/company/agnecyBID.dart' show AgentRequestsPage;
import 'package:snowplow/company/Auth/companyregister.dart';
//import 'package:snowplow/user/homescrren.dart';

class companyLoginPage extends StatefulWidget {
  const companyLoginPage({super.key});

  @override
  State<companyLoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<companyLoginPage> {
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
      var url = Uri.parse('https://snowplow.celiums.com/api/agencies/login');
      var responce = await http.post(
        url,
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'api_mode': "test",
        }),
      );
      var responcedata = jsonDecode(responce.body);
      if (responcedata["message"] == "agency Logged In") {
        //  final agentId = responcedata['data']['cu_id'].toString();
        final agencyId = responcedata['data']['agency_id'].toString();
        final agencyname = responcedata['data']['agency_name'].toString();
        final agencynumber = responcedata['data']['agency_phone'].toString();
        final agencyemail = responcedata['data']['agency_email'].toString();

        print('Agent diefiefnefiefiefuefhID: $agencyId');

        List<String> fetched_details = [
          agencyId,
          agencyname,
          agencyemail,
          agencynumber,
        ];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'tokenn',
          '7161092a3ab46fb924d464e65c84e35',
        ); // or from API if available
        await prefs.setStringList('fetched_details', fetched_details);
        await prefs.setString('agency_id', agencyId); // ✅ store correctly

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login successful')));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AgentHomeScreen()),
        );
      } else {
        print('login failed:${responce.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('invalid email or password')));
      }
    } catch (e) {
      print("Error: $e");
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
            title: Text(' AGENCY LOGIN PAGE'),
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
                    child: Text('Login', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: const Color.fromARGB(255, 32, 71, 241),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Companyregister(),
                        ),
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
