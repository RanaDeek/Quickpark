import 'package:flutter/material.dart';

class chatbot_page extends StatefulWidget {
  const chatbot_page({super.key});

  @override
  State<chatbot_page> createState() => _ChatbotPageState();
}



class _ChatbotPageState extends State<chatbot_page> {
  final List<_Message> _messages = [];
  final TextEditingController _controller = TextEditingController();

  // ===== TOP-LEVEL CATEGORIES ===== //
  final List<String> mainQuestions = [
    'Account & User Settings',
    '📊 Parking Rules & Limits',
    '🛠️ Technical Help',
    '♿ Accessibility & User Support',
    '🚗 Smart Parking Features',
    '📱 App Usage & User Guidance',
    '💬 Feedback & Suggestions',
    '🔋 System & Connectivity',
    '💳 Payments & Billing', // NEW CATEGORY
  ];

// ===== RELATED QUESTIONS BY CATEGORY ===== //
  final Map<String, List<String>> relatedQuestionsMap = {
    'account': [
      'How do I create an account in the app?',
      'Can I change my password from the app?',
      'How do I delete or deactivate my account?',
      'Is it possible to register and manage more than one vehicle?',
      'How do I update my profile information?',
      'Can I log in using Google or social media?', // NEW
      'How do I reset my password if I forget it?', // NEW
      'Can I link my account to family members?', // NEW
    ],

    'rules': [
      'What are the parking rules I should follow?',
      'How long can I reserve a spot in advance?',
      'What happens if I exceed my parking time?',
      'Are there penalties for occupying a reserved spot?',
      'Can I cancel a reservation after booking?',
      'Are there parking time restrictions by day/night?', // NEW
      'What happens if I leave earlier than my reserved time?', // NEW
    ],

    'technical': [
      'Why isn’t the gate opening when I arrive?',
      'What should I do if the app freezes or crashes?',
      'I didn’t get a confirmation message. What should I do?',
      'The system shows "full" but there are empty spots. Why?',
      'What should I do if my car gets stuck inside?', // NEW
      'How do I update the app to the latest version?', // NEW
      'Is there a support chatbot in the app?', // NEW
    ],

    'accessibility': [
      'Is the parking system accessible for disabled drivers?',
      'Can I get help if I have a problem on-site?',
      'How do I report a system error or malfunction?',
      'Is there 24/7 customer service support?',
      'Are there dedicated accessible parking spots?', // NEW
      'Can I request assistance before I arrive?', // NEW
      'Are there audio/visual guidance options for users with disabilities?', // NEW
    ],

    'features': [
      'How does the automatic gate system work?',
      'What sensors are used in the parking system?',
      'How do I know if a parking spot is available?',
      'Does the system support license plate recognition?',
      'Is the parking system integrated with any navigation app?',
      'Can the system remind me when my parking time is nearly up?', // NEW
      'Does the system support auto entry/exit without interaction?', // NEW
      'Can I mark preferred parking spots?', // NEW
      'Is there a live map of the parking lot in the app?', // NEW
    ],

    'usage': [
      'How do I use the smart parking app for the first time?',
      'Can I view my past parking history?',
      'How do I update my vehicle details?',
      'How do I receive parking notifications?',
      'Can I park multiple cars using the same account?',
      'Can I use the app in different languages?', // NEW
      'How do I enable or disable push notifications?', // NEW
      'Does the app support dark mode?', // NEW
    ],

    'feedback': [
      'How can I report a problem with a parking space?',
      'Can I suggest new features for the app?',
      'Where can I give feedback about the parking experience?',
      'How long does it take to respond to feedback?', // NEW
      'Can I track the status of my reported issue?', // NEW
    ],

    'connectivity': [
      'What happens if the system goes offline?',
      'Does the app work without internet?',
      'How is user data protected in this system?',
      'Is my payment information secure?', // NEW
      'What should I do if I notice suspicious activity on my account?', // NEW
      'What happens if my phone battery dies while parked?', // NEW
      'Can I exit the parking without the app?', // NEW
    ],

    'payments': [ // NEW CATEGORY
      'How do I pay for parking?',
      'What payment methods are supported?',
      'Are online payments supported?',
      'Can I get a receipt or invoice for my payment?',
      'Are there subscription or loyalty plans?',
      'How do I request a refund if I didn’t use my reservation?', // NEW
    ],
  };


