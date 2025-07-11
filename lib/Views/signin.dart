import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:drawer/main.dart';
import 'forget_page.dart';
import './auth.dart';
import '../Components/textfield.dart';


const Color primaryColor = Color(0xFF101D33);

class ParkCarScreen extends StatefulWidget {
  const ParkCarScreen({super.key});

  @override
  _ParkCarScreenState createState() => _ParkCarScreenState();
}

class _ParkCarScreenState extends State<ParkCarScreen> {
  final TextEditingController userName = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isChecked = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedUsername = prefs.getString('username');
    String? savedPassword = prefs.getString('password');
    if (savedUsername != null && savedPassword != null) {
      setState(() {
        userName.text = savedUsername;
        password.text = savedPassword;
        isChecked = true;
      });
    }
  }

  Future<void> _saveLoginSession(String userId, String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('username', username);

  }

  Future<void> _saveRememberedCredentials(
    String username,
    String password,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    await prefs.setString('password', password);
  }

  Future<void> _clearRememberedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    await prefs.remove('password');
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
        title: const Text(
          "Sign In",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
      ),
      backgroundColor: const Color(0xFFE2E6ED),
      body: Stack(
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 350),
            painter: WavePainter(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    const Text(
                      "Welcome Back",
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Login to Your Account",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: InputField(
                        hint: "Username",
                        icon: Icons.account_circle,
                        controller: userName,
                        iconColor: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: InputField(
                        hint: "Password",
                        icon: Icons.lock,
                        controller: password,
                        isPassword: true,
                        iconColor: primaryColor,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: isChecked,
                                onChanged: (value) {
                                  setState(() {
                                    isChecked = value!;
                                  });
                                },
                                activeColor: primaryColor,
                              ),
                              const Text(
                                "Remember Me",
                                style: TextStyle(color: primaryColor),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgetPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 150,
                            ),
                          ),
                          onPressed: () async {
                            String u = userName.text.trim();
                            String p = password.text.trim();

                            if (u.isEmpty || p.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Please enter both username and password.",
                                  ),
                                ),
                              );
                              return;
                            }

                            setState(() {
                              isLoading = true;
                            });

                            final response = await http.post(
                              Uri.parse(
                                'https://quickpark.onrender.com/api/login',
                              ),
                              headers: {'Content-Type': 'application/json'},
                              body: jsonEncode({'userName': u, 'password': p}),
                            );

                            setState(() {
                              isLoading = false;
                            });

                            if (response.statusCode == 200) {
                              final json = jsonDecode(response.body);
                              final String? userId = json['user']?['id'];

                              if (userId != null) {
                                await _saveLoginSession(userId,u);

                                if (isChecked) {
                                  await _saveRememberedCredentials(u, p);
                                } else {
                                  await _clearRememberedCredentials();
                                }

                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MyHomePage(),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Unexpected error. User ID missing.",
                                    ),
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Invalid credentials. Please sign up.",
                                  ),
                                ),
                              );
                            }
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => AuthScreen()),
                        );
                      },
                      child: const Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
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
      size.width * 0.2,
      size.height * 0.3,
      size.width * 0.4,
      size.height * 0.4,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.6,
      size.width,
      size.height * 0.2,
    );
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
