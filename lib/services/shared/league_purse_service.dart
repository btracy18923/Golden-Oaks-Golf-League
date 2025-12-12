import '../../models/league.dart';

/// Service for managing league-specific purse information
/// Handles purse amounts for both Monday and Wednesday leagues
class LeaguePurseService {
  
  // Purse amounts (in dollars)
  static double _closestPinPurse = 0.0;
  static double _mulliganPurse = 0.0;
  static double _skatPurse = 0.0; // Monday league specific
  static double _antePurse = 0.0; // Wednesday league specific
  static double _remainingSkatPurse = 0.0; // Remaining skat purse after distributions
  static bool _hasDistributedMoney = false; // Flag to track if money has been distributed
  static bool _closestPinPurseSetExplicitly = false; // Track if closest pin purse was set by closest pin screen
  static bool _mulliganPurseSetExplicitly = false; // Track if mulligan purse was set explicitly
  
  /// Gets the closest pin purse amount
  static double get closestPinPurse => _closestPinPurse;
  
  /// Gets the mulligan purse amount
  static double get mulliganPurse => _mulliganPurse;
  
  /// Gets the skat purse amount (Monday league)
  static double get skatPurse => _skatPurse;
  
  /// Gets the ante purse amount (Wednesday league)
  static double get antePurse => _antePurse;
  
  /// Sets the closest pin purse amount
  static void setClosestPinPurse(double amount, {bool isExplicit = true}) {
    _closestPinPurse = amount;
    if (isExplicit) {
      _closestPinPurseSetExplicitly = true;
    }
  }
  
  /// Sets the mulligan purse amount
  static void setMulliganPurse(double amount, {bool isExplicit = true}) {
    _mulliganPurse = amount;
    if (isExplicit) {
      _mulliganPurseSetExplicitly = true;
    }
  }
  
  /// Sets the skat purse amount (Monday league)
  static void setSkatPurse(double amount) {
    _skatPurse = amount;
  }
  
  /// Sets the ante purse amount (Wednesday league)
  static void setAntePurse(double amount) {
    _antePurse = amount;
  }
  
  /// Sets the remaining skat purse amount (after distributions)
  static void setRemainingPurse(double amount) {
    _remainingSkatPurse = amount;
    _hasDistributedMoney = true;
  }
  
  /// Resets the distribution state (useful for new game sessions)
  /// Does NOT reset explicit purse flags - those persist across screen transitions
  static void resetDistributionState() {
    _remainingSkatPurse = 0.0;
    _hasDistributedMoney = false;
    // Don't reset explicit flags here - they should persist when navigating between screens
  }

  /// Resets all purse states including explicit flags
  /// Only call this when starting a completely new game session
  static void resetAllPurseStates() {
    _remainingSkatPurse = 0.0;
    _hasDistributedMoney = false;
    _closestPinPurseSetExplicitly = false;
    _mulliganPurseSetExplicitly = false;
  }
  
  /// Gets the league-specific primary purse amount
  /// For Monday league, returns remaining purse if money has been distributed
  static double getPrimaryPurse(League league) {
    switch (league) {
      case League.monday:
        // Return remaining purse if distributions have been made, otherwise original amount
        return _hasDistributedMoney ? _remainingSkatPurse : _skatPurse;
      case League.wednesday:
        return _antePurse;
    }
  }
  
  /// Gets the league-specific primary purse label
  static String getPrimaryPurseLabel(League league) {
    switch (league) {
      case League.monday:
        return 'Skat Purse';
      case League.wednesday:
        return 'Ante Purse';
    }
  }
  
  /// Sets the league-specific primary purse amount
  static void setPrimaryPurse(League league, double amount) {
    switch (league) {
      case League.monday:
        setSkatPurse(amount);
        break;
      case League.wednesday:
        setAntePurse(amount);
        break;
    }
  }
  
