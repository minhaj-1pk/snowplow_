import 'package:flutter/material.dart';

import 'package:snowplow/user/USERCOMPANY_SIDE/companyreques.dart';

class CompanyDetailsPage extends StatelessWidget {
  final Map<String, dynamic> company;

  const CompanyDetailsPage({super.key, required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(company['name']),
        // ignore: deprecated_member_use
        backgroundColor: Colors.blue.withOpacity(0.7),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Company Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
                image:
                    company['image'] != null && company['image'].isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(company['image']),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  company['image'] == null || company['image'].isEmpty
                      ? Icon(
                        Icons.business,
                        size: 50,
                        color: Colors.blue.shade700,
                      )
                      : null,
            ),
            SizedBox(height: 16),

            // Name and ID
            Text(
              company['name'],
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              "ID: ${company['id']}",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24),

            // Detail Items in Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    _buildDetailItem(
                      Icons.location_on,
                      "Address",
                      company['address'],
                    ),
                    Divider(),
                    _buildDetailItem(Icons.email, "Email", company['email']),
                    // Uncomment as needed
                    Divider(),
                    _buildDetailItem(Icons.phone, "Phone", company['phone']),
                    // _buildDetailItem(Icons.language, "Website", company['website']),
                  ],
                ),
              ),
            ),

            // CTA Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => direct_to_agency(agencyid: company['id']),
                  ),
                );
              },
              icon: Icon(Icons.add),
              label: Text(
                "Add New Request",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: TextStyle(fontSize: 16, color: Colors.white),
                elevation: 3,
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blue.shade600),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
