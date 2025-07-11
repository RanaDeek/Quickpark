import 'package:flutter/material.dart';

class ReviewPage extends StatelessWidget {
  final String vehicle;
  final String plate;
  final String card;
  final String expiry;
  final String cvv;
  final String address;
  final int method;
  final double amount;
  final double fees;

  ReviewPage({
    required this.vehicle,
    required this.plate,
    required this.card,
    required this.expiry,
    required this.cvv,
    required this.address,
    required this.method,
    required this.amount,
    required this.fees,
  });

  @override
  Widget build(BuildContext context) {
    double total = amount + fees;
    List<String> paymentMethods = ["Manual Card Pay", "PayPal", "Visa"];

    return Scaffold(
      appBar: AppBar(title: Text("Review Booking")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row("Parking", "Friends School"),
            _row("Address", "Resort Street, Cooper Market, 24,3"),
            _row("Vehicle Number", plate),
            _row("Vehicle Type", vehicle),
            _row("Parking Date", "23-3-2024"),
            _row("Spot Number", "Friends School"),
            Divider(),
            _row("Card Number", card),
            _row("Expiry Date", expiry),
            _row("CVV", cvv),
            _row("Billing Address", address),
            _row("Payment Method", paymentMethods[method]),
            Divider(),
            _row("Amount", "\$${amount.toStringAsFixed(2)}"),
            _row("Taxes and Fees", "\$${fees.toStringAsFixed(2)}"),
            _row("Total", "\$${total.toStringAsFixed(2)}"),
            Spacer(),
            ElevatedButton(
              onPressed: () {
                // Submit logic
              },
              child: Text("Payment of \$${total.toStringAsFixed(2)}"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF101D33),
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
