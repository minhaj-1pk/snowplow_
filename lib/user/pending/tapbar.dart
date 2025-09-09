import 'package:flutter/material.dart';

import 'package:snowplow/user/pending/bid_pending.dart';
import 'package:snowplow/user/pending/direct_pending.dart';

class PendingRequestsTabsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pending Requests'),
          backgroundColor: Colors.blue.withOpacity(0.7),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.gavel), text: 'Bid Requests'),
              Tab(icon: Icon(Icons.business_center), text: 'Direct Requests'),
            ],
          ),
        ),
        body: TabBarView(children: [BidRequestsPage(), RequestListScreen()]),
      ),
    );
  }
}
