import 'package:hive/hive.dart';

part 'deduction.g.dart';

@HiveType(typeId: 3)
class Deduction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String? monthKey; // e.g. "2026-03"

  Deduction({
    required this.id,
    required this.title,
    required this.amount,
    this.monthKey,
  });
}
