import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:snowplow/user/Request/newbidsent.dart';
import 'package:snowplow/user/sendBidamount.dart';

class BidRequestsPage extends StatefulWidget {
  @override
  _BidRequestsPageState createState() => _BidRequestsPageState();
}

class _BidRequestsPageState extends State<BidRequestsPage> {
  List<dynamic> bidRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBidRequests();
  }

  Future<void> fetchBidRequests() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenn');
      final userId = prefs.getString('userId');
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/bids/requests"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          "customer_id": userId,
          "per_page": "1000",
          "page": "0",
          "api_mode": "test",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        List<dynamic> bidRequestsss =
            data
                .map((item) {
                  return {
                    'location': item['service_street'] ?? '',
                    'date': item['preferred_date'] ?? '',
                    'urgency': item['urgency_level'] ?? '',
                    'time': item['preferred_time'] ?? '',
                    'bidd_id': item['bid_request_id'] ?? '',
                    'area': item['service_area'] ?? 'na',
                    'image': item['image'] ?? '',
                    'status': (item['status'] == '0') ? 'Accepted' : 'Pending',
                  };
                })
                .toList()
                .reversed
                .toList();
        setState(() {
          bidRequests = bidRequestsss;
        });
      } else {
        setState(() {
          bidRequests = [];
        });
        print("Response: ${response.body}");
      }
    } catch (e) {
      print("Error fetching bid requests: $e");
    }
    setState(() => isLoading = false);
  }

  Future<void> deleteBidRequest(String requestId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('tokenn');
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/bids/delete"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({"request_id": requestId, "api_mode": "test"}),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bid request deleted successfully')),
        );
        fetchBidRequests();
      } else {
        print('Failed to delete: ${response.body}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete bid request')));
      }
    } catch (e) {
      print('Error during delete: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting bid request')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade200, Colors.white, Colors.blue.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7, 1.0],
          ),
        ),

        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BID REQUESTS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.blue.shade900,
                      letterSpacing: 1.8,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NewBidRequestPage()),
                      );
                      fetchBidRequests();
                    },
                    icon: Icon(Icons.add, size: 18),
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
            Expanded(
              child:
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                        onRefresh: fetchBidRequests,
                        color: Colors.lightBlueAccent,
                        child:
                            bidRequests.isEmpty
                                ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz,
                                        size: 58,
                                        color: Colors.blue.shade200,
                                      ),
                                      SizedBox(height: 15),
                                      Text(
                                        "No bid requests found",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                                : ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 1),
                                  itemCount: bidRequests.length,
                                  itemBuilder: (context, index) {
                                    final item = bidRequests[index];
                                    return BidRequestCard(
                                      item: item,
                                      onDelete:
                                          () =>
                                              deleteBidRequest(item['bidd_id']),
                                      onEdit: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => NewBidRequestPage(),
                                            // Optionally pass item for edit
                                          ),
                                        );
                                        fetchBidRequests();
                                      },
                                    );
                                  },
                                ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

class BidRequestCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const BidRequestCard({
    Key? key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  Color get statusColor =>
      (item['status'] == 'Accepted') ? Colors.teal : Colors.orangeAccent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 17, vertical: 9),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SentBidsPage(requestid: item['bidd_id']),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              // Glass card with blur
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 11, sigmaY: 11),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.56),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.08),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.08),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        child:
                            item['image'] != null &&
                                    item['image'].toString().isNotEmpty
                                ? AspectRatio(
                                  aspectRatio: 16 / 7,
                                  child: Image.network(
                                    item['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _placeholderImage(),
                                  ),
                                )
                                : _placeholderImage(),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 12, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['location'] ?? "Unknown Location",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.4,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                            const SizedBox(height: 5),

                            _rowInfo(
                              Icons.calendar_today_rounded,
                              "Date",
                              item['date'],
                            ),
                            _rowInfo(
                              Icons.access_time_rounded,
                              "Time",
                              item['time'],
                            ),
                            _rowInfo(Icons.bolt, "Urgency", item['urgency']),
                            _rowInfo(Icons.location_on, "Area", item['area']),
                            _rowInfo(Icons.numbers, "Bid ID", item['bidd_id']),
                            SizedBox(height: 4),

                            // Status with badge
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Icon(
                                  (item['status'] == "Accepted")
                                      ? Icons.verified_rounded
                                      : Icons.hourglass_top_rounded,
                                  size: 17,
                                  color: statusColor,
                                ),
                                SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.16),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 13,
                                    vertical: 5,
                                  ),
                                  child: Text(
                                    item['status'],
                                    style: TextStyle(
                                      fontSize: 13,
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
                            IconButton(
                              padding: EdgeInsets.symmetric(horizontal: 3),
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
                              padding: EdgeInsets.symmetric(horizontal: 3),
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
                                        title: Text("Delete Bid"),
                                        content: Text(
                                          "Are you sure you want to delete this bid request?",
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
                            SizedBox(width: 4),
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
      ),
    );
  }

  // Info with nice icon and spacing
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
              fontSize: 13.5,
              letterSpacing: .6,
            ),
          ),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.blueGrey.shade900,
                fontSize: 13.3,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Glassy placeholder if no image
  Widget _placeholderImage() => Container(
    height: 85,
    width: double.infinity,
    decoration: BoxDecoration(color: Colors.blue.shade50.withOpacity(0.6)),
    child: Center(
      child: Icon(
        Icons.image_not_supported,
        size: 36,
        color: Colors.blueGrey.shade200,
      ),
    ),
  );
}
