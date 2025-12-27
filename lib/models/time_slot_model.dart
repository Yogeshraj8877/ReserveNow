class TimeSlot {
  final String id;
  final String startTime;
  final String endTime;
  final int durationInHours;
  final bool isAvailable;

  TimeSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.durationInHours,
    required this.isAvailable,
  });

  String get displayTime => '$startTime - $endTime';
  
  String get durationDisplay => '${durationInHours}h${durationInHours > 1 ? 's' : ''}';

  TimeSlot copyWith({
    String? id,
    String? startTime,
    String? endTime,
    int? durationInHours,
    bool? isAvailable,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationInHours: durationInHours ?? this.durationInHours,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'endTime': endTime,
      'durationInHours': durationInHours,
      'isAvailable': isAvailable,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      durationInHours: json['durationInHours'],
      isAvailable: json['isAvailable'],
    );
  }
}
