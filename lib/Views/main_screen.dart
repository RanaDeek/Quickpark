// // import 'package:flutter/material.dart';
// //
// // class MainScreen extends StatefulWidget {
// //   const MainScreen({Key? key}) : super(key: key);
// //
// //   @override
// //   State<MainScreen> createState() => _MainScreenState();
// // }
// //
// // class _MainScreenState extends State<MainScreen> {
// //   // Store expanded question index
// //   int? expandedIndex;
// //
// //   final List<Map<String, dynamic>> questions = [
// //     {
// //       'question': 'What payment methods do you support?',
// //       'subQuestions': [
// //         'Do you support credit cards?',
// //         'Do you support PayPal?',
// //         'Do you support bank transfer?',
// //       ],
// //     },
// //     {
// //       'question': 'How do I request a refund?',
// //       'subQuestions': [
// //         'What is the refund period?',
// //         'How long does a refund take?',
// //       ],
// //     },
// //     {
// //       'question': 'Is my payment secure?',
// //       'subQuestions': [
// //         'How do you protect my data?',
// //         'Do you comply with PCI standards?',
// //       ],
// //     },
// //     // You can add more questions below; only 3 shown initially
// //     {
// //       'question': 'How can I change my billing info?',
// //       'subQuestions': ['Where do I update my credit card?'],
// //     },
// //   ];
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: const Text('FAQs')),
// //       body: ListView.builder(
// //         itemCount: questions.length > 3 && expandedIndex == null ? 3 : questions.length,
// //         itemBuilder: (context, index) {
// //           final q = questions[index];
// //           final isExpanded = expandedIndex == index;
// //
// //           return Column(
// //             crossAxisAlignment: CrossAxisAlignment.start,
// //             children: [
// //               ListTile(
// //                 title: Text(q['question']),
// //                 onTap: () {
// //                   setState(() {
// //                     if (isExpanded) {
// //                       expandedIndex = null;
// //                     } else {
// //                       expandedIndex = index;
// //                     }
// //                   });
// //                 },
// //               ),
// //               if (isExpanded)
// //                 Padding(
// //                   padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
// //                   child: Column(
// //                     crossAxisAlignment: CrossAxisAlignment.start,
// //                     children: List<Widget>.from(
// //                       q['subQuestions'].map<Widget>((sq) => Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 4.0),
// //                         child: Text("• $sq"),
// //                       )),
// //                     ),
// //                   ),
// //                 ),
// //               const Divider(),
// //             ],
// //           );
// //         },
// //       ),
// //     );
// //   }
// // }
//
// import 'package:flutter/material.dart';
//
// import 'chatbot_page.dart';
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: chatbot_page(),
//     );
//   }
// }
