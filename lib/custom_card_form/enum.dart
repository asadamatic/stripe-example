import 'package:stripe_example/custom_card_form/utils.dart';

/// This can also be replace by [CardType] from [flutter-credit-card] package.
enum CreditCardType {
  americanExpress,
  rupay,
  dinersClub,
  discover,
  eftpos,
  jcb,
  mastercard,
  unionpay,
  visa,
  elo,
  hipercard,
  unknown,
}

extension CreditCardTypeExtension on CreditCardType {
  static const Map<CreditCardType, String> _displayNameMap = {
    CreditCardType.americanExpress: 'American Express',
    CreditCardType.dinersClub: 'Diners Club',
    CreditCardType.discover: 'Discover',
    CreditCardType.eftpos: 'Eftpos Australia',
    CreditCardType.elo: 'ELO',
    CreditCardType.hipercard: 'Hipercard',
    CreditCardType.jcb: 'JCB',
    CreditCardType.mastercard: 'MasterCard',
    CreditCardType.unionpay: 'UnionPay',
    CreditCardType.visa: 'Visa',
    CreditCardType.unknown: 'Unknown',
  };

  static const Map<CreditCardType, String> _imageAssetMap = {
    CreditCardType.americanExpress: 'assets/cards/american_express.png',
    CreditCardType.dinersClub: 'assets/cards/diners_club.png',
    CreditCardType.discover: 'assets/cards/discover.png',
    CreditCardType.eftpos: 'assets/cards/eftpos.png',
    CreditCardType.jcb: 'assets/cards/jcb.png',
    CreditCardType.mastercard: 'assets/cards/mastercard.png',
    CreditCardType.unionpay: 'assets/cards/unionpay.png',
    CreditCardType.visa: 'assets/cards/visa.png',
    CreditCardType.unknown: 'assets/cards/unknown_card_new.svg',
    CreditCardType.elo: 'assets/cards/elo.png',
    CreditCardType.hipercard: 'assets/cards/hipercard.png',
  };

  String get displayName => _displayNameMap[this] ?? 'Unknown';

  String get imageAsset =>
      _imageAssetMap[this] ?? 'assets/cards/unknown_card_small.png';

  int get noOfDigitsInCvc => this == CreditCardType.americanExpress ? 4 : 3;

  /// This function determines the Credit Card type based on the cardPatterns
  /// and returns it.
}
