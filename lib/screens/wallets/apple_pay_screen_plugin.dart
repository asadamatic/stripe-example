import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:pay/pay.dart' as pay;
import 'package:stripe_example/config.dart';
import 'package:stripe_example/screens/wallets/apple_pay_screen.dart';
import 'package:stripe_example/widgets/example_scaffold.dart';



class ApplePayExternalPluginScreen extends StatefulWidget {
  @override
  _ApplePayExternalPluginScreenState createState() =>
      _ApplePayExternalPluginScreenState();
}

class _ApplePayExternalPluginScreenState
    extends State<ApplePayExternalPluginScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = rng.nextInt(20000).toDouble();
    var amount = clampDouble(value, 10000, 25000).round().toString();
    var _paymentItems = [
  pay.PaymentItem(
    label: 'Total',
    amount: amount,
    status: pay.PaymentItemStatus.final_price,
  )
];
    return ExampleScaffold(
      title: 'Apple Pay',
      padding: EdgeInsets.all(16),
      tags: ['iOS', 'Pay plugin'],
      children: [
        pay.ApplePayButton(
          paymentConfiguration: pay.PaymentConfiguration.fromJsonString(
            _paymentProfile,
          ),
          paymentItems: _paymentItems,
          margin: const EdgeInsets.only(top: 15),
          onPaymentResult: (paymentResult) => onApplePayResult(paymentResult, amount),
          loadingIndicator: const Center(
            child: CircularProgressIndicator(),
          ),
          childOnError: Text('Apple Pay is not available in this device'),
          onError: (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'There was an error while trying to perform the payment'),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> onApplePayResult(paymentResult, amount) async {
    try {
      log(paymentResult.toString());
      //debugPrint(paymentResult.toString());
      // 1. Get Stripe token from payment result
      final token = await Stripe.instance.createApplePayToken(paymentResult);
      log('Token');
      log(token.toString());
      // 2. fetch Intent Client Secret from backend
      final response = await createPaymentIntent(amount, 'PKR');
      log(response.toString());
      final clientSecret = response['client_secret'];

      final params = PaymentMethodParams.cardFromToken(
        paymentMethodData: PaymentMethodDataCardFromToken(
          token: token.id,
        ),
      );

      // 3. Confirm Apple pay payment method
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: params,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Apple Pay payment succesfully completed')),
      );
    } catch (e, stackTrace) {
      log(e.toString(), stackTrace: stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Map<String, dynamic>> fetchPaymentIntentClientSecret() async {
    final url = Uri.parse('$kApiUrl/create-payment-intent');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'email': 'example@gmail.com',
        'currency': 'usd',
        'items': ['id-1'],
        'request_three_d_secure': 'any',
      }),
    );
    return json.decode(response.body);
  }
}

final _paymentProfile = """{
  "provider": "apple_pay",
  "data": {
    "merchantIdentifier": "merchant.flutter.stripe.test",
    "displayName": "Sam's Fish",
    "merchantCapabilities": ["3DS"],
    "supportedNetworks": [
      "amex",
      "visa",
      "discover",
      "masterCard"
    ],
    "countryCode": "US",
    "currencyCode": "USD",
    "shippingMethods": [
      {
        "amount": "0.00",
        "detail": "Available within an hour",
        "identifier": "in_store_pickup",
        "label": "In-Store Pickup"
      },
      {
        "amount": "4.99",
        "detail": "5-8 Business Days",
        "identifier": "flat_rate_shipping_id_2",
        "label": "UPS Ground"
      },
      {
        "amount": "29.99",
        "detail": "1-3 Business Days",
        "identifier": "flat_rate_shipping_id_1",
        "label": "FedEx Priority Mail"
      }
    ]
  }
}
""";
