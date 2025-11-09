class MulliganManager {
  static final MulliganManager _instance = MulliganManager._internal();
  factory MulliganManager() => _instance;
  MulliganManager._internal();

  double _currentMulliganAmount = 1.0; // Default mulligan amount

  double get currentMulliganAmount => _currentMulliganAmount;

  void setMulliganAmount(double amount) {
    _currentMulliganAmount = amount;
  }

  void setMulliganAmountFromString(String amountString) {
    String numericText = amountString.replaceAll(RegExp(r'[^\d\.]'), '');
    _currentMulliganAmount = double.tryParse(numericText) ?? 1.0;
  }
}