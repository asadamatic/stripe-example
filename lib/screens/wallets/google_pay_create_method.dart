import 'dart:convert';
import 'dart:developer';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_example/config.dart';
import 'package:stripe_example/main.dart';
import 'package:stripe_example/screens/card_payments/custom_card_payment_screen.dart';
import 'package:stripe_example/widgets/example_scaffold.dart';
import 'dart:developer' as developer;

import 'package:stripe_example/widgets/loading_button.dart';

var ran = Random();

class GoogleCreatePaymentMenthod extends StatefulWidget {
  const GoogleCreatePaymentMenthod({Key? key}) : super(key: key);

  @override
  _GoogleCreatePaymentMenthodState createState() =>
      _GoogleCreatePaymentMenthodState();
}

class _GoogleCreatePaymentMenthodState
    extends State<GoogleCreatePaymentMenthod> {
  Future<void> startGooglePay(String amount) async {
    final googlePaySupported = await Stripe.instance
        .isPlatformPaySupported(googlePay: IsGooglePaySupportedParams());
    if (googlePaySupported) {
      try {
        final paymentMethod = await Stripe.instance
            .createPlatformPayPaymentMethod(
                params: PlatformPayPaymentMethodParams.googlePay(
                    googlePayParams: GooglePayParams(
                      testEnv: true,
                      merchantName: 'Test Merchant',
                      merchantCountryCode: 'PK',
                      currencyCode: 'PKR',
                    ),
                    googlePayPaymentMethodParams: GooglePayPaymentMethodParams(
                        amount: int.parse(amount))));

        // 1. fetch Intent Client Secret from backend
        final paymentIntentResult =
            await createPaymentIntent("56472", "PKR", paymentMethod);
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
              await handleNextAction(
                  context, confirmIntentResult['client_secret']);
            }
          }
          return;
        }

        if (paymentIntentResult['client_secret'] != null &&
            paymentIntentResult['next_action'] != null) {
          await handleNextAction(context, paymentIntentResult['client_secret']);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Google Pay payment succesfully completed')),
        );
      } catch (e, stackTrace) {
        if (e is StripeException) {
          developer.log('Error during google pay',
              error: e.error, stackTrace: StackTrace.current);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.error}')),
          );
        } else {
          developer.log('Error during google pay',
              error: e, stackTrace: stackTrace);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google pay is not supported on this device')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = ran.nextInt(20000).toDouble();
    var amount = clampDouble(value, 10000, 25000).toInt().toString();
    ;
    return ExampleScaffold(
      title: 'Google Create Payment Method',
      tags: ['Android'],
      padding: EdgeInsets.all(16),
      children: [
        if (defaultTargetPlatform == TargetPlatform.android)
          SizedBox(
            height: 75,
            child: LoadingButton(
              text: "Google Pay",
              onPressed: () async {
                await startGooglePay(amount);
              },
            ),
          )
        else
          Text('Google Pay is not available in this device'),
      ],
    );
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
