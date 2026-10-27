
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../navigation/main_navigation.dart';
import '../../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color primaryRed = Color(0xFFE31E24);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  bool _isLoading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Login successful: save this user's FCM token.
      await NotificationService.initialize();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigation(),
        ),
            (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Login failed. Please try again.';
      }

      if (mounted) {
        _showMessage(message);
      }
    } catch (e) {
      debugPrint('Login/notification error: $e');

      if (mounted) {
        _showMessage(
          'Login succeeded, but notification setup may have failed.',
        );

        // Continue into the app if authentication succeeded.
        if (_auth.currentUser != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            ),
                (route) => false,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Log In',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: LoginScreen.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 30),
            Image.asset(
              'assets/images/logo.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: 120,
                  height: 120,
                  child: Icon(
                    Icons.bloodtype,
                    color: LoginScreen.primaryRed,
                    size: 80,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log in to continue',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 35),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: LoginScreen.primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                  LoginScreen.primaryRed.withAlpha(150),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  'Log In',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed:
              _isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Back to Welcome',
                style: TextStyle(
                  color: LoginScreen.primaryRed,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
