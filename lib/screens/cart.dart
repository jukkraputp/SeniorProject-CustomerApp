import 'package:customer/interfaces/basket.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:customer/screens/checkout.dart';
import 'package:customer/util/foods.dart';
import 'package:customer/widgets/cart_item.dart';

class Cart extends StatefulWidget {
  const Cart(
      {super.key,
      required this.user,
      required this.shopInfo,
      required this.basket,
      this.shrinkWrap,
      this.physics,
      this.checkout = true,
      required this.updateBasket});

  final User user;
  final ShopInfo shopInfo;
  final Basket basket;
  final bool? shrinkWrap;
  final ScrollPhysics? physics;
  final bool checkout;
  final void Function(String, {Item? item, String mode}) updateBasket;

  @override
  _CartState createState() => _CartState();
}

class _CartState extends State<Cart> with AutomaticKeepAliveClientMixin<Cart> {
  void updateBasket(String shopName, {Item? item, String mode = '+'}) {
    setState(() {
      widget.updateBasket(shopName, item: item, mode: mode);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    print('Cart: ${widget.basket}');
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 0),
        child: ListView.builder(
          shrinkWrap: widget.shrinkWrap == null ? false : widget.shrinkWrap!,
          physics: widget.physics,
          itemCount: widget.basket.itemList.length,
          itemBuilder: (BuildContext context, int index) {
            return CartItem(
              shopName: widget.shopInfo.name,
              itemCounter: widget.basket.itemList[index],
              isFav: false,
              updateBasket: updateBasket,
            );
          },
        ),
      ),
      floatingActionButton: widget.checkout
          ? FloatingActionButton(
              tooltip: "Checkout",
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return Checkout(
                        user: widget.user,
                        shopInfo: widget.shopInfo,
                        basket: widget.basket,
                        updateBasket: updateBasket,
                      );
                    },
                  ),
                );
              },
              heroTag: Object(),
              child: const Icon(
                Icons.arrow_forward,
              ),
            )
          : null,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
