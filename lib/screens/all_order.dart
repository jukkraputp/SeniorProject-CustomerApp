import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/order_status.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_countdown_timer/flutter_countdown_timer.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AllOrderScreen extends StatefulWidget {
  const AllOrderScreen(
      {super.key,
      required this.shopList,
      required this.allOrders,
      this.initialTab = 0,
      required this.setInitialTab,
      required this.orderStatus,
      required this.setOrderListener});

  final List<ShopInfo> shopList;
  final FilteredOrders allOrders;
  final int initialTab;
  final void Function(int) setInitialTab;
  final Map<String, OrderQueue> orderStatus;
  final void Function(
      {required Stream<DatabaseEvent> orderListener,
      required String ownerUID,
      required String shopName,
      required int orderId}) setOrderListener;

  @override
  State<AllOrderScreen> createState() => _AllOrderScreenState();
}

class _AllOrderScreenState extends State<AllOrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // order state = cooking --> ready --> completed

  FilteredOrders filteredOrders = FilteredOrders();

  @override
  void initState() {
    super.initState();
    // setOrderListeners();
    late int initialTab;
    if ((widget.initialTab >= 0) & (widget.initialTab < 3)) {
      initialTab = widget.initialTab;
    } else {
      initialTab = 0;
    }
    _tabController =
        TabController(vsync: this, initialIndex: initialTab, length: 3);
  }

  void setOrderListeners() {
    for (var shopInfo in widget.shopList) {
      for (Order order in widget
              .allOrders.cooking['${shopInfo.ownerUID}-${shopInfo.name}'] ??
          []) {
        if (!widget.orderStatus.containsKey(
            '${shopInfo.ownerUID}-${shopInfo.name}-order${order.orderId}')) {
          var ref = FirebaseDatabase.instance.ref(
              'Order/${shopInfo.ownerUID}-${shopInfo.name}/${order.date.year}/${order.date.month}/${order.date.day}');
          Stream<DatabaseEvent> orderListener = ref.onValue;
          setState(() {
            widget.setOrderListener(
                orderListener: orderListener,
                ownerUID: shopInfo.ownerUID,
                shopName: shopInfo.name,
                orderId: order.orderId!);
          });
        }
      }
    }
  }

  Widget createBody(String type) {
    Size screenSize = MediaQuery.of(context).size;
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
      return const Center(
          child: Text(
        "You have no order yet\n\nLet's order something to bite!",
        textAlign: TextAlign.center,
      ));
    }
    List<Widget> widgetList = [];
    for (var shopKey in map.keys) {
      List<Order> orderList = map[shopKey]!;
      if (type != 'completed') {
        orderList.sort((a, b) => a.date.compareTo(b.date));
      } else {
        orderList.sort((a, b) => b.date.compareTo(a.date));
      }
      for (var order in orderList) {
        int? queue = widget
            .orderStatus[
                '${order.ownerUID}-${order.shopName}-order${order.orderId}']
            ?.currentOrder;
        num? time = widget
            .orderStatus[
                '${order.ownerUID}-${order.shopName}-order${order.orderId}']
            ?.time;
        int targetEpoch = order.date
            .add(Duration(minutes: time?.toInt() ?? 0))
            .millisecondsSinceEpoch;
        int currentEpoch = DateTime.now().toUtc().millisecondsSinceEpoch;
        Widget w = Padding(
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          child: SizedBox(
              height: screenSize.height * 0.1,
              child: ElevatedButton(
                style: ButtonStyle(backgroundColor:
                    MaterialStateProperty.resolveWith<Color?>(
                        (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed)) {
                    return Theme.of(context).colorScheme.primary;
                  }
                  return Theme.of(context).colorScheme.secondary;
                })),
                onPressed: () {
                  ShopInfo? shopInfo;
                  for (var shop in widget.shopList) {
                    if ((shop.ownerUID == order.ownerUID) &&
                        (shop.name == order.shopName)) {
                      shopInfo = shop;
                      break;
                    }
                  }
                  if (shopInfo != null) {
                    Navigator.of(context)
                        .push(MaterialPageRoute(builder: ((context) {
                      return OrderStatusScreen(
                        shopInfo: shopInfo!,
                        order: order,
                      );
                    })));
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding:
                              EdgeInsets.only(right: screenSize.width * 0.025),
                          child: const Icon(FontAwesomeIcons.shop),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(DateFormat('dd MMM yy - HH:mm')
                                .format(order.date)),
                            Text('ร้าน ${order.shopName}'),
                            if (order.orderId != null)
                              Text('Order #${order.orderId}')
                          ],
                        ),
                        if (type == 'cooking')
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.05,
                          ),
                        if (type == 'cooking')
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              queue != 0
                                  ? Text('Queue #$queue')
                                  : const Text('Cooking'),
                              if (targetEpoch - currentEpoch > 0)
                                CountdownTimer(
                                  endTime: targetEpoch,
                                )
                              else
                                const Text('กำลังจะเสร็จในไม่ช้า'),
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
        widgetList.add(const Divider());
      }
    }
    return ListView(
      children: widgetList,
    );
  }

  @override
  Widget build(BuildContext context) {
    for (var orderList in filteredOrders.cooking.values) {
      for (var order in orderList) {
        print('shopName: ${order.shopName}, orderId: ${order.orderId}');
      }
    }
    ThemeData theme =
        Provider.of<AppProvider>(context, listen: false).getTheme();
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
      body: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[cookingBody, readyBody, completedBody],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.setInitialTab(_tabController.index);
    super.dispose();
  }
}
