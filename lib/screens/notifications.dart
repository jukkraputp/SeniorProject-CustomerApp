import 'dart:convert';

import 'package:customer/interfaces/order.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/all_order.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class Notifications extends StatefulWidget {
  const Notifications(
      {super.key,
      required this.allOrders,
      required this.notiList,
      required this.goTo});

  final FilteredOrders allOrders;
  final List<String> notiList;
  final void Function(int, {Map<String, dynamic>? option}) goTo;

  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('noti: ${widget.notiList}');
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Notifications",
        ),
        elevation: 0.0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 10, 10.0, 0),
        child: ListView.builder(
            itemCount: widget.notiList.length,
            itemBuilder: ((context, index) {
              Map<String, dynamic> obj =
                  json.decode(json.decode(widget.notiList[index]));
              String shopName = obj['shopName'];
              int orderId = obj['orderId'];
              return Column(
                children: <Widget>[
                  ListTile(
                    onTap: () async {
                      String noti = json
                          .encode({"orderId": orderId, "shopName": shopName});
                      widget.goTo(2,
                          option: {'order-tab': 'Ready', 'noti': noti});
                      Navigator.of(context).pop();
                    },
                    leading: const Icon(
                      FontAwesomeIcons.burger,
                      size: 50,
                      color: Colors.amber,
                    ),
                    title: Text('$shopName - Order #$orderId'),
                    subtitle: const Text('Your order has been ready!'),
                    trailing: const Icon(
                      Icons.check_circle,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  const Divider()
                ],
              );
            })),
      ),
    );
  }
}
