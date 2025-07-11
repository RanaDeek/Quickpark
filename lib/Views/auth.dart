import 'package:drawer/Views/signup.dart';
import 'package:flutter/material.dart';
import 'signin.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE2E6ED),
      body: SafeArea(
        child: Center(
          child: Padding(
            // Removed or reduced vertical padding to move content up
            padding: const EdgeInsets.symmetric(vertical: 80), // You can tweak this value to adjust the position
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, // Align the content at the top
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "QuickPark",
                  style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF101D33), // Updated text color
                  ),
                ),
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30),
                  child: Text(
                    "Park With Ease, Save Time and Make Your City Smarter",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF101D33), // Updated text color
                      fontSize: 16,
                    ),
                  ),
                ),
                // Image widget
                Image.asset("assets/home.png", width: 350, height: 350),


                const SizedBox(height: 20),

                // LOGIN BUTTON
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ParkCarScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF101D33), // Text color
                      backgroundColor: Colors.transparent, // Transparent background
                      side: const BorderSide(color: Color(0xFF101D33), width: 2), // Border color
                      elevation: 0, // No shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "LOGIN",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101D33), // Text color inside button
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // SIGN UP BUTTON
                SizedBox(
                  width: 350,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: const Color(0xFF101D33), // Text color
                      backgroundColor: Colors.transparent, // Transparent background
                      side: const BorderSide(color: Color(0xFF101D33), width: 2), // Border color
                      elevation: 0, // No shadow
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "SIGN UP",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF101D33), // Text color inside button
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
