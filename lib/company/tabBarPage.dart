import 'package:flutter/material.dart';
import 'package:snowplow/company/Agency_pending.dart/agnecyBID.dart';
import 'package:snowplow/company/Agency_pending.dart/agency_direct_requests.dart';

class RequestsTabScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two tabs: Bid & Direct
      child: Column(
        children: [
          Container(
            color: const Color.fromARGB(255, 2, 68, 100),
            child: TabBar(
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [Tab(text: 'Bid Requests'), Tab(text: 'Direct Requests')],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                AgentRequestsPage(), // Your existing bid requests page
                DirectRequestsPage(), // Create this widget for direct requests
              ],
            ),
          ),
        ],
      ),
    );
  }
}
