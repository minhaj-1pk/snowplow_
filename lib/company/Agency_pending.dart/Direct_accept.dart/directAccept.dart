import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
// import 'package:snowplow/company/TabBar_Page.dart';
// import 'package:snowplow/company/agency_home.dart';

class DIrectDetails extends StatefulWidget {
  final Map<String, dynamic> requestdetails;
  final String? Username;
  const DIrectDetails({
    super.key,
    required this.requestdetails,
    required this.Username,
  });

  @override
  State<DIrectDetails> createState() => _DIrectDetailsState();
}

class _DIrectDetailsState extends State<DIrectDetails> {
  Map<String, dynamic>? request;
  String? customername;
  String? agencyid;
  bool isLoading = false;
  bool isAlreadysend = false;

  @override
  void initState() {
    super.initState();
    _initialize();
    customername = widget.Username;
    request = widget.requestdetails;
    isAlreadysend = request?['isAccepted'] ?? false;
  }

  Future<void> _initialize() async {
    await _getagencyid();
  }

  Future<void> _getagencyid() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    agencyid = prefs.getString("agency_id");
  }

  Future<void> _reply() async {
    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/agencies/requestaccept"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "request_id": request?["requestid"] ?? '',
          "agencyid": agencyid ?? "",
          "api_mode": "test",
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request submitted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Future.delayed(const Duration(seconds: 1), () {
          // Navigator.of(context).pushReplacement(
          //   MaterialPageRoute(builder: (context) => AgentHomeScreen()),
          // );
          Navigator.pop(context);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit request: ${response.body}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Service Request",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color.fromARGB(255, 2, 68, 100),
                  Color.fromARGB(255, 2, 68, 100),
                  Color(0xFF2C5364),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child:
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : request == null
                    ? Center(
                      child: Text(
                        "Request not found",
                        style: textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _glassCard(_buildUserSection()),
                          const SizedBox(height: 16),
                          _glassCard(_buildRequestDetailsCard()),
                          const SizedBox(height: 24),
                          _glassCard(_buildImageSection()),
                          const SizedBox(height: 24),
                          isAlreadysend
                              ? _glassCard(_buildConfirmationSection())
                              : _glassCard(_buildRequestActionSection()),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard(Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Requested by",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        _infoRow(Icons.person, "customer", customername ?? "Unknown"),
        _infoRow(
          Icons.numbers_outlined,
          "User Id",
          (request!["userid"] ?? "Unknown").toString(),
        ),
      ],
    );
  }

  Widget _buildRequestDetailsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Request Details",
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        _infoRow(Icons.numbers, "request_id", request!["requestid"].toString()),
        _infoRow(Icons.location_on, "area(sqft)", request!["area"] ?? "N/A"),
        _infoRow(
          Icons.access_time,
          "created time",
          request!["created_time"] ?? "N/A",
        ),
        _infoRow(Icons.calendar_today, "date", request!["date"] ?? "N/A"),
        _infoRow(Icons.schedule, "time:", request!["time"] ?? "N/A"),
        _infoRow(Icons.place, "loacation", request!["street"] ?? "N/A"),
        _infoRow(Icons.build, "service type", request!["type"] ?? "N/A"),
      ],
    );
  }

  Widget _infoRow(IconData icon, String data, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(data, style: GoogleFonts.poppins(color: Colors.white)),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(text, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    final image = request!["image"];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Uploaded Image",
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        image != null && image != "unknown"
            ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
              ),
            )
            : _buildImagePlaceholder(),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Colors.white54),
      ),
    );
  }

  Widget _buildRequestActionSection() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Decline"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.shade400,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _reply,
            child: const Text("Accept Request"),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationSection() {
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              "Request already accepted",
              style: GoogleFonts.poppins(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
          child: const Text("Back"),
        ),
      ],
    );
  }
}
