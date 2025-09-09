// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// class Showbid extends StatefulWidget {
//   final Map<String, dynamic> biddetails;
//   Showbid({required this.biddetails});

//   @override
//   State<Showbid> createState() => _ShowbidState();
// }

// class _ShowbidState extends State<Showbid> {
//   TextEditingController bidAmountController = TextEditingController();
//   TextEditingController commentController = TextEditingController();
//   bool isSubmitting = false;
//   bool isBidPlaced = false;
//   bool isediting = false;
//   Map<String, dynamic>? existingBid;

//   final Color primaryColor = const Color.fromARGB(255, 3, 69, 102);
//   final Color lightBackground = Color(0xFFF0F8FF);

//   @override
//   void initState() {
//     super.initState();
//     checkExistingBid();
//   }

//   Future<void> checkExistingBid() async {
//     final prefs = await SharedPreferences.getInstance();
//     final agency_id = prefs.getString('agency_id');
//     final bidRequestId = widget.biddetails["requestid"];

//     final response = await http.post(
//       Uri.parse("https://snowplow.celiums.com/api/bids/viewbid"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "bid_request_id": bidRequestId,
//         "agency_id": agency_id,
//         "api_mode": "test",
//       }),
//     );

//     final data = jsonDecode(response.body);
//     if (response.statusCode == 200 &&
//         data['status'] == 1 &&
//         data['data'] != null) {
//       setState(() {
//         isBidPlaced = true;
//         existingBid = data['data'];
//         bidAmountController.text = existingBid?['price'] ?? '';
//         commentController.text = existingBid?['comments'] ?? '';
//       });
//     } else {
//       setState(() {
//         isBidPlaced = false;
//       });
//     }
//   }

//   Future<void> submitBid() async {
//     final bidAmount = bidAmountController.text.trim();
//     final comment = commentController.text.trim();
//     final prefs = await SharedPreferences.getInstance();
//     final agency_id = prefs.getString('agency_id');

//     if (bidAmount.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Please enter a bid amount")));
//       return;
//     }

//     setState(() => isSubmitting = true);

//     final response = await http.post(
//       Uri.parse("https://snowplow.celiums.com/api/bids/createbid"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({
//         "bid_request_id": widget.biddetails["requestid"],
//         "agency_id": agency_id,
//         "price": bidAmount,
//         "comments": comment,
//         "api_mode": "test",
//       }),
//     );

//     setState(() => isSubmitting = false);
//     final data = jsonDecode(response.body);

//     if (response.statusCode == 200 && data['status'] == 1) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Bid submitted successfully")));
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to submit bid")));
//     }
//   }

//   Future<void> updateBid() async {
//     final prefs = await SharedPreferences.getInstance();
//     final agency_id = prefs.getString('agency_id');
//     final bidAmount = bidAmountController.text.trim();
//     final comment = commentController.text.trim();
//     final requestId =
//         widget.biddetails["requestid"] ?? widget.biddetails["requestId"];

//     if (bidAmount.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Please enter a bid amount")));
//       return;
//     }

//     setState(() => isSubmitting = true);

//     final res = await http.post(
//       Uri.parse('https://snowplow.celiums.com/api/bids/bidupdate'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'bid_request_id': requestId,
//         'agency_id': agency_id ?? '',
//         'price': bidAmount,
//         'comments': comment,
//         'api_mode': 'test',
//       }),
//     );

//     setState(() => isSubmitting = false);
//     final result = jsonDecode(res.body);

//     if (res.statusCode == 200 && result['status'] == 1) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Bid updated successfully")));
//       Navigator.pop(context);
//     } else {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text("Failed to update bid")));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final data = widget.biddetails;
//     final imageUrl =
//         data["image"] != null && data["image"].toString().isNotEmpty
//             ? (data["image"].toString().startsWith("http")
//                 ? data["image"]
//                 : "https://snowplow.celiums.com/storage/${data["image"]}")
//             : null;

//     return Scaffold(
//       backgroundColor: primaryColor,
//       appBar: AppBar(
//         title: Text(
//           "Bid Request Details",
//           style: TextStyle(color: Colors.white),
//         ),
//         backgroundColor: primaryColor,
//         // foregroundColor: primaryColor,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (imageUrl != null)
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(12),
//                 child: Image.network(
//                   imageUrl,
//                   height: 220,
//                   width: double.infinity,
//                   fit: BoxFit.cover,
//                   errorBuilder:
//                       (context, error, stackTrace) =>
//                           Center(child: Text("Image not available")),
//                 ),
//               ),
//             SizedBox(height: 20),
//             buildInfoCard(data),
//             SizedBox(height: 24),
//             if (!isBidPlaced) buildBidForm(),
//             if (isBidPlaced && !isediting) buildBidSummary(),
//             if (isBidPlaced && isediting) buildBidUpdateForm(),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget buildInfoCard(Map<String, dynamic> data) {
//   //   return Card(
//   //     color: lightBackground,

