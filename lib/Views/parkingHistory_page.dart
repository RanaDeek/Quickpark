// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
//
// class ParkingHistoryApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         brightness: Brightness.light,
//         useMaterial3: true,
//         fontFamily: 'Roboto',
//         colorSchemeSeed: Colors.deepPurple,
//       ),
//       home: ParkingHistoryPage(),
//     );
//   }
// }
//
// class ParkingHistoryPage extends StatelessWidget {
//   final List<ParkingRecord> history = [
//     ParkingRecord(
//       location: 'Underground Lot A',
//       startTime: DateTime(2025, 4, 5, 10, 15),
//       endTime: DateTime(2025, 4, 5, 12, 45),
//       cost: 4.25,
//     ),
//     ParkingRecord(
//       location: 'Tech Hub Garage',
//       startTime: DateTime(2025, 4, 4, 8, 30),
//       endTime: DateTime(2025, 4, 4, 9, 45),
//       cost: 2.80,
//     ),
//     ParkingRecord(
//       location: 'Airport Terminal 2',
//       startTime: DateTime(2025, 4, 2, 18, 0),
//       endTime: DateTime(2025, 4, 2, 21, 0),
//       cost: 7.00,
//     ),
//     ParkingRecord(
//       location: 'City Center Garage',
//       startTime: DateTime(2025, 4, 6, 9, 30),
//       endTime: DateTime(2025, 4, 6, 11, 0),
//       cost: 3.50,
//     ),
//
//   ];
//
//   String formatDate(DateTime date) {
//     return DateFormat('MMM d, yyyy • h:mm a').format(date);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       extendBodyBehindAppBar: true,
//       body: Container(
//
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(16, 30, 16, 16),
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(bottom: 16, left: 20, right: 20),
//               child: Center(
//                 child: Text(
//                   'Track where you’ve been and how long you stayed , all in one place.',
//                   style: TextStyle(
//                     fontSize: 20,
//                     color: Color(0xFF101D33),
//                     fontWeight: FontWeight.w500,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//               ),
//             ),
//
//             ...history.map((record) {
//               return Container(
//                 margin: EdgeInsets.only(bottom: 16),
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   color: Colors.white.withOpacity(0.4),
//                   border: Border.all(color: Colors.deepPurple.shade100),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.deepPurple.shade200.withOpacity(0.2),
//                       blurRadius: 12,
//                       offset: Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.all(18),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Row(
//                         children: [
//                           Icon(Icons.location_on, color:  Color(0xFF101D33)),
//                           SizedBox(width: 8),
//                           Text(
//                             record.location,
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w600,
//                               color:  Color(0xFF101D33),
//                             ),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 8),
//                       Row(
//                         children: [
//                           Icon(Icons.access_time, color: Colors.grey.shade600),
//                           SizedBox(width: 8),
//                           Text(
//                             '${formatDate(record.startTime)} → ${DateFormat('h:mm a').format(record.endTime)}',
//                             style: TextStyle(color: Colors.grey.shade700),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 6),
//                       Row(
//                         children: [
//                           Icon(Icons.timer, color: Colors.grey.shade600),
//                           SizedBox(width: 8),
//                           Text(
//                             'Duration: ${record.endTime.difference(record.startTime).inMinutes} mins',
//                             style: TextStyle(color: Colors.grey.shade700),
//                           ),
//                         ],
//                       ),
//                       SizedBox(height: 10),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Container(
//                             padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                             decoration: BoxDecoration(
//                               gradient: LinearGradient(
//                                 colors: [Color(0xFF3965AF), Color(0xFF1F3965)],
//                               ),
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             child: Text(
//                               '\$${record.cost.toStringAsFixed(2)}',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           )
//                         ],
//                       )
//                     ],
//                   ),
//                 ),
//               );
//             }).toList(),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class ParkingRecord {
//   final String location;
//   final DateTime startTime;
//   final DateTime endTime;
//   final double cost;
//
//   ParkingRecord({
//     required this.location,
//     required this.startTime,
//     required this.endTime,
//     required this.cost,
//   });
// }
