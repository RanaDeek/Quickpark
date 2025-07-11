import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentPage extends StatefulWidget {
  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  double walletBalance = 0.0;
  String lastUpdated = '';
  List<String> paymentHistory = [];

  String userName = '';
  String userId = ''; // userId fetched from wallet API
  final String baseUrl = "https://quickpark.onrender.com";

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('username') ?? '';
    if (userName.isNotEmpty) {
      await _fetchWalletInfo();
      await _fetchPaymentHistory();
    }
  }

  Future<void> _fetchWalletInfo() async {
    final url = Uri.parse('$baseUrl/api/wallet/$userName');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          userId = data['userID'] ?? '';
          walletBalance = (data['balance'] ?? 0).toDouble();
          lastUpdated = data['lastUpdated'] ?? '';
        });
      } else {
        print("Failed to fetch wallet: ${res.body}");
      }
    } catch (e) {
      print("Error fetching wallet: $e");
    }
  }

  Future<void> deduct50NIS(String username) async {
    final url = Uri.parse('https://quickpark.onrender.com/api/charge-user');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "amount": 50,
          "description": "Reservation Fee - Chatbot"
        }),
      );

      if (response.statusCode == 200) {
        print("Successfully charged 50 NIS");
        // Optional: show success message or update local wallet view
      } else {
        print("Failed to charge 50 NIS: ${response.body}");
      }
    } catch (e) {
      print("Error deducting 50 NIS: $e");
    }
  }


  Future<void> _fetchPaymentHistory() async {
    final url = Uri.parse('$baseUrl/api/payments/$userName');

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        List<String> history = data.map((payment) {
          final amount = payment['amount'];
          final desc = payment['description'] ?? 'Payment';
          final dateStr = payment['date'] != null
              ? DateTime.parse(payment['date']).toLocal().toString().substring(0, 10)
              : 'Unknown date';
          return "$desc - $dateStr";
        }).toList();

        setState(() {
          paymentHistory = history;
        });
      } else {
        print("Failed to fetch payment history: ${res.body}");
      }
    } catch (e) {
      print("Error fetching payment history: $e");
    }
  }

  void _chargeWallet(String method) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Charge Wallet"),
        content: method == "point"
            ? Text("Show this ID to the charging point operator:\n\n$userId")
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Charging via bank account is under development."),
            SizedBox(height: 10),
            Text("Please transfer to:\n\nIBAN: XX00-1234-5678-0000")
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWalletSection(),
            SizedBox(height: 20),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSection() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Wallet Balance",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
            SizedBox(height: 10),
            Text("\$${walletBalance.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 28, color: Colors.green)),
            SizedBox(height: 10),
            Text(
                "Last Updated: ${lastUpdated.isNotEmpty ? lastUpdated.substring(0, 10) : 'N/A'}",
                style: TextStyle(color: Colors.grey[700])),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => _chargeWallet("bank"),
                  child: Text("Charge via Bank", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF101D33),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _chargeWallet("point"),
                  child: Text("Charge at Point", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF101D33),
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Payment History",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
        SizedBox(height: 10),
        paymentHistory.isEmpty
            ? Text("No payment history available.", style: TextStyle(color: Colors.grey))
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: paymentHistory.length,
          itemBuilder: (context, index) {
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: Icon(Icons.receipt, color: Colors.blueGrey),
                title: Text(paymentHistory[index]),
                onTap: () {},
              ),
            );
          },
        ),
      ],
    );
  }
}
