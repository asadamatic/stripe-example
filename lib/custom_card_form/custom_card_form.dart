import 'package:credit_card_validator/credit_card_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_example/custom_card_form/custom_card_field.dart';
import 'package:stripe_example/custom_card_form/enum.dart';
import 'package:stripe_example/custom_card_form/masked_text_controller.dart';
import 'package:stripe_example/custom_card_form/utils.dart';

const String kExpiryDateLabel = 'Expire Date';
const String kExpiryDateHint = 'Month/Year';
const String kExpiryRequiredString = 'Expiry date is required';
const String kCvvLabel = 'CVV';
const String kCvvHint = '3 digits';
const String kCVCValidationString = 'CVC is invalid';
const String kCVCRequiredString = 'CVC card is required';

class CreditCardFormCustom extends StatefulWidget {
  /// A widget showcasing credit card UI.
  const CreditCardFormCustom({
    required this.onCardDetailsChanged,
    this.cardNumber,
    required this.formKey,
    this.expiryDate,
    this.cvvCode,
    this.textStyle,
    super.key,
  });

  final Function(CardDetails) onCardDetailsChanged;
  final GlobalKey<FormState> formKey;

  /// A string indicating number on the card.
  final String? cardNumber;

  /// A string indicating expiry date for the card.
  final String? expiryDate;

  /// A String indicating cvv code.
  final String? cvvCode;

  /// Applies text style to cardNumber, expiryDate, cardHolderName and cvvCode.
  final TextStyle? textStyle;

  /// floating animation enabled/disabled
  @override
  _CreditCardFormCustomState createState() => _CreditCardFormCustomState();
}

class _CreditCardFormCustomState extends State<CreditCardFormCustom>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController controller;

  CreditCardType? cardType;
  String? cardNumber;
  bool isFrontVisible = true;
  bool isGestureUpdate = false;

  Orientation? orientation;
  Size? screenSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _expiryDateController =
        MaskedTextController(text: widget.expiryDate, mask: '00/00');

    _cvvCodeController =
        MaskedTextController(text: widget.cvvCode, mask: '0000');
  }

  final formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  late TextEditingController _expiryDateController;

  late TextEditingController _cvvCodeController;

  FocusNode cvvFocusNode = FocusNode();
  FocusNode expiryDateNode = FocusNode();
  CardDetails _cardDetails = CardDetails();

  CreditCardValidator _ccValidator = CreditCardValidator();
  @override
  Widget build(BuildContext context) {
    print('Rebuilt');
    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          CustomCardField(
              nextNode: expiryDateNode,
              cardNumber: _cardDetails.number,
              onChanged: (String? cardNumber) {
                _cardDetails = _cardDetails.copyWith(number: cardNumber);
                if (cardNumber != null) {
                  final newCardType = detectCCType(cardNumber);
                  if (newCardType != cardType) {
                    setState(() {
                      cardType = newCardType;
                    });
                  }
                }
                widget.onCardDetailsChanged(_cardDetails);
              }),
          TextFormField(
            controller: _expiryDateController,
            onChanged: (String value) {
              if (_expiryDateController.text.startsWith(RegExp('[2-9]'))) {
                _expiryDateController.text = '0' + _expiryDateController.text;
              }
              final date = getExpiryDateData(_expiryDateController.text);
              if (date != null) {
                _cardDetails = _cardDetails.copyWith(
                    expirationMonth: date['month'],
                    expirationYear: date['year']);
                widget.onCardDetailsChanged(_cardDetails);
              }
            },
            focusNode: expiryDateNode,
            onEditingComplete: () {
              FocusScope.of(context).requestFocus(cvvFocusNode);
            },
            decoration: InputDecoration(
              label: Text(kExpiryDateLabel),
              hintText: kExpiryDateHint,
            ),
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[
              AutofillHints.creditCardExpirationDate
            ],
            validator: (String? value) {
              if (value!.isEmpty) {
                return kExpiryRequiredString;
              }

              final result = _ccValidator.validateExpDate(value);

              if (!result.isValid) {
                return result.message;
              }

              return null;
            },
          ),
          TextFormField(
            focusNode: cvvFocusNode,
            controller: _cvvCodeController,
            maxLength: cardType?.noOfDigitsInCvc,
            decoration: InputDecoration(
              label: Text(kCvvLabel),
              hintText: kCvvHint,
            ),
            textInputAction: TextInputAction.next,
            autofillHints: const <String>[AutofillHints.creditCardSecurityCode],
            inputFormatters: [],
            onChanged: (String value) {
              _cardDetails = _cardDetails.copyWith(cvc: value);
              widget.onCardDetailsChanged(_cardDetails);
            },
            validator: (String? value) {
              if (value!.isEmpty) {
                return kCVCRequiredString;
              }

              if (cardType != null) {
                final result = value.length == cardType!.noOfDigitsInCvc;

                if (!result) {
                  return kCVCValidationString;
                }
              }

              return null;
            },
          ),
        ],
      ),
    );
  }
}
