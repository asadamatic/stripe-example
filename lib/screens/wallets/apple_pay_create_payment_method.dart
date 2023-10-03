import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_example/main.dart';
import 'package:stripe_example/screens/card_payments/custom_card_payment_screen.dart';
import 'package:stripe_example/screens/wallets/apple_pay_screen.dart';
import 'package:stripe_example/widgets/example_scaffold.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:stripe_example/widgets/loading_button.dart';

class ApplePayCreatePaymentMethodScreen extends StatefulWidget {
  @override
  _ApplePayScreenState createState() => _ApplePayScreenState();
}

class _ApplePayScreenState extends State<ApplePayCreatePaymentMethodScreen> {
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
    return ExampleScaffold(
      title: 'Apple Pay',
      tags: ['iOS'],
      padding: EdgeInsets.all(16),
      children: [
        if (Stripe.instance.isPlatformPaySupportedListenable.value)
          LoadingButton(
            text: 'Apple Pay',
            onPressed: () async=> await _handlePayPress(amount),
          )
        else
          Text('Apple Pay is not available in this device'),
      ],
    );
  }

  Future<void> _handlePayPress(String amount) async {
    // 1. create payment method

    final paymentMethod = await Stripe.instance.createPlatformPayPaymentMethod(
      params: PlatformPayPaymentMethodParams.applePay(
        applePayParams: ApplePayParams(
          cartItems: [
            ApplePayCartSummaryItem.immediate(
              label: 'Product Test',
              amount: amount,
            ),
          ],
          requiredShippingAddressFields: [
            ApplePayContactFieldsType.name,
            ApplePayContactFieldsType.emailAddress,
            ApplePayContactFieldsType.postalAddress,
          ],
          // shippingMethods: [
          //   ApplePayShippingMethod(
          //     identifier: 'free',
          //     detail: 'Arrives by July 2',
          //     label: 'Free Shipping',
          //     amount: '0.0',
          //   ),
          //   ApplePayShippingMethod(
          //     identifier: 'standard',
          //     detail: 'Arrives by June 29',
          //     label: 'Standard Shipping',
          //     amount: '3.21',
          //   ),
          // ],
          merchantCountryCode: 'PK',
          currencyCode: 'PKR',
        ),
      ),
    );

    final paymentIntentResult =
        await createPaymentIntent(amount, 'PKR', paymentMethod);
    print('Payment Intent');
    developer.log(paymentIntentResult.toString());

    if (paymentIntentResult['error'] != null) {
      showErrorSnackbar(context, paymentIntentResult['error']);
      return;
    }

    if (paymentIntentResult['client_secret'] != null &&
        paymentIntentResult['next_action'] == null) {
      if (confirmPayment) {
        showSuccessSnackbar(context, 'Payment Successful');
      } else {
        final confirmIntentResult =
            await confirmIntent(paymentIntentResult['id']);
        if (confirmIntentResult['error'] != null) {
          showErrorSnackbar(context, confirmIntentResult['error']);
          return;
        }
        if (confirmIntentResult['client_secret'] != null &&
            confirmIntentResult['next_action'] == null) {
          showSuccessSnackbar(context, 'Payment Successful');
        }
        if (confirmIntentResult['client_secret'] != null &&
            confirmIntentResult['next_action'] != null) {
          await handleNextAction(context, confirmIntentResult['client_secret']);
        }
      }
      return;
    }

    if (paymentIntentResult['client_secret'] != null &&
        paymentIntentResult['next_action'] != null) {
      await handleNextAction(context, paymentIntentResult['client_secret']);
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Success!: The payment method with id: ${paymentMethod.id} was created successfully,')));
  }
}

const bool confirmPayment = true;

calculateAmount(String amount) {
  final calculatedAmout = (int.parse(amount)) * 100;
  return calculatedAmout.toString();
}

createPaymentIntent(
    String amount, String currency, PaymentMethod paymentMethod) async {
  try {
    //Request body
    Map<String, dynamic> body = {
      'amount': calculateAmount(amount),
      'currency': currency,
      'payment_method': paymentMethod.id,
      // Either set this to true or call the confirm payment API
      // 'items': "['id-1']",

      // This payment cannot be confirmed automatically
      //as it does not include a paymentMethod
      "confirm": '$confirmPayment'
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
  } catch (err) {
    throw Exception(err.toString());
  }
}

confirmIntent(String paymentIntentId) async {
  try {
    //Request body
    Map<String, dynamic> body = {};

    //Make post request to Stripe
    var response = await http.post(
      Uri.parse(confirmPaymentIntentAPI(paymentIntentId)),
      headers: {
        'Authorization': 'Bearer ${stripeSecretKey}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    final decodedJson = json.decode(response.body);
    print('Confirm Payment');
    print(decodedJson);

    return json.decode(response.body);
  } catch (err) {
    throw Exception(err.toString());
  }
}

Future<void> handleNextAction(BuildContext context, String clientSecret) async {
  final paymentIntent = await Stripe.instance.handleNextAction(clientSecret);
  print('New Payment Intent');
  print(paymentIntent);

  if (paymentIntent.status == PaymentIntentsStatus.RequiresConfirmation) {
    await confirmIntent(paymentIntent.id);
  } else if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
    showSuccessSnackbar(context, 'Payment Successful');
  } else {
    showErrorSnackbar(context, 'Error in confirming payment.');
  }
}
