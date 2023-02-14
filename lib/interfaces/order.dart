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
  bool isCompleted;
  bool isFinished;
  bool isPaid;

  Order(this.uid, this.shopName, this.phoneNumber, this.itemList, this.cost,
      this.date,
      {this.isCompleted = false, this.isFinished = false, this.isPaid = false});

  String toJsonEncoded() {
    List<Map<String, dynamic>> itemList = [];
    for (var itemCounter in this.itemList) {
      itemList.add({
        'name': itemCounter.item.name,
        'price': itemCounter.item.price,
        'id': itemCounter.item.id,
        'image': itemCounter.item.image,
        'count': itemCounter.count
      });
    }
    Map<String, dynamic> obj = {
      'uid': uid,
      'shopName': shopName,
      'phoneNumber': phoneNumber,
      'itemList': itemList,
      'cost': cost,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'isFinished': isFinished,
      'isPaid': isPaid
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

class FilteredOrders {
  Map<String, List<Order>> cooking = {};
  Map<String, List<Order>> ready = {};
  Map<String, List<Order>> completed = {};

  int length() {
    int res = 0;
    for (var key in cooking.keys) {
      List list = cooking[key]!;
      res += list.length;
    }
    for (var key in ready.keys) {
      List list = cooking[key]!;
      res += list.length;
    }
    for (var key in completed.keys) {
      List list = cooking[key]!;
      res += list.length;
    }
    return res;
  }
}
