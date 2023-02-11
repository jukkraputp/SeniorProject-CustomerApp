import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/screens/shop.dart';
import 'package:customer/util/const.dart';
import 'package:customer/util/foods.dart';
import 'package:customer/widgets/smooth_star_rating.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:customer/apis/api.dart';
import 'package:flutter/material.dart';
import 'package:customer/interfaces/menu_list.dart';
import 'package:customer/widgets/grid_product.dart';
import 'package:customer/widgets/home_category.dart';
import 'package:customer/widgets/slider_item.dart';
import 'package:customer/util/categories.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/src/response.dart' as http;

class Home extends StatefulWidget {
  const Home(
      {super.key,
      required this.user,
      required this.shopList,
      required this.dataReady,
      required this.allBasket,
      required this.updateBasket});

  final User user;
  final List<ShopInfo> shopList;
  final bool dataReady;
  final Map<String, Basket> allBasket;
  final void Function(String, {Item? item, String mode}) updateBasket;

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

  final API api = API();
  final int maxShop = 10;
  final TextEditingController _searchControl = TextEditingController();

  Map<String, MenuList> menuListObj = {};
  Map<String, List<String>> menuTypeListObj = {};
  bool widgetReady = false;
  List<String> shopData = [];

  @override
  void initState() {
    super.initState();
  }

  void saveMenuData(String shopName, MenuList menuList) {
    setState(() {
      menuListObj[shopName] = menuList;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print(menuListObj['shop1']?.menu['Food1']?.first.name);
    print('widgetReady: $widgetReady');
    print('dataReady: ${widget.dataReady}');
    Size screenSize = MediaQuery.of(context).size;
    return widget.dataReady
        ? Padding(
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
                      controller: _searchControl,
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
                ListView.builder(
                  shrinkWrap: true,
                  primary: false,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.shopList.length,
                  itemBuilder: (BuildContext context, int index) {
                    Map food = foods[index];
                    return ListTile(
                      title: Text(
                        widget.shopList[index].name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image(
                            image: AssetImage(
                          "${food['img']}",
                        )),
                      ),
                      subtitle: widget.shopList[index].review > 0
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
                                  "${widget.shopList[index].rating} (${widget.shopList[index].review})",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            )
                          : null,
                      onTap: () {
                        String shopName = widget.shopList[index].name;
                        bool needDownload = false;
                        MenuList? shopMenu;
                        if (!shopData.contains(shopName)) {
                          setState(() {
                            shopData.add(shopName);
                          });
                          needDownload = true;
                        } else {
                          shopMenu = menuListObj[shopName];
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (BuildContext context) {
                              return Shop(
                                user: widget.user,
                                shopInfo: widget.shopList[index],
                                basket: widget.allBasket[shopName]!,
                                updateBasket: widget.updateBasket,
                                needDownload: needDownload,
                                shopMenu: shopMenu,
                                saveMenuData: saveMenuData,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          )
        : Center(
            child: Lottie.asset('assets/animations/colors-circle-loader.json'),
          );
  }

  @override
  bool get wantKeepAlive => true;
}
