import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_fs;
import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/payment.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/promptpay_qrcode.dart';
import 'package:customer/util/select_image.dart';
import 'package:customer/widgets/cart_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

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
  final ImagePicker _picker = ImagePicker();

  late StreamSubscription<cloud_fs.QuerySnapshot<Map<String, dynamic>>>
      orderListener;

  bool _showSavingQR = false;
  bool _closingDialog = false;

  @override
  void initState() {
    super.initState();
    String date =
        '${widget.order.date.year}/${widget.order.date.month}/${widget.order.date.day}';
    api
        .getOrder(
            ownerUID: widget.order.ownerUID,
            shopName: widget.order.shopName,
            orderId: widget.order.orderId!,
            date: date)
        .then((streamQuery) {
      orderListener = streamQuery.listen((event) {
        for (var docChange in event.docChanges) {
          var doc = docChange.doc;
          if (doc.exists) {
            var data = doc.data();
            setState(() {
              widget.order.paymentImage = data?['paymentImage'];
            });
          }
        }
      });
    });

    Permission.notification.isGranted.then((isGranted) {
      if (!isGranted) {
        Permission.notification.request();
      }
    });
  }

  void setListener() async {}

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    AppProvider appProvider = Provider.of<AppProvider>(context, listen: false);
    if (_showSavingQR) {
      if (_closingDialog) {
        setState(() {
          _closingDialog = false;
          _showSavingQR = false;
          Navigator.of(context).pop();
        });
      }
    } else if (_closingDialog) {
      setState(() {
        _closingDialog = false;
      });
    }
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
                            const Text('Payment Status: ยังไม่ได้จ่ายเงิน'),
                            IconButton(
                              iconSize: screenSize.width * 0.5,
                              onPressed: () async {
                                http.Response res = await http.get(Uri.parse(
                                    PromptPay.qrcode(widget.order.phoneNumber,
                                        widget.order.cost)));
                                final result =
                                    await ImageGallerySaver.saveImage(
                                        res.bodyBytes);
                                if (result['isSuccess']) {
                                  setState(() {
                                    _showSavingQR = true;
                                  });
                                  showDialog(
                                      context: context,
                                      builder: (context) {
                                        Future.delayed(
                                            const Duration(seconds: 5), () {
                                          setState(() {
                                            _closingDialog = true;
                                          });
                                        });
                                        return AlertDialog(
                                          title: const Text(
                                              'QR Code has been saved'),
                                          actions: <Widget>[
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _closingDialog = true;
                                                  });
                                                },
                                                child: const Text('OK'))
                                          ],
                                        );
                                      });
                                }
                              },
                              icon: PromptPayQRCode(
                                phoneNumber: widget.shopInfo.phoneNumber,
                                cost: widget.order.cost,
                              ),
                            ),
                            if (widget.order.paymentImage != null)
                              CachedNetworkImage(
                                  height: screenSize.width * 0.5,
                                  width: screenSize.width * 0.5,
                                  fit: BoxFit.cover,
                                  imageUrl: widget.order.paymentImage!),
                            // ---------- upload image button ---------- //
                            TextButton(
                              style: TextButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).toggleableActiveColor),
                              onPressed: () async {
                                var res = await selectImage(_picker);
                                if (res != null) {
                                  String date =
                                      '${widget.order.date.year}/${widget.order.date.month}/${widget.order.date.day}';
                                  api
                                      .uploadPaymentImage(
                                          ownerUID: widget.order.ownerUID,
                                          shopName: widget.order.shopName,
                                          date: date,
                                          orderId: widget.order.orderId!,
                                          bytesImage: res.bytes)
                                      .then((res) {
                                    print(res.body);
                                  });
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                  Icon(
                                    Icons.upload,
                                    color: Colors.white,
                                  ),
                                  Divider(),
                                  Text(
                                    'อัพโหลด หลักฐานการจ่ายเงิน',
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                            ),
                            const Divider()
                          ])
                        : const Text('Payment Status: Paid'),
                    !widget.order.isFinished
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const <Widget>[
                                Text('Status: Cooking'),
                                Icon(FontAwesomeIcons.bowlFood)
                              ])
                        : !widget.order.isCompleted
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
                                    Text('Status: Ready'),
                                    Icon(FontAwesomeIcons.check)
                                  ])
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const <Widget>[
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
                            shopInfo: widget.shopInfo,
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

  @override
  void dispose() {
    orderListener.cancel();
    super.dispose();
  }
}
