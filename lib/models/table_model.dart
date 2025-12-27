enum TableStatus {
  available,
  booked,
  selected,
}

enum TableShape {
  rectangular,
  circular,
  square,
}

class RestaurantTable {
  final String id;
  final String number;
  final int capacity;
  final TableShape shape;
  final TableStatus status;
  final String? bookedBy;
  final DateTime? bookedAt;
  final int row;
  final int column;

  RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
    required this.shape,
    required this.status,
    this.bookedBy,
    this.bookedAt,
    required this.row,
    required this.column,
  });

  RestaurantTable copyWith({
    String? id,
    String? number,
    int? capacity,
    TableShape? shape,
    TableStatus? status,
    String? bookedBy,
    DateTime? bookedAt,
    int? row,
    int? column,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
      shape: shape ?? this.shape,
      status: status ?? this.status,
      bookedBy: bookedBy ?? this.bookedBy,
      bookedAt: bookedAt ?? this.bookedAt,
      row: row ?? this.row,
      column: column ?? this.column,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'capacity': capacity,
      'shape': shape.name,
      'status': status.name,
      'bookedBy': bookedBy,
      'bookedAt': bookedAt?.toIso8601String(),
      'row': row,
      'column': column,
    };
  }

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    return RestaurantTable(
      id: json['id'],
      number: json['number'],
      capacity: json['capacity'],
      shape: TableShape.values.firstWhere((e) => e.name == json['shape']),
      status: TableStatus.values.firstWhere((e) => e.name == json['status']),
      bookedBy: json['bookedBy'],
      bookedAt: json['bookedAt'] != null ? DateTime.parse(json['bookedAt']) : null,
      row: json['row'],
      column: json['column'],
    );
  }
}
