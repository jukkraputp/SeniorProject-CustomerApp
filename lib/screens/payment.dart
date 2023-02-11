import 'package:customer/interfaces/payment.dart';
import 'package:customer/providers/app_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

class PaymentSelectionScreen extends StatelessWidget {
  const PaymentSelectionScreen({super.key, required this.setPaymentMethod});

  final void Function() setPaymentMethod;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Payment')),
      body: ListView(
        children: <Widget>[
          // Cash
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: ElevatedButton(
                onPressed: () {
                  Provider.of<AppProvider>(context, listen: false)
                      .setPaymentMethod(Payment.cash);
                  setPaymentMethod();
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: <Widget>[
                    const Icon(FontAwesomeIcons.moneyBillWave),
                    const SizedBox(width: 20),
                    Text(Payment.cash)
                  ],
                )),
          ),
          // PromptPay
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: ElevatedButton(
                onPressed: () {
                  Provider.of<AppProvider>(context, listen: false)
                      .setPaymentMethod(Payment.promptpay);
                  setPaymentMethod();
                  print(
                      'Current Payment Method: ${Provider.of<AppProvider>(context, listen: false).paymentMethod}');
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: <Widget>[
                    const Icon(FontAwesomeIcons.qrcode),
                    const SizedBox(width: 20),
                    Text(Payment.promptpay)
                  ],
                )),
          ),
          // Mobile Banking
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: ElevatedButton(
                onPressed: () {
                  Provider.of<AppProvider>(context, listen: false)
                      .setPaymentMethod(Payment.mobileBanking);
                  setPaymentMethod();
                  Navigator.of(context).pop();
                },
                child: Row(
                  children: <Widget>[
                    const Icon(FontAwesomeIcons.bank),
                    const SizedBox(width: 20),
                    Text(Payment.mobileBanking)
                  ],
                )),
          ),
        ],
      ),
    );
  }
}
