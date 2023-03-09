import 'dart:convert';

import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/payment.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/order_status.dart';
import 'package:customer/screens/payment.dart';
import 'package:customer/util/confirmation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:customer/util/foods.dart';
import 'package:customer/widgets/cart_item.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class Checkout extends StatefulWidget {
  const Checkout(
      {super.key,
      required this.user,
      required this.shopInfo,
      required this.basket,
      required this.updateBasket,
      required this.setOrderListener});

  final User user;
  final ShopInfo shopInfo;
  final Basket basket;
  final void Function(
      {required String ownerUID,
      required String shopName,
      Item? item,
      String mode}) updateBasket;
  final void Function(
      {required Stream<DatabaseEvent> orderListener,
      required String ownerUID,
      required String shopName,
      required int orderId}) setOrderListener;

  @override
  _CheckoutState createState() => _CheckoutState();
}

class _CheckoutState extends State<Checkout> {
  final API api = API();
  final TextEditingController _couponlControl = TextEditingController();
  String paymentMethod = Payment.cash;

  @override
  void initState() {
    super.initState();
    setPaymentMethod();
  }

  void setPaymentMethod() {
    Provider.of<AppProvider>(context, listen: false)
        .checkPaymentMethod()
        .then((value) {
      setState(() {
        paymentMethod = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout",
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
        elevation: 0.0,
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(10.0, 0, 10.0, screenSize.height * 0.1),
        child: ListView(
          children: <Widget>[
            const SizedBox(height: 20.0),
            const Text(
              "Items",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            ListView.builder(
              primary: false,
              shrinkWrap: true,
              itemCount: widget.basket.itemList.length,
              itemBuilder: (BuildContext context, int index) {
                ItemCounter itemCounter = widget.basket.itemList[index];
                return CartItem(
                  shopInfo: widget.shopInfo,
                  itemCounter: itemCounter,
                  isFav: false,
                  updateBasket: widget.updateBasket,
                  adjustButtons: false,
                );
              },
            ),
            const SizedBox(height: 10.0),
            const Text(
              "Payment Method",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
            Card(
              elevation: 4.0,
              child: ListTile(
                title: Text(paymentMethod),
                subtitle: paymentMethod == Payment.mobileBanking
                    ? const Text(
                        "... Bank",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
                leading: Icon(
                  paymentMethod == Payment.cash
                      ? FontAwesomeIcons.moneyBillWave
                      : paymentMethod == Payment.promptpay
                          ? FontAwesomeIcons.qrcode
                          : FontAwesomeIcons.bank,
                  size: screenSize.width * 0.125,
                  color: Theme.of(context).accentColor,
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: ((context) {
                    return PaymentSelectionScreen(
                      setPaymentMethod: setPaymentMethod,
                    );
                  }))),
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Card(
        elevation: 4.0,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 5, 5, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          "฿ ${widget.basket.cost}",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(5, 5, 10, 5),
                    width: 150.0,
                    height: 50.0,
                    child: ElevatedButton(
                      child: Text(
                        "Place Order".toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      onPressed: () {
                        confirmation(context,
                            onYes: () {
                              Navigator.of(context).pop();
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return Center(
                                      child: Lottie.asset(
                                          'assets/animations/colors-circle-loader.json'),
                                    );
                                  });
                              DateTime dateTime = DateTime.now().toUtc();
                              Order order = Order(
                                  uid: widget.user.uid,
                                  ownerUID: widget.shopInfo.ownerUID,
                                  shopName: widget.shopInfo.name,
                                  phoneNumber: widget.shopInfo.phoneNumber,
                                  itemList: widget.basket.itemList,
                                  cost: widget.basket.cost,
                                  date: dateTime);
                              api.addOrder(order).then((res) {
                                Map<String, dynamic> resBody =
                                    json.decode(res.body);
                                int orderId = resBody['orderId'];

                                String path =
                                    'Order/${widget.shopInfo.ownerUID}-${widget.shopInfo.name}/${dateTime.year}/${dateTime.month}/${dateTime.day}';
                                print('after add: $path');
                                var ref = FirebaseDatabase.instance.ref(path);
                                Stream<DatabaseEvent> orderListener =
                                    ref.onValue;
                                widget.setOrderListener(
                                    orderListener: orderListener,
                                    ownerUID: widget.shopInfo.ownerUID,
                                    shopName: widget.shopInfo.name,
                                    orderId: orderId);
                                if (res.statusCode == 200) {
                                  try {
                                    String topic =
                                        json.decode(res.body)['orderTopic'];
                                    print('topic: $topic');
                                    FirebaseMessaging.instance
                                        .subscribeToTopic(topic)
                                        .whenComplete(
                                            () => print('subscribed'));
                                  } catch (_) {
                                    print(_);
                                  }
                                }
                                order.orderId = resBody['orderId'];
                                Provider.of<AppProvider>(context, listen: false)
                                    .clearBasket();
                                widget.updateBasket(
                                    ownerUID: widget.shopInfo.ownerUID,
                                    shopName: widget.shopInfo.name,
                                    mode: 'clear');
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                    MaterialPageRoute(builder: ((context) {
                                  return OrderStatusScreen(
                                    shopInfo: widget.shopInfo,
                                    order: order,
                                  );
                                })));
                              });
                            },
                            onNo: () => Navigator.of(context).pop(),
                            title: const Text('Order Confirmation'),
                            content:
                                const Text('Are you sure to place an order?'));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