  /// Formats a purse amount as currency string
  static String formatPurseAmount(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
  
  /// Gets the complete purse header text for a specific league
  static Map<String, String> getPurseHeaderData(League league) {
    return {
      'primary': '${getPrimaryPurseLabel(league)} = ${formatPurseAmount(getPrimaryPurse(league))}',
      'closestPin': 'Closest Pin Purse = ${formatPurseAmount(_closestPinPurse)}',
      'mulligan': 'Mulligan Purse = ${formatPurseAmount(_mulliganPurse)}',
    };
  }
  
  /// Resets all purse amounts to zero
  static void resetAllPurses() {
    _closestPinPurse = 0.0;
    _mulliganPurse = 0.0;
    _skatPurse = 0.0;
    _antePurse = 0.0;
  }
  
  /// Loads purse amounts from database or storage
  /// TODO: Implement database loading logic
  static Future<void> loadPurseAmounts(League league) async {
    // Placeholder for database loading
    // This would typically load from SQLite or Firebase
    //print('Loading purse amounts for ${league.name} league...');
    
    // For now, set some default values for demonstration
    switch (league) {
      case League.monday:
        setSkatPurse(25.0);
        break;
      case League.wednesday:
        setAntePurse(30.0);
        break;
    }
    
    setClosestPinPurse(15.0);
    setMulliganPurse(20.0);
  }
  
  /// Loads secondary purse amounts (Closest Pin, Mulligan) without overwriting primary purse
  /// Used when Players Ante is already set and we don't want to reset it
  /// Only sets default values if purses haven't been explicitly set by other screens
  static Future<void> loadSecondaryPurseAmounts() async {
    // Only load default values if purses haven't been explicitly set
    // This preserves values that were updated by other screens (like Closest Pin screen)
    if (!_closestPinPurseSetExplicitly) {
      setClosestPinPurse(15.0, isExplicit: false);
    }
    if (!_mulliganPurseSetExplicitly) {
      setMulliganPurse(20.0, isExplicit: false);
    }
  }
  
  /// Saves purse amounts to database or storage
  /// TODO: Implement database saving logic
  static Future<void> savePurseAmounts(League league) async {
    // Placeholder for database saving
    //print('Saving purse amounts for ${league.name} league...');
    //print('Primary Purse: ${formatPurseAmount(getPrimaryPurse(league))}');
    //print('Closest Pin Purse: ${formatPurseAmount(_closestPinPurse)}');
    //print('Mulligan Purse: ${formatPurseAmount(_mulliganPurse)}');
  }
  
  /// Updates a specific purse amount by type
  static void updatePurseAmount(League league, String purseType, double amount) {
    switch (purseType.toLowerCase()) {
      case 'skat':
        setSkatPurse(amount);
        break;
      case 'ante':
        setAntePurse(amount);
        break;
      case 'closest_pin':
      case 'closestpin':
        setClosestPinPurse(amount);
        break;
      case 'mulligan':
        setMulliganPurse(amount);
        break;
      default:
        throw ArgumentError('Unknown purse type: $purseType');
    }
  }
  
  // Current Players Ante amount for calculation
  static double _playersAnte = 5.0; // Default value
  
  // Current Closest Pin amount for calculation
  static double _closestPinAmount = 4.0; // Default value
  
  // Current Mulligan amount for calculation
  static double _mulliganAmount = 2.0; // Default value
  
  /// Sets the current Players Ante amount
  static void setPlayersAnte(double amount) {
    _playersAnte = amount;
  }
  
  /// Gets the current Players Ante amount
  static double get playersAnte => _playersAnte;
  
  /// Sets the current Closest Pin amount
  static void setClosestPinAmount(double amount) {
    _closestPinAmount = amount;
  }
  
  /// Gets the current Closest Pin amount
  static double get closestPinAmount => _closestPinAmount;
  
  /// Sets the current Mulligan amount
  static void setMulliganAmount(double amount) {
    _mulliganAmount = amount;
  }
  
  /// Gets the current Mulligan amount
  static double get mulliganAmount => _mulliganAmount;
  
  /// Calculates and sets the Skat Purse based on Players Ante and selected players count
  static void calculateSkatPurse(double playersAnte, int selectedPlayersCount) {
    _skatPurse = playersAnte * selectedPlayersCount;
  }
  
  /// Calculates and sets the Skat Purse based on current Players Ante and selected players count
  static void calculateSkatPurseFromCount(int selectedPlayersCount) {
    _skatPurse = _playersAnte * selectedPlayersCount;
  }
  
  /// Calculates and sets the Closest Pin Purse based on Closest Pin amount and selected players count
  /// Only calculates if not explicitly set by another screen (like Closest Pin screen)
  static void calculateClosestPinPurse(double closestPinAmount, int selectedPlayersCount) {
    if (!_closestPinPurseSetExplicitly) {
      _closestPinPurse = closestPinAmount * selectedPlayersCount;
    }
  }

  /// Calculates and sets the Closest Pin Purse based on current Closest Pin amount and selected players count
  /// Only calculates if not explicitly set by another screen (like Closest Pin screen)
  static void calculateClosestPinPurseFromCount(int selectedPlayersCount) {
    if (!_closestPinPurseSetExplicitly) {
      _closestPinPurse = _closestPinAmount * selectedPlayersCount;
    }
  }
  
  /// Calculates and sets the Mulligan Purse based on Mulligan amount and selected players count
  /// Only calculates if not explicitly set by another screen
  static void calculateMulliganPurse(double mulliganAmount, int selectedPlayersCount) {
    if (!_mulliganPurseSetExplicitly) {
      _mulliganPurse = mulliganAmount * selectedPlayersCount;
    }
  }

  /// Calculates and sets the Mulligan Purse based on current Mulligan amount and selected players count
  /// Only calculates if not explicitly set by another screen
  static void calculateMulliganPurseFromCount(int selectedPlayersCount) {
    if (!_mulliganPurseSetExplicitly) {
      _mulliganPurse = _mulliganAmount * selectedPlayersCount;
    }
  }
  
  /// Gets all purse amounts as a map for debugging or export
  static Map<String, double> getAllPurseAmounts() {
    return {
      'skatPurse': _skatPurse,
      'antePurse': _antePurse,
      'closestPinPurse': _closestPinPurse,
      'mulliganPurse': _mulliganPurse,
    };
  }
}