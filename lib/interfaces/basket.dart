import 'package:customer/interfaces/item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Basket {
  List<ItemCounter> itemList = [];
  double cost = 0;
  int amount = 0;

  Basket({List<ItemCounter>? itemList, double? cost, int? amount}) {
    if (itemList != null) {
      this.itemList = itemList;
    }
    if (cost != null) {
      this.cost = cost;
    }
    if (amount != null) {
      this.amount = amount;
    }
  }

  void addItem(Item newItem) {
    for (var item in itemList) {
      if (item.item.name == newItem.name) {
        item.count += 1;
        try {
          cost += double.parse(newItem.price);
        } catch (e) {
          print(e);
        }

        amount += 1;
        return;
      }
    }
    itemList.add(ItemCounter(newItem, 1));
    try {
      cost += double.parse(newItem.price);
    } catch (e) {
      print(e);
    }
    amount += 1;
  }

  void removeItem(Item targetItem, {int amount = 1}) {
    for (var item in itemList) {
      if (item.item.name == targetItem.name) {
        item.count -= amount;
        if (item.count <= 0) {
          itemList.remove(item);
        }
        try {
          cost -= double.parse(targetItem.price);
        } catch (e) {
          print(e);
        }
        this.amount -= 1;
        return;
      }
    }
  }

  void clear() {
    itemList = [];
    cost = 0;
    amount = 0;
  }
}
