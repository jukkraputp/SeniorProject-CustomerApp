import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/promptpay_qrcode.dart';
import 'package:customer/widgets/cart_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen(
      {super.key, required this.shopInfo, required this.order});

  final ShopInfo shopInfo;
  final Order order;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final API api = API();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    AppProvider appProvider = Provider.of<AppProvider>(context, listen: false);
    return Scaffold(
        appBar: AppBar(
            title: const Text('Order Status'),
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) {
                  if (route.settings.name == 'MainScreen') {
                    return true;
                  } else {
                    return false;
                  }
                });
              },
              icon: const Icon(Icons.home),
            )),
        body: ListView(
          children: [
            Padding(
                padding:
                    EdgeInsets.fromLTRB(10, 10, 10, screenSize.width * 0.1),
                child: Center(
                    child: Column(
                  children: <Widget>[
                    !widget.order.isPaid
                        ? Column(children: <Widget>[
                            const Text('Status: Waiting for payment'),
                            PromptPayQRCode(
                              phoneNumber: widget.shopInfo.phoneNumber,
                              cost: widget.order.cost,
                            )
                          ])
                        : !widget.order.isFinished
                            ? Column(children: const <Widget>[
                                Text('Status: Cooking'),
                                Icon(FontAwesomeIcons.truckLoading)
                              ])
                            : !widget.order.isCompleted
                                ? Column(children: const <Widget>[
                                    Text('Status: Ready'),
                                    Icon(FontAwesomeIcons.bowlFood)
                                  ])
                                : Column(children: const <Widget>[
                                    Text('Status: Order Completed'),
                                  ]),
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.025),
                    Container(
                      child: ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        primary: false,
                        shrinkWrap: true,
                        itemCount: widget.order.itemList.length,
                        itemBuilder: (BuildContext context, int index) {
                          ItemCounter itemCounter =
                              widget.order.itemList[index];
                          return CartItem(
                            shopName: widget.shopInfo.name,
                            itemCounter: itemCounter,
                            isFav: false,
                            adjustButtons: false,
                          );
                        },
                      ),
                    ),
                  ],
                )))
          ],
        ));
  }
}
