import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/promptpay_qrcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen(
      {super.key,
      required this.shopInfo,
      required this.order,
      required this.orderStatus,
      required this.updateBasket});

  final ShopInfo shopInfo;
  final Order order;
  final String orderStatus;
  final Function(String, {Item? item, String mode}) updateBasket;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final API api = API();

  bool _ready = false;

  @override
  void initState() {
    super.initState();
    api.addOrder(widget.order).then((res) {
      print('addOrder Result: ${res.body}');
      Provider.of<AppProvider>(context, listen: false).clearBasket();
      setState(() {
        _ready = true;
      });
      widget.updateBasket(widget.shopInfo.name, mode: 'clear');
    });
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
      body: _ready
          ? Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, screenSize.width * 0.1),
              child: Center(
                child: Column(children: <Widget>[
                  Text('Status: ${widget.orderStatus}'),
                  PromptPayQRCode(
                    phoneNumber: widget.shopInfo.phoneNumber,
                    cost: widget.order.cost,
                  )
                ]),
              ))
          : Center(
              child:
                  Lottie.asset('assets/animations/colors-circle-loader.json'),
            ),
    );
  }
}
