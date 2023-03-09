import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as cloud_fs;
import 'package:customer/interfaces/order.dart' as food_order;
import 'package:customer/interfaces/register.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:customer/interfaces/history.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/menu_list.dart';
import 'package:http/http.dart' as http;
import 'package:customer/interfaces/customer/user.dart' as customer;

const String backendUrl = 'http://jukkraputp.sytes.net';

class API {
  final cloud_fs.FirebaseFirestore _firestoreDB =
      cloud_fs.FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _rtDB = FirebaseDatabase.instance;

  // Firestore Database

  Future<MenuList> getShopMenu(
      {required String ownerUID, required String shopName}) async {
    List<String> types = await getShopTypes(ownerUID, shopName);
    MenuList menuList = MenuList(typesList: types);
    for (var type in types) {
      cloud_fs.QuerySnapshot<Map<String, dynamic>> querySnapshot =
          await _firestoreDB
              .collection('Menu')
              .doc('$ownerUID-$shopName')
              .collection(type)
              .get();
      for (var doc in querySnapshot.docs) {
        menuList.menu[type]!.add(Item(
            name: doc['name'],
            price: doc['price'],
            time: doc['time'],
            image: doc['image'],
            id: doc['id'],
            available: doc['available']));
      }
    }
    return menuList;
  }

  Future<List<String>> getShopTypes(String ownerUID, String shopName) async {
    cloud_fs.DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
        await _firestoreDB.collection('Menu').doc('$ownerUID-$shopName').get();
    List<String> types = [];
    if (documentSnapshot.exists) {
      var data = documentSnapshot.data();
      List<String> typeList = [];
      for (var type in data?['types'] ?? []) {
        typeList.add(type.toString());
      }
      types = typeList;
    }
    return types;
  }

  Future<Stream<cloud_fs.QuerySnapshot<Map<String, dynamic>>>> getAllOrders(
      String uid) async {
    Stream<cloud_fs.QuerySnapshot<Map<String, dynamic>>> collectionStream =
        _firestoreDB
            .collection('Orders')
            .where('uid', isEqualTo: uid)
            .snapshots();
    return collectionStream;
  }

  Future<Stream<cloud_fs.QuerySnapshot<Map<String, dynamic>>>> getOrder({
    required String ownerUID,
    required String shopName,
    required int orderId,
    required String date,
  }) async {
    Stream<cloud_fs.QuerySnapshot<Map<String, dynamic>>> collectionStream =
        _firestoreDB
            .collection('Orders')
            .where('ownerUID', isEqualTo: ownerUID)
            .where('shopName', isEqualTo: shopName)
            .where('orderId', isEqualTo: orderId)
            .where('date', isEqualTo: date)
            .snapshots();
    return collectionStream;
  }

