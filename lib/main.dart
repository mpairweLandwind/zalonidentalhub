import 'package:flutter/material.dart';
import 'package:zalonidentalhub/login_page.dart';
import 'package:zalonidentalhub/main_screen.dart';
import 'package:zalonidentalhub/models/cart_model.dart';
import 'package:zalonidentalhub/providers/product_provider.dart';
import 'package:zalonidentalhub/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zalonidentalhub/screens/account_screen.dart';
import 'package:zalonidentalhub/screens/cart_screen.dart';
import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/loginScreen': (context) => const LoginScreen(),
        '/registerScreen': (context) => const RegisterScreen(),
        '/Dashboard': (context) => const MainScreen(),
        '/CartScreen': (context) => CartScreen(
              cartItems: const [],
              cartTotal: 0,
              cart: Cart(),
              user: null,
            ),
        '/accountScreen': (context) => const AccountScreen(),
      },
      title: 'Zaloni Dental Hub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.wait<void>([
        ref.read(productProvider.notifier).fetchProducts(null),
        ref.read(productProvider.notifier).fetchCategory(),
        ref.read(productProvider.notifier).fetchPromotion(),
        ref.read(productProvider.notifier).fetchSpecialCategories(),
      ]); // Get the loaded products
    } catch (e) {
      debugPrint("Error loading data: $e");
    }

    if (mounted) {
      await Future.delayed(const Duration(seconds: 3)); // Wait for 5 seconds
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.lightBlue.shade300,
                Colors.blueAccent.shade700,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Flexible(
                flex: 2,
                child: Image.asset(
                  'assets/zaloni_logo.png', // Replace with your logo asset
                  height: 120.0,
                ),
              ),
              const SizedBox(height: 24.0),
              const Text(
                'Welcome to Zaloni Dental Hub',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Complete dental care at your fingertips.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // Navigate to the MainScreen (Dashboard)
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const MainScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blueAccent.shade700,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
            ],
          ),
        ),
      ),
    );
  }
}
