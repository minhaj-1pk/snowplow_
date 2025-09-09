import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/company/show_Bid.dart';

class AgentRequestsPage extends StatefulWidget {
  @override
  _AgentRequestsPageState createState() => _AgentRequestsPageState();
}

class _AgentRequestsPageState extends State<AgentRequestsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> agentRequests = [];
  bool isLoading = true;

  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    fetchAgentRequests();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> fetchAgentRequests() async {
    setState(() => isLoading = true);

    final response = await http.post(
      Uri.parse('https://snowplow.celiums.com/api/bids/agentrequests'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({"per_page": "1000", "page": "0", "api_mode": "test"}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      List<dynamic> biddata = jsonResponse['data'];
      final Set<String> uniqueCustomerIds =
          biddata
              .map<String>(
                (item) => item["customer_id"]?.toString() ?? "unknown",
              )
              .toSet();

      Map<String, String> customerNameMap = {};
      await Future.wait(
        uniqueCustomerIds.map((customerId) async {
          if (customerId == "unknown") {
            customerNameMap[customerId] = "unknown";
            return;
          }
          try {
            final nameResponse = await http.post(
              Uri.parse('https://snowplow.celiums.com/api/profile/details'),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: jsonEncode({"customer_id": customerId, "api_mode": "test"}),
            );
            if (nameResponse.statusCode == 200) {
              final profileData = jsonDecode(nameResponse.body);
              customerNameMap[customerId] =
                  profileData['data']["customer_name"] ?? "unknown";
            } else {
              customerNameMap[customerId] = "unknown";
            }
          } catch (e) {
            customerNameMap[customerId] = "unknown";
          }
        }),
      );
      List<dynamic> mapdata =
          biddata.map((item) {
            final status = item['status'].toString();
            final customerId = item['customer_id'] ?? "unknown";
            return {
              "requestid": item["bid_request_id"] ?? "unknown",
              "userid": customerId,
              "customer_name": customerNameMap[customerId] ?? "unknown",
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
              "status": item["status"] ?? "unknown",
              "accepted": status == "0",
            };
          }).toList();

      if (mapdata.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'bid_request_id',
          mapdata[0]["requestid"].toString(),
        );
      }

      setState(() {
        agentRequests = mapdata;
        isLoading = false;
      });

      _fadeController.forward();
    } else {
      setState(() => isLoading = false);
      print('Failed to load agent requests: ${response.statusCode}');
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

  Color statusColor(dynamic request) {
    if (request['accepted']) return Colors.green;
    if (request['status'] == "2") return Colors.red;
    return Colors.orangeAccent;
  }

  Widget buildRequestCard(Map<String, dynamic> request, int index) {
    final urgencyColor =
        request['urgency'].toString().toLowerCase() == 'urgent'
            ? Colors.redAccent
            : Colors.lightBlueAccent;

    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(
            (index / agentRequests.length),
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
              builder: (context) => Showbid(biddetails: request),
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Stack(
            children: [
              // Glassmorphic background
              ClipRRect(
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
                      border: Border.all(
                        color: Colors.white.withOpacity(0.075),
                      ),
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
                        Stack(
                          children: [
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
                                            (c, e, s) => Container(
                                              height: 125,
                                              color: Colors.blueGrey[50],
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
                                            Icons.photo_library,
                                            size: 40,
                                            color: Colors.blueGrey[200],
                                          ),
                                        ),
                                      ),
                            ),
                            // Profile circle avatar
                            // Positioned(
                            //   top: 14,
                            //   left: 14,
                            //   child: CircleAvatar(
                            //     backgroundColor: urgencyColor,
                            //     radius: 22,
                            //     child: Text(
                            //       request['customer_name'] != "unknown"
                            //           ? request['customer_name']
                            //               .toString()
                            //               .substring(0, 1)
                            //               .toUpperCase()
                            //           : "?",
                            //       style: TextStyle(
                            //         fontWeight: FontWeight.bold,
                            //         fontSize: 20,
                            //         color: Colors.white,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(18, 16, 18, 13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Request type and badge
                              Row(
                                children: [
                                  Icon(
                                    Icons.home_repair_service_rounded,
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
                                        letterSpacing: 0.2,
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
                                      request['accepted']
                                          ? 'ACCEPTED'
                                          : (request['status'] == "2"
                                              ? "DECLINED"
                                              : "PENDING"),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              // Customer details
                              infoRow(
                                Icons.person_outline_outlined,
                                "CUSTOMER",
                                request['customer_name'],
                              ),
                              infoRow(
                                Icons.location_city_rounded,
                                "AREA",
                                request['area'],
                              ),
                              infoRow(
                                Icons.streetview_outlined,
                                "STREET",
                                request['street'],
                              ),
                              infoRow(
                                Icons.calendar_today_outlined,
                                "DATE",
                                request['date'],
                              ),
                              infoRow(
                                Icons.access_time_outlined,
                                "TIME",
                                request['time'],
                              ),
                              infoRow(
                                Icons.hourglass_bottom_outlined,
                                "URGENCY",
                                request['urgency'],
                              ),
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
              // Small urgency flag
              // if (request['urgency'].toString().toLowerCase() == 'urgent')
              //   Positioned(
              //     top: 6,
              //     right: 16,
              //     child: Chip(
              //       backgroundColor: Colors.redAccent,
              //       label: Text(
              //         "URGENT",
              //         style: TextStyle(
              //           color: Colors.white,
              //           fontWeight: FontWeight.bold,
              //           fontSize: 11,
              //           letterSpacing: 1.1,
              //         ),
              //       ),
              //       avatar: Icon(
              //         Icons.priority_high,
              //         color: Colors.white,
              //         size: 17,
              //       ),
              //       padding: EdgeInsets.zero,
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }

  // Header widget
  Widget buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 2, 68, 100),
            const Color.fromARGB(255, 2, 68, 100),
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
          Icon(Icons.gavel, size: 40, color: Colors.white),
          SizedBox(height: 8),
          Text(
            "Agent Bid Requests",
            style: TextStyle(
              fontSize: 24,
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          SizedBox(height: 5),
          Text(
            "Total: ${agentRequests.length}",
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
                    : agentRequests.isEmpty
                    ? Center(
                      child: Text(
                        "No bid requests found",
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
                      onRefresh: fetchAgentRequests,
                      child: ListView.builder(
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.only(top: 8),
                        itemCount: agentRequests.length,
                        itemBuilder: (context, index) {
                          return buildRequestCard(agentRequests[index], index);
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