  Future<food_order.FilteredOrders> allOrdersEventHandler(
      cloud_fs.QuerySnapshot<Map<String, dynamic>> event, String uid) async {
    print('allOrdersEventHandler - uid: $uid');
    food_order.FilteredOrders allOrders = food_order.FilteredOrders();
    for (var doc in event.docs) {
      Map<String, dynamic> obj = doc.data();
      int orderId = obj['orderId'];
      String ownerUID = obj['ownerUID'];
      String shopName = obj['shopName'];
      String date = obj['date'];
      bool isCompleted = obj['isCompleted'];
      bool isFinished = obj['isFinished'];
      bool isPaid = obj['isPaid'];
      String? paymentImage = obj['paymentImage'];
      if (isCompleted) {
        // search in firestore
        cloud_fs.QuerySnapshot<Map<String, dynamic>> snapshot =
            await _firestoreDB
                .collection('History')
                .doc('$ownerUID-$shopName')
                .collection(date)
                .where('orderId', isEqualTo: orderId)
                .get();
        for (var doc in snapshot.docs) {
          var data = doc.data();
          cloud_fs.Timestamp timestamp = data['date'];
          List<ItemCounter> itemList = [];
          for (var item in data['itemList']) {
            itemList.add(ItemCounter(
                Item(
                  name: item['name'],
                  price: item['price'],
                  time: item['time'],
                  image: item['image'],
                  id: item['id'],
                ),
                item['count']));
          }
          String shopKey = '$ownerUID-$shopName';
          // Completed
          food_order.Order order = food_order.Order(
              uid: uid,
              ownerUID: ownerUID,
              shopName: shopName,
              phoneNumber: data['shopPhoneNumber'],
              itemList: itemList,
              cost: data['cost'],
              date: DateTime.fromMillisecondsSinceEpoch(
                  timestamp.millisecondsSinceEpoch),
              isCompleted: isCompleted,
              isFinished: isFinished,
              isPaid: isPaid,
              orderId: orderId,
              paymentImage: paymentImage);
          if (allOrders.completed.containsKey(shopKey)) {
            allOrders.completed[shopKey]!.add(order);
          } else {
            allOrders.completed[shopKey] = [order];
          }
        }
      } else {
        // search in real time database
        DatabaseReference ref = FirebaseDatabase.instance.ref();
        String path = 'Order/$ownerUID-$shopName/$date/order$orderId';
        print(path);
        DataSnapshot dataSnapshot = await ref.child(path).get();

        Map<String, dynamic> dataObj =
            json.decode(json.encode(dataSnapshot.value));
        bool isFinished = dataObj['isFinished'];
        List<ItemCounter> itemList = [];
        for (var item in dataObj['itemList']) {
          itemList.add(ItemCounter(
              Item(
                  name: item['name'],
                  price: item['price'],
                  time: item['time'],
                  image: item['image'],
                  id: item['id']),
              item['count']));
        }
        num cost = dataObj['cost'];
        food_order.Order order = food_order.Order(
            uid: uid,
            ownerUID: ownerUID,
            shopName: shopName,
            phoneNumber: dataObj['shopPhoneNumber'],
            itemList: itemList,
            cost: cost.toDouble(),
            date: DateTime.parse(dataObj['date']),
            isCompleted: isCompleted,
            isFinished: isFinished,
            isPaid: isPaid,
            orderId: orderId,
            paymentImage: paymentImage);
        String shopKey = '$ownerUID-$shopName';
        if (isFinished) {
          // Ready
          if (allOrders.ready.containsKey(shopKey)) {
            allOrders.ready[shopKey]!.add(order);
          } else {
            allOrders.ready[shopKey] = [order];
          }
        } else {
          // Cooking
          if (allOrders.cooking.containsKey(shopKey)) {
            allOrders.cooking[shopKey]!.add(order);
          } else {
            allOrders.cooking[shopKey] = [order];
          }
        }
      }
    }
    print('Handler');
    print('Cooking');
    for (var orderList in allOrders.cooking.values) {
      for (var order in orderList) {
        print('shopName: ${order.shopName}, orderId: ${order.orderId}');
      }
    }
    print('Ready');
    for (var orderList in allOrders.ready.values) {
      for (var order in orderList) {
        print('shopName: ${order.shopName}, orderId: ${order.orderId}');
      }
    }
    print('Completed');
    for (var orderList in allOrders.completed.values) {
      for (var order in orderList) {
        print('shopName: ${order.shopName}, orderId: ${order.orderId}');
      }
    }
    return allOrders;
  }

  Future<String?> getShopName(String key) async {
    cloud_fs.DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await _firestoreDB.collection('ShopList').doc(key).get();
    if (docSnapshot.exists) {
      return docSnapshot['name'];
    }
    return null;
  }