  // ===== PRE-DEFINED ANSWERS FOR EACH QUESTION ===== //
  final Map<String, String> predefinedAnswers = {
    // Account & User Settings
    'How do I create an account in the app?':
    'Open the app and tap **Sign-Up**. Fill in your name, email, mobile number and create a password. You’ll receive an email or SMS verification code—enter it to activate your account.',
    'Can I change my password from the app?':
    'Yes. Go to **Profile → Security → Change Password**. Enter your current password and then the new one. You’ll be logged out of other devices for safety.',
    'How do I delete or deactivate my account?':
    'In **Profile → Account Settings** tap **Deactivate Account**. A confirmation email will be sent. Deactivation hides your data; permanent deletion is processed within 30 days.',
    'Is it possible to register and manage more than one vehicle?':
    'Absolutely. In **Vehicles** tap **Add Vehicle**, then enter the additional license plate and description. You can switch the active vehicle at check-in time.',
    'How do I update my profile information?':
    'Go to **Profile → Edit Profile** to update your personal details such as name, email, and phone number.',
    'Can I log in using Google or social media?':
    'Yes, you can sign in or register using Google or Facebook accounts for faster access.',
    'How do I reset my password if I forget it?':
    'Use the **Forgot Password** link on the login screen. Enter your registered email to receive reset instructions.',
    'Can I link my account to family members?':
    'Currently, you can share vehicle details by adding multiple vehicles under your account, but separate user profiles are not supported yet.',

    // Parking Rules & Limits
    'What are the parking rules I should follow?':
    '• Park only in marked bays  • Keep aisles clear  • Observe max time limits displayed in the app & on signage  • Use reserved/disabled bays only if authorised.',
    'How long can I reserve a spot in advance?':
    'You can reserve parking spots up to 7 days in advance, subject to availability.',
    'What happens if I exceed my parking time?':
    'You’ll receive a push notification to extend your stay. If no action is taken, an overtime fee of **50 NIS** is added to your wallet balance.',
    'Are there penalties for occupying a reserved spot?':
    'Yes. A reserved-spot violation incurs a **70 NIS** fine and may trigger towing for repeat offences.',
    'Can I cancel a reservation after booking?':
    'Cancellations are free up to **10 minutes** before the reservation start. After that, the first 30 minutes are billed.',
    'Are there parking time restrictions by day/night?':
    'Some zones may have different time restrictions during night hours; check the app’s zone info for details.',
    'What happens if I leave earlier than my reserved time?':
    'You will be charged only for the time your vehicle was parked. Any unused reserved time will be released back to the system.',

    // Technical Help
    'Why isn’t the gate opening when I arrive?':
    'Ensure Bluetooth & Location are ON and your phone is near the reader. If plates are dirty, clean them for the camera. Press the intercom for manual assistance.',
    'What should I do if the app freezes or crashes?':
    'Force-close the app and reopen. Check for updates on the App Store/Play Store. If the issue persists, clear cache from **Settings → Apps → Storage**.',
    'I didn’t get a confirmation message. What should I do?':
    'Check spam folders and verify your phone number/email. You can resend the confirmation from **Profile → Resend Verification**.',
    'The system shows "full" but there are empty spots. Why?':
    'Some spots may be reserved or sensors may have a 1-2 minute refresh delay. Refresh the map or wait briefly; if still incorrect, report via the app.',
    'What should I do if my car gets stuck inside?':
    'Use the intercom at the gate or call our 24/7 support hotline for immediate assistance.',
    'How do I update the app to the latest version?':
    'Visit your device’s app store and enable automatic updates or check manually for new versions.',
    'Is there a support chatbot in the app?':
    'Yes, tap the **Help** icon in the app to chat with our virtual assistant anytime.',

    // Accessibility & User Support
    'Is the parking system accessible for disabled drivers?':
    'Yes. There are extra-wide bays near exits, tactile paving, and lowered ticket machines. You can filter for accessible spots in the app.',
    'Can I get help if I have a problem on-site?':
    'Yes—tap the **Help** button or use the gate intercom to talk to our 24/7 support team who can open gates remotely if needed.',
    'How do I report a system error or malfunction?':
    'Go to **Support → Report an Issue**. Attach photos or screenshots; our tech team responds within 2 business hours.',
    'Is there 24/7 customer service support?':
    'Absolutely. Phone: +970-599-123-456 or email support@quickpark.ps any time, any day.',
    'Are there dedicated accessible parking spots?':
    'Yes, accessible spots are clearly marked and located close to entrances/exits.',
    'Can I request assistance before I arrive?':
    'Yes, contact support through the app or call ahead to arrange assistance.',
    'Are there audio/visual guidance options for users with disabilities?':
    'Our app includes voice guidance and high-contrast visual modes for accessibility.',

    // Smart Parking Features
    'How does the automatic gate system work?':
    'A licence-plate camera and RFID reader detect your registered vehicle and open the barrier automatically once your booking starts.',
    'What sensors are used in the parking system?':
    'We use overhead ultrasonic sensors plus ground IoT nodes to detect occupancy, combined with LPR cameras at entry/exit.',
    'How do I know if a parking spot is available?':
    'Green indicators on the map are updated every 15 seconds. A grey spot means reserved; red means occupied.',
    'Does the system support license plate recognition?':
    'Yes—LPR cameras identify your registered plate so you can enter and exit without scanning a QR code.',
    'Is the parking system integrated with any navigation app?':
    'Tap **Navigate** in the booking screen to open Google Maps or Waze with the destination pre-filled.',
    'Can the system remind me when my parking time is nearly up?':
    'Yes, you can enable reminders in the app’s notification settings.',
    'Does the system support auto entry/exit without interaction?':
    'Yes, registered vehicles can enter and exit automatically during their booking period.',
    'Can I mark preferred parking spots?':
    'You can save favorite spots in the app to make future reservations quicker.',
    'Is there a live map of the parking lot in the app?':
    'Yes, the app displays a live occupancy map updated every few seconds.',

    // App Usage & User Guidance
    'How do I use the smart parking app for the first time?':
    'Create an account, add your vehicle, load wallet funds or link a card, then search for available spots and tap **Reserve**.',
    'Can I view my past parking history?':
    'Yes. Go to **Profile → Parking History** to filter by date or vehicle and export receipts as PDF.',
    'How do I update my vehicle details?':
    'Navigate to **Vehicles**, select the plate, then tap **Edit** to change colour, model, or plate number.',
    'How do I receive parking notifications?':
    'Enable push notifications during onboarding or later via **Settings → Notifications**. You can choose reminders for expiring sessions.',
    'Can I park multiple cars using the same account?':
    'Yes, add each car in **Vehicles**. Select the active car during reservation. Only one car can use a single booking at a time.',
    'Can I use the app in different languages?':
    'Yes, the app supports multiple languages. Change your preferred language under **Settings → Language**.',
    'How do I enable or disable push notifications?':
    'Go to **Settings → Notifications** and toggle notifications on or off as desired.',
    'Does the app support dark mode?':
    'Yes, enable dark mode in your device’s settings or within the app’s appearance options.',

    // Feedback & Suggestions
    'How can I report a problem with a parking space?':
    'Open the spot on the map and tap **Report Issue**. Describe the problem and optionally attach a photo.',
    'Can I suggest new features for the app?':
    'We welcome ideas! Use **Settings → Feedback & Ideas** or email ideas@quickpark.ps.',
    'Where can I give feedback about the parking experience?':
    'After checkout you’ll receive a rating pop-up, or you can leave feedback anytime under **Profile → Feedback**.',
    'How long does it take to respond to feedback?':
    'Our support team responds to feedback within 48 hours.',
    'Can I track the status of my reported issue?':
    'Yes, go to **Support → My Reports** to see the status of any problems you’ve reported.',

    // System & Connectivity
    'What happens if the system goes offline?':
    'Gates switch to fail-safe mode allowing exit. Your booking is preserved locally and syncs once online.',
    'Does the app work without internet?':
    'You can view current bookings cached on your device. Real-time availability and payments require a connection.',
    'How is user data protected in this system?':
    'All data is AES-256 encrypted at rest and TLS 1.3 in transit. We follow GDPR and local privacy regulations.',
    'Is my payment information secure?':
    'Yes, payments are processed via PCI-DSS compliant gateways ensuring the highest security.',
    'What should I do if I notice suspicious activity on my account?':
    'Immediately change your password and contact support through the app or email security@quickpark.ps.',
    'What happens if my phone battery dies while parked?':
    'You can exit manually via the intercom or use your backup access card provided at registration.',
    'Can I exit the parking without the app?':
    'Yes, there are manual gates operated by staff or via intercom support if app access is unavailable.',

    // Payments & Billing
    'How do I pay for parking?':
    'You can pay via the app using credit/debit cards, mobile wallets, or wallet balance.',
    'What payment methods are supported?':
    'We support Visa, MasterCard, Apple Pay, Google Pay, and local mobile payment services.',
    'Are online payments supported?':
    'Yes, all payments are securely processed online in real-time.',
    'Can I get a receipt or invoice for my payment?':
    'Receipts are automatically generated and can be downloaded from **Profile → Payments**.',
    'Are there subscription or loyalty plans?':
    'Yes, frequent users can subscribe to monthly plans with discounted rates and rewards.',
    'How do I request a refund if I didn’t use my reservation?':
    'Submit a refund request in **Support → Refunds**. Refunds are processed within 5 business days subject to terms.',
  };


