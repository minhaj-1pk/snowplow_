import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  String? name, email, phone, userId, token;
  bool isLoading = false, isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    fetchUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('tokenn');
    userId = widget.userId ?? prefs.getString('userId');
    if (userId == null || userId!.isEmpty) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User not authenticated.")));
      return;
    }

    final url = Uri.parse("https://snowplow.celiums.com/api/profile/details");
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': token ?? '',
          'api_mode': 'test',
          'customer_id': userId!,
        },
        body: jsonEncode({'customer_id': userId, 'api_mode': 'test'}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'];
        setState(() {
          name = userData['customer_name'];
          email = userData['customer_email'];
          phone = userData['customer_phone'];
          _nameController.text = name ?? '';
          _emailController.text = email ?? '';
          _phoneController.text = phone ?? '';
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile data')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading profile data')));
    }
    setState(() => isLoading = false);
  }

  Future<void> updateUserData() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    token = token ?? prefs.getString('tokenn');
    userId = userId ?? prefs.getString('userId');
    if (userId == null || token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Missing user ID or token.')));
      setState(() => isLoading = false);
      return;
    }
    final url = Uri.parse('https://snowplow.celiums.com/api/profile/update');
    final updatedData = {
      'customer_id': userId,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'api_mode': 'test',
    };
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Authorization': token!},
        body: jsonEncode(updatedData),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully!')),
        );
        await fetchUserData();
        setState(() => isEditing = false);
      } else {
        final errorBody = json.decode(response.body);
        final errorMsg = errorBody['message'] ?? 'Failed to update profile.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    }
    setState(() => isLoading = false);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushNamedAndRemoveUntil(context, '/mainPage', (route) => false);
  }

  Widget _profileAvatar() {
    return CircleAvatar(
      radius: 56,
      backgroundColor: Colors.white,
      child: CircleAvatar(
        radius: 52,
        backgroundColor: Color(0xFFB6D0E2),
        child: ClipOval(
          child: Image.asset(
            "assets/3001758.png",
            fit: BoxFit.cover,
            height: 65,
          ),
        ),
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        decoration: BoxDecoration(
          color: Color(0xFFE6F0FA),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: EdgeInsets.all(8),
        child: Icon(icon, color: Color(0xFF4A90E2)),
      ),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    TextInputType keyboard,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Colors.blue.shade400;
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FA),
      appBar: AppBar(
        backgroundColor: primary,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        centerTitle: true,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        actions: [
          if (isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                height: 27,
                width: 27,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _profileAvatar(),
            const SizedBox(height: 28),

            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child:
                  isEditing
                      ? Column(
                        key: ValueKey("edit"),
                        children: [
                          _editField(
                            "Name",
                            _nameController,
                            TextInputType.name,
                          ),
                          _editField(
                            "Email",
                            _emailController,
                            TextInputType.emailAddress,
                          ),
                          _editField(
                            "Phone",
                            _phoneController,
                            TextInputType.phone,
                          ),
                        ],
                      )
                      : Card(
                        key: ValueKey("view"),
                        elevation: 3,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _infoTile(
                                icon: Icons.person,
                                value: name ?? "--",
                                label: "Name",
                              ),
                              _infoTile(
                                icon: Icons.email,
                                value: email ?? "--",
                                label: "Email",
                              ),
                              _infoTile(
                                icon: Icons.phone,
                                value: phone ?? "--",
                                label: "Phone",
                              ),
                            ],
                          ),
                        ),
                      ),
            ),
            const SizedBox(height: 34),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: Colors.white,
                ),
                label: Text(
                  isEditing ? "Save Changes" : "Edit Profile",
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
                onPressed:
                    isLoading
                        ? null
                        : () {
                          if (isEditing) {
                            updateUserData();
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            if (isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    isEditing = false;
                    _nameController.text = name ?? '';
                    _emailController.text = email ?? '';
                    _phoneController.text = phone ?? '';
                  });
                },
                child: Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),

            SizedBox(height: 15),

            Divider(height: 5, color: Colors.blueGrey.shade100, thickness: 1.2),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.logout, color: Colors.redAccent),
                label: Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                onPressed: isLoading ? null : logout,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(color: Colors.redAccent, width: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
