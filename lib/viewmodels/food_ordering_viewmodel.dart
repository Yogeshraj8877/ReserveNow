import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/food_models.dart';
import '../services/food_service.dart';

class FoodOrderingViewModel extends StateNotifier<AsyncValue<List<FoodItem>>> {
  FoodOrderingViewModel() : super(const AsyncValue.loading()) {
    loadMenuItems();
  }

  Future<void> loadMenuItems() async {
    state = const AsyncValue.loading();
    try {
      final menuItems = await FoodService.getMenuItems();
      state = AsyncValue.data(menuItems);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<List<FoodItem>> getMenuItemsByCategory(FoodCategory category) async {
    try {
      return await FoodService.getMenuItemsByCategory(category);
    } catch (e) {
      print('Error getting menu items by category: $e');
      return [];
    }
  }

  Future<void> createInitialMenuItems() async {
    try {
      await FoodService.createInitialMenuItems();
      await loadMenuItems(); // Reload after creating
    } catch (e) {
      print('Error creating initial menu items: $e');
    }
  }
}

class TableOrdersViewModel extends StateNotifier<AsyncValue<List<FoodOrder>>> {
  TableOrdersViewModel() : super(const AsyncValue.loading());

  Future<void> loadOrdersForTable(String tableId, DateTime date) async {
    state = const AsyncValue.loading();
    try {
      final orders = await FoodService.getOrdersForTable(tableId, date);
      state = AsyncValue.data(orders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadTodayOrders() async {
    state = const AsyncValue.loading();
    try {
      final orders = await FoodService.getTodayOrders();
      state = AsyncValue.data(orders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await FoodService.updateOrderStatus(orderId, status);
      // Reload orders after update
      if (state.value != null) {
        state = AsyncValue.data(state.value!);
      }
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}

class UserFoodOrdersViewModel extends StateNotifier<AsyncValue<List<FoodOrder>>> {
  UserFoodOrdersViewModel() : super(const AsyncValue.loading());

  Future<void> loadUserOrders(String userId) async {
    state = const AsyncValue.loading();
    try {
      final orders = await FoodService.getUserOrders(userId);
      state = AsyncValue.data(orders);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<String> createFoodOrder(FoodOrder order) async {
    try {
      final orderId = await FoodService.createFoodOrder(order);
      // Reload orders after creating
      if (state.value != null) {
        state = AsyncValue.data(state.value!);
      }
      return orderId;
    } catch (e) {
      print('Error creating food order: $e');
      throw e;
    }
  }
}
