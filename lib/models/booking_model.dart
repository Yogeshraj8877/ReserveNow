import 'package:uuid/uuid.dart';
import 'table_model.dart';
import 'time_slot_model.dart';
import 'food_models.dart';

enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  completed,
}

class Booking {
  final String id;
  final String userId;
  final RestaurantTable table;
  final DateTime date;
  final TimeSlot timeSlot;
  final int guestCount;
  final BookingStatus status;
  final DateTime createdAt;
  final String? specialRequests;
  final List<OrderItem>? foodOrder;

  Booking({
    String? id,
    required this.userId,
    required this.table,
    required this.date,
    required this.timeSlot,
    required this.guestCount,
    required this.status,
    DateTime? createdAt,
    this.specialRequests,
    this.foodOrder,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  Booking copyWith({
    String? id,
    String? userId,
    RestaurantTable? table,
    DateTime? date,
    TimeSlot? timeSlot,
    int? guestCount,
    BookingStatus? status,
    DateTime? createdAt,
    String? specialRequests,
    List<OrderItem>? foodOrder,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      table: table ?? this.table,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      guestCount: guestCount ?? this.guestCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      specialRequests: specialRequests ?? this.specialRequests,
      foodOrder: foodOrder ?? this.foodOrder,
    );
  }

  double get foodOrderTotal {
    if (foodOrder == null || foodOrder!.isEmpty) return 0.0;
    return foodOrder!.fold(0.0, (total, item) => total + item.totalPrice);
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get displayInfo {
    return 'Table ${table.number} - $formattedDate, ${timeSlot.displayTime} - $guestCount guests';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'table': table.toJson(),
      'date': date.toIso8601String(),
      'timeSlot': timeSlot.toJson(),
      'guestCount': guestCount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'specialRequests': specialRequests,
      'foodOrder': foodOrder?.map((item) => item.toJson()).toList(),
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? foodOrderData = json['foodOrder'];
    return Booking(
      id: json['id'],
      userId: json['userId'],
      table: RestaurantTable.fromJson(json['table']),
      date: DateTime.parse(json['date']),
      timeSlot: TimeSlot.fromJson(json['timeSlot']),
      guestCount: json['guestCount'],
      status: BookingStatus.values.firstWhere((e) => e.name == json['status']),
      createdAt: DateTime.parse(json['createdAt']),
      specialRequests: json['specialRequests'],
      foodOrder: foodOrderData?.map((item) => OrderItem.fromJson(item)).toList(),
    );
  }
}
