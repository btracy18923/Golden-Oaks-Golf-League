import '../shared/base_auto_fill_service.dart';
import '../monday/monday_auto_fill_service.dart';
import '../wednesday/wednesday_auto_fill_service.dart';
import '../../models/league.dart';

/// Factory for creating league-specific auto fill services
/// Returns appropriate auto fill service based on league type
class AutoFillFactory {
  
  /// Creates an auto fill service instance based on the specified league
  /// 
  /// Returns:
  /// - MondayAutoFillService for Monday league (fills SKATS 30-40)
  /// - WednesdayAutoFillService for Wednesday league (fills GROSS 39-49)
  /// 
  /// Throws Exception if unsupported league is provided
  static BaseAutoFillService create(League league) {
    switch (league) {
      case League.monday:
        return MondayAutoFillService();
      case League.wednesday:
        return WednesdayAutoFillService();
      default:
        throw Exception('Unsupported league: ${league.name}');
    }
  }
  
  /// Gets the display name for the auto fill function based on league
  /// 
  /// Returns:
  /// - "Auto Fill SKATS" for Monday league
  /// - "Auto Fill GROSS" for Wednesday league
  static String getAutoFillDisplayName(League league) {
    switch (league) {
      case League.monday:
        return 'Auto Fill SKATS';
      case League.wednesday:
        return 'Auto Fill GROSS';
      default:
        return 'Auto Fill';
    }
  }
  
  /// Gets the field name being auto-filled based on league
  /// 
  /// Returns:
  /// - "SKATS" for Monday league
  /// - "GROSS" for Wednesday league
  static String getAutoFillFieldName(League league) {
    switch (league) {
      case League.monday:
        return 'SKATS';
      case League.wednesday:
        return 'GROSS';
      default:
        return 'SCORE';
    }
  }
  
  /// Gets the value range being used for auto fill based on league
  /// 
  /// Returns:
  /// - "30-40" for Monday league
  /// - "39-49" for Wednesday league
  static String getAutoFillRange(League league) {
    switch (league) {
      case League.monday:
        return '30-40';
      case League.wednesday:
        return '39-49';
      default:
        return 'N/A';
    }
  }
}