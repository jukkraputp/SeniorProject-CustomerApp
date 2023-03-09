import 'dart:convert';

import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/payment.dart';
import 'package:customer/interfaces/prefs_key.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:customer/util/const.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppProvider extends ChangeNotifier {
  AppProvider() {
    checkTheme();
    checkPaymentMethod();
  }

  ThemeData theme = Constants.lightTheme;
  Key key = UniqueKey();
  GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String paymentMethod = 'Cash';

  void setKey(value) {
    key = value;
    notifyListeners();
  }

  void setNavigatorKey(value) {
    navigatorKey = value;
    notifyListeners();
  }

  void setTheme(value, c) {
    theme = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString("theme", c).then((val) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
            overlays: SystemUiOverlay.values);
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor:
              c == "dark" ? Constants.darkPrimary : Constants.lightPrimary,
          statusBarIconBrightness:
              c == "dark" ? Brightness.light : Brightness.dark,
        ));
      });
    });
    notifyListeners();
  }

  ThemeData getTheme() {
    return theme;
  }

  Future<ThemeData> checkTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    ThemeData t;
    String r = prefs.getString("theme") ?? "light";

    if (r == "light") {
      t = Constants.lightTheme;
      setTheme(Constants.lightTheme, "light");
    } else {
      t = Constants.darkTheme;
      setTheme(Constants.darkTheme, "dark");
    }

    return t;
  }

  Future<Map<String, Basket>> getBasket(User user) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Map<String, Basket> basket = {};
    List<String>? shopList =
        prefs.getStringList(PrefsKey.basketShopList(user.email));
    if (shopList != null) {
      for (String shopName in shopList) {
        List<ItemCounter> itemList = [];
        List<String>? idList =
            prefs.getStringList(PrefsKey.basketIdList(shopName));
        if (idList != null) {
          for (String itemId in idList) {
            String? itemString =
                prefs.getString(PrefsKey.basketItemList(shopName).item(itemId));
            if (itemString != null) {
              dynamic obj = json.decode(itemString);
              Item item = Item(
                  name: obj['name'],
                  price: obj['price'],
                  time: obj['time'],
                  image: obj['image'],
                  id: obj['id'],
                  bytes: obj['bytes'],
                  rating: obj['rating'],
                  rater: obj['rater']);
              int? count =
                  prefs.getInt(PrefsKey.basketItemList(shopName).count(itemId));
              if (count != null) {
                ItemCounter itemCounter = ItemCounter(item, count);
                itemList.add(itemCounter);
              }
            }
          }
        }
        double? cost = prefs.getDouble(PrefsKey.basketCost(shopName));
        int? amount = prefs.getInt(PrefsKey.basketAmount(shopName));
        basket[shopName] =
            Basket(itemList: itemList, cost: cost, amount: amount);
      }
    }

    return basket;
  }

  Future<void> clearBasket() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String method = prefs.getString(PrefsKey.paymentMethod) ?? Payment.cash;
    String mode = prefs.getString(PrefsKey.theme) ?? 'light';
    prefs.clear();
    prefs.setString(PrefsKey.paymentMethod, method);
    if (mode == 'light') {
      setTheme(Constants.lightTheme, mode);
    } else if (mode == 'dark') {
      setTheme(Constants.darkTheme, mode);
    }
  }

  Future<String> checkPaymentMethod() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String method = prefs.getString(PrefsKey.paymentMethod) ?? Payment.cash;
    setPaymentMethod(method);
    return method;
  }

  String getPaymentMethod() {
    return paymentMethod;
  }

  Future<void> setPaymentMethod(String method) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PrefsKey.paymentMethod, method).whenComplete(() {
      String? currentMethod = prefs.getString(PrefsKey.paymentMethod);
    });
  }

  Future<void> setNotiStatus(bool status) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notiStatus', status);
  }

  Future<bool> getNotiStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool notiStatus = prefs.getBool('notiStatus') ?? false;
    return notiStatus;
  }

  Future<void> setNotiList(List<String> notiList) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notiList', notiList);
  }

  Future<List<String>> getNotiList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notiList = prefs.getStringList('notiList') ?? [];
    return notiList;
  }

  Future<bool> removeNoti(String noti) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notiList = prefs.getStringList('notiList') ?? [];
    notiList.remove(noti);
    return await prefs.setStringList('notiList', notiList);
  }

  Future<void> clearNotiList() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('notiList', []);
  }

  Future<bool> addOrderTopic(String shopName, String orderTopic) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> orderTopicList =
        prefs.getStringList('$shopName-orderTopicList') ?? [];
    orderTopicList.add(orderTopic);
    return await prefs.setStringList(
        '$shopName-orderTopicList', orderTopicList);
  }

  Future<List<String>> getOrderTopicList(String shopName) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('$shopName-orderTopicList') ?? [];
  }
}
