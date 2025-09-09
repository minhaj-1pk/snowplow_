import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/user/Request/directusernew.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});

  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  List<Map<String, dynamic>> requests = [];
  bool isLoading = true;
  Map<String, String> agencyNames = {}; // Cache agency names

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  Future<void> fetchRequests() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      String? customerId = prefs.getString('userId');

      if (customerId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Customer ID not found")));
        return;
      }

      final response = await http.post(
        Uri.parse('https://snowplow.celiums.com/api/requests/list'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "customer_id": customerId,
          "per_page": "100",
          "page": "0",
          "api_mode": "test",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rawData = data['data'];

        // Gather all futures, then wait
        List<Future<Map<String, dynamic>>> futureRequests =
            rawData.map((item) async {
              final agencyId = item["agency_id"] ?? "";
              final agencyName = await fetchAgencyName(agencyId);
              final status = (item["status"]).toString();

              return {
                "location": item["service_city"] ?? '',
                "area": item["service_area"] ?? "N/A",
                "date": item["preferred_date"] ?? "N/A",
                "urgency": item["urgency_level"] ?? "N/A",
                "requestType": item["request_type"] ?? "N/A",
                "company": agencyName,
                "request_id": item["request_id"] ?? "",
                "image": item["image"],
                "statusText": status == "0" ? "Accepted" : "Pending",
              };
            }).toList();

        final tempRequests = await Future.wait(futureRequests);

        setState(() {
          requests = tempRequests.reversed.toList(); // Newest on top
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to fetch requests")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error")));
    }
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

  Future<void> deletedirectRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenn');
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/requests/delete"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"request_id": requestId, "api_mode": "test"}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Direct request deleted')));
        fetchRequests();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete request')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting request')));
    }
  }

  void showEditDeleteDialog(String requestId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Choose an action'),
            content: Text('Do you want to delete or edit this request?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DirectRequestSENDPAGE()),
                  );
                },
                child: Text('Edit'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  deletedirectRequest(requestId);
                },
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.7, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "DIRECT REQUESTS",
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.blue.shade900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DirectRequestSENDPAGE(),
                          ),
                        );
                        fetchRequests();
                      },
                      icon: Icon(Icons.add, size: 19),
                      label: Text(
                        "New",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main List
              Expanded(
                child:
                    isLoading
                        ? Center(child: CircularProgressIndicator())
                        : requests.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                size: 56,
                                color: Colors.blue.shade200,
                              ),
                              SizedBox(height: 15),
                              Text(
                                "No direct requests found",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                        : RefreshIndicator(
                          onRefresh: fetchRequests,
                          color: Colors.lightBlueAccent,
                          child: ListView.builder(
                            padding: EdgeInsets.only(top: 10, bottom: 10),
                            itemCount: requests.length,
                            itemBuilder:
                                (context, index) => DirectRequestCard(
                                  request: requests[index],
                                  onDelete:
                                      () => deletedirectRequest(
                                        requests[index]['request_id'],
                                      ),
                                  onEdit: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DirectRequestSENDPAGE(),
                                      ),
                                    );
                                    fetchRequests();
                                  },
                                  onMore:
                                      () => showEditDeleteDialog(
                                        requests[index]['request_id'],
                                      ),
                                ),
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DirectRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onMore;

  const DirectRequestCard({
    Key? key,
    required this.request,
    required this.onDelete,
    required this.onEdit,
    required this.onMore,
  }) : super(key: key);

  Color get statusColor =>
      request['statusText'] == 'Accepted' ? Colors.teal : Colors.orangeAccent;
  Widget containerPlaceholderIcon() {
    return Container(
      height: 90,
      width: double.infinity,
      color: Colors.blue.shade50.withOpacity(0.5),
      child: Center(
        child: Icon(Icons.image, size: 37, color: Colors.blueGrey.shade200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.56),
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.09),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.08),
                    width: 1.3,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image placeholder (if you add real images, change here)
                    // ClipRRect(
                    //   borderRadius: BorderRadius.vertical(top: Radius.circular(21)),
                    //   child: Container(
                    //     height: 90,
                    //     width: double.infinity,
                    //     color: Colors.blue.shade50.withOpacity(0.5),
                    //     child: Center(
                    //       child: Icon(Icons.image, size: 37, color: Colors.blueGrey.shade200),
                    //     ),
                    //   ),
                    // ),
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(21),
                      ),
                      child:
                          request['image'] != null
                              ? Image.network(
                                request['image'],
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => containerPlaceholderIcon(),
                              )
                              : containerPlaceholderIcon(),
                    ),

                    // Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 9, 14, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['location'] ?? "Unknown Location",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.4,
                              color: Colors.indigo.shade900,
                            ),
                          ),
                          const SizedBox(height: 5),
                          _rowInfo(
                            Icons.calendar_today_rounded,
                            "Date",
                            request['date'],
                          ),
                          _rowInfo(
                            Icons.access_time_rounded,
                            "Urgency",
                            request['urgency'],
                          ),
                          _rowInfo(
                            Icons.category,
                            "Type",
                            request['requestType'],
                          ),
                          _rowInfo(
                            Icons.business,
                            "Company",
                            request['company'],
                          ),
                          _rowInfo(
                            Icons.location_on_sharp,
                            "Area",
                            request['area'],
                          ),
                          SizedBox(height: 4),
                          // Status Row
                          Row(
                            children: [
                              Icon(
                                (request['statusText'] == "Accepted")
                                    ? Icons.verified_rounded
                                    : Icons.hourglass_top_rounded,
                                size: 17,
                                color: statusColor,
                              ),
                              SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.17),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 13,
                                  vertical: 5,
                                ),
                                child: Text(
                                  request['statusText'],
                                  style: TextStyle(
                                    fontSize: 12.7,
                                    color: statusColor,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 0, color: Colors.grey[300]),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 7.0,
                        right: 12.0,
                        bottom: 2,
                        top: 2,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // You can use menu or individual icons as you wish
                          IconButton(
                            icon: Icon(
                              Icons.edit_note,
                              color: Colors.blue,
                              size: 21,
                            ),
                            tooltip: 'Edit',
                            onPressed: onEdit,
                          ),
                          SizedBox(width: 8),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.redAccent,
                              size: 21,
                            ),
                            tooltip: 'Delete',
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (_) => AlertDialog(
                                      title: Text("Delete Request"),
                                      content: Text(
                                        "Are you sure you want to delete this direct request?",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.pop(context),
                                          child: Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            onDelete();
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          child: Text("Delete"),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                          SizedBox(width: 2),
                          // ...or use an overflow menu
                          // IconButton(
                          //   icon: Icon(Icons.more_vert, color: Colors.grey),
                          //   onPressed: onMore,
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info row with icon and spacing
  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.blue.shade300),
          SizedBox(width: 8),
          Text(
            "$label:",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey.shade700,
              fontSize: 13.1,
              letterSpacing: .6,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