  // ===== CHAT FLOW ===== //
  void _sendQuestion(String question) {
    if (question.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(_Message('user', question));
    });

    // Determine answer & related questions
    final answer = predefinedAnswers[question] ?? 'Sorry, I don’t have an answer for that yet.';
    final related = _getRelated(question);

    setState(() {
      _messages.add(_Message('bot', answer, related: related));
    });

    _controller.clear();
  }

  List<String> _getRelated(String question) {
    // Return related questions based on the category keyword contained in the original question.
    final lower = question.toLowerCase();
    for (final entry in relatedQuestionsMap.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return [];
  }

  Widget _buildMessage(_Message message) {
    final isUser = message.sender == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? Colors.indigo[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.message),
            if (!isUser && message.related.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Related Questions:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Wrap(
                spacing: 6,
                children: message.related
                    .map((q) => ActionChip(label: Text(q), onPressed: () => _sendQuestion(q)))
                    .toList(),
              ),
            ]
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Suggested Categories:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ...mainQuestions.map(
                        (q) => TextButton(
                      onPressed: () => _sendQuestion(q),
                      child: Align(alignment: Alignment.centerLeft, child: Text(q)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _sendQuestion,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendQuestion(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message {
  final String sender;
  final String message;
  final List<String> related;
  _Message(this.sender, this.message, {this.related = const []});
}
enum _Sender { user, bot }

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, required this.onTap});
  final _Message msg;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    final bg = isUser ? Colors.indigo[200] : Colors.grey[300];
    final icon = isUser ? Icons.person : Icons.smart_toy;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 12, child: Icon(icon, size: 16)),
                const SizedBox(width: 8),
                Flexible(child: Text(msg.toString())),
              ],
            ),
            if (!isUser && msg.related.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: msg.related
                    .map((r) => GestureDetector(
                  onTap: () => onTap(r),
                  child: Chip(label: Text(r)),
                ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final active = ((t + i * 0.3) % 1) < 0.5;
            return AnimatedOpacity(
              opacity: active ? 1.0 : 0.3,
              duration: const Duration(milliseconds: 300),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 3),
                child: CircleAvatar(radius: 3, backgroundColor: Colors.indigo),
              ),
            );
          }),
        );
      },
    );
  }
}
