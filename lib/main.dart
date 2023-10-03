import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:stripe_example/.env.example.dart';
import 'screens/screens.dart';
import 'widgets/dismiss_focus_overlay.dart';

const stripePublishableKey =
    'pk_test_51Mt3kbLQNGoDmJOHVJqusEmxZqHcrxsdhUxCYFzmpE7TA5OiqOtRvnKwDLbQRoBsPJ6qficCpPcFLH3mC6Fm35ix00yXJPW2iR';
const stripeSecretKey =
    'sk_test_51Mt3kbLQNGoDmJOH52NXQfPx0lAb90rJeJCbMBEBEdeXBoYEJfrsaPuMWi0QhFsE93cUHWCfbEYlqYHSCuRD2Vlj00afaUPoEo';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = stripePublishableKey;
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DismissFocusOverlay(
      child: MaterialApp(
        theme: exampleAppTheme,
        home: HomePage(),
        navigatorObservers: [],
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stripe Examples'),
      ),
      body: ListView(children: [
        ...ListTile.divideTiles(
          context: context,
          tiles: [for (final example in Example.screens) example],
        ),
      ]),
    );
  }
}

final exampleAppTheme = ThemeData(
  colorScheme: ColorScheme.light(
    primary: Color(0xff6058F7),
    secondary: Color(0xff6058F7),
  ),
  primaryColor: Colors.white,
  appBarTheme: AppBarTheme(elevation: 1),
);