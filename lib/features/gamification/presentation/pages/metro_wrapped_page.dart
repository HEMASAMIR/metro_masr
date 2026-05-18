import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/offline_storage.dart';
import 'dart:math' as math;

class MetroWrappedPage extends StatefulWidget {
  const MetroWrappedPage({super.key});

  @override
  State<MetroWrappedPage> createState() => _MetroWrappedPageState();
}

class _MetroWrappedPageState extends State<MetroWrappedPage> {
  int _currentSlide = 0;
  final PageController _controller = PageController();

  late final int trips;
  late final int stations;
  late final double money;
  late final int hoursSaved;

  @override
  void initState() {
    super.initState();
    trips = AppStorage.getTrips();
    stations = AppStorage.getStationsCrossed();
    money = AppStorage.getMoneySaved();
    // Assuming 20 minutes saved per trip vs driving in traffic
    hoursSaved = (trips * 20) ~/ 60;
  }

  void _nextSlide() {
    if (_currentSlide < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = context.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final width = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx > width / 2) {
            _nextSlide();
          } else {
            if (_currentSlide > 0) {
              _controller.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
            }
          }
        },
        child: Stack(
          children: [
            PageView(
              controller: _controller,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (idx) => setState(() => _currentSlide = idx),
              children: [
                _buildSlide1(isAr),
                _buildSlide2(isAr),
                _buildSlide3(isAr),
                _buildSlide4(isAr),
              ],
            ),
            // Progress bars
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                children: List.generate(4, (index) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentSlide ? Colors.white : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            // Close button
            Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSlide1(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(child: const Icon(Icons.train, size: 100, color: Colors.white)),
            const SizedBox(height: 30),
            FadeInUp(
              child: Text(
                isAr ? 'حصاد المترو ${DateTime.now().year}' : 'Metro Wrapped ${DateTime.now().year}',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                'Ready to see your journey?'.tr(),
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide2(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF1CB5E0), Color(0xFF000046)], begin: Alignment.topRight, end: Alignment.bottomLeft),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ZoomIn(child: Text('$trips', style: const TextStyle(fontSize: 100, fontWeight: FontWeight.bold, color: Colors.white))),
            FadeInUp(
              child: Text(
                'Trips taken with us'.tr(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: Text(
                isAr ? 'وعديت على $stations محطة!\nأنت لافف القاهرة كلها.' : 'Crossing $stations stations!\nYou explored all of Cairo.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide3(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF00b09b), Color(0xFF96c93d)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeInDown(child: const Icon(Icons.account_balance_wallet, size: 100, color: Colors.white)),
            const SizedBox(height: 20),
            ZoomIn(
              delay: const Duration(milliseconds: 200),
              child: Text('${money.round()}', style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              child: Text(
                'EGP Saved!'.tr(),
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'If you took taxis, you would have paid this much more.'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide4(bool isAr) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], begin: Alignment.bottomRight, end: Alignment.topLeft),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BounceInDown(child: const Icon(Icons.timer, size: 100, color: Colors.white)),
            const SizedBox(height: 20),
            FadeInUp(
              child: Text(
                isAr ? 'ووفرت $hoursSaved ساعة' : 'Saved $hoursSaved hours',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 10),
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Text(
                'of traffic jams above ground.'.tr(),
                style: const TextStyle(fontSize: 18, color: Colors.white70),
              ),
            ),
            const SizedBox(height: 50),
            FadeInUp(
              delay: const Duration(milliseconds: 600),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                icon: const Icon(Icons.share),
                label: Text('Share Wrapped'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing...'.tr())));
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
