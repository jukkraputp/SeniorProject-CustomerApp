import 'dart:async';
import 'dart:convert';

import 'package:badges/badges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/menu_list.dart';
import 'package:customer/interfaces/order.dart' as food_order;
import 'package:customer/interfaces/prefs_key.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/all_order.dart';
import 'package:customer/screens/shop.dart';
import 'package:customer/util/number.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:customer/screens/cart.dart';
import 'package:customer/screens/home.dart';
import 'package:customer/screens/notifications.dart';
import 'package:customer/screens/profile.dart';
import 'package:customer/util/const.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as google_map;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key, required this.user, this.bgMessageData});

  final User user;
  final Map<String, dynamic>? bgMessageData;

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late StreamSubscription<RemoteMessage> messageListener;
  late StreamSubscription<QuerySnapshot<Map<String, dynamic>>>
      allOrdersListener;
  late PageController _pageController;
  final API api = API();
  final List<String> _pageName = ['Home', 'Basket', 'Order', 'Menu'];

  Map<String, StreamSubscription<DatabaseEvent>> _orderListeners = {};
  Map<String, food_order.OrderQueue> _orderStatus = {};

  Map<String, MenuList> menuListObj = {};
  List<String> shopData = [];
  int _page = 0;
  List<ShopInfo> shopList = [];
  bool _dataReady = false;
  Map<String, Basket> allBasket = {};
  String mainScreenTitle = Constants.appName;
  food_order.FilteredOrders allOrders = food_order.FilteredOrders();
  List<String> noti = [];
  bool showNotiBadge = false;
  int orderInitialTab = 0;
  Position? _position;
  bool _init = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    AppProvider appProvider = Provider.of<AppProvider>(context, listen: false);

    // Test if location services are enabled.
    Geolocator.isLocationServiceEnabled().then((value) {
      print('location service: $value');
      if (!value) {
        // Location services are not enabled don't continue
        // accessing the position and request users of the
        // App to enable the location services.
      } else {
        getPermission().then((isGranted) {
          print('LocationPermission: $isGranted');
        });
      }
    });

    api.getAllOrders(widget.user.uid).then((collectionStream) {
      allOrdersListener = collectionStream.listen((event) {
        print('event: $event');
        api
            .allOrdersEventHandler(event, widget.user.uid)
            .then((filteredOrders) {
          if (_init) {
            print('initial');
            _init = false;
            filteredOrders.cooking.forEach(
              (key, value) {
                for (var order in value) {
                  var ref = FirebaseDatabase.instance.ref(
                      'Order/${order.ownerUID}-${order.shopName}/${order.date.year}/${order.date.month}/${order.date.day}');
                  Stream<DatabaseEvent> orderListener = ref.onValue;
                  setOrderListener(
                      orderListener: orderListener,
                      ownerUID: order.ownerUID,
                      shopName: order.shopName,
                      orderId: order.orderId!);
                }
              },
            );
          }

          setState(() {
            print('setting getAllOrders');
            allOrders = filteredOrders;
          });
        });
      });
    });

    messageListener =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('onMessage - event: $message');
      if (message.data['message'] == 'finishOrder') {
        appProvider.setNotiStatus(true);
        var jsonStr = json.encode(message.data['data']);
        print(jsonStr);
        print(message.from!.split('/'));
        setState(() {
          noti.add(jsonStr);
          appProvider.setNotiList(noti);
          showNotiBadge = true;
          if (message.from != null) {
            String topic = message.from!.split('/').last;
            FirebaseMessaging.instance.unsubscribeFromTopic(topic);
          }
        });
      }
    }, cancelOnError: true);
  }

  void saveMenuData(ShopInfo shopInfo, MenuList menuList) {
    setState(() {
      String shopKey = '${shopInfo.ownerUID}-${shopInfo.name}';
      menuListObj[shopKey] = menuList;
      shopData.add(shopKey);
    });
  }

  Future<void> setShopList(Position position) async {
    AppProvider appProvider = Provider.of<AppProvider>(context, listen: false);
    var value = await api.getShopList(position);
    var notiStatus = await appProvider.getNotiStatus();
    var notiList = await appProvider.getNotiList();
    setState(() {
      shopList = value;
      showNotiBadge = notiStatus;
      noti = notiList;
      setBasket();
    });
  }

  Future<bool> getPermission() async {
    bool isGranted = false;
    var permission = await Geolocator.checkPermission();

    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        Navigator.of(context).pop();
      } else {
        isGranted = true;
      }
    } else {
      isGranted = true;
    }
    if (isGranted) {
      var pos = await Geolocator.getCurrentPosition();
      setState(() {
        _position = pos;
      });
      await setShopList(pos);
    }
    return isGranted;
  }

  void setBasket() {
    Provider.of<AppProvider>(context, listen: false)
        .getBasket(widget.user)
        .then((value) {
      if (value.isEmpty) {
        for (var shopInfo in shopList) {
          String ownerUID = shopInfo.ownerUID;
          String shopName = shopInfo.name;
          value.addAll({'$ownerUID-$shopName': Basket()});
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

  void updateBasket(
      {required String ownerUID,
      required String shopName,
      Item? item,
      String mode = '+'}) {
    String shopKey = '$ownerUID-$shopName';
    if (mode == 'clear' && allBasket.containsKey(shopKey)) {
      allBasket[shopKey]!.clear();
    }
    if (item == null || !allBasket.containsKey(shopKey)) return;
    if (mode == '+') {
      setState(() {
        allBasket[shopKey]!.addItem(item);
      });
    } else if (mode == '-') {
      setState(() {
        allBasket[shopKey]!.removeItem(item, amount: 1);
      });
    } else {
      print('updateBasket::wrong mode');
    }
    saveToPrefs();
    if (allBasket[shopKey]!.itemList.isEmpty && _pageName[_page] == 'Home') {
      Navigator.of(context).pop();
    }
  }

  void setOrderListener(
      {required Stream<DatabaseEvent> orderListener,
      required String ownerUID,
      required String shopName,
      required int orderId}) {
    var listener = orderListener.listen((event) {
      var snapshot = event.snapshot;

      if (snapshot.exists) {
        Map<String, dynamic> data = json.decode(json.encode(snapshot.value));

        int currentOrder = 999999;
        double time = 0;
        String orderKey = '$ownerUID-$shopName-order$orderId';
        data.forEach((key, value) {
          if (!value['isFinished']) {
            int streamOrderId = int.parse(key.split('order').last);
            if (currentOrder > streamOrderId) {
              currentOrder = streamOrderId;
            }
            if (streamOrderId <= orderId) {
              time += value['totalTime'];
            }
          }
        });
        setState(() {
          _orderStatus[orderKey] = food_order.OrderQueue(
              currentOrder: orderId - currentOrder, time: time);
        });
      }
    });
    setState(() {
      var key = '$ownerUID-$shopName-order$orderId';
      if (_orderListeners.containsKey(key)) {
        _orderListeners[key]!.cancel();
      }
      _orderListeners[key] = listener;
    });
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
          String shopKey = showShopList[index];
          String ownerUID = shopKey.split('-').first;
          String shopName = shopKey.split('-').last;
          Basket basket = allBasket[shopKey]!;
          MenuList? shopMenu = menuListObj[shopKey];
          late ShopInfo shopInfo;
          for (var shop in shopList) {
            if ((shop.ownerUID == ownerUID) && (shop.name == shopName)) {
              shopInfo = shop;
              break;
            }
          }
          return Column(
            children: <Widget>[
              ElevatedButton(
                  onPressed: () => Navigator.of(context)
                          .push(MaterialPageRoute(builder: ((context) {
                        return Shop(
                          user: widget.user,
                          shopInfo: shopInfo,
                          basket: basket,
                          updateBasket: updateBasket,
                          shopMenu: shopMenu,
                          saveMenuData: saveMenuData,
                          setOrderListener: setOrderListener,
                          allQueue: _orderStatus,
                        );
                      }))),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade400),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                            alignment: Alignment.topLeft,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'ร้าน $shopName',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 24),
                                ),
                                Text(
                                  '${isInteger(basket.cost) ? '${basket.cost.ceil()}' : '${basket.cost}'} บาท',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 24),
                                )
                              ],
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          height: screenSize.height / 2,
                          color: Colors.white,
                          child: Cart(
                            user: widget.user,
                            shopInfo: shopList[index],
                            basket: basket,
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            updateBasket: updateBasket,
                            checkout: false,
                            setOrderListener: setOrderListener,
                          ),
                        ),
                      )
                    ],
                  )),
              Divider()
            ],
          );
        }));
    return cartWidget;
  }

  void goTo(int page, {Map<String, dynamic>? option}) {
    navigationTapped(page);
    if (option != null) {
      if (option.containsKey('order-tab')) {
        late int val;
        switch (option['order-tab']) {
          case 'Cooking':
            val = 0;
            break;
          case 'Ready':
            val = 1;
            break;
          case 'Completed':
            val = 2;
            break;
        }
        setState(() {
          orderInitialTab = val;
          for (var data in noti) {
            if (json.encode(json.decode(data)) == option['noti']) {
              noti.remove(data);
              Provider.of<AppProvider>(context, listen: false).removeNoti(data);
              break;
            }
          }
        });
      }
    }
  }

  void setOrderInitialTab(int val) {
    orderInitialTab = val;
  }

  void signOut() {
    allOrdersListener.cancel();
    for (var key in _orderListeners.keys) {
      var orderListener = _orderListeners[key]!;
      orderListener.cancel();
    }
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    for (var order in _orderStatus.keys) {
      print(order);
    }
    return WillPopScope(
      onWillPop: () => Future.value(false),
      child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            centerTitle: true,
            title: Text(
              mainScreenTitle,
              style: Theme.of(context).appBarTheme.titleTextStyle,
            ),
            elevation: 0.0,
            actions: <Widget>[
              Container(
                  // decoration: BoxDecoration(border: Border.all()),
                  constraints:
                      const BoxConstraints(maxHeight: 50, maxWidth: 50),
                  child: Badge(
                    position: BadgePosition.topEnd(top: 2.5, end: 2.5),
                    showBadge: showNotiBadge,
                    badgeContent: const Icon(
                      FontAwesomeIcons.exclamation,
                      size: 10,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.notifications,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          showNotiBadge = false;
                          Provider.of<AppProvider>(context, listen: false)
                              .setNotiStatus(false);
                        });
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return Notifications(
                                allOrders: allOrders,
                                notiList: noti,
                                goTo: goTo,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ))
            ],
          ),
          body: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _pageController,
            onPageChanged: onPageChanged,
            children: <Widget>[
              Home(
                user: widget.user,
                position: _position,
                shopList: shopList,
                menuListObj: menuListObj,
                shopData: shopData,
                dataReady: _dataReady,
                allBasket: allBasket,
                updateBasket: updateBasket,
                setOrderListener: setOrderListener,
                saveMenuData: saveMenuData,
                allQueue: _orderStatus,
              ),
              showCartAll(),
              AllOrderScreen(
                shopList: shopList,
                allOrders: allOrders,
                initialTab: orderInitialTab,
                setInitialTab: setOrderInitialTab,
                orderStatus: _orderStatus,
                setOrderListener: setOrderListener,
              ),
              Profile(
                user: widget.user,
                signOut: signOut,
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
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
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor,
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
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.fastfood,
                    size: 24.0,
                  ),
                  color: _pageName[_page] == 'Order'
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor,
                  onPressed: () async {
                    navigationTapped(2);
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.menu,
                    size: 24.0,
                  ),
                  color: _pageName[_page] == 'Menu'
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context)
                          .bottomNavigationBarTheme
                          .unselectedItemColor,
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
        PrefsKey.basketShopList(widget.user.email), allBasket.keys.toList());
    for (String shopName in allBasket.keys) {
      List<ItemCounter> itemList = allBasket[shopName]!.itemList;
      double cost = allBasket[shopName]!.cost;
      int amount = allBasket[shopName]!.amount;
      List<String> idList = [];
      for (ItemCounter itemCounter in itemList) {
        Item item = itemCounter.item;
        int count = itemCounter.count;
        idList.add(item.id);
        prefs.setString(
            PrefsKey.basketItemList(shopName).item(item.id),
            json.encode({
              'name': item.name,
              'price': item.price,
              'time': item.time,
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
    _pageController.dispose();
    messageListener.cancel();
    for (var orderListener in _orderListeners.values) {
      orderListener.cancel();
      _orderListeners.remove(orderListener);
    }
    allOrdersListener.cancel();
    super.dispose();
  }

  Future<void> onPageChanged(int page) async {
    if ((_pageName[page] == 'Home') && (_position != null)) {
      await setShopList(_position!);
    }
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
