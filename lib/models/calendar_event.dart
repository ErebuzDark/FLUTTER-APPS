import 'package:hive/hive.dart';

part 'calendar_event.g.dart'; // this will be auto-generated

@HiveType(typeId: 0)
class CalendarEvent extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String note;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  bool notifyMe;

  CalendarEvent({
    required this.title,
    required this.note,
    required this.date,
    required this.notifyMe,
  });
}