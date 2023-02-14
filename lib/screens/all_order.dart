import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/order_status.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AllOrderScreen extends StatefulWidget {
  const AllOrderScreen({super.key, required this.allOrders});

  final FilteredOrders allOrders;

  @override
  State<AllOrderScreen> createState() => _AllOrderScreenState();
}

class _AllOrderScreenState extends State<AllOrderScreen>
    with SingleTickerProviderStateMixin {
  final API api = API();
  late TabController _tabController;

  // order state = cooking --> ready --> completed

  FilteredOrders filteredOrders = FilteredOrders();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, initialIndex: 0, length: 3);
  }

  FilteredOrders filterOrders(Map<String, List<int>> allOrders) {
    FilteredOrders filtered = FilteredOrders();
    for (var key in allOrders.keys) {
      List list = allOrders[key]!;
      print('all order: $list');
    }
    return filtered;
  }

  Widget createBody(String type) {
    Map<String, List<Order>> map = {};
    switch (type) {
      case 'cooking':
        map = widget.allOrders.cooking;
        break;
      case 'ready':
        map = widget.allOrders.ready;
        break;
      case 'completed':
        map = widget.allOrders.completed;
        break;
    }
    if (map.isEmpty) {
      return const Center(child: Text('no data'));
    }
    List<Widget> widgetList = [];
    for (var shopName in map.keys) {
      List<Order> orderList = map[shopName]!;
      for (var order in orderList) {
        Widget w = Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Container(
              decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(width: 0.1))),
              margin: const EdgeInsets.only(left: 10),
              height: MediaQuery.of(context).size.height * 0.1,
              child: ElevatedButton(
                onPressed: () {
                  api.getShopInfo(shopName).then((shopInfo) {
                    if (shopInfo != null) {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: ((context) {
                        return OrderStatusScreen(
                          shopInfo: shopInfo,
                          order: order,
                        );
                      })));
                    }
                  });

                  ;
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(FontAwesomeIcons.shop),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.05,
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(DateFormat('dd MMM yy - HH:mm')
                                .format(order.date)),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.01,
                            ),
                            Text(order.shopName),
                          ],
                        ),
                      ],
                    ),
                    Text('฿ ${order.cost.toString()}')
                  ],
                ),
              )),
        );
        widgetList.add(w);
      }
    }
    return ListView(
      children: widgetList,
    );
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme =
        Provider.of<AppProvider>(context, listen: false).getTheme();
    print('allOrders: ${widget.allOrders}');
    // filterOrders(widget.allOrders);
    Widget cookingBody = createBody('cooking');
    Widget readyBody = createBody('ready');
    Widget completedBody = createBody('completed');
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.secondary,
        labelColor: Theme.of(context).colorScheme.secondary,
        unselectedLabelColor: theme.unselectedWidgetColor,
        labelStyle: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w800,
        ),
        tabs: const <Widget>[
          Tab(
            text: "Cooking",
          ),
          Tab(
            text: "Ready",
          ),
          Tab(
            text: "Completed",
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[cookingBody, readyBody, completedBody],
      ),
    );
  }
}