  Future<List<ShopInfo>> getShopList(Position pos) async {
    // 1 latitude = 111.1 km
    double lat = 1 / 111.1;
    // 1 longitude = 111.321 km
    double lon = 1 / 111.321;
    double distanceFromCenter = 20;
    double distance =
        sqrt(pow(distanceFromCenter, 2) + pow(distanceFromCenter, 2)); // km
    double lowerLat = pos.latitude - (lat * distance);
    double lowerLon = pos.longitude - (lon * distance);
    double greaterLat = pos.latitude + (lat * distance);
    double greaterLon = pos.longitude + (lon * distance);
    cloud_fs.GeoPoint lesserGeopoint = cloud_fs.GeoPoint(lowerLat, lowerLon);
    cloud_fs.GeoPoint greaterGeopoint =
        cloud_fs.GeoPoint(greaterLat, greaterLon);
    cloud_fs.QuerySnapshot querySnapshot = await cloud_fs
        .FirebaseFirestore.instance
        .collection('ShopList')
        .where("position", isGreaterThanOrEqualTo: lesserGeopoint)
        .where("position", isLessThanOrEqualTo: greaterGeopoint)
        .get();
    List<dynamic> shopList =
        querySnapshot.docs.map((doc) => doc.data()).toList();
    List<ShopInfo> res = [];
    for (var i = 0; i < shopList.length; i++) {
      if (shopList[i]['shopName'] != null) {
        cloud_fs.GeoPoint geoPoint = shopList[i]['position'];
        ShopInfo obj = ShopInfo(
            name: shopList[i]['shopName'],
            rating: shopList[i]['rating'],
            review: shopList[i]['rater'],
            phoneNumber: shopList[i]['phoneNumber'],
            ownerUID: shopList[i]['ownerUID'],
            latitude: geoPoint.latitude,
            longitude: geoPoint.longitude);
        res.add(obj);
      }
    }
    res.sort(((a, b) => a.compareTo(b, pos)));
    return res;
  }

  Future<ShopInfo?> getShopInfo(String ownerUID, String shopName) async {
    cloud_fs.DocumentSnapshot docSnapshot = await _firestoreDB
        .collection('ShopList')
        .doc('$ownerUID-$shopName')
        .get();
    if (docSnapshot.exists) {
      Map<String, dynamic> data = json.decode(json.encode(docSnapshot.data()!));
      return ShopInfo(
          name: data['name'],
          rating: data['rating'],
          review: data['review'],
          phoneNumber: data['phoneNumber'],
          ownerUID: data['ownerUID'],
          latitude: data['latitude'],
          longitude: data['longitude']);
    }
    return null;
  }

  Future<History> getHistory(String shopName, String orderDocId) async {
    DateTime today = DateTime.now();
    String id = '${today.year}${today.month}${today.day}';
    var ref = _firestoreDB
        .collection('History')
        .doc(shopName)
        .collection(id)
        .doc(orderDocId);
    var doc = await ref.get();
    var data = doc.data();
    var history = History(
        orderId: data?['orderId'],
        totalAmount: data?['totalAmount'],
        date: data?['date'],
        foods: data?['foods']);
    return history;
  }

  Future<List<History>> getHistoryList(String shopName) async {
    final List<History> historyList = [];
    DateTime today = DateTime.now();
    String id = '${today.year}${today.month}${today.day}';
    var ref = _firestoreDB.collection('History').doc(shopName).collection(id);
    var datas = await ref.get();
    for (var doc in datas.docs) {
      var data = doc.data();
      var history = History(
          orderId: data['orderId'],
          totalAmount: data['totalAmount'],
          date: data['date'],
          foods: data['foods']);
      historyList.add(history);
    }
    return historyList;
  }

  // Storage

  Future<TaskSnapshot> deleteType(String key, String typeName) async {
    String shopName = key.split('_').first;
    return await _storage
        .ref()
        .child('$shopName/$typeName/not-in-use.txt')
        .putString('this folder is unused');
  }

  Future<TaskSnapshot> setNewType(String key, String typeName) async {
    String shopName = key.split('_').first;
    try {
      await _storage.ref().child('$shopName/$typeName/not-in-use.txt').delete();
    } catch (e) {
      print('API setNewType: $e');
    }
    return await _storage
        .ref()
        .child('$shopName/$typeName/foo.txt')
        .putString('foo file');
  }

