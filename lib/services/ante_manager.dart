class AnteManager {
  static final AnteManager _instance = AnteManager._internal();
  factory AnteManager() => _instance;
  AnteManager._internal();

  double _currentAnteAmount = 6.0; // Default Wednesday amount

  double get currentAnteAmount => _currentAnteAmount;

  void setAnteAmount(double amount) {
    _currentAnteAmount = amount;
  }

  void setAnteAmountFromString(String amountString) {
    String numericText = amountString.replaceAll(RegExp(r'[^\d\.]'), '');
    _currentAnteAmount = double.tryParse(numericText) ?? 6.0;
  }
}