class PrefsKey {
  static String theme = 'theme';

  static String paymentMethod = 'payment method';

  static String basketShopList(String? email) {
    return '${email}_basket_shopList';
  }

  static PrefsKeyItemCounter basketItemList(String shopName) {
    return PrefsKeyItemCounter(shopName: shopName);
  }

  static String basketIdList(String shopName) {
    return '${shopName}_basket_idList';
  }

  static String basketCost(String shopName) {
    return '${shopName}_basket_cost';
  }

  static String basketAmount(String shopName) {
    return '${shopName}_basket_amount';
  }
}

class PrefsKeyItemCounter {
  PrefsKeyItemCounter({String? shopName}) {
    _setBaseKey(shopName);
  }

  String baseKey = '';

  void _setBaseKey(String? shopName) {
    baseKey = '${shopName}_basket_itemList';
  }

  String item(String itemId) {
    return '${baseKey}_${itemId}_item';
  }

  String count(String itemId) {
    return '${baseKey}_${itemId}_count';
  }
}
