import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'FAQPage.dart';

class HelpCenterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildHelpSection(
              icon: Icons.help_outline,
              title: "FAQs",
              description: "Find answers to your questions.",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FAQPage()),
                );
              },
            ),

            const SizedBox(height: 16),
            _buildHelpSection(
              icon: Icons.phone_in_talk,
              title: "Call Support",
              description: "Speak to a representative.",
              onTap: () async {
                final Uri callUri = Uri(scheme: 'tel', path: '0592432662');
                if (await canLaunchUrl(callUri)) {
                  await launchUrl(callUri);
                }
              },
            ),
            const SizedBox(height: 16),
            _buildHelpSection(
              icon: Icons.email_outlined,
              title: "Email Us",
              description: "Reach out via email.",
              onTap: () async {
                final Uri emailUri = Uri(
                  scheme: 'mailto',
                  path: 'faten.sultan.02@gmail.com',
                  query: 'subject=QuickPark Support&body=Hello, I need help with...',
                );
                if (await canLaunchUrl(emailUri)) {
                  await launchUrl(emailUri);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Color(0xFF101D33)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style:
                        const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
//
//
// class HelpCenterApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.teal,
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: AppBarTheme(
//           backgroundColor: Colors.teal,
//           foregroundColor: Colors.white,
//         ),
//       ),
//       home: HelpCenterScreen(),
//     );
//   }
// }
//
// class HelpCenterScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//
//       body: Padding(
//         padding: EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: ListView(
//                 children: [
//                   _buildHelpSection(
//                     icon: Icons.help_outline,
//                     title: "FAQs",
//                     description: "Find answers to your questions.",
//                     onTap: () {},
//                   ),
//                   SizedBox(height: 16),
//                   _buildHelpSection(
//                     icon: Icons.chat_bubble_outline,
//                     title: "Live Chat",
//                     description: "Chat with our support team.",
//                     onTap: () {},
//                   ),
//                   SizedBox(height: 16),
//                   _buildHelpSection(
//                     icon: Icons.phone_in_talk,
//                     title: "Call Support",
//                     description: "Speak to a representative.",
//                     onTap: () {},
//                   ),
//                   SizedBox(height: 16),
//                   _buildHelpSection(
//                     icon: Icons.email_outlined,
//                     title: "Email Us",
//                     description: "Reach out via email.",
//                     onTap: () {},
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHelpSection({
//     required IconData icon,
//     required String title,
//     required String description,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12.0),
//         ),
//         elevation: 5,
//         child: Padding(
//           padding: EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               Icon(icon, size: 40, color:  Color(0xFF101D33)),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
//                     SizedBox(height: 4),
//                     Text(description),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }