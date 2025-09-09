import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/company/Agency_pending.dart/Direct_accept.dart/directAccept.dart';

class DirectRequestsPage extends StatefulWidget {
  @override
  _DirectRequestsPageState createState() => _DirectRequestsPageState();
}

class _DirectRequestsPageState extends State<DirectRequestsPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> requestlist = [];
  bool isLoading = true;
  final Map<String, String> _userNames = {};
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    );
    fetchDirectRequests();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchDirectRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final agency_id = prefs.getString('agency_id');

    final response = await http.post(
      Uri.parse('https://snowplow.celiums.com/api/requests/agencyrequests'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        "agency_id": agency_id,
        "per_page": "1000",
        "api_mode": "test",
      }),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> requestlistt = jsonData['data'] ?? [];

      await Future.wait(
        requestlistt.map(
          (item) =>
              _fetchUsername(item["customer_id"]?.toString() ?? "unknown"),
        ),
      );

      setState(() {
        isLoading = false;
        requestlist =
            requestlistt.reversed.map((item) {
              final status = (item["status"]).toString();
              return {
                "requestid": item["request_id"] ?? "unknown",
                "userid": item["customer_id"] ?? "unknown",
                "street": item["service_street"] ?? "unknown",
                "latitude": item["service_latitude"] ?? "unknown",
                "longitude": item["service_longitude"] ?? "unknown",
                "type": item["service_type"] ?? "unknown",
                "area": item["service_area"] ?? "unknown",
                "time": item["preferred_time"] ?? "unknown",
                "date": item["preferred_date"] ?? "unknown",
                "urgency": item["urgency_level"] ?? "unknown",
                "image": item["image"] ?? "unknown",
                "created_time": item["created"] ?? "unknown",
                "isAccepted": status == "0",
              };
            }).toList();
      });

      _fadeController.forward();
    } else {
      setState(() => isLoading = false);
      print('Failed to load direct requests');
    }
  }

  Future<void> _fetchUsername(String userId) async {
    if (_userNames.containsKey(userId)) return;

    try {
      final res = await http.post(
        Uri.parse('https://snowplow.celiums.com/api/profile/details'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'customer_id': userId, 'api_mode': 'test'}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final name = (data['data']?['customer_name'] ?? 'Unknown').toString();
        setState(() => _userNames[userId] = name);
      }
    } catch (_) {
      setState(() => _userNames[userId] = 'Unknown');
    }
  }

  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade100),
          SizedBox(width: 7),
          Text(
            "$label: ",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 13, color: Colors.white70),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color statusColor(Map<String, dynamic> request) {
    if (request['isAccepted'] == true) return Colors.green;
    return Colors.orangeAccent;
  }

  Widget buildRequestCard(Map<String, dynamic> request, int index) {
    final username = _userNames[request['userid']] ?? 'Loading...';
    final urgencyColor =
        request['urgency'].toString().toLowerCase() == 'urgent'
            ? Colors.redAccent
            : Colors.lightBlueAccent;

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            (index / requestlist.length),
            1,
            curve: Curves.easeIn,
          ),
        ),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => DIrectDetails(
                    requestdetails: request,
                    Username: username,
                  ),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      urgencyColor.withOpacity(0.25),
                      Colors.blueGrey.withOpacity(0.3),
                      Colors.black.withOpacity(0.13),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.075)),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 22,
                      spreadRadius: 1,
                      color: urgencyColor.withOpacity(0.12),
                      offset: Offset(2, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Header
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child:
                          request['image'] != "unknown" &&
                                  request['image'].toString().isNotEmpty
                              ? Image.network(
                                request['image'],
                                height: 125,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) => Container(
                                      height: 125,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                              )
                              : Container(
                                height: 125,
                                color: urgencyColor.withOpacity(0.14),
                                child: Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.build,
                                color: Colors.lightBlue[100],
                                size: 20,
                              ),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  request['type'],
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor(request),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  request['isAccepted'] == true
                                      ? 'ACCEPTED'
                                      : 'PENDING',

                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          infoRow(Icons.person, "CUSTOMER", username),
                          infoRow(Icons.location_city, "AREA", request['area']),
                          infoRow(
                            Icons.streetview,
                            "STREET",
                            request['street'],
                          ),
                          infoRow(
                            Icons.calendar_today,
                            "DATE",
                            request['date'],
                          ),
                          infoRow(Icons.access_time, "TIME", request['time']),
                          infoRow(Icons.alarm, "URGENCY", request['urgency']),
                          Row(
                            children: [
                              Icon(
                                Icons.key,
                                size: 16,
                                color: Colors.blueGrey.shade100,
                              ),
                              SizedBox(width: 7),
                              Text(
                                "REQ#: ",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white.withOpacity(0.92),
                                ),
                              ),
                              Text(
                                request['requestid'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                              Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 15,
                                    color: Colors.blueGrey.shade100,
                                  ),
                                  SizedBox(width: 3),
                                  Text(
                                    request['created_time'],
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(0, 5, 0, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.fromARGB(255, 2, 68, 100),
            Color.fromARGB(255, 2, 68, 100),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(46),
          bottomRight: Radius.circular(46),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text(
            "Agent Direct Requests",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Total: ${requestlist.length}",
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[900]!.withOpacity(0.96),
      child: Column(
        children: [
          buildHeader(),
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                        strokeWidth: 2.5,
                      ),
                    )
                    : requestlist.isEmpty
                    ? Center(
                      child: Text(
                        "No direct requests found",
                        style: TextStyle(
                          color: Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
                    )
                    : RefreshIndicator(
                      color: Colors.cyanAccent,
                      backgroundColor: Colors.blueGrey[900],
                      onRefresh: fetchDirectRequests,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: 8),
                        itemCount: requestlist.length,
                        itemBuilder: (context, index) {
                          return buildRequestCard(requestlist[index], index);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
