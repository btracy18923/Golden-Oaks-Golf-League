# Project Splitting Plan - Golden Oaks Golf App

## Overview
Split the current unified golf app into three separate device-optimized projects, each supporting both Monday and Wednesday leagues but with layouts optimized for specific device sizes.

## 1. Project Structure

### Device-Specific Projects
```
golf_app_phone/          (6.5" phone version)
├── android/
├── lib/
│   ├── screens/ (phone-optimized layouts)
│   ├── widgets/ (phone-specific components)
│   └── main.dart
├── pubspec.yaml
└── README.md

golf_app_tablet_8/       (8" Fire Tablet version)
├── android/
├── lib/
│   ├── screens/ (8" tablet layouts)
│   ├── widgets/ (8" tablet components)
│   └── main.dart
├── pubspec.yaml
└── README.md

golf_app_tablet_10/      (10" tablet version)
├── android/
├── lib/
│   ├── screens/ (10" tablet layouts)
│   ├── widgets/ (10" tablet components)
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## 2. Naming Strategy

### App Names
- "GoldenOaks (Phone)"
- "GoldenOaks (8\" Tablet)" 
- "GoldenOaks (10\" Tablet)"

### Git Repository Names
- `golf-app-phone`
- `golf-app-tablet-8` 
- `golf-app-tablet-10`

### App Identifiers
- Phone: `com.goldenoaks.phone`
- 8" Tablet: `com.goldenoaks.tablet8`
- 10" Tablet: `com.goldenoaks.tablet10`

## 3. Shared Code Strategy

### Recommended: Copy Shared Code (Option C)
- Duplicate shared services across all 3 projects
- Simplest to maintain and deploy
- Update all 3 projects when shared logic changes

### Shared Components (to be duplicated)
- `models/` - League, Player models
- `services/`
  - `database_helper.dart`
  - `firebase_upload_service.dart` 
  - `handicap_calculation_service.dart`
  - `screen_data_retention_service.dart`
- `utils/` - Utility functions

### Alternative Options
**Option A: Flutter Package**
- Create shared package for common services
- More complex but cleaner architecture

**Option B: Git Submodule**
- Keep shared services in separate repo
- Include as submodule in each project

## 4. Device-Specific Customizations

### 6.5" Phone Project
- **Target Resolution**: 720 × 1600 px; 412 × 915 dp
- **Orientation**: Landscape-only
- **UI Features**:
  - Compact UI elements
  - Smaller fonts and spacing
  - Optimized for touch interaction
  - Status bar hidden for max screen space
  - Tight padding (8px horizontal)

### 8" Fire Tablet Project
- **Target Resolution**: 800 × 1280 px
- **UI Features**:
  - Balanced layout spacing
  - Medium-sized UI elements
  - Standard tablet interactions
  - Moderate padding (16px)
  - Good balance of content density

### 10" Tablet Project
- **Target Resolution**: 800 × 1280 px (lower density)
- **UI Features**:
  - Generous spacing and padding (24px)
  - Larger UI elements
  - Maximum information density
  - Optimized for administrative tasks
  - Comfortable viewing distances

## 5. Implementation Steps

### Phase 1: Preparation
1. **Identify shared vs device-specific code**
   - Mark files to be duplicated vs customized
   - Remove ResponsiveWrapper and device detection logic
   
2. **Set up new Git repositories**
   - Create 3 new GitHub repositories with planned names
   - Set up proper README files for each

### Phase 2: Project Creation
1. **Clone current project 3 times**
   - Start with `golf_app_v4` as base
   - Create separate directories for each device
   
2. **Clean up each project**
   - Remove unused layout methods
   - Remove responsive wrapper components
   - Keep only relevant screen layouts for target device
   
3. **Update app identifiers and names**
   - Modify `android/app/build.gradle`
   - Update `android/app/src/main/AndroidManifest.xml`
   - Update app display names

### Phase 3: Optimization
1. **Optimize layouts for each device**
   - Phone: Use existing `_buildPhoneLandscapeLayout()` methods
   - 8" Tablet: Use existing tablet layouts with medium spacing
   - 10" Tablet: Use existing tablet layouts with generous spacing
   
2. **Remove device detection code**
   - Remove `ResponsiveWrapper`
   - Remove device detection logic from screens
   - Simplify build methods to use only target device layout

### Phase 4: Testing & Deployment
1. **Test each project on target device**
   - Verify layouts work correctly
   - Test league switching (Monday/Wednesday)
   - Verify database sync across devices
   
2. **Set up CI/CD** (optional)
   - Configure automated builds for each repository
   - Set up release management

## 6. Key Benefits

### Complete Isolation
- No interference between device layouts
- Changes to one device won't affect others
- Simpler debugging and maintenance

### Optimized Builds
- Each APK contains only code for its target device
- Smaller app size
- Better performance

### Independent Development
- Modify layouts for specific devices
- Device-specific features and optimizations
- Easier A/B testing on individual devices

### Simplified Deployment
- Each tablet gets its dedicated app version
- Clear identification by device type
- No complex responsive logic to maintain

## 7. League Support

Each app will maintain the existing dual-league architecture:
- **Main Menu**: Monday/Wednesday league selection
- **Color Schemes**: Green for Monday, Orange for Wednesday  
- **Database**: Same SQLite + Firebase sync across all devices
- **Data Isolation**: League filtering maintained in all CRUD operations

## 8. Deployment Strategy

### Target Devices
- **6.5" Phone** → Install "GoldenOaks (Phone)"
- **8" Fire Tablet** → Install "GoldenOaks (8\" Tablet)"
- **10" Tablet** → Install "GoldenOaks (10\" Tablet)"

### Distribution
- Each device gets its optimized APK
- All apps sync to same Firebase collections
- Cross-device data consistency maintained

## 9. Next Steps

### Immediate Actions
1. Choose shared code strategy (recommend Option C for simplicity)
2. Create first device-specific project (recommend starting with 6.5" phone)
3. Test isolated layout on target device
4. Create remaining device projects
5. Set up Git repositories

### Future Considerations
- Monitor maintenance overhead of duplicated code
- Consider refactoring to shared package if complexity grows
- Evaluate CI/CD automation for multiple repositories