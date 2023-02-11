import 'package:cached_network_image/cached_network_image.dart';
import 'package:customer/interfaces/payment.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';

class PromptPayQRCode extends StatelessWidget {
  const PromptPayQRCode(
      {super.key, required this.phoneNumber, required this.cost});

  final String phoneNumber;
  final double cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: CachedNetworkImage(imageUrl: PromptPay.qrcode(phoneNumber, cost)),
    );
  }
}
