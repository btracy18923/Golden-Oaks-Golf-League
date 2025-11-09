class ClosestPinManager {
  static final ClosestPinManager _instance = ClosestPinManager._internal();
  factory ClosestPinManager() => _instance;
  ClosestPinManager._internal();

  double _currentClosestPinAmount = 1.0; // Default closest pin amount

  double get currentClosestPinAmount => _currentClosestPinAmount;

  void setClosestPinAmount(double amount) {
    _currentClosestPinAmount = amount;
  }

  void setClosestPinAmountFromString(String amountString) {
    String numericText = amountString.replaceAll(RegExp(r'[^\d\.]'), '');
    _currentClosestPinAmount = double.tryParse(numericText) ?? 1.0;
  }
}