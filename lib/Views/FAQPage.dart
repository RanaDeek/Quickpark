import 'package:flutter/material.dart';

class FAQPage extends StatelessWidget {
  final List<Map<String, String>> faqs = [
    {
      "question": "How do I reserve a parking spot?",
      "answer":
      "Open the app, enter your destination, and the system will show you the nearest available spot. You can reserve it with a single tap."
    },
    {
      "question": "What happens if I arrive late?",
      "answer":
      "You have a 15-minute window to reach your reserved spot. If you don’t arrive in time, the reservation will be cancelled automatically."
    },
    {
      "question": "Can I extend my parking time?",
      "answer":
      "Yes, you'll receive a notification 10 minutes before your time ends. You can extend the reservation through the app."
    },
    {
      "question": "How does the payment work?",
      "answer":
      "After confirming your reservation and duration, payment can be completed securely through the app using your saved details."
    },
    {
      "question": "Is my information secure?",
      "answer":
      "Absolutely. Your personal and payment data is encrypted and securely stored using best practices."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "FAQs",
          style: TextStyle(color: Colors.white),

        ),
        iconTheme: const IconThemeData(color: Colors.white),

        backgroundColor: const Color(0xFF101D33),
      ),
      body: ListView.builder(
        itemCount: faqs.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(
                faq['question']!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    faq['answer']!,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
