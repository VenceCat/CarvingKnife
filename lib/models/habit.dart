import 'package:intl/intl.dart';
import '../services/habit_icons.dart';

class Habit {
  String id;
  String title;
  String description;
  List<CheckInRecord> checkInRecords;
  String? reminderTime;
  String createdAt;
  int iconIndex;
  int dailyTarget;
  int sortOrder;
  bool isPinned;

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    List<CheckInRecord>? checkInRecords,
    this.reminderTime,
    String? createdAt,
    this.iconIndex = 0,
    this.dailyTarget = 1,
    this.sortOrder = 0,
    this.isPinned = false,
  })  : checkInRecords = checkInRecords ?? [],
        createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  List<CheckInRecord> get completedCheckInRecords => checkInRecords;

  List<String> get checkInTimes => completedCheckInRecords.map((r) => r.time).toList();

  int get completedCheckInCount => completedCheckInRecords.length;

  int getCheckInCountForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return checkInRecords.where((r) => r.time.startsWith(dateStr)).length;
  }

  int get todayCheckInCount => getCheckInCountForDate(DateTime.now());

  bool get isTodayCompleted => todayCheckInCount >= dailyTarget;

  int get todayRemainingCount => (dailyTarget - todayCheckInCount).clamp(0, dailyTarget);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'checkInRecords': checkInRecords.map((r) => r.toJson()).toList(),
    'reminderTime': reminderTime,
    'createdAt': createdAt,
    'iconIndex': iconIndex,
    'iconCodePoint': HabitIcons.getIcon(iconIndex).codePoint,
    'dailyTarget': dailyTarget,
    'sortOrder': sortOrder,
    'isPinned': isPinned,
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    List<CheckInRecord> records = [];
    if (json['checkInRecords'] != null) {
      records = (json['checkInRecords'] as List)
          .map((r) => CheckInRecord.fromJson(r as Map<String, dynamic>))
          .toList();
    } else if (json['checkInTimes'] != null) {
      records = (json['checkInTimes'] as List)
          .map((t) => CheckInRecord(time: t as String))
          .toList();
    }

    return Habit(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      checkInRecords: records,
      reminderTime: json['reminderTime'] as String?,
      createdAt: json['createdAt'] as String?,
      iconIndex: (json['iconIndex'] as int?) ?? 0,
      dailyTarget: (json['dailyTarget'] as int?) ?? 1,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      isPinned: (json['isPinned'] as bool?) ?? false,
    );
  }
}

class CheckInRecord {
  String time;
  String? note;

  CheckInRecord({
    required this.time,
    this.note,
  });

  Map<String, dynamic> toJson() => {
    'time': time,
    'note': note,
  };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    time: json['time'] as String,
    note: json['note'] as String?,
  );
}

