import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:snowplow/user/pending/tapbar.dart';

class SentBidsPage extends StatefulWidget {
  final String? requestid;
  SentBidsPage({super.key, required this.requestid});

  @override
  _SentBidsPageState createState() => _SentBidsPageState();
}

class _SentBidsPageState extends State<SentBidsPage> {
  List<dynamic> sentBids = [];
  bool isLoading = true;
  String? id;
  Map<String, String> agencyNames = {};

  @override
  void initState() {
    super.initState();
    id = widget.requestid.toString();
    fetchSentBids();
  }

  Future<String> fetchAgencyName(String agencyId) async {
    if (agencyId.isEmpty || agencyId == "N/A") return 'Unknown';
    if (agencyNames.containsKey(agencyId)) return agencyNames[agencyId]!;
    try {
      final response = await http.post(
        Uri.parse('https://snowplow.celiums.com/api/agencies/details'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"agency_id": agencyId, "api_mode": "test"}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final name = data['data']['agency_name'] ?? 'Unknown';
        agencyNames[agencyId] = name;
        return name;
      }
    } catch (_) {}
    return 'Unknown';
  }

  Future<void> fetchSentBids() async {
    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/bids/bidlist"),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"bid_request_id": id, "api_mode": "test"}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse.containsKey('data') && jsonResponse['data'] is List) {
          final List<dynamic> requestList = jsonResponse['data'];

          if (requestList.isNotEmpty) {
            // List<dynamic> fetchdata =
            //     requestList.map((request) async {
            //       final agencyId = request["agency_id"] ?? "";
            //       print("agencyyyedd id $agencyId");
            //       final agencyName = await fetchAgencyName(agencyId);
            //       return {
            //         "requestId": request["bid_request_id"],
            //         "bid_id": request["bid_id"],
            //         "agency_id": request["agency_id"],
            //         "price": request["price"],
            //         "comments": request["comments"],
            //         "created": request["created"],
            //         "company": agencyName,
            //         "status": request["status"] ?? "Pending",
            //       };
            //     }).toList();
            List<Map<String, dynamic>> fetchdata = await Future.wait(
              requestList.map((request) async {
                final agencyId = request["agency_id"] ?? "";
                final agencyName = await fetchAgencyName(agencyId);
                return {
                  "requestId": request["bid_request_id"],
                  "bid_id": request["bid_id"],
                  "agency_id": request["agency_id"],
                  "price": request["price"],
                  "comments": request["comments"],
                  "created": request["created"],
                  "company": agencyName,
                  "status": request["status"] ?? "Pending",
                };
              }),
            );

            setState(() {
              sentBids = fetchdata;
            });
          } else {
            setState(() {
              sentBids = [];
            });
          }
        } else {
          setState(() {
            sentBids = [];
          });
        }
      } else {
        showCustomSnackBar("Failed to fetch bids.", false);
      }
    } catch (e) {
      showCustomSnackBar("Error fetching bids.", false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showCustomSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> acceptBid(String bidid, int index) async {
    try {
      setState(() {
        isLoading = true;
      });

      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/bids/accept"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"bid_id": bidid, "api_mode": "test"}),
      );

      if (response.statusCode == 200) {
        showCustomSnackBar("Bid Accepted Successfully!", true);
        // Optionally refresh bids or go to another page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PendingRequestsTabsPage()),
        );
      } else {
        showCustomSnackBar("Failed to Accept Bid", false);
      }
    } catch (e) {
      showCustomSnackBar("Error Occurred", false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void declineBid(String bidId) {
    setState(() {
      sentBids.removeWhere((bid) => bid['bid_id'] == bidId);
    });
    showCustomSnackBar("Bid Declined", false);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'closed':
        return Colors.grey;
      case 'accepted':
        return Colors.green;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sent Bids",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade200,
                const Color.fromARGB(255, 122, 189, 231),
                const Color.fromARGB(255, 181, 211, 232),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),

      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.75, 1.0],
          ),
        ),
        child:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : sentBids.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 64,
                          color: Colors.blueGrey.shade200,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Unfortunately...",
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "No bid amount has been sent for this request yet.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                : ListView.builder(
                  itemCount: sentBids.length,
                  padding: EdgeInsets.symmetric(vertical: 10),
                  itemBuilder: (context, index) {
                    final bid = sentBids[index];
                    final String status = bid['status'].toString();
                    final bool isAccepted = status.toLowerCase() == 'accepted';

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 9,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.61),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.07),
                                width: 1.1,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _rowInfo(
                                    icon: Icons.person,
                                    label: "Agency name",
                                    value: bid["company"],
                                    highlight: true,
                                  ),
                                  _rowInfo(
                                    icon: Icons.currency_rupee_rounded,
                                    label: "Amount",
                                    value: "₹${bid['price']}",
                                    highlight: true,
                                  ),
                                  _rowInfo(
                                    icon: Icons.message_rounded,
                                    label: "Comments",
                                    value: bid['comments'] ?? '-',
                                  ),
                                  _rowInfo(
                                    icon: Icons.business,
                                    label: "Agency",
                                    value: bid['agency_id'],
                                  ),
                                  _rowInfo(
                                    icon: Icons.numbers,
                                    label: "Request ID",
                                    value: bid['requestId'],
                                  ),
                                  _rowInfo(
                                    icon: Icons.calendar_today,
                                    label: "Created",
                                    value: bid['created'],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Chip(
                                        label: Text(
                                          status,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        backgroundColor: getStatusColor(status),
                                      ),
                                      Spacer(),
                                      if (!isAccepted) ...[
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 18,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                          ),
                                          onPressed:
                                              () => acceptBid(
                                                bid['bid_id'],
                                                index,
                                              ),
                                          child: Text("Accept"),
                                        ),
                                        SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                          ),
                                          onPressed:
                                              () => declineBid(bid['bid_id']),
                                          child: Text("Decline"),
                                        ),
                                      ] else ...[
                                        Text(
                                          "✅ Bid is Closed",
                                          style: TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }

  Widget _rowInfo({
    required IconData icon,
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: highlight ? Colors.green : Colors.blueGrey.shade400,
          ),
          SizedBox(width: 10),
          Text(
            "$label:",
            style: GoogleFonts.poppins(
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color:
                  highlight
                      ? Colors.blueGrey.shade900
                      : Colors.blueGrey.shade700,
              fontSize: 13.5,
            ),
          ),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? Colors.teal[700] : Colors.blueGrey.shade900,
                fontSize: 14.3,
                letterSpacing: .4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
