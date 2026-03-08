import 'package:flutter/material.dart';
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
  bool isTimedCheckIn;
  int checkInDurationMinutes;
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
    this.isTimedCheckIn = false,
    this.checkInDurationMinutes = 25,
    this.sortOrder = 0,
    this.isPinned = false,
  })  : checkInRecords = checkInRecords ?? [],
        createdAt = createdAt ?? DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

  List<CheckInRecord> get completedCheckInRecords =>
      checkInRecords.where((r) => r.countsTowardTarget).toList();

  List<String> get checkInTimes =>
      completedCheckInRecords.map((r) => r.time).toList();

  int get completedCheckInCount => completedCheckInRecords.length;

  int getCheckInCountForDate(DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return checkInRecords
        .where((r) => r.countsTowardTarget && r.time.startsWith(dateStr))
        .length;
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
    'isTimedCheckIn': isTimedCheckIn,
    'checkInDurationMinutes': checkInDurationMinutes,
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
      isTimedCheckIn: (json['isTimedCheckIn'] as bool?) ?? false,
      checkInDurationMinutes: (json['checkInDurationMinutes'] as int?) ?? 25,
      sortOrder: (json['sortOrder'] as int?) ?? 0,
      isPinned: (json['isPinned'] as bool?) ?? false,
    );
  }
}

class CheckInRecord {
  String time;
  String? note;
  int? elapsedSeconds;
  bool? timedCompleted;

  CheckInRecord({
    required this.time,
    this.note,
    this.elapsedSeconds,
    this.timedCompleted,
  });

  bool get isTimedRecord => (elapsedSeconds ?? 0) > 0;

  bool get isTimedInterrupted => isTimedRecord && timedCompleted == false;

  bool get countsTowardTarget => timedCompleted != false;

  String? get timedSummary {
    if (!isTimedRecord) return null;
    return '坚持${_formatDuration(elapsedSeconds!)}';
  }

  static String _formatDuration(int seconds) {
    final safeSeconds = seconds.clamp(0, 864000);
    final hours = safeSeconds ~/ 3600;
    final minutes = (safeSeconds % 3600) ~/ 60;
    final secs = safeSeconds % 60;

    final parts = <String>[];
    if (hours > 0) parts.add('${hours}小时');
    if (minutes > 0) parts.add('${minutes}分钟');
    if (secs > 0 || parts.isEmpty) parts.add('${secs}秒');
    return parts.join();
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'note': note,
    'elapsedSeconds': elapsedSeconds,
    'timedCompleted': timedCompleted,
  };

  factory CheckInRecord.fromJson(Map<String, dynamic> json) => CheckInRecord(
    time: json['time'] as String,
    note: json['note'] as String?,
    elapsedSeconds: json['elapsedSeconds'] as int?,
    timedCompleted: json['timedCompleted'] as bool?,
  );
}
