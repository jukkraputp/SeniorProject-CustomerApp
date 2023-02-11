import 'package:flutter/foundation.dart';

class Item {
  String name;
  String price;
  String image;
  String id;
  Uint8List? bytes;
  bool delete = false;
  double? rating;
  int? rater;

  int? idIn(List<Item> itemList) {
    for (var i = 0; i < itemList.length; i++) {
      Item item = itemList[i];
      if (id == item.id) {
        return i;
      }
    }
    return null;
  }

  Item(this.name, this.price, this.image, this.id,
      {this.bytes, this.rating, this.rater});
}

class ItemCounter {
  Item item;
  int count;

  ItemCounter(this.item, this.count);
}
