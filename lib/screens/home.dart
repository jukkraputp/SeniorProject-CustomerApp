import 'dart:math';

import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/order.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/screens/shop.dart';
import 'package:customer/util/const.dart';
import 'package:customer/widgets/smooth_star_rating.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/material.dart';
import 'package:customer/interfaces/menu_list.dart';

class Home extends StatefulWidget {
  const Home(
      {super.key,
      required this.user,
      required this.position,
      required this.shopList,
      required this.menuListObj,
      required this.shopData,
      required this.dataReady,
      required this.allBasket,
      required this.updateBasket,
      required this.setOrderListener,
      required this.saveMenuData,
      required this.allQueue});

  final User user;
  final Position? position;
  final List<ShopInfo> shopList;
  final Map<String, MenuList> menuListObj;
  final List<String> shopData;
  final bool dataReady;
  final Map<String, Basket> allBasket;
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
  final void Function(ShopInfo, MenuList)? saveMenuData;
  final Map<String, OrderQueue> allQueue;

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with AutomaticKeepAliveClientMixin<Home> {
  List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }

  final int maxShop = 10;
  final TextEditingController _searchController = TextEditingController();

  // Map<String, MenuList> menuListObj = {};
  // Map<String, List<String>> menuTypeListObj = {};
  bool widgetReady = false;
  // List<String> shopData = [];
  List<ShopInfo> _foundShops = [];

  @override
  void initState() {
    super.initState();
    _foundShops = _foundShops;
  }

  // void saveMenuData(String shopName, MenuList menuList) {
  //   setState(() {
  //     menuListObj[shopName] = menuList;
  //   });
  // }

  String distanceOf(double x1, double y1, double x2, double y2) {
    late String unit;
    double distance = sqrt(pow(x1 - x2, 2) + pow(y1 - y2, 2)) * 111 * 1000;
    if (distance > 1000) {
      distance /= 1000;
      unit = 'km';
    } else {
      unit = 'm';
    }
    return distance.ceil() != 0
        ? '${distance.ceil()} $unit'
        : '<${distance.ceil() + 1} $unit';
  }

  // This function is called whenever the text field changes
  void _runFilter(String enteredKeyword) {
    List<ShopInfo> results = [];
    if (enteredKeyword.isEmpty) {
      // if the search field is empty or only contains white-space, we'll display all users
      results = _foundShops;
    } else {
      results = _foundShops
          .where((shop) =>
              shop.name.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
      // we use the toLowerCase() method to make it case-insensitive
    }

    // Refresh the UI
    setState(() {
      _foundShops = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    Size screenSize = MediaQuery.of(context).size;
    if (_searchController.text.isEmpty) {
      setState(() {
        _foundShops = widget.shopList;
      });
    }
    return widget.dataReady
        ? GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
              child: ListView(
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Card(
                    elevation: 6.0,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(
                          Radius.circular(5.0),
                        ),
                      ),
                      child: TextField(
                        onChanged: ((value) => _runFilter(value)),
                        style: const TextStyle(
                          fontSize: 15.0,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(10.0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide: const BorderSide(
                              color: Colors.white,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Colors.white,
                            ),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          hintText: "Search..",
                          suffixIcon: const Icon(
                            Icons.search,
                            color: Colors.black,
                          ),
                          hintStyle: const TextStyle(
                            fontSize: 15.0,
                            color: Colors.black,
                          ),
                        ),
                        maxLines: 1,
                        controller: _searchController,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  /* Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                    "History",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ), */
                  _foundShops.isNotEmpty
                      ? ListView.builder(
                          shrinkWrap: true,
                          primary: false,
                          // physics: const NeverScrollableScrollPhysics(),
                          itemCount: _foundShops.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Card(
                              child: ListTile(
                                title: Text(
                                  _foundShops[index].name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: Icon(
                                    FontAwesomeIcons.shop,
                                    size: screenSize.width * 0.08,
                                  ),
                                ),
                                subtitle: _foundShops[index].review > 0
                                    ? Row(
                                        children: <Widget>[
                                          SmoothStarRating(
                                            starCount: 1,
                                            color: Constants.ratingBG,
                                            allowHalfRating: true,
                                            rating: 5.0,
                                            size: 12.0,
                                          ),
                                          const SizedBox(width: 6.0),
                                          Text(
                                            "${_foundShops[index].rating} (${_foundShops[index].review})",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                                trailing: widget.position != null
                                    ? Text(distanceOf(
                                        _foundShops[index].latitude,
                                        _foundShops[index].longitude,
                                        widget.position!.latitude,
                                        widget.position!.longitude))
                                    : null,
                                onTap: () {
                                  String ownerUID = _foundShops[index].ownerUID;
                                  String shopName = _foundShops[index].name;
                                  String shopKey = '$ownerUID-$shopName';
                                  Basket basket =
                                      widget.allBasket[shopKey] ?? Basket();
                                  bool needDownload = false;
                                  MenuList? shopMenu;
                                  if (!widget.shopData.contains(shopKey)) {
                                    needDownload = true;
                                  } else {
                                    shopMenu = widget.menuListObj[shopKey];
                                  }
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (BuildContext context) {
                                        return Shop(
                                          user: widget.user,
                                          shopInfo: _foundShops[index],
                                          basket: basket,
                                          updateBasket: widget.updateBasket,
                                          needDownload: needDownload,
                                          shopMenu: shopMenu,
                                          saveMenuData: widget.saveMenuData,
                                          setOrderListener:
                                              widget.setOrderListener,
                                          allQueue: widget.allQueue,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No shop found',
                          ),
                        ),
                  const SizedBox(height: 30),
                ],
              ),
            ))
        : Center(
            child: Lottie.asset('assets/animations/colors-circle-loader.json'),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
