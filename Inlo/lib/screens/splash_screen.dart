import 'package:flutter/material.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // --- MODERN SLATE & INDIGO PALETTE ---
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _bgSlate = Color(0xFFF8FAFC);
  static const Color _textMain = Color(0xFF1E293B);
  static const Color _textMuted = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    // Logic remains untouched: 3-second delay then move to Login
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgSlate, // Updated to light slate background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Updated App Icon Container
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _indigo.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.house_rounded,
                size: 50,
                color: _indigo, // Updated to Indigo
              ),
            ),
            const SizedBox(height: 32),
            // Updated Title
            const Text(
              'Inlo',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900, // Thicker weight for premium feel
                color: _textMain,
                letterSpacing: -1.5,
              ),
            ),
            const SizedBox(height: 8),
            // Updated Subtitle
            const Text(
              'Find your perfect stay',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _textMuted,
              ),
            ),
            const SizedBox(height: 60),
            // Updated Loading Indicator
            SizedBox(
              width: 60,
              height: 3, // Slightly thinner line for elegance
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  backgroundColor: _indigo.withOpacity(0.1),
                  color: _indigo,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}