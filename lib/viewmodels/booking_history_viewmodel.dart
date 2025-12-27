import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';

class BookingHistoryViewModel extends StateNotifier<AsyncValue<List<Booking>>> {
  BookingHistoryViewModel() : super(const AsyncValue.loading());

  List<Booking> _userBookings = [];

  void initializeBookings(String userId) {
    print('BookingHistoryViewModel: Initializing for userId: $userId');
    if (userId.isEmpty) {
      print('BookingHistoryViewModel: User ID is empty, returning empty list');
      state = const AsyncValue.data([]);
      return;
    }

    // Listen to real-time booking updates
    FirebaseService.getUserBookings(userId).listen((bookings) {
      print('BookingHistoryViewModel: Received ${bookings.length} bookings from Firebase');
      _userBookings = bookings;
      state = AsyncValue.data(_userBookings);
    }, onError: (error) {
      print('BookingHistoryViewModel: Error loading bookings: $error');
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  // Cancel booking
  Future<bool> cancelBooking(String bookingId, String tableId) async {
    try {
      await FirebaseService.cancelBooking(bookingId, tableId);
      
      // Update local state
      _userBookings = _userBookings.map((booking) {
        if (booking.id == bookingId) {
          return booking.copyWith(status: BookingStatus.cancelled);
        }
        return booking;
      }).toList();
      
      state = AsyncValue.data(_userBookings);
      return true;
    } catch (e) {
      print('Error cancelling booking: $e');
      return false;
    }
  }

  // Get upcoming bookings
  List<Booking> getUpcomingBookings() {
    final now = DateTime.now();
    print('Getting upcoming bookings - Current date: $now');
    final upcoming = _userBookings.where((booking) {
      final isUpcoming = booking.date.isAfter(now) || 
                       booking.date.isAtSameMomentAs(now);
      print('Booking date: ${booking.date}, IsUpcoming: $isUpcoming, Status: ${booking.status}');
      return isUpcoming && 
             booking.status != BookingStatus.cancelled &&
             booking.status != BookingStatus.completed;
    }).toList();
    print('Found ${upcoming.length} upcoming bookings');
    return upcoming;
  }

  // Get past bookings
  List<Booking> getPastBookings() {
    final now = DateTime.now();
    print('Getting past bookings - Current date: $now');
    final past = _userBookings.where((booking) {
      final isPast = booking.date.isBefore(now);
      print('Booking date: ${booking.date}, IsPast: $isPast, Status: ${booking.status}');
      return isPast || 
             booking.status == BookingStatus.cancelled ||
             booking.status == BookingStatus.completed;
    }).toList();
    print('Found ${past.length} past bookings');
    return past;
  }
}
