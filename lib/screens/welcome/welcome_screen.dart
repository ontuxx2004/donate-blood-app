
import 'dart:async';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  static const Color primaryRed = Color(0xFFE31E24);

  final List<String> motivationalMessages = [
    'Be a hero. Save a life.',
    'Every drop counts.',
    'Your kindness can save a life.',
    'One donation can make a difference.',
  ];

  int currentMessage = 0;
  Timer? messageTimer;

  @override
  void initState() {
    super.initState();

    messageTimer = Timer.periodic(
      const Duration(seconds: 3),
          (timer) {
        if (!mounted) return;

        setState(() {
          currentMessage =
              (currentMessage + 1) % motivationalMessages.length;
        });
      },
    );
  }

  @override
  void dispose() {
    messageTimer?.cancel();
    super.dispose();
  }

  // Get Started opens Login
  void goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void goToSignup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SignupScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryRed,
      body: SafeArea(
        child: Stack(
          children: [
            // Top decorative circle
            Positioned(
              top: -70,
              left: -50,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Bottom decorative circle
            Positioned(
              bottom: -90,
              right: -60,
              child: Container(
                width: 210,
                height: 210,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Blood icon
                    Container(
                      width: 115,
                      height: 115,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bloodtype,
                        color: primaryRed,
                        size: 70,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // App title
                    const Text(
                      'Donate Blood',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Save Lives',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Animated motivational message
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        motivationalMessages[currentMessage],
                        key: ValueKey(currentMessage),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Together, we can make a difference.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Get Started button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: primaryRed,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account?',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: goToLogin,
                          child: const Text(
                            'Log In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Signup
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: goToSignup,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.white,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Create New Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Footer
                    const Text(
                      'Every drop counts ❤️',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Developer credit
                    const Text(
                      'Developed by Talha Zubayer Ontu',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
