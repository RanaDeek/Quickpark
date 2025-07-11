import 'package:flutter/material.dart';
import './auth.dart'; // Import AuthScreen

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize AnimationController
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1), // Duration of the animation
    )..repeat(reverse: true); // Repeat the animation (with reverse effect)

    // Create a Tween to animate vertical position of the image
    _animation = Tween<double>(begin: 0.0, end: 30.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // Smooth animation curve
      ),
    );

    // Navigate to AuthScreen after 3 seconds
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    });
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is disposed
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E6ED),
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Location Pin Image with animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Padding(
                  padding: EdgeInsets.only(bottom: _animation.value), // Dynamic padding based on animation
                  child: child,
                );
              },
              child: Image.asset(
                'assets/location.png', // Path to your location pin image
                width: 230, // Adjust size as needed
                height: 230,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
