import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/providers/authprovider.dart';

class AccountScreen extends ConsumerWidget {
  static const routeName = '/account';

  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider); // Fetching the authentication provider
    final user = auth.userModel; // Accessing user data
    final isLoggedIn = auth.isAuthenticated; // Checking login state

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(context, isLoggedIn, user, ref),
            const SizedBox(height: 20),
           
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, bool isLoggedIn, dynamic user, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundImage: AssetImage('assets/account.png'),
          ),
          const SizedBox(height: 10),
          Text(
            isLoggedIn && user != null
                ? 'Welcome To ZaloniDentalHub, ${user.firstName} ${user.lastName}'
                : 'Welcome To ZaloniDentalHub',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          if (!isLoggedIn)
            Row(
              children: [
                _buildButton('Login', () {
                  Navigator.pushNamed(context, '/loginScreen');
                }),
                const SizedBox(width: 10),
                _buildButton('Register', () {
                  Navigator.pushNamed(context, '/registerScreen');
                }),
              ],
            )
          else
            _buildButton('Logout', () {
              ref.read(authProvider.notifier).logout();
            }),
        ],
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(
        text,
        style: const TextStyle(color: Colors.blue),
      ),
    );
  }
  
  
}
