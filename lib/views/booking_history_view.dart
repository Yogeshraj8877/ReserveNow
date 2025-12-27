import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../views/profile_screen.dart';

class BookingHistoryView extends ConsumerStatefulWidget {
  const BookingHistoryView({super.key});

  @override
  ConsumerState<BookingHistoryView> createState() => _BookingHistoryViewState();
}

class _BookingHistoryViewState extends ConsumerState<BookingHistoryView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingHistoryViewModelProvider);
    final upcomingBookings = ref.watch(upcomingBookingsProvider);
    final pastBookings = ref.watch(pastBookingsProvider);
    final userEmail = AuthService.getCurrentUserEmail();
    final userInitial = userEmail?.isNotEmpty == true ? userEmail![0].toUpperCase() : 'U';

    print('Building booking history - Bookings state: ${bookingsAsync}');
    print('Upcoming bookings count: ${upcomingBookings.length}');
    print('Past bookings count: ${pastBookings.length}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,

        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // actions: [
        //   IconButton(
        //     icon: CircleAvatar(
        //       backgroundColor: const Color(0xFF2196F3),
        //       child: Text(
        //         userInitial,
        //         style: const TextStyle(
        //           color: Colors.white,
        //           fontWeight: FontWeight.bold,
        //           fontSize: 16,
        //         ),
        //       ),
        //     ),
        //     onPressed: () {
        //       Navigator.of(context).push(
        //         MaterialPageRoute(
        //           builder: (context) => const ProfileScreen(),
        //         ),
        //       );
        //     },
        //   ),
        // ],
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  radius: 18,
                  child: Text(
                    userInitial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],

        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Past'),
          ],
          indicatorColor: const Color(0xFF2196F3),
          labelColor: const Color(0xFF2196F3),
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: bookingsAsync.when(
        loading: () {
          print('Bookings are loading...');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          print('Error loading bookings: $error');
          return Center(child: Text('Error: $error'));
        },
        data: (bookings) {
          print('Bookings loaded: ${bookings.length} items');
          return TabBarView(
            controller: _tabController,
            children: [
              _buildBookingsList(upcomingBookings, isUpcoming: true),
              _buildBookingsList(pastBookings, isUpcoming: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, {required bool isUpcoming}) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUpcoming ? Icons.event_available : Icons.history,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isUpcoming ? 'No upcoming bookings' : 'No past bookings',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking, isUpcoming);
      },
    );
  }

  Widget _buildBookingCard(Booking booking, bool isUpcoming) {
    Color statusColor;
    String statusText;
    
    switch (booking.status) {
      case BookingStatus.pending:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case BookingStatus.confirmed:
        statusColor = Colors.green;
        statusText = 'Confirmed';
        break;
      case BookingStatus.cancelled:
        statusColor = Colors.red;
        statusText = 'Cancelled';
        break;
      case BookingStatus.completed:
        statusColor = Colors.blue;
        statusText = 'Completed';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Table Number and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Table ${booking.table.number}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Booking Details
            _buildDetailRow(Icons.calendar_today, 
                DateFormat('EEEE, MMMM d, yyyy').format(booking.date)),
            _buildDetailRow(Icons.access_time, booking.timeSlot.displayTime),
            _buildDetailRow(Icons.people, '${booking.guestCount} Guests'),
            _buildDetailRow(Icons.event_seat, 'Capacity: ${booking.table.capacity}'),
            
            if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty)
              _buildDetailRow(Icons.note, booking.specialRequests!),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            if (isUpcoming && booking.status != BookingStatus.cancelled)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, booking),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('Cancel Booking'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showBookingDetails(context, booking),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showBookingDetails(context, booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('View Details'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Text(
          'Are you sure you want to cancel your booking for Table ${booking.table.number} on ${DateFormat('MMMM d, yyyy').format(booking.date)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              final bookingHistoryViewModel = ref.read(bookingHistoryViewModelProvider.notifier);
              bookingHistoryViewModel.cancelBooking(booking.id, booking.table.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _showBookingDetails(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Booking Details - Table ${booking.table.number}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(Icons.calendar_today, 
                  DateFormat('EEEE, MMMM d, yyyy').format(booking.date)),
              _buildDetailRow(Icons.access_time, booking.timeSlot.displayTime),
              _buildDetailRow(Icons.people, '${booking.guestCount} Guests'),
              _buildDetailRow(Icons.event_seat, 'Table Capacity: ${booking.table.capacity}'),
              _buildDetailRow(Icons.table_bar, 'Table Shape: ${booking.table.shape.name}'),
              _buildDetailRow(Icons.confirmation_number, 'Booking ID: ${booking.id}'),
              if (booking.specialRequests != null && booking.specialRequests!.isNotEmpty)
                _buildDetailRow(Icons.note, 'Special Requests: ${booking.specialRequests!}'),
              _buildDetailRow(Icons.schedule, 
                  'Booked on: ${DateFormat('MMMM d, yyyy').format(booking.createdAt)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
