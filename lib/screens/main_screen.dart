import 'dart:convert';

import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/prefs_key.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/all_order.dart';
import 'package:customer/screens/inbox.dart';
import 'package:customer/screens/shop.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:customer/screens/cart.dart';
import 'package:customer/screens/home.dart';
import 'package:customer/screens/notifications.dart';
import 'package:customer/screens/profile.dart';
import 'package:customer/util/const.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user});

  final User user;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  int _page = 0;
  final List<String> _pageName = ['Home', 'Basket', 'Order', 'Menu'];
  List<ShopInfo> shopList = [];
  bool _dataReady = false;
  final API api = API();
  Map<String, Basket> allBasket = {};
  String mainScreenTitle = Constants.appName;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    api.getShopList().then((value) {
      print('MainScreen: ${value}');
      setState(() {
        shopList = value;
        setBasket();
      });
    });
  }

  Future<void> updateAllOrders() async {
    var data = await api.getAllOrders(widget.user.uid);
  }

  void setBasket() {
    Provider.of<AppProvider>(context, listen: false)
        .getBasket(widget.user)
        .then((value) {
      print('basket: $value');
      if (value.isEmpty) {
        for (var shopInfo in shopList) {
          String shopName = shopInfo.name;
          value.addAll({'$shopName': Basket()});
        }
      }
      setState(() {
        allBasket = value;
        _dataReady = true;
      });
    });
  }

  void printBasket() {
    dynamic obj = {};
    for (String shopName in allBasket.keys) {
      List<dynamic> list = [];
      for (var itemCounter in allBasket[shopName]!.itemList) {
        Item item = itemCounter.item;
        print('item image: ${item.image}');
        int count = itemCounter.count;
        list.add({'item': item, 'count': count});
      }
      obj[shopName] = list;
    }
    print('Provider Basket: $obj');
  }

  void updateBasket(String shopName, {Item? item, String mode = '+'}) async {
    if (mode == 'clear' && allBasket.containsKey(shopName)) {
      allBasket[shopName]!.clear();
    }
    if (item == null || !allBasket.containsKey(shopName)) return;
    print('updateBasket');
    if (mode == '+') {
      setState(() {
        allBasket[shopName]!.addItem(item);
      });
    } else if (mode == '-') {
      setState(() {
        allBasket[shopName]!.removeItem(item, amount: 1);
      });
    } else {
      print('updateBasket::wrong mode');
    }
    await saveToPrefs();
    if (allBasket[shopName]!.itemList.isEmpty && _pageName[_page] == 'Home') {
      Navigator.of(context).pop();
    }
  }

  Widget showCartAll() {
    Size screenSize = MediaQuery.of(context).size;
    int itemCount = 0;
    List<String> showShopList = [];
    for (var shopName in allBasket.keys) {
      if (allBasket[shopName]!.itemList.isNotEmpty) {
        itemCount += 1;
        showShopList.add(shopName);
      }
    }
    ListView cartWidget = ListView.builder(
        itemCount: itemCount,
        itemBuilder: ((context, index) {
          String shopName = showShopList[index];
          print(shopName);
          return ElevatedButton(
              onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(builder: ((context) {
                    return Shop(
                        user: widget.user,
                        shopInfo: shopList[index],
                        basket: allBasket[shopName]!,
                        updateBasket: updateBasket);
                  }))),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Container(
                      alignment: Alignment.topLeft,
                      child: Text(
                        shopName,
                        style:
                            const TextStyle(color: Colors.black, fontSize: 24),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Container(
                      height: screenSize.height / 2,
                      color: Colors.white,
                      child: Cart(
                        user: widget.user,
                        shopInfo: shopList[index],
                        basket: allBasket[shopName]!,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        updateBasket: updateBasket,
                        checkout: false,
                      ),
                    ),
                  )
                ],
              ));
        }));
    return cartWidget;
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Provider.of<AppProvider>(context, listen: false).theme;
    print('MainScreen Page: ${_pageName[_page]}');
    printBasket();
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(mainScreenTitle),
            elevation: 0.0,
            backgroundColor: theme.appBarTheme.backgroundColor,
            actions: <Widget>[
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  size: 22.0,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return Notifications();
                      },
                    ),
                  );
                },
                tooltip: "Notifications",
              ),
            ],
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: onPageChanged,
            children: <Widget>[
              Home(
                user: widget.user,
                shopList: shopList,
                dataReady: _dataReady,
                allBasket: allBasket,
                updateBasket: updateBasket,
              ),
              showCartAll(),
              AllOrderScreen(),
              Profile(user: widget.user),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).primaryColor,
            shape: const CircularNotchedRectangle(),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const SizedBox(width: 7),
                IconButton(
                  icon: const Icon(
                    FontAwesomeIcons.house,
                    size: 24.0,
                  ),
                  color: _pageName[_page] == 'Home'
                      ? Theme.of(context).colorScheme.secondary
                      : theme.bottomNavigationBarTheme.unselectedItemColor,
                  onPressed: () {
                    navigationTapped(0);
                  },
                ),
                IconButton(
                  onPressed: () {
                    navigationTapped(1);
                  },
                  icon: const Icon(FontAwesomeIcons.basketShopping),
                  color: _pageName[_page] == 'Basket'
                      ? Theme.of(context).colorScheme.secondary
                      : theme.bottomNavigationBarTheme.unselectedItemColor,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fastfood,
                    size: 24.0,
                  ),
                  color: _pageName[_page] == 'Order'
                      ? Theme.of(context).colorScheme.secondary
                      : theme.bottomNavigationBarTheme.unselectedItemColor,
                  onPressed: () {
                    navigationTapped(2);
                    api.getAllOrders(widget.user.uid);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.menu,
                    size: 24.0,
                  ),
                  color: _pageName[_page] == 'Menu'
                      ? Theme.of(context).colorScheme.secondary
                      : theme.bottomNavigationBarTheme.unselectedItemColor,
                  onPressed: () {
                    navigationTapped(3);
                  },
                ),
                const SizedBox(width: 7),
              ],
            ),
          )),
    );
  }

  void navigationTapped(int page) {
    _pageController.jumpToPage(page);
  }

  Future<void> saveToPrefs() async {
    print('saving basket');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        PrefsKey.basketShopList(widget.user.email), allBasket.keys.toList());
    for (String shopName in allBasket.keys) {
      List<ItemCounter> itemList = allBasket[shopName]!.itemList;
      print(itemList.length);
      double cost = allBasket[shopName]!.cost;
      int amount = allBasket[shopName]!.amount;
      print('basket cost: $cost');
      print('basket amount: $amount');
      List<String> idList = [];
      for (ItemCounter itemCounter in itemList) {
        Item item = itemCounter.item;
        int count = itemCounter.count;
        idList.add(item.id);
        print('itemId: ${item.id}');
        prefs.setString(
            PrefsKey.basketItemList(shopName).item(item.id),
            json.encode({
              'name': item.name,
              'price': item.price,
              'image': item.image,
              'id': item.id,
              'bytes': item.bytes,
              'delete': item.delete,
              'rating': item.rating,
              'rater': item.rater
            }));
        prefs.setInt(PrefsKey.basketItemList(shopName).count(item.id), count);
      }
      prefs.setDouble(PrefsKey.basketCost(shopName), cost);
      prefs.setInt(PrefsKey.basketAmount(shopName), amount);
      prefs.setStringList(PrefsKey.basketIdList(shopName), idList);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  void onPageChanged(int page) {
    setState(() {
      _page = page;
      switch (_pageName[page]) {
        case 'Home':
          mainScreenTitle = Constants.appName;
          break;
        case 'Basket':
          mainScreenTitle = 'Basket';
          break;
        case 'Order':
          mainScreenTitle = 'My Order';
          break;
        default:
          mainScreenTitle = 'Menu';
      }
    });
  }
}
