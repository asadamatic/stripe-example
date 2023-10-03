import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_example/config.dart';
import 'package:stripe_example/custom_card_form/custom_card_form.dart';
import 'package:stripe_example/main.dart';
import 'package:stripe_example/widgets/loading_button.dart';

const String paymentIntentsAPI = 'https://api.stripe.com/v1/payment_intents';
String confirmPaymentIntentAPI(String paymentIntentId) =>
    'https://api.stripe.com/v1/payment_intents/$paymentIntentId/confirm';

/// If this is false, then there is need to call
/// [confirmPaymentInent] API.
const bool confirmPayment = true;

class CustomCardPaymentScreen extends StatefulWidget {
  @override
  _CustomCardPaymentScreenState createState() =>
      _CustomCardPaymentScreenState();
}

class _CustomCardPaymentScreenState extends State<CustomCardPaymentScreen> {
  CardDetails _card = CardDetails();
  bool? _saveCard = false;

  final formKey = GlobalKey<FormState>();

  onCardDetailsChanged(CardDetails _changedCardDetails) {
    _card = _changedCardDetails;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
                margin: EdgeInsets.all(16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    'If you don\'t want to or can\'t rely on the CardField you'
                    ' can use the dangerouslyUpdateCardDetails in combination with '
                    'your own card field implementation. \n\n'
                    'Please beware that this will potentially break PCI compliance: '
                    'https://stripe.com/docs/security/guide#validating-pci-compliance')),
            SizedBox(
              width: 300.0,
              child: Flexible(
                  child: CreditCardFormCustom(
                onCardDetailsChanged: onCardDetailsChanged,
                formKey: formKey,
                cardNumber: '',
                cvvCode: '',
                expiryDate: '',
              )),
            ),
            CheckboxListTile(
              value: _saveCard,
              onChanged: (value) {
                setState(() {
                  _saveCard = value;
                });
              },
              title: Text('Save card during payment'),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: LoadingButton(
                onPressed: _handlePayPress,
                text: 'Pay',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayPress() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    print('Card Details');
    print(_card.number);
    await Stripe.instance.dangerouslyUpdateCardDetails(_card);

    try {
      final billingDetails = BillingDetails(
          email: 'email@stripe.com',
          phone: '+48888000888',
          address: Address(
            city: 'Houston',
            country: 'US',
            line1: '1459  Circle Drive',
            line2: '',
            state: 'Texas',
            postalCode: '77063',
          )); // mocked data for tests

      final paymentMethod = await Stripe.instance.createPaymentMethod(
          params: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(
          billingDetails: billingDetails,
        ),
      ));

      final paymentIntentResult =
          await createPaymentIntent('43122', 'PKR', paymentMethod);
      print('Payment Intent');
      log(paymentIntentResult.toString());

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
    } catch (e) {
      showErrorSnackbar(context, 'Error: $e');
      rethrow;
    }
  }



  Future<void> handleNextAction(
      BuildContext context, String clientSecret) async {
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
}

  void showErrorSnackbar(BuildContext context, String error) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $error')));
  }

  void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
