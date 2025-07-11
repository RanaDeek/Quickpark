import 'package:drawer/Views/DestinationPage.dart';
import 'package:drawer/Views/StreetViewPage.dart';
import 'package:flutter/material.dart';
import 'findParking_page.dart';

class QuickParkApp extends StatelessWidget {
  const QuickParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  List<AnimationController> _animationControllers = [];
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();

    // Create animation controllers for each timeline step
    for (int i = 0; i < 7; i++) { // There are 7 steps
      AnimationController controller = AnimationController(
        duration: Duration(seconds: 1),
        vsync: this,
      );
      _animationControllers.add(controller);
      _animations.add(Tween(begin: 0.0, end: 1.0).animate(controller));

      // Trigger the animation with a delay
      Future.delayed(Duration(milliseconds: i * 500), () {
        controller.forward();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "مرحباً بك في تطبيق QuickPark",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            Text(
              "يتيح لك تطبيق QuickPark حجز مكان لركن سيارتك بسهولة. ما عليك سوى تحديد وجهتك.",
              style: TextStyle(fontSize: 18, color: Colors.black54, height: 1.5),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 20),
            _buildTimelineRules(), // Updated to apply animation here
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DestinationPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("التالي", style: TextStyle(fontSize: 18, color: Color(0xFF101D33))),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward, color: Color(0xFF101D33), size: 24),
                  ],
                ),
              ),
            ),



          ],
        ),
      ),
    );
  }

  /// Builds the step-by-step timeline layout for the rules section with animation
  Widget _buildTimelineRules() {
    return Column(
      children: [
        _buildTimelineStep("حدد موقعك وابحث عن موقف متاح", Icons.location_on, true, 0),
        _buildTimelineStep("قارن الخيارات واحجز موقفك", Icons.search, false, 1),
        _buildTimelineStep("تحرك نحو الموقف وأتمم الدفع", Icons.compare_arrows, true, 2),
        _buildTimelineStep("لديك 15 دقيقة للوصول قبل الإلغاء", Icons.timer_outlined, false, 3),
        _buildTimelineStep("عند الوصول، اضغط زر الفتح", Icons.directions_car, true, 4),
        _buildTimelineStep("يمكنك تمديد الوقت إذا لزم الأمر", Icons.more_time, false, 5),
        _buildTimelineStep("اركن سيارتك واستمتع بوقتك!", Icons.local_parking, true, 6),
      ],
    );
  }


  /// Helper method to create a step in the timeline with animation
  Widget _buildTimelineStep(String text, IconData icon, bool isLeft, int index) {
    return AnimatedBuilder(
      animation: _animations[index],
      builder: (context, child) {
        return Opacity(
          opacity: _animations[index].value,
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: isLeft ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          if (!isLeft) _buildStepCard(text, icon),
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(color:Color(0xFF101D33), shape: BoxShape.circle),
              ),
              Container(width: 2, height: 40, color: Color(0xFF101D33)),
            ],
          ),
          if (isLeft) _buildStepCard(text, icon),
        ],
      ),
    );
  }

  /// Step card with icon and text
  Widget _buildStepCard(String text, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 17, horizontal: 20),
        child: Row(
          children: [
            Icon(icon, color:Color(0xFF101D33), size: 28),
            SizedBox(width: 10),
            Text(text, style: TextStyle(fontSize: 16, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
