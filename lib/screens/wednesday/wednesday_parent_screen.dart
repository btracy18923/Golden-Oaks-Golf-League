import 'package:flutter/material.dart';
import 'wednesday_player_selection_screen.dart';
import 'wednesday_player_scores_screen.dart';
import 'wednesday_player_profile_screen.dart';
import '../../models/league.dart';
import '../../widgets/responsive_wrapper.dart';

class WednesdayParentScreen extends StatefulWidget {
  const WednesdayParentScreen({super.key});

  @override
  State<WednesdayParentScreen> createState() => _WednesdayParentScreenState();
}

class _WednesdayParentScreenState extends State<WednesdayParentScreen> {
  
  void navigateToScreen(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      phone: _buildPhoneLayout(),
      tablet8: _buildTablet8Layout(),
      tablet10: _buildTablet10Layout(),
    );
  }
  
  Widget _buildPhoneLayout() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Wednesday League',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 48,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildLeagueTitleSection(20, 12, 14),
                    const SizedBox(height: 12),
                    _buildPhoneSettingsSection(),
                    const SizedBox(height: 12),
                    _buildImageSection(80, 8),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            _buildNavigationSection(80, 16, 10),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTablet8Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Wednesday League - Golden Oaks Golf',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 56,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeagueTitleSection(18, 10, 12),
                        const SizedBox(height: 16),
                        _buildTabletSettingsSection(),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 6,
                    child: _buildImageSection(100, 10),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildNavigationSection(100, 18, 11),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTablet10Layout() {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Wednesday League - Golden Oaks Golf',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 64,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLeagueTitleSection(24, 12, 16),
                        const SizedBox(height: 20),
                        _buildTabletSettingsSection(),
                        const Spacer(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 7,
                    child: _buildImageSection(120, 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildNavigationSection(120, 20, 12),
          ],
        ),
      ),
    );
  }

  Widget _buildLeagueTitleSection(double fontSize, double borderRadius, double padding) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.orange[300],
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Text(
        'WEDNESDAY LEAGUE',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
  
  Widget _buildPhoneSettingsSection() {
    return Column(
      children: [
        _buildSettingCard('Player\'s Ante', '\$5.00', 12, 14),
        const SizedBox(height: 8),
        _buildSettingCard('Closest Pin', '\$1.00', 12, 14),
        const SizedBox(height: 8),
        _buildSettingCard('Payout Split', '40% / 60%', 12, 14),
      ],
    );
  }
  
  Widget _buildTabletSettingsSection() {
    return Row(
      children: [
        Expanded(child: _buildSettingCard('Player\'s Ante', '\$5.00', 12, 16)),
        const SizedBox(width: 12),
        Expanded(child: _buildSettingCard('Closest Pin', '\$1.00', 12, 16)),
        const SizedBox(width: 12),
        Expanded(child: _buildSettingCard('Payout Split', '40% / 60%', 12, 16)),
      ],
    );
  }
  
  Widget _buildSettingCard(String title, String value, double padding, double titleFontSize) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.orange[200],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.black,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: titleFontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImageSection(double iconSize, double borderRadius) {
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
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Center(
              child: Icon(
                Icons.park,
                size: iconSize,
                color: Colors.orange[600],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildNavigationSection(double buttonWidth, double iconSize, double fontSize) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [
          _buildNavigationButton(
            'Player Selection',
            Icons.people,
            Colors.orange[300]!,
            () => navigateToScreen(const WednesdayPlayerSelectionScreen()),
            buttonWidth,
            iconSize,
            fontSize,
          ),
          _buildNavigationButton(
            'Player Scores',
            Icons.score,
            Colors.orange[200]!,
            () => navigateToScreen(const WednesdayPlayerScoresScreen()),
            buttonWidth,
            iconSize,
            fontSize,
          ),
          _buildNavigationButton(
            'Player Profiles',
            Icons.person,
            Colors.orange[100]!,
            () => navigateToScreen(const WednesdayPlayerProfileScreen()),
            buttonWidth,
            iconSize,
            fontSize,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(String title, IconData icon, Color bgColor, VoidCallback onPressed, double buttonWidth, double iconSize, double fontSize) {
    return Container(
      width: buttonWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}