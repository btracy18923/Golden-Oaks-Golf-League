# golf_app_v3
# Located at: "C:\Users\Acer\AndroidStudioProjects\golf_app_v3"


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Firebase browser key: AIzaSyCNbOi-C2QsZIa9H6XTzQw62BNVNx5_nkQ

1. Enable Anonymous Authentication in Firebase Console
2. Configure Firebase Security Rules for tablet access
3. Implement Auto-Sync between Monday/Wednesday tablets
4. Add Download/Restore functionality from Firebase
5. Setup Real-time Sync for live updates

📱 Current Tablet Setup:

- Monday Tablet: Local SQLite + manual Firebase upload capability
- Wednesday Tablet: Local SQLite + manual Firebase upload capability
- Web Interface: Can read from Firebase (via your Netlify site)

6.5" phone resolution: 720 x 1600 px; 412 x 915 dp
8" Fire Tablet: 800 x 1280 px
10.2" tablet: 800 x 1280

Expected dp values:
- 6.5" phone: 412dp shortest side → < 450
- 8" Fire Tablet: ~533dp shortest side → 450-600 range
- 10.2" tablet: >600dp shortest side → >= 600
  ✅ ParentScreenUI is NOW FULLY FINISHED!

  What was completed:

  ✅ All text widgets updated to use ResponsiveTypography:
    - Players Ante: Labels and values (both phone + tablet)
    - Closest Pin: Labels and values (both phone + tablet)
    - Mulligans: Labels and values (both phone + tablet)
    - Course Selector: "Select Course" labels (both phone + tablet)
    - Course Dropdown: "Choose Course" hint, selected values, and dropdown items

  Font sizes now scale automatically:
    - Phone (< 450dp): Labels 12px, Values 18px, Body 14px, Small 10px
    - 8" Tablet (450-650dp): Labels 14px, Values 24px, Body 16px, Small 12px
    - 10" Tablet (≥ 650dp): Labels 18px, Values 32px, Body 20px, Small 14px

  Your 10" tablet will now show:
    - "Players Ante": 18px (was 20px hardcoded)
    - "$25.00" amounts: 32px (was 26px hardcoded)
    - "Choose Course": 20px (was 14px hardcoded)
    - All other text: Appropriately scaled for 10" tablets

  Next step: Test this on your 10" tablet - you should see noticeably larger, properly scaled text throughout the ParentScreenUI!



