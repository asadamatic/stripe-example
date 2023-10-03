import 'package:stripe_example/custom_card_form/enum.dart';

Map<String, int>? getExpiryDateData(String expiryDate) {
  // Split the string by '/' to get month and year parts
  List<String> parts = expiryDate.split('/');

  // Check if there are exactly two parts (month and year)
  if (parts.length != 2) {
    throw ArgumentError("Invalid expiry date format");
  }

  // Extract the month and year as integers
  int? month = int.tryParse(parts[0]);
  int? year = int.tryParse(parts[1]);

  // Check if month and year are valid integers
  if (month == null || year == null) {
    return null;
  }

  // Create a Map to hold the extracted data
  Map<String, int> expiryData = {
    'month': month,
    'year': year,
  };

  return expiryData;
}

@deprecated
enum CardType {
  otherBrand,
  mastercard,
  visa,
  rupay,
  americanExpress,
  unionpay,
  discover,
  elo,
  hipercard,
}

@deprecated
const Map<CardType, String> CardTypeIconAsset = <CardType, String>{
  CardType.visa: 'assets/card_icons/visa.png',
  CardType.rupay: 'assets/card_icons/rupay.png',
  CardType.americanExpress: 'assets/card_icons/amex.png',
  CardType.mastercard: 'assets/card_icons/mastercard.png',
  CardType.unionpay: 'assets/card_icons/unionpay.png',
  CardType.discover: 'assets/card_icons/discover.png',
  CardType.elo: 'assets/card_icons/elo.png',
  CardType.hipercard: 'assets/card_icons/hipercard.png',
};

/// Credit Card prefix patterns as of March 2019
/// A [List<String>] represents a range.
/// i.e. ['51', '55'] represents the range of cards starting with '51' to those starting with '55'
Map<CreditCardType, Set<List<String>>> cardNumPatterns =
    <CreditCardType, Set<List<String>>>{
  CreditCardType.visa: <List<String>>{
    <String>['4'],
  },
  CreditCardType.rupay: <List<String>>{
    <String>['60'],
    <String>['6521'],
    <String>['6522'],
  },
  CreditCardType.americanExpress: <List<String>>{
    <String>['34'],
    <String>['37'],
  },
  CreditCardType.unionpay: <List<String>>{
    <String>['62'],
  },
  CreditCardType.discover: <List<String>>{
    <String>['6011'],
    <String>['622126', '622925'], // China UnionPay co-branded
    <String>['644', '649'],
    <String>['65']
  },
  CreditCardType.mastercard: <List<String>>{
    <String>['51', '55'],
    <String>['2221', '2229'],
    <String>['223', '229'],
    <String>['23', '26'],
    <String>['270', '271'],
    <String>['2720'],
  },
  CreditCardType.elo: <List<String>>{
    <String>['401178'],
    <String>['401179'],
    <String>['438935'],
    <String>['457631'],
    <String>['457632'],
    <String>['431274'],
    <String>['451416'],
    <String>['457393'],
    <String>['504175'],
    <String>['506699', '506778'],
    <String>['509000', '509999'],
    <String>['627780'],
    <String>['636297'],
    <String>['636368'],
    <String>['650031', '650033'],
    <String>['650035', '650051'],
    <String>['650405', '650439'],
    <String>['650485', '650538'],
    <String>['650541', '650598'],
    <String>['650700', '650718'],
    <String>['650720', '650727'],
    <String>['650901', '650978'],
    <String>['651652', '651679'],
    <String>['655000', '655019'],
    <String>['655021', '655058']
  },
  CreditCardType.hipercard: <List<String>>{
    <String>['606282'],
  },
};

CreditCardType? detectCCType(String cardNumber) {
  //Default card type is other
  CreditCardType cardType = CreditCardType.unknown;

  if (cardNumber.isEmpty) {
    return cardType;
  }

  cardNumPatterns.forEach(
    (CreditCardType type, Set<List<String>> patterns) {
      for (List<String> patternRange in patterns) {
        // Remove any spaces
        String ccPatternStr = cardNumber.replaceAll(RegExp(r'\s+\b|\b\s'), '');
        final int rangeLen = patternRange[0].length;
        // Trim the Credit Card number string to match the pattern prefix length
        if (rangeLen < cardNumber.length) {
          ccPatternStr = ccPatternStr.substring(0, rangeLen);
        }

        if (patternRange.length > 1) {
          // Convert the prefix range into numbers then make sure the
          // Credit Card num is in the pattern range.
          // Because Strings don't have '>=' type operators
          final int ccPrefixAsInt = int.parse(ccPatternStr);
          final int startPatternPrefixAsInt = int.parse(patternRange[0]);
          final int endPatternPrefixAsInt = int.parse(patternRange[1]);
          if (ccPrefixAsInt >= startPatternPrefixAsInt &&
              ccPrefixAsInt <= endPatternPrefixAsInt) {
            // Found a match
            cardType = type;
            break;
          }
        } else {
          // Just compare the single pattern prefix with the Credit Card prefix
          if (ccPatternStr == patternRange[0]) {
            // Found a match
            cardType = type;
            break;
          }
        }
      }
    },
  );

  return cardType;
}

CreditCardType convertDisplayNameToEnum(String displayName) {
  if (displayName == null) {
    return CreditCardType.unknown;
  }
  List<String> words = displayName.split(' ');
  String formattedName = words.first.toLowerCase() +
      words
          .sublist(1)
          .map((word) =>
              word.substring(0, 1).toUpperCase() +
              word.substring(1).toLowerCase())
          .join('');

  return CreditCardType.values.firstWhere(
    (type) => type.toString().split('.').last == formattedName,
    orElse: () => CreditCardType.unknown,
  );
}
