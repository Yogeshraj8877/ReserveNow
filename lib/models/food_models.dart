enum FoodCategory {
  appetizers,
  mainCourse,
  desserts,
  beverages,
}

class FoodItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final FoodCategory category;
  final String imageUrl;
  final bool available;
  final int preparationTime; // in minutes

  FoodItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl = '',
    this.available = true,
    this.preparationTime = 15,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category.name,
      'imageUrl': imageUrl,
      'available': available,
      'preparationTime': preparationTime,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      price: json['price'].toDouble(),
      category: FoodCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => FoodCategory.mainCourse,
      ),
      imageUrl: json['imageUrl'] ?? '',
      available: json['available'] ?? true,
      preparationTime: json['preparationTime'] ?? 15,
    );
  }
}

class OrderItem {
  final String foodItemId;
  final String foodItemName;
  final double price;
  final int quantity;
  final String? specialInstructions;

  OrderItem({
    required this.foodItemId,
    required this.foodItemName,
    required this.price,
    required this.quantity,
    this.specialInstructions,
  });

  double get totalPrice => price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'foodItemId': foodItemId,
      'foodItemName': foodItemName,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      foodItemId: json['foodItemId'],
      foodItemName: json['foodItemName'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      specialInstructions: json['specialInstructions'],
    );
  }
}

class FoodOrder {
  final String id;
  final String bookingId;
  final String tableId;
  final String userId;
  final List<OrderItem> items;
  final double totalAmount;
  final DateTime orderTime;
  final DateTime? deliveryTime;
  final String status; // pending, preparing, ready, delivered, cancelled
  final String? specialInstructions;

  FoodOrder({
    required this.id,
    required this.bookingId,
    required this.tableId,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.orderTime,
    this.deliveryTime,
    this.status = 'pending',
    this.specialInstructions,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'tableId': tableId,
      'userId': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderTime': orderTime.toIso8601String(),
      'deliveryTime': deliveryTime?.toIso8601String(),
      'status': status,
      'specialInstructions': specialInstructions,
    };
  }

  factory FoodOrder.fromJson(Map<String, dynamic> json) {
    return FoodOrder(
      id: json['id'],
      bookingId: json['bookingId'],
      tableId: json['tableId'],
      userId: json['userId'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: json['totalAmount'].toDouble(),
      orderTime: DateTime.parse(json['orderTime']),
      deliveryTime: json['deliveryTime'] != null
          ? DateTime.parse(json['deliveryTime'])
          : null,
      status: json['status'] ?? 'pending',
      specialInstructions: json['specialInstructions'],
    );
  }
}
