import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ante_manager.dart';
import '../services/closest_pin_manager.dart';
import '../services/mulligan_manager.dart';
import '../services/device_detection_service.dart';
import 'monday/monday_parent_screen.dart';
import 'wednesday/wednesday_parent_screen.dart';
import '../widgets/responsive_wrapper.dart';

class UnifiedMainMenuScreen extends StatefulWidget {
  const UnifiedMainMenuScreen({super.key});

  @override
  State<UnifiedMainMenuScreen> createState() => _UnifiedMainMenuScreenState();
}

class _UnifiedMainMenuScreenState extends State<UnifiedMainMenuScreen> {
  @override
  void initState() {
    super.initState();

    // Lock all devices to landscape mode only
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  @override
  void dispose() {
    // Keep landscape mode locked - don't reset orientation constraints
    super.dispose();
  }

  void selectMondayLeague() async {
    AnteManager().setAnteAmount(5.0);
    ClosestPinManager().setClosestPinAmount(4.0);
    MulliganManager().setMulliganAmount(2.0);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MondayParentScreen()),
    );
  }

  void selectWednesdayLeague() async {
    AnteManager().setAnteAmount(5.0);
    ClosestPinManager().setClosestPinAmount(1.0);
    MulliganManager().setMulliganAmount(1.0);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WednesdayParentScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet10: _buildTablet10Layout(),
    );
  }

  // 6.5" phone layout
  Widget _buildPhoneLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League - 3.8.26',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildLeagueButtons(isPhone: true),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: _buildLogoImage(borderRadius: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTablet10Layout() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Golden Oaks Golf League - 3.8.26',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: _buildLeagueButtons(isPhone: false),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 7,
              child: _buildLogoImage(borderRadius: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueButtons({required bool isPhone}) {
    final is10Tablet = DeviceDetectionService.is10Tablet(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select Your League:',
          style: TextStyle(
            fontSize: isPhone ? 18 : 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isPhone ? 12 : 16),

        if (isPhone)
          // Phone: Horizontal layout with compact buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 2),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: ElevatedButton(
                      onPressed: selectMondayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Monday',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 2),
                  child: AspectRatio(
                    aspectRatio: 2.0,
                    child: ElevatedButton(
                      onPressed: selectWednesdayLeague,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[200],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black,
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Wednesday',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          // Tablet: Horizontal layout with larger buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ElevatedButton(
                    onPressed: selectMondayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[200],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(is10Tablet ? 40 : 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Monday\nLeague',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(left: 8),
                  child: ElevatedButton(
                    onPressed: selectWednesdayLeague,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[200],
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.all(is10Tablet ? 40 : 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                    ),
                    child: const Text(
                      'Wednesday\nLeague',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLogoImage({required double borderRadius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/images/GoldenOaks.png',
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Center(
              child: Icon(
                Icons.park,
                size: 120,
                color: Colors.green[600],
              ),
            ),
          );
        },
      ),
    );
  }
}
