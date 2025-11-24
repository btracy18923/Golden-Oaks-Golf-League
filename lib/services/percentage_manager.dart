/// Service for managing percentage distribution for payouts
/// Handles individual and group percentage calculations
class PercentageManager {
  
  // Default percentage values
  double _individualPercent = 40.0; // Default individual percentage
  double _groupPercent = 60.0; // Default group percentage (100 - individual)
  
  /// Singleton pattern implementation
  static final PercentageManager _instance = PercentageManager._internal();
  
  factory PercentageManager() {
    return _instance;
  }
  
  PercentageManager._internal();
  
  /// Gets the current individual percentage
  double get individualPercent => _individualPercent;
  
  /// Gets the current group percentage
  double get groupPercent => _groupPercent;
  
  /// Gets the individual percentage as decimal (for calculations)
  double get individualPercentDecimal => _individualPercent / 100.0;
  
  /// Gets the group percentage as decimal (for calculations)
  double get groupPercentDecimal => _groupPercent / 100.0;
  
  /// Sets the individual percentage and automatically updates group percentage
  /// Individual + Group should always equal 100%
  void setIndividualPercent(double percent) {
    if (percent < 0.0 || percent > 100.0) {
      throw ArgumentError('Percentage must be between 0 and 100');
    }
    
    _individualPercent = percent;
    _groupPercent = 100.0 - percent;
  }
  
  /// Sets the group percentage and automatically updates individual percentage
  /// Individual + Group should always equal 100%
  void setGroupPercent(double percent) {
    if (percent < 0.0 || percent > 100.0) {
      throw ArgumentError('Percentage must be between 0 and 100');
    }
    
    _groupPercent = percent;
    _individualPercent = 100.0 - percent;
  }
  
  /// Resets to default percentages (40% individual, 60% group)
  void resetToDefaults() {
    _individualPercent = 40.0;
    _groupPercent = 60.0;
  }
  
  /// Calculates individual purse amount from total purse
  double calculateIndividualPurse(double totalPurse) {
    return totalPurse * individualPercentDecimal;
  }
  
  /// Calculates group purse amount from total purse
  double calculateGroupPurse(double totalPurse) {
    return totalPurse * groupPercentDecimal;
  }
  
  /// Validates that percentages add up to 100%
  bool isValid() {
    return (_individualPercent + _groupPercent).abs() - 100.0 < 0.001; // Allow for floating point precision
  }
  
  @override
  String toString() {
    return 'PercentageManager(individual: $_individualPercent%, group: $_groupPercent%)';
  }
}