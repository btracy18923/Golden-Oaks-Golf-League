class PercentageManager {
  static final PercentageManager _instance = PercentageManager._internal();
  factory PercentageManager() => _instance;
  PercentageManager._internal();

  double _individualPercent = 40.0; // Default individual percentage
  double _groupPercent = 60.0; // Default group percentage

  double get individualPercent => _individualPercent;
  double get groupPercent => _groupPercent;

  void setIndividualPercent(double percent) {
    _individualPercent = percent.clamp(0.0, 100.0);
    _groupPercent = 100.0 - _individualPercent;
  }

  void setGroupPercent(double percent) {
    _groupPercent = percent.clamp(0.0, 100.0);
    _individualPercent = 100.0 - _groupPercent;
  }

  void setPercentagesFromString(String individualPercentString, String groupPercentString) {
    String individualNumeric = individualPercentString.replaceAll(RegExp(r'[^\d\.]'), '');
    double individual = double.tryParse(individualNumeric) ?? 40.0;
    setIndividualPercent(individual);
  }

  // Get individual percentage as decimal for calculations (40% = 0.40)
  double get individualPercentDecimal => _individualPercent / 100.0;

  // Get group percentage as decimal for calculations (60% = 0.60)
  double get groupPercentDecimal => _groupPercent / 100.0;
}