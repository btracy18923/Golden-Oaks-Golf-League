class AppConfig {
  static const String versionDate = '7.14.26';

  // When incrementing dbVersion, you MUST also add a migration block in
  // database_helper.dart -> _upgradeDatabase() for the new version number.
  static const int dbVersion = 27;
}
