import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  final Function(int) onItemSelected;
  final int selectedIndex;

  const AppDrawer({super.key, required this.onItemSelected, required this.selectedIndex});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String _userName = '';
  String _fullName = '';
  String _email = '';
  String _profilePicInitials = 'RD'; // Default initials

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('username'); // Get userName from SharedPreferences

    if (userName == null) {
      print('❌ No userName found in SharedPreferences');
      return;
    }

    // Fetch user data from the server
    final url = Uri.parse('https://quickpark.onrender.com/api/users/username/$userName');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          _userName = data['userName'];
          _fullName = data['fullName'];
          _email = data['email'];
          _profilePicInitials = _generateInitials(data['fullName']); // Generate initials from full name
        });

        print('✅ User data loaded successfully');
      } else {
        print('❌ Failed to load user data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  // Generate initials for the profile picture
  String _generateInitials(String fullName) {
    List<String> nameParts = fullName.split(' ');
    if (nameParts.isNotEmpty) {
      return nameParts[0][0] + (nameParts.length > 1 ? nameParts[1][0] : ''); // Take first letter of first and second name
    }
    return 'NN'; // Default initials if no name is provided
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(_fullName),
            accountEmail: Text(_email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _profilePicInitials,
                style: TextStyle(fontSize: 24.0, color: Color(0xFF101D33)),
              ),
            ),
            decoration: const BoxDecoration(color: Color(0xFF101D33)),
          ),
          // Section 1: Main Features
          _buildDrawerItem(context, Icons.home, "Home", 0),
          _buildDrawerItem(context, Icons.payment, "Payments & Billing", 1),
          _buildDrawerItem(context, Icons.adb_outlined , "Chatbot", 2),
          const Divider(),
          // Section 2: User & Support
          _buildDrawerItem(context, Icons.person, "My Profile", 3),
          _buildDrawerItem(context, Icons.help, "Help Center", 4),
          _buildDrawerItem(context, Icons.info, "About App", 5),
          const Divider(),
          // Section for Logout
          _buildDrawerItem(context, Icons.exit_to_app, "Logout", 7),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, IconData icon, String title, int index) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: widget.selectedIndex == index,
      onTap: () {
        widget.onItemSelected(index);
        Navigator.pop(context); // Close drawer after selection
      },
    );
  }
}
