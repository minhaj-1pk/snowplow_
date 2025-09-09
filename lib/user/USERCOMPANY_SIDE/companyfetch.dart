import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snowplow/user/USERCOMPANY_SIDE/companydetails.dart';

class CompanyListPage extends StatefulWidget {
  @override
  _CompanyListPageState createState() => _CompanyListPageState();
}

class _CompanyListPageState extends State<CompanyListPage> {
  List<Map<String, dynamic>> companies = [];
  List<Map<String, dynamic>> filteredCompanies = [];
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  List<String> allAgencyIds = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> fetchCompanies() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    final url = Uri.parse("http://snowplow.celiums.com/api/agencies/list");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"per_page": "100", "page": "0", "api_mode": "test"}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> agencyList = data['data'] ?? [];

        setState(() {
          allAgencyIds = [];

          companies =
              agencyList.map<Map<String, dynamic>>((agency) {
                final id = agency['agency_id']?.toString() ?? '';
                if (id.isNotEmpty) {
                  allAgencyIds.add(id);
                }
                return {
                  'id': id,
                  'name': agency['agency_name'] ?? '',
                  'image': agency['logo_url'] ?? '',
                  'address': agency['agency_address'] ?? '',
                  'email': agency['agency_email'] ?? '',
                  'phone': agency['agency_phone'] ?? '',
                };
              }).toList();

          filteredCompanies = List.from(companies);
          isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('allAgencyIds', jsonEncode(allAgencyIds));
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage =
              "Failed to load companies (Error ${response.statusCode})";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = "Connection error: ${e.toString()}";
      });
    }
  }

  void filterCompanies(String query) {
    final filtered =
        companies.where((company) {
          final name = company['name'].toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
    setState(() {
      filteredCompanies = filtered;
    });
  }

  Widget buildBannerHeader() {
    // Simple but visually striking banner/header
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withOpacity(0.6),
            radius: 26,
            child: Icon(
              Icons.business,
              size: 34,
              color: Colors.lightBlueAccent,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Browse Companies",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  "Explore, compare, and check company profiles!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSearchField() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.decelerate,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.lightBlueAccent.withOpacity(0.13),
              blurRadius: 10,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: TextField(
          controller: searchController,
          onChanged: filterCompanies,
          style: TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: "Search companies...",
            hintStyle: TextStyle(color: Colors.blueGrey.shade300),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.blue.shade400),
            suffixIcon:
                searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.blueGrey.shade300),
                      onPressed: () {
                        searchController.clear();
                        filterCompanies('');
                      },
                    )
                    : null,
            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget buildCompanyCard(Map<String, dynamic> company) {
    // Glass-like card with a little gradient, image, and icon overlay
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 95,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.28),
                      Colors.blue.withOpacity(0.11),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.10),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => CompanyDetailsPage(company: company),
                    ),
                  ),
              child: ListTile(
                leading: Container(
                  height: 57,
                  width: 57,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade200, Colors.blue.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
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
                            Icons.domain,
                            color: Colors.white.withOpacity(0.85),
                            size: 32,
                          )
                          : null,
                ),
                title: Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Text(
                    company['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: Colors.indigo.shade900,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.mail_outline,
                          size: 15,
                          color: Colors.blueGrey.shade400,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            company['email'],
                            style: TextStyle(
                              color: Colors.blueGrey.shade500,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (company['address']?.toString().trim().isNotEmpty ??
                        false)
                      Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: Colors.amber.shade600,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                company['address'],
                                style: TextStyle(
                                  fontSize: 12.7,
                                  color: Colors.blueGrey.shade400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.blue.shade400,
                ),
                contentPadding: EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
        ),
        SizedBox(height: 26),
        Text(
          "Loading companies...",
          style: TextStyle(
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 80.0),
      child: Column(
        children: [
          Icon(Icons.business, size: 54, color: Colors.blueGrey.shade200),
          SizedBox(height: 15),
          Text(
            "No companies found",
            style: TextStyle(
              color: Colors.blueGrey.shade600,
              fontSize: 17,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade300, size: 46),
          SizedBox(height: 13),
          Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red.shade800,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 18),
          OutlinedButton.icon(
            icon: Icon(Icons.refresh, color: Colors.blue),
            label: Text(
              "Retry",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.blue.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
            ),
            onPressed: fetchCompanies,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Companies",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchCompanies,
            tooltip: "Reload",
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade200.withOpacity(0.5),
              Colors.white,
              Colors.blue.shade50,
            ],
            stops: [0, 0.74, 1],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          bottom: false,
          child:
              isLoading
                  ? Center(child: buildLoadingState())
                  : hasError
                  ? buildErrorWidget()
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBannerHeader(),
                      buildSearchField(),
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.lightBlueAccent,
                          onRefresh: fetchCompanies,
                          child:
                              filteredCompanies.isEmpty
                                  ? ListView(children: [buildEmptyState()])
                                  : ListView.builder(
                                    itemCount: filteredCompanies.length,
                                    physics: BouncingScrollPhysics(),
                                    itemBuilder: (_, index) {
                                      final company = filteredCompanies[index];
                                      return buildCompanyCard(company);
                                    },
                                  ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
        ),
      ),
    );
  }
}
