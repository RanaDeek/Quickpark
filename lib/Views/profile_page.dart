import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String _name = '';
  String _userName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username == null) {
      print('❌ No username found in SharedPreferences');
      return;
    }

    final url = Uri.parse('https://quickpark.onrender.com/api/users/username/$username');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _name = data['fullName'] ?? '';
          _email = data['email'] ?? '';
          _userName = data['userName'] ?? '';
        });

        print('✅ User loaded: $_name');
      } else {
        print('❌ Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching user: $e');
    }
  }
  Future<void> _updateUserData(String fullName, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');

    if (username == null) {
      print('❌ Username not found in SharedPreferences');
      return;
    }

    final url = Uri.parse('https://quickpark.onrender.com/api/users/update/username/$username');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'fullName': fullName,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _name = fullName;
          _email = email;
        });

        // ✅ Show success SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        print('✅ User updated successfully');
      } else {
        print('❌ Failed to update user: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error updating user: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedName = nameController.text.trim();
              final updatedEmail = emailController.text.trim();

              _updateUserData(updatedName, updatedEmail);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.pushReplacementNamed(context, '/splash');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF101D33),
        onPressed: _showEditProfileDialog,
        child: const Icon(
          Icons.edit,
          color: Colors.white, // Set the color of the icon here
        ),      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CustomPaint(
              size: Size(MediaQuery.of(context).size.width, 330),
              painter: WavePainter(),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 90),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _name,
                style: const TextStyle(
                  color: Color(0xFF101D33),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _userName,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(Icons.email_outlined, _email),
              _buildInfoCard(Icons.phone_android, _userName),
              const SizedBox(height: 10),
             ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF101D33),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.white),
        ),
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
