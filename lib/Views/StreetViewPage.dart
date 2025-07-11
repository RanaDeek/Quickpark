import 'dart:convert';
import 'package:drawer/Views/TimerPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../Components/textfield.dart';

class UParkingStreetPage extends StatefulWidget {
  final String destination;

  const UParkingStreetPage({Key? key, required this.destination})
    : super(key: key);

  @override
  _UParkingStreetPageState createState() => _UParkingStreetPageState();
}
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();


class _UParkingStreetPageState extends State<UParkingStreetPage> {
  String? userName;
  List<Map<String, dynamic>> slots = [];
  int? selectedSlotNumber;
  bool isLoading = false;
  final TextEditingController timerController = TextEditingController();
  double walletBalance = 0.0;
  final double ratePerHour = 0.5;



  final String apiBaseUrl = 'https://quickpark.onrender.com/api/slots';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    loadUserData();

  }

  @override
  void dispose() {
    timerController.dispose();
    super.dispose();
  }
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUserName = prefs.getString('username');

    if (!mounted) return;

    if (storedUserName == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('المستخدم غير مسجل الدخول.')),
      );

      return;
    }

    setState(() {
      userName = storedUserName;
    });

    // Fetch available slots
    await fetchSlots();

    // Fetch wallet balance
    try {
      final res = await http.get(Uri.parse("https://quickpark.onrender.com/api/wallet/$userName"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        print("Wallet data for $userName: $data");
        setState(() {
          walletBalance = (data['balance'] ?? 0).toDouble();
        });
      } else {
        print("Failed to fetch wallet: ${res.statusCode} - ${res.body}");
      }
    } catch (e) {
      print("Error fetching wallet data: $e");
    }
  }


  Future<void> fetchSlots() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiBaseUrl));
      if (!mounted) return;

      if (response.statusCode == 200) {
        List data = json.decode(response.body);
        setState(() {
          slots = List<Map<String, dynamic>>.from(data);
          selectedSlotNumber = _getLockedSlotByUser();
        });
      } else {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل المواقف: ${response.statusCode}'),
          ),
        );

      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز')),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء جلب البيانات')),
      );

    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  int? _getLockedSlotByUser() {
    for (var slot in slots) {
      if (slot['lockedBy'] == userName) {
        return slot['slotNumber'];
      }
    }
    return null;
  }

  Future<bool> selectSlot(int slotNumber) async {
    final alreadyLocked = _getLockedSlotByUser();
    if (alreadyLocked != null && alreadyLocked != slotNumber) {
      final cancelSuccess = await cancelSlot(alreadyLocked);
      if (!cancelSuccess) return false;
    }

    final url = Uri.parse('$apiBaseUrl/$slotNumber/select');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userName': userName}),
    );

    if (!mounted) return false;

    if (response.statusCode == 200) {
      await fetchSlots();
      if (!mounted) return false;

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تم اختيار الموقف بنجاح')),
      );

      return true;
    } else {
      final resBody = json.decode(response.body);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تعذر اختيار الموقف')),
      );

      return false;
    }
  }
  Future<void> SlotConfirmation(int slotNumber, double duration) async {
    final int? enteredDuration = int.tryParse(timerController.text);
    if (enteredDuration == null || enteredDuration <= 0) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال مدة صالحة (أكثر من 0 دقيقة)')),
      );
      return;
    }

    final ratePerMinute = 0.05;
    final totalCost = enteredDuration * ratePerMinute;

    try {
      final deductResponse = await http.post(
        Uri.parse("https://quickpark.onrender.com/api/wallet/deduct"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "userName": userName,
          "amount": totalCost,
          "description": "حجز موقف في $slotNumber لمدة $enteredDuration دقيقة"
        }),
      );

      if (deductResponse.statusCode != 200) {
        Navigator.pop(context);
        scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text("فشل خصم المبلغ. الرجاء المحاولة مجددًا.")),
        );
        return;
      }

      final data = json.decode(deductResponse.body);
      if (mounted) {
        setState(() {
          walletBalance = data['newBalance'].toDouble();
        });
      }
    } catch (e) {
      Navigator.pop(context);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("حدث خطأ في الاتصال بالخادم.")),
      );
      return;
    }

    final confirmUrl = Uri.parse('$apiBaseUrl/$slotNumber/confirm');
    final confirmResponse = await http.put(
      confirmUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userName': userName,
        'duration': enteredDuration,
      }),
    );

    if (!mounted) return;

    if (confirmResponse.statusCode == 200) {
      await fetchSlots();

      final snackBarController = scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تم تأكيد الحجز بنجاح')),
      );

      if (snackBarController != null) {
        await snackBarController.closed;
      }

      setState(() {
        timerController.clear();
      });

      Navigator.pop(context);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TimerPage(
            minutes: 30,
            slotNumber: slotNumber,
          ),
        ),
      );
    }
    else {
      final resBody = json.decode(confirmResponse.body);
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(resBody['error'] ?? 'فشل تأكيد الحجز')),
      );
    }
  }
  Future<bool> cancelSlot(int slotNumber) async {
    final url = Uri.parse('$apiBaseUrl/$slotNumber/cancel');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userName': userName}),
    );

    if (!mounted) return false;

    if (response.statusCode == 200) {
      await fetchSlots();
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تم الغاء الا')),
      );

      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تم إلغاء الحجز')),
      );

      timerController.clear();
      return true;
    } else {
      final resBody = json.decode(response.body);
      scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء الحجز')),
      );

      return false;
    }
  }

  void handleSelect(int slotNumber) async {
    bool success = await selectSlot(slotNumber);
    if (success && mounted) {
      setState(() {
        selectedSlotNumber = slotNumber;
      });
    }
  }

  void handleConfirm(int slotNumber, double totalCost) async {
    await SlotConfirmation(slotNumber, totalCost);

    // Optionally clear selectedSlotNumber or do something else after confirmation:
    if (mounted) {
      setState(() {
        selectedSlotNumber = null;
      });
    }
  }

  void handleCancel() async {
    if (selectedSlotNumber == null) return;

    bool success = await cancelSlot(selectedSlotNumber!);
    if (success && mounted) {
      setState(() {
        selectedSlotNumber = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (userName == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final lockedSlot = _getLockedSlotByUser();

    final screenWidth = MediaQuery.of(context).size.width;
    final int slotCount = slots.length;

    final double horizontalPadding = 16 * 2;
    final double spacing = 8;
    final double totalSpacing = spacing * (slotCount - 1);

    final double slotWidth =
        (screenWidth - horizontalPadding - totalSpacing) / slotCount;

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
        title: const Text("المواقف المتاحة", style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF101D33), Color(0xFF2C3E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Color(0xFF101D33),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'الوجهة: ${widget.destination}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    slots.asMap().entries.map((entry) {
                      int index = entry.key;
                      final slot = entry.value;
                      final slotNum = slot['slotNumber'];
                      final status = slot['status'];
                      final lockedBy = slot['lockedBy'];
                      final isSelected = selectedSlotNumber == slotNum;
                      final isLockedByMe = lockedBy == userName;

                      return Container(
                        width: slotWidth,
                        margin: EdgeInsets.only(
                          right: index == slotCount - 1 ? 0 : spacing,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.green[300]
                              : (status == 'available'
                              ? Colors.white
                              : (status == 'reserved'
                              ? Colors.blue[300]   // Blue for reserved
                              : Colors.grey[300])),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : (status == 'reserved'
                                ? Colors.blue       // Blue border for reserved
                                : Colors.grey),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if ((status == 'available') || isLockedByMe || status == 'reserved') {
                              handleSelect(slotNum);
                            } else {
                              scaffoldMessengerKey.currentState?.showSnackBar(
                                const SnackBar(
                                  content: Text('المكان غير متاح'),
                                ),
                              );

                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_parking,
                                  size: 30,
                                  color: isSelected
                                      ? Colors.white
                                      : (status == 'available'
                                      ? Color(0xFF101D33)
                                      : (status == 'reserved'
                                      ? Color(0xFF101D33)
                                      : Colors.black54)),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Slot #$slotNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  status.toUpperCase(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (status == 'available'
                                        ? Colors.green
                                        : (status == 'reserved'
                                        ? Color(0xFF101D33)
                                        : Colors.red)),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (lockedBy != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text(
                                      'By: $lockedBy',
                                      style: const TextStyle(fontSize: 9),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: screenWidth - 32,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final dashWidth = 15.0;
                  final dashHeight = 4.0;
                  final dashCount =
                      (constraints.maxWidth / (dashWidth * 2)).floor();

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(dashCount, (index) {
                      return Container(
                        width: dashWidth,
                        height: dashHeight,
                        color: Colors.white,
                      );
                    }),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (lockedSlot != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal:0),
                    child: InputField(
                      hint: 'أدخل مدة الوقوف (بالدقائق)',
                      icon: Icons.timer,
                      controller: timerController,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال مدة صحيحة';
                        }
                        final num? parsed = num.tryParse(value);
                        if (parsed == null || parsed <= 0) {
                          return 'المدة يجب أن تكون رقمًا موجبًا';
                        }
                        return null;
                      },
                      iconColor: Colors.indigo,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Buttons row side by side with spacing
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (selectedSlotNumber != null && timerController.text.isNotEmpty) {
                                final duration = double.tryParse(timerController.text);
                                if (duration != null) {
                                  handleConfirm(selectedSlotNumber!, duration);
                                } else {
                                  scaffoldMessengerKey.currentState?.showSnackBar(
                                    const SnackBar(content: Text('يرجى إدخال مدة صحيحة')),
                                  );

                                }
                              } else {
                                scaffoldMessengerKey.currentState?.showSnackBar(
                                  const SnackBar(content: Text('يرجى اختيار الموقف وادخال المدة')),
                                );
                              }
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('Confirm'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF101D33),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: handleCancel,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          if (lockedSlot == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'يرجى اختيار مكان وقوف أولاً',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    ),
    );
  }
}
