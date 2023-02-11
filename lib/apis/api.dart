import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart' as CloudFS;
import 'package:customer/interfaces/order.dart' as FoodOrder;
import 'package:customer/interfaces/register.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:customer/interfaces/omise.dart';
import 'package:customer/interfaces/shop_info.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:customer/interfaces/history.dart';
import 'package:customer/interfaces/item.dart';
import 'package:customer/interfaces/menu_list.dart';
import 'package:http/http.dart' as http;
import 'package:customer/interfaces/customer/user.dart' as AppUser;

const String backendUrl = 'http://jukkraputp.sytes.net';

class API {
  final CloudFS.FirebaseFirestore _firestoreDB =
      CloudFS.FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseDatabase _rtDB = FirebaseDatabase.instance;

  // Firestore Database

  Future<Map<String, List<int>>> getAllOrders(String uid) async {
    print('getting all orders: $uid');
    Map<String, List<int>> allOrders = {};
    CloudFS.DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await _firestoreDB.collection('Orders').doc(uid).get();
    if (docSnapshot.exists) {
      List<dynamic> data = docSnapshot.data()!['data'] as List<dynamic>;
      print(data);
      for (var obj in data) {
        int orderId = obj['orderId'];
        String shopName = obj['shopName'];
        print('$shopName order$orderId');
        DatabaseReference ref = _rtDB.ref();
        DataSnapshot orderData = await ref.child('Order/$shopName').get();
        if (orderData.exists) {
          print(orderData.value);
        } else {
          print('No data available.');
        }
      }
    }
    return {};
  }

  Future<String?> getShopName(String key) async {
    CloudFS.DocumentSnapshot<Map<String, dynamic>> docSnapshot =
        await _firestoreDB.collection('ShopList').doc(key).get();
    if (docSnapshot.exists) {
      return docSnapshot['name'];
    }
    return null;
  }

  Future<List<ShopInfo>> getShopList() async {
    CloudFS.QuerySnapshot querySnapshot =
        await _firestoreDB.collection('ShopList').get();
    List<dynamic> shopList =
        querySnapshot.docs.map((doc) => doc.data()).toList();
    List<ShopInfo> res = [];
    for (var i = 0; i < shopList.length; i++) {
      if (shopList[i]['name'] != null) {
        ShopInfo obj = ShopInfo(
            name: shopList[i]['name'],
            rating: shopList[i]['rating'],
            review: shopList[i]['review'],
            phoneNumber: shopList[i]['phoneNumber']);
        res.add(obj);
      }
    }
    return res;
  }

  /* Future<String?> getshopName(String token) async {
    try {
      var doc = await _firestoreDB.collection('TokenList').doc(token).get();
      return doc.data()?['key'];
    } on Exception catch (_) {
      return null;
    }
  } */

  Future<String?> getMode(String token) async {
    try {
      var doc = await _firestoreDB.collection('TokenList').doc(token).get();
      return doc.data()?['mode'];
    } on Exception catch (_) {
      return null;
    }
  }

