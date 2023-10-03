import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_example/main.dart';
import 'package:stripe_example/screens/card_payments/custom_card_payment_screen.dart';
import 'package:stripe_example/screens/wallets/apple_pay_create_payment_method.dart';
import 'package:stripe_example/widgets/example_scaffold.dart';
import 'package:stripe_example/widgets/loading_button.dart';

import '../../config.dart';
import 'dart:developer' as developer;

var rng = Random();

class ApplePayScreen extends StatefulWidget {
  @override
  _ApplePayScreenState createState() => _ApplePayScreenState();
}

class _ApplePayScreenState extends State<ApplePayScreen> {
  // final items = [
  //   ApplePayCartSummaryItem.immediate(
  //     label: 'Product Test',
  //     amount: '0.01',
  //   )
  // ];

  final shippingMethods = [
    ApplePayShippingMethod(
      identifier: 'free',
      detail: 'Arrives by July 2',
      label: 'Free Shipping',
      amount: '0.0',
    ),
    ApplePayShippingMethod(
      identifier: 'standard',
      detail: 'Arrives by June 29',
      label: 'Standard Shipping',
      amount: '3.21',
    )
  ];

  @override
  void initState() {
    Stripe.instance.isPlatformPaySupportedListenable.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    Stripe.instance.isPlatformPaySupportedListenable.removeListener(update);
    super.dispose();
  }

  void update() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final value = rng.nextInt(20000).toDouble();
    var amount = clampDouble(value, 10000, 25000).toInt().toString();
    ;
    // "10000";

    final items = [
      ApplePayCartSummaryItem.immediate(
        label: 'Cart',
        amount: amount,
      )
    ];
    return ExampleScaffold(
      title: 'Apple Pay',
      tags: ['iOS'],
      padding: EdgeInsets.all(16),
      children: [
        if (Stripe.instance.isPlatformPaySupportedListenable.value)
          LoadingButton(
            // TODO: Uncomment this if you want to use PlatformPaymentButton
            // onShippingContactSelected: (contact) async {
            //   debugPrint('Shipping contact updated $contact');

            //   // Mandatory after entering a shipping contact
            //   await Stripe.instance.updatePlatformSheet(
            //     params: PlatformPaySheetUpdateParams.applePay(
            //       summaryItems: items,
            //       shippingMethods: shippingMethods,
            //       errors: [],
            //     ),
            //   );

            //   return;
            // },
            // onShippingMethodSelected: (method) async {
            //   debugPrint('Shipping method updated $method');
            //   // Mandatory after entering a shipping contact
            //   await Stripe.instance.updatePlatformSheet(
            //     params: PlatformPaySheetUpdateParams.applePay(
            //       summaryItems: items,
            //       shippingMethods: shippingMethods,
            //       errors: [],
            //     ),
            //   );

            //   return;
            // },
            // onCouponCodeEntered: (couponCode) {
            //   debugPrint('set coupon $couponCode');
            // },
            // onOrderTracking: () async {
            //   debugPrint('set order tracking');

            //   /// Provide a URL to your web service that will provide the order details
            //   ///
            //   await Stripe.instance.configurePlatformOrderTracking(
            //       orderDetails: PlatformPayOrderDetails.applePay(
            //     orderTypeIdentifier: 'orderTypeIdentifier',
            //     orderIdentifier: 'https://your-web-service.com/v1/orders/',
            //     webServiceUrl: 'webServiceURL',
            //     authenticationToken: 'token',
            //   ));
            // },
            // type: PlatformButtonType.buy,
            // appearance: PlatformButtonStyle.whiteOutline,
            text: 'Apple Pay',
            onPressed: () => _handlePayPress(
              amount: amount,
              summaryItems: items,
              shippingMethods: shippingMethods,
            ),
          )
        else
          Text('Apple Pay is not available in this device'),
      ],
    );
  }

  Future<void> _handlePayPress({
    required String amount,
    required List<ApplePayCartSummaryItem> summaryItems,
    required List<ApplePayShippingMethod> shippingMethods,
  }) async {
    try {
      // 1. fetch Intent Client Secret from backend
      final paymentIntent = await createPaymentIntent(amount, 'PKR');
      developer.log(paymentIntent.toString());
      final clientSecret = paymentIntent['client_secret'];

      if (paymentIntent['error'] != null) {
        showErrorSnackbar(context, paymentIntent['error']['message']);
        return;
      }
      // 2. Confirm apple pay payment
      final confirmPaymentIntent =
          await Stripe.instance.confirmPlatformPayPaymentIntent(
        clientSecret: clientSecret,
        confirmParams: PlatformPayConfirmParams.applePay(
          applePay: ApplePayParams(
              cartItems: summaryItems,
              requiredShippingAddressFields: [
                ApplePayContactFieldsType.name,
                ApplePayContactFieldsType.postalAddress,
                ApplePayContactFieldsType.emailAddress,
                ApplePayContactFieldsType.phoneNumber,
              ],
              shippingMethods: shippingMethods,
              merchantCountryCode: 'PK',
              currencyCode: 'PKR',
              supportsCouponCode: true,
              couponCode: 'Coupon'),
        ),
      );

      developer.log(confirmPaymentIntent.toString());
      if (paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation) {
        await confirmIntent(paymentIntent.id);
      } else if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
        showSuccessSnackbar(context, 'Payment Successful');
      } else {
        showErrorSnackbar(context, 'Error in confirming payment.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      rethrow;
    }
  }
}

const bool confirmPayment = true;

calculateAmount(String amount) {
  final calculatedAmout = (int.parse(amount)) * 100;
  return calculatedAmout.toString();
}

createPaymentIntent(String amount, String currency) async {
  try {
    //Request body
    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
      // 'payment_method': paymentMethod.id,
      // Either set this to true or call the confirm payment API
      // 'items': "['id-1']",

      // This payment cannot be confirmed automatically
      //as it does not include a paymentMethod
      // "confirm": '$confirmPayment'
    };

    //Make post request to Stripe
    var response = await http.post(
      Uri.parse(paymentIntentsAPI),
      headers: {
        'Authorization': 'Bearer ${stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    return json.decode(response.body);
  } catch (err, stackTrace) {
    developer.log("Radix Error", error: err, stackTrace: stackTrace);
    throw Exception(err.toString());
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
