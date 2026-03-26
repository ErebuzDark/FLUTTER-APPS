import 'package:hive/hive.dart';

part 'budget.g.dart';

@HiveType(typeId: 2)
class Budget extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String label; // e.g. "Salary", "Savings"

  @HiveField(2)
  String? monthKey; // e.g. "2026-03"

  Budget({required this.amount, required this.label, this.monthKey});
}
