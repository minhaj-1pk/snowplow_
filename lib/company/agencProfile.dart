import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AgencyProfile extends StatefulWidget {
  final String? userId;
  const AgencyProfile({super.key, this.userId});

  @override
  State<AgencyProfile> createState() => _AgencyProfileState();
}

class _AgencyProfileState extends State<AgencyProfile> {
  String? name;
  String? email;
  String? phone;
  String? userId;
  String? agentid;
  String? token;
  bool isLoading = false;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('tokenn');
    agentid = prefs.getString('agency_id');
    if (agentid == null || token == null) {
      print('Missing token or agency ID');
      return;
    }
    setState(() => isLoading = true);

    final url = Uri.parse("https://snowplow.celiums.com/api/agencies/details");
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode({'agency_id': agentid, 'api_mode': 'test'}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final agencyData = data['data'];
        setState(() {
          name = agencyData['agency_name'];
          email = agencyData['agency_email'];
          phone = agencyData['agency_phone'];
          _nameCtrl.text = name ?? '';
          _emailCtrl.text = email ?? '';
          _phoneCtrl.text = phone ?? '';
        });
      }
    } catch (e) {
      print('Error fetching agency data: $e');
    }
    setState(() => isLoading = false);
  }

  Future<void> updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    token = token ?? prefs.getString('tokenn');
    agentid = agentid ?? prefs.getString('agency_id');
    if (agentid == null || token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Missing agency ID or token.')));
      return;
    }

    final url = Uri.parse('https://snowplow.celiums.com/api/profile/update');
    final updatedData = {
      'agency_id': agentid,
      'agency_name': _nameCtrl.text.trim(),
      'agency_email': _emailCtrl.text.trim(),
      'agency_phone': _phoneCtrl.text.trim(),
      'api_mode': 'test',
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Profile updated!')));
        setState(() {
          name = _nameCtrl.text;
          email = _emailCtrl.text;
          phone = _phoneCtrl.text;
        });
        Navigator.of(context).pop(); // Close modal
      }
    } catch (e) {
      print("Update error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred. Try again.')));
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/mainPage', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gradient background!
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0f2027), Color(0xFF203a43), Color(0xFF2c5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child:
                    isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : SingleChildScrollView(
                          physics: BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(height: 30),
                              // Glowing Circle Avatar with animation
                              TweenAnimationBuilder(
                                tween: Tween<double>(begin: 0.8, end: 1.0),
                                duration: Duration(milliseconds: 600),
                                curve: Curves.easeOutBack,
                                builder: (context, value, child) {
                                  return Transform.scale(
                                    scale: value,
                                    child: child,
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.cyanAccent.withOpacity(
                                          0.5,
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 54,
                                    backgroundColor: Colors.white,
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundImage: AssetImage(
                                        'assets/agency.png',
                                      ),
                                      backgroundColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              Text(
                                name ?? 'Agency Name',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.1,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 12,
                                      color: Colors.black38,
                                      offset: Offset(1.2, 1.2),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 4),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 18,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  'AGENCY PROFILE',
                                  style: TextStyle(
                                    letterSpacing: 2,
                                    color: Colors.cyanAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              SizedBox(height: 32),
                              // Glass Card Effect (frosted glass)
                              FrostedGlassCard(
                                child: Column(
                                  children: [
                                    buildInfoRow(
                                      Icons.email_outlined,
                                      email ?? 'agency@email.com',
                                    ),
                                    buildInfoRow(
                                      Icons.phone,
                                      phone ?? '+91 12345 67890',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 35),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GradientButton(
                                    icon: Icons.edit,
                                    label: "Edit Profile",
                                    onPressed: () => openEditModal(context),
                                  ),
                                  SizedBox(width: 15),
                                  GradientButton(
                                    icon: Icons.logout,
                                    label: "Log Out",
                                    onPressed: logout,
                                    colors: [
                                      Colors.redAccent,
                                      Colors.deepOrange,
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildInfoRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 26),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 17,
                color: Colors.white,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void openEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black54,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (ctx) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: FrostedGlassCard(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit Agency Profile',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.cyanAccent,
                    ),
                  ),
                  SizedBox(height: 14),

                  _buildTextInput(
                    'Agency Name',
                    Icons.account_circle,
                    _nameCtrl,
                    false,
                  ),
                  SizedBox(height: 8),
                  _buildTextInput('Email', Icons.email, _emailCtrl, false),
                  SizedBox(height: 8),
                  _buildTextInput(
                    'Phone',
                    Icons.phone,
                    _phoneCtrl,
                    false,
                    inputType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),

                  GradientButton(
                    label: "Save Changes",
                    icon: Icons.save,
                    onPressed: updateUserData,
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildTextInput(
    String label,
    IconData icon,
    TextEditingController controller,
    bool enabled, {
    TextInputType? inputType,
  }) {
    return TextField(
      controller: controller,
      enabled: true,
      keyboardType: inputType,
      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.cyan.shade50,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      ),
    );
  }
}

// Fancy frosted Glass Card
class FrostedGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const FrostedGlassCard({Key? key, required this.child, this.padding})
    : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28),
      padding: padding ?? EdgeInsets.symmetric(vertical: 18, horizontal: 19),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.30),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade900.withOpacity(0.14),
            blurRadius: 18,
            spreadRadius: 3,
          ),
        ],
      ),
      child: child,
    );
  }
}

// Custom Gradient Button
class GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<Color>? colors;
  final void Function() onPressed;
  const GradientButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.colors,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final btnColors =
        colors ?? [const Color.fromARGB(255, 16, 149, 149), Colors.blue];
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 140,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: LinearGradient(
            colors: btnColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: btnColors.last.withOpacity(0.19),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