  // Chat

  // subscribe to firebase real-time

  // Through backend server

  Future<http.Response> uploadPaymentImage(
      {required String ownerUID,
      required String shopName,
      required String date,
      required,
      required int orderId,
      required Uint8List bytesImage}) async {
    Reference ref = _storage.ref('$ownerUID-$shopName-payment/order$orderId');
    late String imageUrl;
    http.Response res;
    await ref.putData(bytesImage);
    imageUrl = await ref.getDownloadURL();
    res = await http.post(Uri.parse('$backendUrl:7777/upload-payment-image'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({
          'ownerUID': ownerUID,
          'shopName': shopName,
          'date': date,
          'orderId': orderId,
          'paymentImageUrl': imageUrl
        }));
    return res;
  }

  // save order to firebase
  Future<http.Response> saveOrder(
      String uid, String shopName, int orderId) async {
    http.Response res = await http.post(
        Uri.parse('$backendUrl:7777/save-order'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(
            {'username': uid, 'shopName': shopName, 'orderId': orderId}));
    return res;
  }

  // register
  Future<http.Response> register(
      {required String username,
      required String email,
      required String password,
      required String phoneNumber,
      String countryCode = '66',
      String mode = 'Customer'}) async {
    http.Response res = await http.post(Uri.parse('$backendUrl:7777/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'phoneNumber': '+$countryCode$phoneNumber',
          'mode': mode
        }));
    return res;
  }

  // delete everything relate to pos tokens
  Future<http.Response> clearToken(
      {required String secret, required String username}) async {
    return await http.post(
        Uri.parse('http://jukkraputp.sytes.net:7777/clear-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({'secret': secret, 'username': username}));
  }

  // generate otp for pos
  Future<String> generateToken(
      {required String shopName, String mode = "Reception"}) async {
    http.Response res = await http.post(
        Uri.parse('http://jukkraputp.sytes.net:7777/generate-token'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode({'key': shopName, 'mode': mode}));
    return jsonDecode(res.body)['OTP'];
  }

  // Write data to database through backend server api
  Future<http.Response> addOrder(food_order.Order order) async {
    String? IID_TOKEN = await FirebaseMessaging.instance.getToken();
    String jsonEncoded = order.toJsonEncoded(args: {'IID_TOKEN': IID_TOKEN});

    http.Response httpRes =
        await http.post(Uri.parse('http://jukkraputp.sytes.net:7777/add'),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncoded);
    return httpRes;
  }

  // get total amount of an order
  double getTotalAmount(Map<String, int> order, MenuList menuList) {
    double totalAmount = 0;
    order.forEach((key, value) {
      String type = key.split('-')[0];
      int index =
          menuList.menu[type]?.indexWhere((element) => element.id == key) ?? -1;
      var item = menuList.menu[type]![index];
      double itemVal = 0;
      try {
        itemVal = item.price * value;
      } on Exception catch (_) {
        itemVal = 0;
      }
      totalAmount += itemVal;
    });
    return totalAmount;
  }

  // Change isFinished to True
  Future<http.Response> finishOrder(String shopName, String orderId) async {
    return http.post(Uri.parse('http://jukkraputp.sytes.net:7777/finish'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'shopName': shopName, 'orderId': orderId}));
  }

  // Move order from realtime database to firestore
  Future<http.Response> completeOrder(String shopName, String orderId) async {
    return http.post(Uri.parse('http://jukkraputp.sytes.net:7777/complete'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(
            <String, String>{'shopName': shopName, 'orderId': orderId}));
  }

  // update new picture in firebase storage
  Future<bool> updateStorageData(
      String shopName, Map<String, List<Item>> obj) async {
    final shopRef = _storage.ref().child(shopName);
    final types = obj.keys;
    for (var type in types) {
      final typeRef = shopRef.child(type);
      final updateList = obj[type]!;
      for (var item in updateList) {
        final itemRef = typeRef.child('${item.id}.jpg');
        try {
          if (item.delete) {
            itemRef.delete();
          } else {
            if (item.bytes != null) await itemRef.putData(item.bytes!);
          }
          await updateProductInfo(
              shopName, type, item.id, item.name, item.price,
              delete: item.delete);
        } on FirebaseException catch (e) {
          print(e);
          return false;
        }
      }
    }
    return true;
  }

  // update product info on firebase firestore
  Future<http.Response> updateProductInfo(
      String shopName, String type, String id, String name, double price,
      {bool delete = false}) async {
    return http.post(Uri.parse('$backendUrl:7777/update-product'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'shop_key': shopName,
          'type': type,
          'id': id,
          'product': {'name': name, 'price': price, 'delete': delete}
        }));
  }

  // ------------------- Manager --------------------//

  Stream<cloud_fs.DocumentSnapshot<Map<String, dynamic>>> listenFirestore(
      {required String collection, required String documentId}) {
    return _firestoreDB.collection(collection).doc(documentId).snapshots();
  }

  Future<customer.User?> getUserInfo(String userId) async {
    cloud_fs.DocumentSnapshot<Object> res =
        await _firestoreDB.collection('Manager').doc(userId).get();
    var data = res.data();
    if (data != null) {
      var obj = jsonDecode(jsonEncode(data));
      String name = obj['name'];
      List<String> shopList = [];
      String? receptionToken;
      String? chefToken;
      cloud_fs.DocumentSnapshot<Object> reception =
          await _firestoreDB.collection('OTP').doc(obj['Reception']).get();
      if (reception.data() != null) {
        var receptionData = jsonDecode(jsonEncode(reception.data()));
        String jwt = receptionData['token'];
        bool isExpired = JwtDecoder.isExpired(jwt);
        if (!isExpired) {
          receptionToken = obj['Reception'];
        }
      }
      cloud_fs.DocumentSnapshot<Object> chef =
          await _firestoreDB.collection('OTP').doc(obj['Chef']).get();
      if (chef.data() != null) {
        var chefData = jsonDecode(jsonEncode(chef.data()));
        String jwt = chefData['token'];
        bool isExpired = JwtDecoder.isExpired(jwt);
        if (!isExpired) {
          chefToken = obj['Chef'];
        }
      }
      for (var shopName in obj['shopList']) {
        shopList.add(shopName.toString());
      }

      customer.User user = customer.User(name, shopList);
      return user;
    }
    return null;
  }

  //-------------------- Omise ----------------------//

  // create token
  /* Future<OmiseResponse.Token> createToken(
      String publicKey,
      String name,
      String number,
      String expirationMonth,
      String expirationYear,
      String securityCode,
      {OmiseTokenInfo? info}) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    if (info != null) {
      final response = await omise.token.create(
          name, number, expirationMonth, expirationYear, securityCode,
          city: info.city,
          country: info.country,
          postalCode: info.postalCode,
          state: info.state,
          street1: info.street1,
          street2: info.street2,
          phoneNumber: info.phoneNumber);
      return response;
    } else {
      final response = await omise.token
          .create(name, number, expirationMonth, expirationYear, securityCode);
      return response;
    }
  }

  // create source
  Future<OmiseResponse.Source> createSource(
      String publicKey, int amount, String currency, String type,
      {OmiseSourceInfo? info}) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    final response = await omise.source.create(amount, currency, type);
    return response;
  }

  // retrieve a capability
  Future<OmiseResponse.Capability> retrieveCap(String publicKey) async {
    OmiseFlutter omise = OmiseFlutter(publicKey);
    final response = await omise.capability.retrieve();
    return response;
  } */

  // start transaction
  Future<http.Response> createTrans(
      String sourceId, int amount, String currency) async {
    var response = await http.post(
        Uri.parse('http://jukkraputp.sytes.net:8888/api/v1/start-trans'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'source_id': sourceId,
          'amount': amount * 100,
          'currency': currency
        }));
    return response;
  }
}
