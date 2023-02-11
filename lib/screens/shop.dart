import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/apis/api.dart';
import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/menu_list.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:customer/screens/cart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:lottie/lottie.dart';
import 'package:badges/badges.dart' as badges;
import 'package:provider/provider.dart';

class Shop extends StatefulWidget {
  const Shop(
      {super.key,
      required this.user,
      required this.shopInfo,
      required this.basket,
      required this.updateBasket,
      this.needDownload = false,
      this.shopMenu,
      this.saveMenuData});

  final User user;
  final ShopInfo shopInfo;
  final Basket basket;
  final void Function(String, {Item? item, String mode}) updateBasket;
  final bool needDownload;
  final MenuList? shopMenu;
  final void Function(String, MenuList)? saveMenuData;

  @override
  State<Shop> createState() => _ShopState();
}

class _ShopState extends State<Shop> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final API api = API();
  final double iconSize = 20;
  String? _selectedType;
  ListView _body = ListView();
  List<Widget> _menuTypeButtons = [];
  bool _ready = false;
  late MenuList shopMenu;

  @override
  void initState() {
    super.initState();
    if (widget.needDownload) {
      api.getMenuList(widget.shopInfo.name).then((value) {
        if (widget.saveMenuData != null) {
          widget.saveMenuData!(widget.shopInfo.name, value);
        }
        setState(() {
          _selectedType = value.menu.keys.toList().first;
          _menuTypeButtons = createMenuTypeButtons((value.menu.keys.toList()));
          _body = createListView(value);
          shopMenu = value;
        });
      });
    } else if (widget.shopMenu != null) {
      setState(() {
        shopMenu = widget.shopMenu!;
        _selectedType = widget.shopMenu!.menu.keys.toList().first;
      });
    }
  }

  void updateBasket(String shopName, {Item? item, String mode = '+'}) {
    print('Shop: $mode');
    setState(() {
      widget.updateBasket(shopName, item: item, mode: mode);
    });
  }

  ListView createListView(MenuList menuList) {
    double imgSize = 75;
    Size screenSize = MediaQuery.of(context).size;
    late ListView widgets;
    print('shop ready: $_ready');
    if (menuList.menu.containsKey(_selectedType)) {
      widgets = ListView.builder(
          itemCount: menuList.menu[_selectedType]!.length,
          itemBuilder: ((BuildContext context, int index) {
            return Container(
                margin:
                    const EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 5),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      widget.updateBasket(widget.shopInfo.name,
                          item: menuList.menu[_selectedType]?[index]);
                      rebuildWidgets(
                          _selectedType!, menuList.menu.keys.toList());
                    });
                  },
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        menuList.menu[_selectedType]![index].bytes != null
                            ? Image.memory(
                                menuList.menu[_selectedType]![index].bytes!,
                                width: imgSize,
                                height: imgSize,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                width: imgSize,
                                height: imgSize,
                                fit: BoxFit.cover,
                                imageUrl:
                                    menuList.menu[_selectedType]![index].image,
                              ),
                        Text(
                          menuList.menu[_selectedType]![index].name,
                          textAlign: TextAlign.center,
                        ),
                        Text(
                            '${menuList.menu[_selectedType]![index].price}     ')
                      ]),
                ));
          }));
      setState(() {
        _ready = true;
      });
    } else {
      widgets = ListView();
    }
    return widgets;
  }

  List<Widget> createMenuTypeButtons(List<String> types) {
    List<Widget> buttons = [];
    for (var foodType in types) {
      buttons.add(Container(
          margin: const EdgeInsets.all(1),
          child: TextButton(
              onPressed: () => rebuildWidgets(foodType, types),
              style: ButtonStyle(
                backgroundColor: _selectedType == foodType
                    ? MaterialStateProperty.all(Colors.black)
                    : MaterialStateProperty.all(Colors.grey.shade400),
              ),
              child: Text(
                foodType,
                style: TextStyle(
                    color: _selectedType == foodType
                        ? Colors.white
                        : Colors.black),
              ))));
    }

    return buttons;
  }

  void rebuildWidgets(String foodType, List<String> types) {
    setState(() {
      _selectedType = foodType;
      _ready = false;
      _menuTypeButtons = createMenuTypeButtons(types);
      _body = createListView(shopMenu);
    });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Provider.of<AppProvider>(context, listen: false).theme;
    double iconSize = 24;
    print('shop: $_selectedType');
    print('basket: ${widget.basket}');
    if (widget.shopMenu != null) {
      setState(() {
        _menuTypeButtons =
            createMenuTypeButtons((widget.shopMenu!.menu.keys.toList()));
        _body = createListView(widget.shopMenu!);
      });
    }
    return Scaffold(
      key: _key,
      /* endDrawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height / 5,
              child: DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: Text(
                  widget.shopName,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            ListTile(
              onTap: () {
                /* setState(() {
                  _editing = true;
                }); */
              },
              leading: Icon(
                Icons.edit,
                size: iconSize,
              ),
              title: const Text(
                'Edit',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(
                Icons.receipt,
                size: iconSize,
              ),
              title: const Text(
                'shop',
                style: TextStyle(fontSize: 20),
              ),
            ),
            ListTile(
              onTap: () {},
              leading: Icon(
                Icons.food_bank,
                size: iconSize,
              ),
              title: const Text(
                '',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ), */
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.keyboard_backspace,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.shopInfo.name,
        ),
        /* actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.menu,
              size: iconSize,
            ),
            onPressed: () => _key.currentState!.openEndDrawer(),
            tooltip: "Menu",
          ),
        ], */
      ),
      body: (_selectedType != null) & _ready
          ? Stack(
              children: <Widget>[
                _body,
                if (widget.basket.itemList.isNotEmpty)
                  Positioned(
                      right: 20.0,
                      bottom: 20.0,
                      child: badges.Badge(
                        position: badges.BadgePosition.topEnd(),
                        badgeContent: IconButton(
                          constraints:
                              const BoxConstraints(maxHeight: 15, maxWidth: 15),
                          padding: const EdgeInsets.all(0),
                          icon: const Icon(
                            Icons.clear,
                            color: Colors.white,
                            size: 15,
                          ),
                          onPressed: () =>
                              updateBasket(widget.shopInfo.name, mode: 'clear'),
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (BuildContext context) {
                                return Scaffold(
                                  appBar: AppBar(
                                    automaticallyImplyLeading: false,
                                    leading: IconButton(
                                      icon: const Icon(
                                        Icons.keyboard_backspace,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                    centerTitle: true,
                                    title: const Text('My Order'),
                                  ),
                                  body: Cart(
                                    user: widget.user,
                                    shopInfo: widget.shopInfo,
                                    basket: widget.basket,
                                    updateBasket: updateBasket,
                                  ),
                                );
                              },
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(10),
                            backgroundColor: Colors.blue, // <-- Button color
                            foregroundColor: Colors.white, // <-- Splash color
                          ),
                          child: Row(
                            children: <Widget>[
                              badges.Badge(
                                position: badges.BadgePosition.bottomEnd(),
                                badgeContent: Text(
                                  '${widget.basket.amount}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                child: Icon(
                                  Icons.food_bank,
                                  size: iconSize * 1.5,
                                ),
                              ),
                              SizedBox(
                                width: iconSize * 2,
                              ),
                              Text('฿ ${widget.basket.cost}'),
                            ],
                          ),
                        ),
                      ))
              ],
            )
          : Center(
              child:
                  Lottie.asset('assets/animations/colors-circle-loader.json'),
            ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
            height: 50,
            child: ListView(
                scrollDirection: Axis.horizontal, children: _menuTypeButtons)),
      ),
    );
  }
}
