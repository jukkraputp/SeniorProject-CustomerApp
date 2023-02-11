class Payment {
  static String cash = 'Cash';
  static String promptpay = 'PromptPay';
  static String mobileBanking = 'Mobile Banking';
}

class PromptPay {
  static String qrcode(String phoneNumber, double cost) {
    return "https://promptpay.io/$phoneNumber/$cost.png";
  }
}