//   //     elevation: 3,
//   //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//   //     child: Padding(
//   //       padding: EdgeInsets.all(16),
//   //       child: Column(
//   //         crossAxisAlignment: CrossAxisAlignment.start,
//   //         children: [
//   //           detailRow("Request ID", data["requestid"] ?? data["requestId"]),
//   //           detailRow("Service Type", data["type"]),
//   //           detailRow("Area", data["area"]),
//   //           detailRow("Street", data["street"]),
//   //           detailRow("Preferred Date", data["date"]),
//   //           detailRow("Preferred Time", data["time"]),
//   //           detailRow("Urgency", data["urgency"]),
//   //           detailRow("Status", data["status"]),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//   Widget detailRow(IconData icon, String label, dynamic value) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Icon(icon, color: Colors.blue.shade800, size: 20),
//         SizedBox(width: 10),
//         Expanded(
//           child: RichText(
//             text: TextSpan(
//               style: TextStyle(fontSize: 15, color: Colors.black),
//               children: [
//                 TextSpan(
//                   text: "$label: ",
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 TextSpan(text: "$value"),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget sectionTitle(String title, {double fontSize = 16}) {
//     return Text(
//       title,
//       style: TextStyle(
//         fontWeight: FontWeight.w700,
//         fontSize: fontSize,
//         color: Colors.black,
//       ),
//     );
//   }

//   Widget buildInfoCard(Map<String, dynamic> data) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [Colors.blue.shade50, Colors.white],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.15),
//             blurRadius: 12,
//             offset: Offset(0, 6),
//           ),
//         ],
//       ),
//       margin: EdgeInsets.symmetric(horizontal: 4),
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             sectionTitle("Request Information", fontSize: 18),
//             SizedBox(height: 16),
//             Wrap(
//               runSpacing: 12,
//               children: [
//                 detailRow(
//                   Icons.confirmation_number,
//                   "Request ID",
//                   data["requestid"] ?? data["requestId"],
//                 ),
//                 detailRow(
//                   Icons.miscellaneous_services,
//                   "Service Type",
//                   data["type"],
//                 ),
//                 detailRow(Icons.location_on, "Area", data["area"]),
//                 detailRow(Icons.map, "Street", data["street"]),
//                 detailRow(Icons.calendar_today, "Preferred Date", data["date"]),
//                 detailRow(Icons.access_time, "Preferred Time", data["time"]),
//                 detailRow(Icons.priority_high, "Urgency", data["urgency"]),
//                 detailRow(Icons.verified, "Status", data["status"]),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildBidForm() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         sectionTitle("Enter Bid Amount"),
//         buildTextField(bidAmountController, "e.g. 5000", Icons.attach_money),
//         SizedBox(height: 20),
//         sectionTitle("Enter Comment (Optional)"),
//         buildTextField(
//           commentController,
//           "Add a comment...",
//           Icons.comment,
//           maxLines: 3,
//         ),
//         SizedBox(height: 24),
//         buildSubmitButton("Submit Bid", Icons.send, submitBid),
//       ],
//     );
//   }

//   Widget buildBidSummary() {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: Text(
//                 "Your Submitted Bid",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 18,
//                   color: primaryColor,
//                 ),
//               ),
//             ),
//             SizedBox(height: 16),
//             Text(
//               "Bid Amount: ₹${existingBid?['price'] ?? ''}",
//               style: TextStyle(fontSize: 16),
//             ),
//             SizedBox(height: 8),
//             Text(
//               "Comment: ${existingBid?['comments'] ?? 'No comment'}",
//               style: TextStyle(fontSize: 16),
//             ),
//             SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 onPressed: () => setState(() => isediting = true),
//                 icon: Icon(Icons.edit, color: Colors.white),
//                 label: Text(
//                   "Update Bid",
//                   style: TextStyle(color: Colors.white),
//                 ),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: primaryColor,
//                   padding: EdgeInsets.symmetric(vertical: 14),
//                   textStyle: TextStyle(fontSize: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget buildBidUpdateForm() {
//     return Card(
//       elevation: 3,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               "Update Your Bid",
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//                 color: primaryColor,
//               ),
//             ),
//             SizedBox(height: 12),
//             buildTextField(
//               bidAmountController,
//               "Enter new bid",
//               Icons.attach_money,
//             ),
//             SizedBox(height: 16),
//             buildTextField(
//               commentController,
//               "Update comment",
//               Icons.comment,
//               maxLines: 3,
//             ),
//             SizedBox(height: 24),
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     onPressed: isSubmitting ? null : updateBid,
//                     icon: Icon(Icons.check),
//                     label:
//                         isSubmitting
//                             ? CircularProgressIndicator(color: Colors.white)
//                             : Text("Submit Update"),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green.shade600,
//                       padding: EdgeInsets.symmetric(vertical: 14),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 12),
//                 Expanded(
//                   child: OutlinedButton.icon(
//                     onPressed: () => setState(() => isediting = false),
//                     icon: Icon(Icons.cancel),
//                     label: Text("Cancel"),
//                     style: OutlinedButton.styleFrom(
//                       foregroundColor: primaryColor,
//                       side: BorderSide(color: primaryColor),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // Widget detailRow(String title, dynamic value) {
//   //   return Padding(
//   //     padding: const EdgeInsets.symmetric(vertical: 6),
//   //     child: Row(
//   //       children: [
//   //         Icon(Icons.check_circle_outline, color: Colors.blueGrey, size: 20),
//   //         SizedBox(width: 10),
//   //         Expanded(
//   //           child: Text("$title: $value", style: TextStyle(fontSize: 16)),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   // Widget sectionTitle(String title) {
//   //   return Text(
//   //     title,
//   //     style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//   //   );
//   // }

//   Widget buildTextField(
//     TextEditingController controller,
//     String hint,
//     IconData icon, {
//     int maxLines = 2,
//   }) {
//     return TextField(
//       controller: controller,
//       maxLines: maxLines,
//       keyboardType: TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: Colors.white),
//         prefixIcon: Icon(icon, color: Colors.blue.shade800),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//         focusedBorder: OutlineInputBorder(
//           borderSide: BorderSide(color: Colors.blue.shade800, width: 2),
//           borderRadius: BorderRadius.circular(10),
//         ),
//       ),
//     );
//   }

//   Widget buildSubmitButton(String label, IconData icon, Function onPressed) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton.icon(
//         onPressed: isSubmitting ? null : () => onPressed(),
//         icon: Icon(icon),
//         label:
//             isSubmitting
//                 ? CircularProgressIndicator(color: Colors.white)
//                 : Text(label),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: primaryColor.withValues(blue: 2).withOpacity(0.6),
//           padding: EdgeInsets.symmetric(vertical: 14),
//           textStyle: TextStyle(fontSize: 16, color: Colors.white),
//         ),
//       ),
//     );
//   }
// }
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Showbid extends StatefulWidget {
  final Map<String, dynamic> biddetails;
  const Showbid({super.key, required this.biddetails});

  @override
  State<Showbid> createState() => _ShowbidState();
}

class _ShowbidState extends State<Showbid> {
  TextEditingController bidAmountController = TextEditingController();
  TextEditingController commentController = TextEditingController();

  bool isSubmitting = false;
  bool isBidPlaced = false;
  bool isediting = false;
  Map<String, dynamic>? existingBid;
  Color get _mainBgColor =>
      Theme.of(context).brightness == Brightness.dark
          ? Color(0xFF212B36)
          : Color(0xFFE8F1F9);

  final Color primaryColor = const Color.fromARGB(255, 3, 69, 102);
  final Color accentColor = Color(0xFF57B5E4);

  @override
  void initState() {
    super.initState();
    checkExistingBid();
  }

  Future<void> checkExistingBid() async {
    final prefs = await SharedPreferences.getInstance();
    final agency_id = prefs.getString('agency_id');
    final bidRequestId = widget.biddetails["requestid"];

    final response = await http.post(
      Uri.parse("https://snowplow.celiums.com/api/bids/viewbid"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "bid_request_id": bidRequestId,
        "agency_id": agency_id,
        "api_mode": "test",
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 &&
        data['status'] == 1 &&
        data['data'] != null) {
      setState(() {
        isBidPlaced = true;
        existingBid = data['data'];
        bidAmountController.text = existingBid?['price'] ?? '';
        commentController.text = existingBid?['comments'] ?? '';
      });
    } else {
      setState(() {
        isBidPlaced = false;
      });
    }
  }

  Future<void> submitBid() async {
    final bidAmount = bidAmountController.text.trim();
    final comment = commentController.text.trim();
    final prefs = await SharedPreferences.getInstance();
    final agency_id = prefs.getString('agency_id');

    if (bidAmount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a bid amount")));
      return;
    }

    setState(() => isSubmitting = true);

    final response = await http.post(
      Uri.parse("https://snowplow.celiums.com/api/bids/createbid"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "bid_request_id": widget.biddetails["requestid"],
        "agency_id": agency_id,
        "price": bidAmount,
        "comments": comment,
        "api_mode": "test",
      }),
    );

    setState(() => isSubmitting = false);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['status'] == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bid submitted successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to submit bid")));
    }
  }

  Future<void> updateBid() async {
    final prefs = await SharedPreferences.getInstance();
    final agency_id = prefs.getString('agency_id');
    final bidAmount = bidAmountController.text.trim();
    final comment = commentController.text.trim();
    final requestId =
        widget.biddetails["requestid"] ?? widget.biddetails["requestId"];

    if (bidAmount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please enter a bid amount")));
      return;
    }

    setState(() => isSubmitting = true);

    final res = await http.post(
      Uri.parse('https://snowplow.celiums.com/api/bids/bidupdate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'bid_request_id': requestId,
        'agency_id': agency_id ?? '',
        'price': bidAmount,
        'comments': comment,
        'api_mode': 'test',
      }),
    );

    setState(() => isSubmitting = false);
    final result = jsonDecode(res.body);

    if (res.statusCode == 200 && result['status'] == 1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Bid updated successfully")));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to update bid")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.biddetails;
    final imageUrl =
        data["image"] != null && data["image"].toString().isNotEmpty
            ? (data["image"].toString().startsWith("http")
                ? data["image"]
                : "https://snowplow.celiums.com/storage/${data["image"]}")
            : null;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Color.fromARGB(255, 2, 68, 100),
      appBar: AppBar(
        backgroundColor: primaryColor.withOpacity(0.92),
        elevation: 8,
        centerTitle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
        ),
        title: const Text(
          "Bid Request Details",
          style: TextStyle(
            color: Colors.white,
            letterSpacing: 1.1,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 2, 68, 100),
              Color.fromARGB(255, 2, 68, 100).withOpacity(0.45),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: kToolbarHeight + 36,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.32),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      imageUrl,
                      height: 216,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) =>
                              Center(child: Text("Image not available")),
                    ),
                  ),
                ),
              buildInfoCard(data),
              const SizedBox(height: 28),
              if (!isBidPlaced)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: buildBidForm(),
                ),
              if (isBidPlaced && !isediting)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 280),
                  child: buildBidSummary(),
                ),
              if (isBidPlaced && isediting)
                AnimatedSwitcher(
                  duration: Duration(milliseconds: 280),
                  child: buildBidUpdateForm(),
                ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget detailRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: accentColor.withOpacity(0.18),
            child: Icon(icon, color: primaryColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 15.4,
                  color: Colors.black87,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: "$label: ",
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: "$value"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget sectionTitle(String title, {double fontSize = 17}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, top: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          color: primaryColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // Widget buildInfoCard(Map<String, dynamic> data) {
  //   return Card(
  //     elevation: 10,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  //     margin: const EdgeInsets.all(3),
  //     color: _mainBgColor,
  //     child: Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 22),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           sectionTitle("Request Information", fontSize: 19),
  //           Divider(thickness: 1, color: Colors.blueGrey.withOpacity(0.21)),
  //           const SizedBox(height: 9),
  //           ...[
  //             detailRow(Icons.person, "customer name", data["customer_name"]),
  //             detailRow(
  //               Icons.confirmation_number,
  //               "Request ID",
  //               data["requestid"] ?? data["requestId"],
  //             ),
  //             detailRow(
  //               Icons.miscellaneous_services,
  //               "Service Type",
  //               data["type"] ?? "",
  //             ),
  //             detailRow(Icons.location_on, "Area", data["area"] ?? ""),
  //             detailRow(Icons.map, "Street", data["street"] ?? ""),
  //             detailRow(
  //               Icons.calendar_today,
  //               "Preferred Date",
  //               data["date"] ?? "",
  //             ),
  //             detailRow(
  //               Icons.access_time,
  //               "Preferred Time",
  //               data["time"] ?? "",
  //             ),
  //             detailRow(Icons.priority_high, "Urgency", data["urgency"] ?? ""),
  //             detailRow(Icons.verified, "Status", data["status"] ?? ""),
  //           ].expand((widget) => [widget, const SizedBox(height: 7)]).toList(),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget buildBidForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      elevation: 7,
      shadowColor: accentColor.withOpacity(0.18),
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            sectionTitle("Enter Bid Amount"),
            buildTextField(
              bidAmountController,
              "e.g. 5000",
              Icons.attach_money,
            ),
            const SizedBox(height: 19),
            sectionTitle("Enter Comment (Optional)"),
            buildTextField(
              commentController,
              "Add a comment...",
              Icons.comment,
              maxLines: 3,
            ),
            const SizedBox(height: 25),
            buildSubmitButton("Submit Bid", Icons.send, submitBid),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(Map<String, dynamic> data) {
    bool showAllDetails = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          margin: const EdgeInsets.all(3),
          color: _mainBgColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                sectionTitle("Request Information", fontSize: 19),
                Divider(thickness: 1, color: Colors.blueGrey.withOpacity(0.21)),
                const SizedBox(height: 9),
                ...[
                  detailRow(
                    Icons.person,
                    "customer name",
                    data["customer_name"],
                  ),
                  detailRow(
                    Icons.confirmation_number,
                    "Request ID",
                    data["requestid"] ?? data["requestId"],
                  ),
                  detailRow(
                    Icons.miscellaneous_services,
                    "Service Type",
                    data["type"] ?? "",
                  ),
                  if (showAllDetails) ...[
                    detailRow(Icons.location_on, "Area", data["area"] ?? ""),
                    detailRow(Icons.map, "Street", data["street"] ?? ""),
                    detailRow(
                      Icons.calendar_today,
                      "Preferred Date",
                      data["date"] ?? "",
                    ),
                    detailRow(
                      Icons.access_time,
                      "Preferred Time",
                      data["time"] ?? "",
                    ),
                    detailRow(
                      Icons.priority_high,
                      "Urgency",
                      data["urgency"] ?? "",
                    ),
                    detailRow(Icons.verified, "Status", data["status"] ?? ""),
                  ],
                ].expand((widget) => [widget, const SizedBox(height: 7)]),

                // Show More/Less button
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        showAllDetails = !showAllDetails;
                      });
                    },
                    child: Text(
                      showAllDetails ? "Show Less" : "Show More",
                      style: TextStyle(color: primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildBidSummary() {
    return Card(
      elevation: 9,
      color: Colors.green.shade50.withOpacity(0.65),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Text(
                  "Your Submitted Bid",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: Colors.green.shade700,
                  size: 22,
                ),
                const SizedBox(width: 7),
                Text(
                  "Amount:",
                  style: TextStyle(fontSize: 16.6, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 3),
                Text(
                  "₹${existingBid?['price'] ?? ''}",
                  style: TextStyle(fontSize: 16.7, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Icon(Icons.comment, color: Colors.blueGrey, size: 22),
                const SizedBox(width: 7),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16.2, color: Colors.black87),
                      children: [
                        TextSpan(
                          text: "Comment: ",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextSpan(
                          text: existingBid?['comments'] ?? 'No comment',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 21),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => isediting = true),
                icon: Icon(Icons.edit, color: Colors.white),
                label: Text(
                  "Update Bid",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBidUpdateForm() {
    return Card(
      elevation: 7,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Update Your Bid",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.3,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            buildTextField(
              bidAmountController,
              "Enter new bid",
              Icons.attach_money,
            ),
            const SizedBox(height: 15),
            buildTextField(
              commentController,
              "Update comment",
              Icons.comment,
              maxLines: 3,
            ),
            const SizedBox(height: 21),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSubmitting ? null : updateBid,
                    icon:
                        isSubmitting
                            ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Icon(Icons.check, color: Colors.white),
                    label: Text(
                      isSubmitting ? "Updating..." : "Submit Update",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => isediting = false),
                    icon: Icon(Icons.cancel, color: primaryColor),
                    label: Text(
                      "Cancel",
                      style: TextStyle(color: primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType:
            (icon == Icons.attach_money)
                ? TextInputType.number
                : TextInputType.text,
        style: TextStyle(color: Colors.black87, fontSize: 15.7),
        decoration: InputDecoration(
          fillColor: Colors.blue.shade50.withOpacity(0.6),
          filled: true,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.blueGrey.shade400, fontSize: 15),
          prefixIcon: Icon(icon, color: accentColor, size: 22),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(11)),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: accentColor.withOpacity(0.35)),
            borderRadius: BorderRadius.circular(11),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: accentColor, width: 2),
            borderRadius: BorderRadius.circular(11),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 13, horizontal: 15),
        ),
      ),
    );
  }

  Widget buildSubmitButton(String label, IconData icon, Function onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: isSubmitting ? null : () => onPressed(),
        icon:
            isSubmitting
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : Icon(icon, color: Colors.white),
        label: Text(
          isSubmitting ? "Submitting..." : label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: TextStyle(fontSize: 16, color: Colors.white),
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
        ),
      ),
    );
  }
}
