class BankAccount {
  late String accountNumber; // assigned after construction
  final String holderName;
  double balance;
  final String? bankBranch;

  BankAccount({
    required this.holderName,
    this.balance = 0.0,
    this.bankBranch,
  });

  void initializeAccount(String number) {
    accountNumber = number;
  }

  /// Reading an unset `late` field throws, so we catch it to test.
  bool isAccountNumberSet() {
    try {
      final _ = accountNumber;
      return true;
    } on Error {
      return false; // LateInitializationError
    }
  }

  /// Safe text for the UI.
  String get displayNumber =>
      isAccountNumberSet() ? accountNumber : 'Account not initialized';
}