import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:flutter/material.dart';
import 'package:customer/util/const.dart';
import 'package:customer/widgets/smooth_star_rating.dart';

class CartItem extends StatelessWidget {
  final ShopInfo shopInfo;
  ItemCounter itemCounter;
  final bool isFav;
  final void Function(
      {required String ownerUID,
      required String shopName,
      Item? item,
      String mode}) updateBasket;
  final bool adjustButtons;

  CartItem(
      {super.key,
      required this.shopInfo,
      required this.itemCounter,
      required this.isFav,
      this.updateBasket = dummyFunction,
      this.adjustButtons = true});

  static void dummyFunction(
      {required String ownerUID,
      required String shopName,
      Item? item,
      String mode = '+'}) {}

  // feature
  final bool foodOptions = false;

  @override
  Widget build(BuildContext context) {
    Item item = itemCounter.item;
    Size screenSize = MediaQuery.of(context).size;
    double imgSize = 75;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: InkWell(
        onTap: () {
          /* if (foodOptions) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return ProductDetails(
                    updateBasket: updateBasket,
                    itemCounter: itemCounter,
                  );
                },
              ),
            );
          } */
        },
        child: Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 0.0, right: 10.0),
              child: SizedBox(
                height: screenSize.width / 3.5,
                width: screenSize.width / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: item.image != ''
                      ? CachedNetworkImage(
                          width: imgSize,
                          height: imgSize,
                          fit: BoxFit.cover,
                          imageUrl: item.image)
                      : item.bytes != null
                          ? Image.memory(item.bytes!)
                          : null,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: screenSize.width / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: screenSize.width * 0.2,
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                          overflow: TextOverflow.clip,
                        ),
                      ),
                      // adjustment buttons
                      Row(
                        children: <Widget>[
                          if (adjustButtons)
                            IconButton(
                                onPressed: () => updateBasket(
                                    ownerUID: shopInfo.ownerUID,
                                    shopName: shopInfo.name,
                                    item: item,
                                    mode: '-'),
                                color: Colors.black,
                                icon: const Icon(Icons.remove_circle)),
                          Text(
                            '${itemCounter.count}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (adjustButtons)
                            IconButton(
                                onPressed: () => updateBasket(
                                    ownerUID: shopInfo.ownerUID,
                                    shopName: shopInfo.name,
                                    item: item,
                                    mode: '+'),
                                color: Colors.black,
                                icon: const Icon(Icons.add_circle))
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                if (item.rating != null)
                  Row(
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
                        "${item.rating} (${item.rater} Reviews)",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                if (item.rating != null) const SizedBox(height: 10.0),
                SizedBox(
                  width: screenSize.width / 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        "฿ ${itemCounter.item.price} each",
                        style: const TextStyle(
                          fontSize: 14.0,
                        ),
                      ),
                      Text(
                        "฿ ${item.price * itemCounter.count}",
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
