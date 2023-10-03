import 'package:credit_card_validator/credit_card_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:stripe_example/custom_card_form/enum.dart';
import 'package:stripe_example/custom_card_form/masked_text_controller.dart';
import 'package:stripe_example/custom_card_form/utils.dart';

const String kCardNumberLabel = 'Card Number';
const String kCardNumberHint = 'Please Enter Your Credit Card Number';
const String kNumberValidationString = 'Card number is required';

class CustomCardField extends StatefulWidget {
  /// A widget showcasing credit card UI.
  const CustomCardField({
    this.cardNumber,
    this.textStyle,
    required this.onChanged,
    this.nextNode,
    super.key,
  });

  final Function(String) onChanged;
  final FocusNode? nextNode;

  /// A string indicating number on the card.
  final String? cardNumber;

  /// Applies text style to cardNumber, expiryDate, cardHolderName and cvvCode.
  final TextStyle? textStyle;

  /// floating animation enabled/disabled
  @override
  _CustomCardFieldState createState() => _CustomCardFieldState();
}

class _CustomCardFieldState extends State<CustomCardField>
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
    _cardNumberController = MaskedTextController(
        text: widget.cardNumber, mask: '0000 0000 0000 0000');
  }

  final formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    controller.dispose();

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  late TextEditingController _cardNumberController;

  CreditCardValidator _ccValidator = CreditCardValidator();

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _cardNumberController,
      onChanged: (String value) {
        setState(() {
          cardType = detectCCType(value);
        });
        widget.onChanged(value);
      },
      onEditingComplete: () {
        FocusScope.of(context).requestFocus(widget.nextNode);
      },
      decoration: InputDecoration(
        label: Text(kCardNumberLabel),
        hintText: kCardNumberHint,
        suffixIconConstraints:
            BoxConstraints(maxHeight: 45, maxWidth: 80.0, minWidth: 60.0),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(2.0),
          child: getCardTypeImage(cardType),
        ),
      ),
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      autofillHints: <String>[AutofillHints.creditCardNumber],
      validator: (String? value) {
        // Validate less that 13 digits +3 white spaces
        if (value!.isEmpty || value.length < 16) {
          return kNumberValidationString;
        }
        final result = _ccValidator.validateCCNum(value);

        if (!result.isValid) {
          return result.message;
        }
        return null;
      },
    );
  }

  Widget? getCardTypeImage(CreditCardType? cardType) {
    if (cardType == null) {
      return null;
    }
    if (cardType! == CreditCardType.unknown) {
      return SvgPicture.asset(cardType.imageAsset,
          width: 60.0, color: Theme.of(context).colorScheme.primary);
    }
    return Image.asset(
      cardType.imageAsset,
    );
  }
}
