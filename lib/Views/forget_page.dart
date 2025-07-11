import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

class ForgetPage extends StatefulWidget {
  const ForgetPage({super.key});

  @override
  _ForgetPageState createState() => _ForgetPageState();
}

class _ForgetPageState extends State<ForgetPage> {
  final emailController = TextEditingController();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? generatedOTP;
  bool otpSent = false;
  bool otpVerified = false;

  String hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Send OTP to email
  Future<void> _sendOTP() async {
    String email = emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://quickpark.onrender.com/api/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      generatedOTP = responseBody['otpToken']; // JWT from backend
      setState(() {
        otpSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your email')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send OTP')),
      );
    }
  }

  // Verify OTP using backend
  Future<void> _verifyOTP() async {
    String otp = otpController.text.trim();

    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://quickpark.onrender.com/api/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'otpToken': generatedOTP,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        otpVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP verified. Please enter new password.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP')),
      );
    }
  }

  // Reset password with new password
  Future<void> _resetPassword() async {
    String newPassword = newPasswordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('https://quickpark.onrender.com/api/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'otpToken': generatedOTP, // <-- correct key name
        'newPassword': newPassword, // Send plain text password here
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password has been reset successfully')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to reset password')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101D33),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.email, size: 60, color: Color(0xFF101D33)),
                  const SizedBox(height: 20),
                  Text(
                    otpVerified
                        ? "Reset Password"
                        : (otpSent ? "Enter OTP" : "Reset via Email"),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Email input
                  if (!otpSent)
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  // OTP input
                  if (otpSent && !otpVerified)
                    TextField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Enter OTP',
                        border: OutlineInputBorder(),
                      ),
                    ),

                  // Password fields
                  if (otpVerified) ...[
                    TextField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action button
                  ElevatedButton(
                    onPressed: otpVerified
                        ? _resetPassword
                        : (otpSent ? _verifyOTP : _sendOTP),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF101D33),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    child: Text(
                      otpVerified
                          ? "Reset Password"
                          : (otpSent ? "Verify OTP" : "Send OTP"),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                  if (otpSent && !otpVerified)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          otpSent = false;
                          otpController.clear();
                        });
                      },
                      child: const Text("Back", style: TextStyle(color: Colors.black54)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
