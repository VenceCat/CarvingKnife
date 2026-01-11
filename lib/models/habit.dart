import 'package:intl/intl.dart';

class Habit {
  String id;
  String title;
  String description;
  List<CheckInRecord> checkInRecords;
  String? reminderTime;
  String createdAt;
  int iconIndex; // 新增：图标索引

  Habit({
    required this.id,
    required this.title,
    this.description = '',
    List<CheckInRecord>? checkInRecords,
    this.reminderTime,
    String? createdAt,
    this.iconIndex = 0, // 默认图标索引
  })  : checkInRecords = checkInRecords ?? [],
        createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  List<String> get checkInTimes => checkInRecords.map((r) => r.time).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'checkInRecords': checkInRecords.map((r) => r.toJson()).toList(),
    'reminderTime': reminderTime,
    'createdAt': createdAt,
    'iconIndex': iconIndex, // 新增
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
      iconIndex: (json['iconIndex'] as int?) ?? 0, // 新增
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