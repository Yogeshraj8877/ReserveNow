import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/table_booking_viewmodel.dart';
import '../viewmodels/booking_history_viewmodel.dart';
import '../viewmodels/food_ordering_viewmodel.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

// Table Booking Providers
final tableBookingViewModelProvider = 
    StateNotifierProvider<TableBookingViewModel, AsyncValue<List<RestaurantTable>>>(
  (ref) => TableBookingViewModel(),
);

// Separate state providers for selection values
final selectedTableIdProvider = StateProvider<String?>((ref) => null);
final selectedDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedStartDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedEndDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedTimeSlotProvider = StateProvider<TimeSlot?>((ref) => null);
final guestCountProvider = StateProvider<int>((ref) => 1);

// Available Tables Provider with manual refresh capability
final availableTablesProvider = Provider<List<RestaurantTable>>((ref) {
  final tables = ref.watch(tableBookingViewModelProvider);
  final guestCount = ref.watch(guestCountProvider);
  
  return tables.when(
    data: (tableList) {
      final available = tableList.where((table) => 
        table.capacity >= guestCount && 
        table.status != TableStatus.booked
      ).toList();
      print('Available tables provider: Found ${available.length} available tables out of ${tableList.length} total');
      return available;
    },
    loading: () => <RestaurantTable>[],
    error: (_, __) => <RestaurantTable>[],
  );
});

// Manual refresh trigger for available tables
final availableTablesRefreshProvider = StateProvider<int>((ref) => 0);

final availableTablesWithRefreshProvider = Provider<List<RestaurantTable>>((ref) {
  // Watch for manual refresh triggers
  ref.watch(availableTablesRefreshProvider);
  
  final tables = ref.watch(tableBookingViewModelProvider);
  final guestCount = ref.watch(guestCountProvider);
  
  return tables.when(
    data: (tableList) {
      final available = tableList.where((table) => 
        table.capacity >= guestCount && 
        table.status != TableStatus.booked
      ).toList();
      print('Available tables with refresh: Found ${available.length} available tables out of ${tableList.length} total');
      return available;
    },
    loading: () => <RestaurantTable>[],
    error: (_, __) => <RestaurantTable>[],
  );
});

final canProceedToBookingProvider = Provider<bool>((ref) {
  final selectedTableId = ref.watch(selectedTableIdProvider);
  final selectedStartDate = ref.watch(selectedStartDateProvider);
  final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
  final guestCount = ref.watch(guestCountProvider);
  
  return selectedTableId != null && 
         selectedStartDate != null && 
         selectedTimeSlot != null && 
         guestCount > 0;
});

// Booking History Providers
final bookingHistoryViewModelProvider = 
    StateNotifierProvider<BookingHistoryViewModel, AsyncValue<List<Booking>>>(
  (ref) {
    final viewModel = BookingHistoryViewModel();
    final userId = ref.watch(userIdProvider);
    print('bookingHistoryViewModelProvider - creating with userId: $userId');
    if (userId.isNotEmpty) {
      viewModel.initializeBookings(userId);
    }
    return viewModel;
  },
);

final upcomingBookingsProvider = Provider<List<Booking>>((ref) {
  print('upcomingBookingsProvider called');
  final bookingsAsync = ref.watch(bookingHistoryViewModelProvider);
  return bookingsAsync.when(
    data: (bookings) {
      print('upcomingBookingsProvider - filtering ${bookings.length} bookings');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final upcoming = bookings.where((booking) {
        final bookingDate = DateTime(booking.date.year, booking.date.month, booking.date.day);
        final isUpcoming = bookingDate.isAfter(today) || 
                          bookingDate.isAtSameMomentAs(today);
        print('Booking date: ${booking.date}, IsUpcoming: $isUpcoming, Status: ${booking.status}');
        return isUpcoming && 
               booking.status != BookingStatus.cancelled &&
               booking.status != BookingStatus.completed;
      }).toList();
      print('Found ${upcoming.length} upcoming bookings');
      return upcoming;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final pastBookingsProvider = Provider<List<Booking>>((ref) {
  print('pastBookingsProvider called');
  final bookingsAsync = ref.watch(bookingHistoryViewModelProvider);
  return bookingsAsync.when(
    data: (bookings) {
      print('pastBookingsProvider - filtering ${bookings.length} bookings');
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final past = bookings.where((booking) {
        final bookingDate = DateTime(booking.date.year, booking.date.month, booking.date.day);
        final isPast = bookingDate.isBefore(today);
        print('Booking date: ${booking.date}, IsPast: $isPast, Status: ${booking.status}');
        return isPast || 
               booking.status == BookingStatus.cancelled ||
               booking.status == BookingStatus.completed;
      }).toList();
      print('Found ${past.length} past bookings');
      return past;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Mock User ID Provider
final userIdProvider = Provider<String>((ref) {
  final userId = FirebaseService.getCurrentUserId();
  print('Current user ID from Firebase: $userId');
  return userId ?? '';
});

// Time Slots Provider
final timeSlotsProvider = Provider<List<TimeSlot>>((ref) {
  return [
    TimeSlot(
      id: '1',
      startTime: '11:00',
      endTime: '12:00',
      durationInHours: 1,
      isAvailable: true,
    ),
    TimeSlot(
      id: '2',
      startTime: '12:00',
      endTime: '14:00',
      durationInHours: 2,
      isAvailable: true,
    ),
    TimeSlot(
      id: '3',
      startTime: '14:00',
      endTime: '16:00',
      durationInHours: 2,
      isAvailable: true,
    ),
    TimeSlot(
      id: '4',
      startTime: '16:00',
      endTime: '18:00',
      durationInHours: 2,
      isAvailable: true,
    ),
    TimeSlot(
      id: '5',
      startTime: '18:00',
      endTime: '20:00',
      durationInHours: 2,
      isAvailable: true,
    ),
    TimeSlot(
      id: '6',
      startTime: '20:00',
      endTime: '22:00',
      durationInHours: 2,
      isAvailable: true,
    ),
  ];
});

// Food Ordering Providers
final foodOrderingViewModelProvider = 
    StateNotifierProvider<FoodOrderingViewModel, AsyncValue<List<FoodItem>>>(
  (ref) => FoodOrderingViewModel(),
);

final tableOrdersViewModelProvider = 
    StateNotifierProvider<TableOrdersViewModel, AsyncValue<List<FoodOrder>>>(
  (ref) => TableOrdersViewModel(),
);

final userFoodOrdersViewModelProvider = 
    StateNotifierProvider<UserFoodOrdersViewModel, AsyncValue<List<FoodOrder>>>(
  (ref) => UserFoodOrdersViewModel(),
);

// Food Cart State
final foodCartProvider = StateProvider<List<OrderItem>>((ref) => []);

// Selected food category
final selectedFoodCategoryProvider = StateProvider<FoodCategory?>((ref) => null);
