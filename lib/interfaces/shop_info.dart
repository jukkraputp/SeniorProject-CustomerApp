import 'dart:math';

import 'package:geolocator/geolocator.dart';

class ShopInfo {
  String name;
  num rating;
  int review;
  String phoneNumber;
  String ownerUID;
  double latitude;
  double longitude;

  ShopInfo(
      {required this.name,
      required this.rating,
      required this.review,
      required this.phoneNumber,
      required this.ownerUID,
      required this.latitude,
      required this.longitude});

  int compareTo(ShopInfo anotherShopInfo, Position positon) {
    double shopDistance = sqrt(pow(latitude - positon.latitude, 2) +
        pow(longitude - positon.longitude, 2));
    double anotherShopDistance = sqrt(
        pow(anotherShopInfo.latitude - positon.latitude, 2) +
            pow(anotherShopInfo.longitude - positon.longitude, 2));
    if (shopDistance < anotherShopDistance) {
      return -1;
    } else if (shopDistance > anotherShopDistance) {
      return 1;
    } else {
      return 0;
    }
  }
}
