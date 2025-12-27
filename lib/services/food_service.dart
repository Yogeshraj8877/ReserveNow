import 'package:firebase_database/firebase_database.dart';
import '../models/food_models.dart';

class FoodService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String _menuPath = 'menu';
  static const String _ordersPath = 'foodOrders';

  // Get all food items
  static Future<List<FoodItem>> getMenuItems() async {
    try {
      print('FoodService: Getting menu items...');
      final snapshot = await _database.child(_menuPath).get();
      print('FoodService: Menu snapshot value type: ${snapshot.value.runtimeType}');
      
      if (snapshot.value == null) {
        print('FoodService: No menu items found in database');
        return [];
      }
      
      // Handle different data types from Firebase
      final data = snapshot.value;
      List<FoodItem> menuItems = [];
      
      if (data is List) {
        // Handle List structure
        print('FoodService: Processing menu as List with ${data.length} items');
        for (final item in data) {
          if (item is Map) {
            final itemData = Map<String, dynamic>.from(item as Map<Object?, Object?>);
            menuItems.add(FoodItem.fromJson(itemData));
          }
        }
      } else if (data is Map) {
        // Handle Map structure
        print('FoodService: Processing menu as Map with ${data.length} entries');
        final Map<dynamic, dynamic> mapData = data;
        menuItems = mapData.entries.map((entry) {
          if (entry.value is Map) {
            final itemData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            itemData['id'] = entry.key.toString();
            return FoodItem.fromJson(itemData);
          }
          return null;
        }).where((item) => item != null).cast<FoodItem>().toList();
      } else {
        print('FoodService: Unexpected data type: ${data.runtimeType}');
        return [];
      }
      
      print('FoodService: Successfully loaded ${menuItems.length} menu items');
      return menuItems;
    } catch (e) {
      print('Error getting menu items: $e');
      return [];
    }
  }

  // Get food items by category
  static Future<List<FoodItem>> getMenuItemsByCategory(FoodCategory category) async {
    try {
      final snapshot = await _database.child(_menuPath).get();
      if (snapshot.value == null) return [];
      
      // Handle different data types from Firebase
      final data = snapshot.value;
      List<FoodItem> allItems = [];
      
      if (data is List) {
        // Handle List structure
        for (final item in data) {
          if (item is Map) {
            final itemData = Map<String, dynamic>.from(item as Map<Object?, Object?>);
            allItems.add(FoodItem.fromJson(itemData));
          }
        }
      } else if (data is Map) {
        // Handle Map structure
        final Map<dynamic, dynamic> mapData = data;
        allItems = mapData.entries
            .where((entry) => entry.value is Map)
            .map((entry) {
              final itemData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
              itemData['id'] = entry.key.toString();
              return FoodItem.fromJson(itemData);
            })
            .toList();
      }
      
      // Filter by category and availability
      return allItems
          .where((item) => item.category == category.name && item.available)
          .toList();
    } catch (e) {
      print('Error getting menu items by category: $e');
      return [];
    }
  }

  // Create initial menu items
  static Future<void> createInitialMenuItems() async {
    try {
      final menuItems = [
        // Appetizers
        FoodItem(
          id: '1',
          name: 'Spring Rolls',
          description: 'Crispy vegetable spring rolls with sweet chili sauce',
          price: 6.99,
          category: FoodCategory.appetizers,
          preparationTime: 10,
        ),
        FoodItem(
          id: '2',
          name: 'Garlic Bread',
          description: 'Toasted garlic bread with herbs and butter',
          price: 4.99,
          category: FoodCategory.appetizers,
          preparationTime: 8,
        ),
        FoodItem(
          id: '3',
          name: 'Caesar Salad',
          description: 'Fresh romaine lettuce with caesar dressing and croutons',
          price: 8.99,
          category: FoodCategory.appetizers,
          preparationTime: 5,
        ),

        // Main Course
        FoodItem(
          id: '4',
          name: 'Grilled Chicken',
          description: 'Juicy grilled chicken with herbs and lemon',
          price: 15.99,
          category: FoodCategory.mainCourse,
          preparationTime: 20,
        ),
        FoodItem(
          id: '5',
          name: 'Beef Burger',
          description: 'Classic beef burger with lettuce, tomato, and cheese',
          price: 12.99,
          category: FoodCategory.mainCourse,
          preparationTime: 15,
        ),
        FoodItem(
          id: '6',
          name: 'Pasta Carbonara',
          description: 'Creamy pasta with bacon and parmesan cheese',
          price: 13.99,
          category: FoodCategory.mainCourse,
          preparationTime: 18,
        ),
        FoodItem(
          id: '7',
          name: 'Grilled Salmon',
          description: 'Fresh Atlantic salmon with lemon butter sauce',
          price: 18.99,
          category: FoodCategory.mainCourse,
          preparationTime: 25,
        ),
        FoodItem(
          id: '8',
          name: 'Vegetarian Pizza',
          description: 'Wood-fired pizza with fresh vegetables',
          price: 14.99,
          category: FoodCategory.mainCourse,
          preparationTime: 20,
        ),

        // Desserts
        FoodItem(
          id: '9',
          name: 'Chocolate Cake',
          description: 'Rich chocolate cake with chocolate frosting',
          price: 6.99,
          category: FoodCategory.desserts,
          preparationTime: 5,
        ),
        FoodItem(
          id: '10',
          name: 'Ice Cream Sundae',
          description: 'Vanilla ice cream with chocolate sauce and nuts',
          price: 5.99,
          category: FoodCategory.desserts,
          preparationTime: 3,
        ),
        FoodItem(
          id: '11',
          name: 'Tiramisu',
          description: 'Classic Italian dessert with coffee and mascarpone',
          price: 7.99,
          category: FoodCategory.desserts,
          preparationTime: 5,
        ),

        // Beverages
        FoodItem(
          id: '12',
          name: 'Fresh Orange Juice',
          description: 'Freshly squeezed orange juice',
          price: 3.99,
          category: FoodCategory.beverages,
          preparationTime: 2,
        ),
        FoodItem(
          id: '13',
          name: 'Coffee',
          description: 'Freshly brewed coffee',
          price: 2.99,
          category: FoodCategory.beverages,
          preparationTime: 3,
        ),
        FoodItem(
          id: '14',
          name: 'Lemonade',
          description: 'Fresh lemonade with mint',
          price: 3.49,
          category: FoodCategory.beverages,
          preparationTime: 2,
        ),
        FoodItem(
          id: '15',
          name: 'Soft Drink',
          description: 'Assorted soft drinks (Coke, Sprite, etc.)',
          price: 2.49,
          category: FoodCategory.beverages,
          preparationTime: 1,
        ),
      ];

      // Add to Firebase Realtime Database
      for (final item in menuItems) {
        await _database.child(_menuPath).child(item.id).set(item.toJson());
      }

      print('Created ${menuItems.length} initial menu items');
    } catch (e) {
      print('Error creating initial menu items: $e');
    }
  }

  // Create food order
  static Future<String> createFoodOrder(FoodOrder order) async {
    try {
      await _database.child(_ordersPath).child(order.id).set(order.toJson());
      print('Created food order: ${order.id}');
      return order.id;
    } catch (e) {
      print('Error creating food order: $e');
      throw e;
    }
  }

  // Get orders for a specific table on a specific date
  static Future<List<FoodOrder>> getOrdersForTable(String tableId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _database.child(_ordersPath).get();
      if (snapshot.value == null) return [];
      
      // Handle different data types from Firebase
      final data = snapshot.value;
      if (data is! Map) {
        print('Expected Map but got ${data.runtimeType}');
        return [];
      }
      
      final Map<dynamic, dynamic> mapData = data as Map<dynamic, dynamic>;
      return mapData.entries
          .where((entry) {
            if (entry.value is! Map) return false;
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            final orderTime = DateTime.parse(orderData['orderTime']);
            return orderData['tableId'] == tableId &&
                   orderTime.isAfter(startOfDay) &&
                   orderTime.isBefore(endOfDay);
          })
          .map((entry) {
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            orderData['id'] = entry.key.toString();
            return FoodOrder.fromJson(orderData);
          })
          .toList()
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));
    } catch (e) {
      print('Error getting orders for table: $e');
      return [];
    }
  }

  // Get all orders for today
  static Future<List<FoodOrder>> getTodayOrders() async {
    try {
      print('FoodService: Getting today orders...');
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _database.child(_ordersPath).get();
      print('FoodService: Snapshot value type: ${snapshot.value.runtimeType}');
      print('FoodService: Snapshot value: ${snapshot.value}');
      
      if (snapshot.value == null) {
        print('FoodService: No orders found in database');
        return [];
      }
      
      // Handle different data types from Firebase
      final data = snapshot.value;
      if (data is! Map) {
        print('Expected Map but got ${data.runtimeType}');
        return [];
      }
      
      final Map<dynamic, dynamic> mapData = data as Map<dynamic, dynamic>;
      print('FoodService: Found ${mapData.length} entries in orders database');
      
      return mapData.entries
          .where((entry) {
            if (entry.value is! Map) return false;
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            final orderTime = DateTime.parse(orderData['orderTime']);
            return orderTime.isAfter(startOfDay) && orderTime.isBefore(endOfDay);
          })
          .map((entry) {
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            orderData['id'] = entry.key.toString();
            return FoodOrder.fromJson(orderData);
          })
          .toList()
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));
    } catch (e) {
      print('Error getting today orders: $e');
      return [];
    }
  }

  // Update order status
  static Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      final updateData = {'status': status};
      if (status == 'delivered') {
        updateData['deliveryTime'] = DateTime.now().toIso8601String();
      }
      
      await _database.child(_ordersPath).child(orderId).update(updateData);
      print('Updated order status: $orderId -> $status');
    } catch (e) {
      print('Error updating order status: $e');
      throw e;
    }
  }

  // Create sample food orders for testing
  static Future<void> createSampleOrders() async {
    try {
      print('FoodService: Creating sample food orders...');
      
      final sampleOrders = [
        FoodOrder(
          id: 'sample_order_1',
          bookingId: 'booking_1',
          tableId: '1',
          userId: 'sample_user_1',
          items: [
            OrderItem(
              foodItemId: '1',
              foodItemName: 'Spring Rolls',
              price: 6.99,
              quantity: 2,
            ),
            OrderItem(
              foodItemId: '13',
              foodItemName: 'Coffee',
              price: 2.99,
              quantity: 1,
            ),
          ],
          totalAmount: 16.97,
          orderTime: DateTime.now(),
          status: 'pending',
        ),
        FoodOrder(
          id: 'sample_order_2',
          bookingId: 'booking_2',
          tableId: '2',
          userId: 'sample_user_2',
          items: [
            OrderItem(
              foodItemId: '5',
              foodItemName: 'Beef Burger',
              price: 12.99,
              quantity: 1,
            ),
            OrderItem(
              foodItemId: '15',
              foodItemName: 'Soft Drink',
              price: 2.49,
              quantity: 2,
            ),
          ],
          totalAmount: 17.97,
          orderTime: DateTime.now().subtract(const Duration(minutes: 30)),
          status: 'preparing',
        ),
        FoodOrder(
          id: 'sample_order_3',
          bookingId: 'booking_3',
          tableId: '3',
          userId: 'sample_user_3',
          items: [
            OrderItem(
              foodItemId: '7',
              foodItemName: 'Grilled Salmon',
              price: 18.99,
              quantity: 1,
            ),
            OrderItem(
              foodItemId: '9',
              foodItemName: 'Chocolate Cake',
              price: 6.99,
              quantity: 1,
            ),
          ],
          totalAmount: 25.98,
          orderTime: DateTime.now().subtract(const Duration(hours: 1)),
          status: 'ready',
        ),
      ];

      for (final order in sampleOrders) {
        await _database.child(_ordersPath).child(order.id).set(order.toJson());
      }

      print('FoodService: Created ${sampleOrders.length} sample orders');
    } catch (e) {
      print('Error creating sample orders: $e');
    }
  }

  // Get orders by user
  static Future<List<FoodOrder>> getUserOrders(String userId) async {
    try {
      final snapshot = await _database.child(_ordersPath).get();
      if (snapshot.value == null) return [];
      
      // Handle different data types from Firebase
      final data = snapshot.value;
      if (data is! Map) {
        print('Expected Map but got ${data.runtimeType}');
        return [];
      }
      
      final Map<dynamic, dynamic> mapData = data as Map<dynamic, dynamic>;
      return mapData.entries
          .where((entry) {
            if (entry.value is! Map) return false;
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            return orderData['userId'] == userId;
          })
          .map((entry) {
            final orderData = Map<String, dynamic>.from(entry.value as Map<Object?, Object?>);
            orderData['id'] = entry.key.toString();
            return FoodOrder.fromJson(orderData);
          })
          .toList()
        ..sort((a, b) => b.orderTime.compareTo(a.orderTime));
    } catch (e) {
      print('Error getting user orders: $e');
      return [];
    }
  }
}
