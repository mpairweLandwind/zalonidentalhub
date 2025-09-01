import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/providers/authprovider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).register(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to LoginScreen after successful registration
        Navigator.pushReplacementNamed(context, '/loginScreen');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        // Make the screen scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value!.isEmpty ? 'Enter first name' : null,
                ),
                const SizedBox(height: 16), // Add spacing
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => value!.isEmpty ? 'Enter last name' : null,
                ),
                const SizedBox(height: 16), // Add spacing
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                      value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 16), // Add spacing
                TextFormField(
                  controller: _phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                ),
                const SizedBox(height: 16), // Add spacing
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16), // Add spacing
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  obscureText: true,
                  validator: (value) => value != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50), // Full-width button
                  ),
                  child: authState.isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
                if (authState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                SizedBox(height: screenHeight * 0.05), // Add extra space at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