  /// Set Name and Price of MenuList object.
  Future<MenuList> setNameAndPrice(
      String key, MenuList menuList, ListResult types) async {
    var ref = _firestoreDB.collection('Menu').doc(key);
    for (var typeRef in types.prefixes) {
      var type = typeRef.name;
      var querySnapshot = await ref.collection(type).get();
      Map<String, Map<String, dynamic>> infoMap = {};
      for (var doc in querySnapshot.docs) {
        infoMap[doc.id] = doc.data();
      }
      menuList.menu[type]?.forEach((element) {
        var id = element.id;
        if (infoMap.containsKey(id)) {
          element.name = infoMap[id]?['name'];
          element.price = '${infoMap[id]?['price']}';
        }
      });
    }
    return menuList;
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

  Future<String> getImage(String key, String type, String name) async {
    var imageURL =
        await _storage.ref().child('$key/$type/$name.jpg').getDownloadURL();
    return imageURL;
  }

  Future<MenuList> getMenuList(String shopName) async {
    print('getting menuList');
    var shopRef = _storage.ref().child(shopName);
    var types = await shopRef.listAll();
    MenuList result = MenuList(types: types);
    for (var typeRef in types.prefixes) {
      result.menu[typeRef.name] = [];
      var images = await typeRef.listAll();
      var imagesRefList = images.items;
      imagesRefList.sort(((a, b) => a.name
          .substring(a.name.length - 6, a.name.length - 4)
          .compareTo(b.name.substring(b.name.length - 6, b.name.length - 4))));
      for (var imageRef in imagesRefList) {
        if (imageRef.name.contains('not-in-use')) {
          result.menu.remove(typeRef.name);
          break;
        }
        var url = await imageRef.getDownloadURL();
        if (url.contains('.jpg')) {
          Item newItem = Item('', '', url,
              imageRef.name.substring(0, imageRef.name.length - 4));
          result.menu[typeRef.name]?.add(newItem);
        }
      }
    }
    await setNameAndPrice(shopName, result, types);
    return result;
  }

  // gen new id by searching on storage
  Future<String> genNewId(String key, String type) async {
    key = key.split('_').first;
    print('genNewId: $key, $type');
    var typeRef = _storage.ref().child(key).child(type);
    final items = await typeRef.listAll();
    final itemsRefList = items.items;
    itemsRefList.sort(((a, b) => a.name
        .substring(a.name.length - 6, a.name.length - 4)
        .compareTo(b.name.substring(b.name.length - 6, b.name.length - 4))));
    if (itemsRefList.isNotEmpty) {
      var foodId = itemsRefList.last.name
          .substring(0, itemsRefList.last.name.length - 4);
      late String lastId;
      lastId = foodId.split('-').last;
      if (lastId == 'foo') {
        lastId = '-1';
      }
      return (double.parse(lastId) + 1).toString();
    }
    return '';
  }

  /* Future<String> genImageUrl(Uint8List image) async {
    late String res;
    final Reference ref = _storage.ref().child('genUrl').child('tempImg.png');
    res = await ref.putData(image).then((p0) async {
      res = await ref.getDownloadURL();
      return res;
    });
    return res;
  } */

  // Chat

  // subscribe to firebase real-time

  // Through backend server

  // save order to firebase
  Future<http.Response> saveOrder(
      String uid, String shopName, int orderId) async {
    http.Response res = await http.post(Uri.parse('$backendUrl/save-order'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(
            {'username': uid, 'shopName': shopName, 'orderId': orderId}));
    return res;
  }

  // register
  Future<RegisterResult> register(
      {required String username,
      required String password,
      String mode = 'Register'}) async {
    if (password.length < 6) {
      return RegisterResult(
          message: 'password required the minimum length of 6');
    }
    http.Response res = await http.post(Uri.parse('$backendUrl/register'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
        body: jsonEncode(
            {'username': username, 'password': password, 'mode': mode}));
    print(res);
    return RegisterResult();
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
    print(res.body);
    return jsonDecode(res.body)['OTP'];
  }

  // Write data to database through backend server api
  Future<http.Response> addOrder(FoodOrder.Order order) async {
    return http.post(Uri.parse('http://jukkraputp.sytes.net:7777/add'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: order.toJsonEncoded());
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
        itemVal = double.parse(item.price) * value;
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
    for (var key in obj.keys) {
      for (var item in obj[key]!) {
        print(item);
      }
    }
    print('updating firebase');
    final shopRef = _storage.ref().child(shopName);
    final types = obj.keys;
    for (var type in types) {
      final typeRef = shopRef.child(type);
      final updateList = obj[type]!;
      for (var item in updateList) {
        print('${item.id}, ${item.delete}');
        final itemRef = typeRef.child('${item.id}.jpg');
        print(itemRef);
        var imageList = await typeRef.listAll();
        for (var image in imageList.items) {
          print(await image.getDownloadURL());
        }
        try {
          if (item.delete) {
            itemRef.delete();
          } else {
            if (item.bytes != null) await itemRef.putData(item.bytes!);
          }
          await updateProductInfo(shopName, type, item.id, item.name,
              double.parse(item.price).toDouble(),
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

  Stream<CloudFS.DocumentSnapshot<Map<String, dynamic>>> listenFirestore(
      {required String collection, required String documentId}) {
    return _firestoreDB.collection(collection).doc(documentId).snapshots();
  }

  Future<AppUser.User?> getUserInfo(String userId) async {
    CloudFS.DocumentSnapshot<Object> res =
        await _firestoreDB.collection('Manager').doc(userId).get();
    var data = res.data();
    if (data != null) {
      var obj = jsonDecode(jsonEncode(data));
      String name = obj['name'];
      List<String> shopList = [];
      String? receptionToken;
      String? chefToken;
      CloudFS.DocumentSnapshot<Object> reception =
          await _firestoreDB.collection('OTP').doc(obj['Reception']).get();
      if (reception.data() != null) {
        var receptionData = jsonDecode(jsonEncode(reception.data()));
        String jwt = receptionData['token'];
        bool isExpired = JwtDecoder.isExpired(jwt);
        if (!isExpired) {
          receptionToken = obj['Reception'];
        }
      }
      CloudFS.DocumentSnapshot<Object> chef =
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

      AppUser.User user = AppUser.User(name, shopList);
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
    print(sourceId);
    print(amount);
    print(currency);
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
    print(response.statusCode);
    return response;
  }
}
