enum AcquisitionVerdict { pode, naoPode, podeComRisco }
enum ScenarioProfile { conservador, realista, agressivo }

class PossibilityInput {
  PossibilityInput({
    required this.fixedIncome,
    required this.variableIncome,
    required this.fixedCosts,
    required this.safeMarginPercent,
    required this.debtTarget,
    required this.installments,
    required this.interest,
  });

  final double fixedIncome;
  final double variableIncome;
  final double fixedCosts;
  final double safeMarginPercent;
  final double debtTarget;
  final int installments;
  final double interest;

  double get totalIncome => fixedIncome + variableIncome;
}

class PossibilityResult {
  PossibilityResult({
    required this.profile,
    required this.verdict,
    required this.installmentValue,
    required this.incomeCommittedPercent,
    required this.postFixedSlack,
    required this.rotativeRisk,
    required this.recommendation,
  });

  final ScenarioProfile profile;
  final AcquisitionVerdict verdict;
  final double installmentValue;
  final double incomeCommittedPercent;
  final double postFixedSlack;
  final double rotativeRisk;
  final String recommendation;
}
