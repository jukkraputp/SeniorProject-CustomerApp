import 'dart:convert';

import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';

class Order {
  String uid;
  String? orderId;
  String shopName;
  String phoneNumber;
  List<ItemCounter> itemList;
  double cost;
  DateTime date;
  bool isFinished = false;
  String paymentStatus;

  Order(this.uid, this.shopName, this.phoneNumber, this.itemList, this.cost,
      this.date,
      {this.paymentStatus = 'Waiting for payment'});

  String toJsonEncoded() {
    List<Map<String, dynamic>> itemList = [];
    for (var itemCounter in this.itemList) {
      itemList.add({'itemId': itemCounter.item.id, 'count': itemCounter.count});
    }
    Map<String, dynamic> obj = {
      'uid': uid,
      'shopName': shopName,
      'phoneNumber': phoneNumber,
      'itemList': itemList,
      'cost': cost,
      'date': date.toIso8601String(),
      'isFinished': isFinished,
      'status': paymentStatus
    };
    if (orderId != null) {
      obj['orderId'] = orderId;
    }
    return json.encode(obj);
  }
}

class PaymentStatus {
  static String waitingForPayment = 'Waiting for payment';
  static String waitingForPaymentConfirmation =
      'Waiting for payment confirmation';
  static String paymentSuccessful = 'Payment successful';
}
