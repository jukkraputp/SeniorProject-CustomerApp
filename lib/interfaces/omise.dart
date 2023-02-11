class OmiseTokenInfo {
  String city;
  String country;
  String postalCode;
  String state;
  String street1;
  String street2;
  String phoneNumber;

  OmiseTokenInfo(this.city, this.country, this.postalCode, this.state,
      this.street1, this.street2, this.phoneNumber);
}

class OmiseSourceInfo {
  String barcode;
  String email;
  int installmentTerm;
  String name;
  String storeId;
  String storeName;
  String terminalId;
  String phoneNumber;
  bool zeroInterestInstallments;

  OmiseSourceInfo(
      this.barcode,
      this.email,
      this.installmentTerm,
      this.name,
      this.storeId,
      this.storeName,
      this.terminalId,
      this.phoneNumber,
      this.zeroInterestInstallments);
}
