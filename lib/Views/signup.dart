import 'package:flutter/material.dart';
import 'dart:convert'; // for utf8 encoding
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../Components/button.dart'; // Assuming you have a Button component
import '../Components/textfield.dart'; // Assuming you have an InputField component
import './auth.dart'; // Assuming the AuthScreen is in this file
import 'signin.dart'; // Assuming this screen exists for the next navigation

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final fullName = TextEditingController();
  final email = TextEditingController();
  final userName = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final user = {
        'fullName': fullName.text.trim(),
        'email': email.text.trim(),
        'userName': userName.text.trim(),
        'password': password.text.trim(),
      };

      try {
        final response = await http.post(
          Uri.parse('https://quickpark.onrender.com/api/users'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(user),
        );

        // Print the raw response body for debugging
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Attempt to decode the response
        final result = jsonDecode(response.body);

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("User registered successfully.")),
          );
          fullName.clear();
          email.clear();
          userName.clear();
          password.clear();
          confirmPassword.clear();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ParkCarScreen()), // Go to the next screen
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${result['message']}")),
          );
        }
      } catch (e) {
        // Handle any errors, including JSON parsing errors
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AuthScreen()),
            );
          },
        ),
        title: const Text("Sign Up", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF101D33),
      ),
      backgroundColor: const Color(0xFFE2E6ED),
      body: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 170),
            painter: WavePainter(),
          ),
          SafeArea(
            child: SizedBox.expand(
              child: Column(
                children: [
                  const SizedBox(height: 150),
                  const Text(
                    "Sign Up",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?", style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ParkCarScreen()),
                          );
                        },
                        child: const Text("Login"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              InputField(
                                hint: "Full Name",
                                icon: Icons.person,
                                controller: fullName,
                                validator: (value) =>
                                value!.isEmpty ? "Enter your full name" : null,
                                iconColor: const Color(0xFF101D33),
                              ),
                              InputField(
                                hint: "Email",
                                icon: Icons.email,
                                controller: email,
                                validator: (value) =>
                                value!.contains("@") ? null : "Enter a valid email",
                                iconColor: const Color(0xFF101D33),
                              ),
                              InputField(
                                hint: "Username",
                                icon: Icons.account_circle,
                                controller: userName,
                                validator: (value) {
                                  if (value == null || value.isEmpty) return "Enter a username";
                                  if (value.contains(' ')) return "Username cannot contain spaces";
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(RegExp(r'\s')), // No whitespace allowed
                                ],
                                iconColor: const Color(0xFF101D33),
                              ),
                              InputField(
                                hint: "Password",
                                icon: Icons.lock,
                                controller: password,
                                isPassword: true,
                                validator: (value) => value!.length < 6
                                    ? "Password must be at least 6 characters"
                                    : null,
                                iconColor: const Color(0xFF101D33),
                              ),
                              InputField(
                                hint: "Re-enter Password",
                                icon: Icons.lock,
                                controller: confirmPassword,
                                isPassword: true,
                                validator: (value) =>
                                value != password.text ? "Passwords do not match" : null,
                                iconColor: const Color(0xFF101D33),
                              ),
                              const SizedBox(height: 10),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: SizedBox(
                                  width: 360,
                                  child: Button(
                                    label: "SIGN UP",
                                    press: _handleSignup, // Calls the signup function
                                    color: const Color(0xFF101D33),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final Gradient gradient = LinearGradient(
      colors: [Color(0xFF101D33), Color(0xFF2C3E50)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    Paint paint = Paint()..shader = gradient.createShader(rect);

    Path path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
        size.width * 0.2, size.height * 0.3, size.width * 0.4, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.6, size.width, size.height * 0.2);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
