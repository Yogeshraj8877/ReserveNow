import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/models.dart';

class FirebaseService {
  static final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Tables Collection
  static const String _tablesPath = 'tables';
  static const String _bookingsPath = 'bookings';

  // Initialize tables in Firebase
  static Future<void> initializeTables() async {
    try {
      final tablesSnapshot = await _database.child(_tablesPath).get();
      
      // Always recreate tables to ensure we have 1000 tables
      if (tablesSnapshot.value == null || true) { // Force recreation for now
        await _createInitialTables();
      }
    } catch (e) {
      print('Error initializing tables: $e');
    }
  }

  // Force create tables (for testing)
  static Future<void> forceCreateTables() async {
    try {
      print('Firebase: Force creating tables...');
      // Clear existing tables first
      await _database.child(_tablesPath).remove();
      print('Firebase: Cleared existing tables');
      // Create new 1000 tables
      await _createInitialTables();
      print('Firebase: Created 1000 new tables');
    } catch (e) {
      print('Error force creating tables: $e');
    }
  }

  static Future<void> _createInitialTables() async {
    final initialTables = <RestaurantTable>[];
    
    // Create 1000 tables arranged in rows
    int tableId = 1;
    int maxTablesPerRow = 10; // 10 tables per row for better layout
    int totalRows = 10; // 100 rows to get 1000 tables
    
    for (int row = 0; row < totalRows; row++) {
      for (int col = 0; col < maxTablesPerRow; col++) {
        // Vary table capacities for variety (2, 4, 6, 8 persons)
        final capacities = [2, 4, 6, 8];
        final capacity = capacities[(tableId - 1) % capacities.length];
        
        // Vary table shapes for variety
        final shapes = [TableShape.square, TableShape.rectangular, TableShape.circular];
        final shape = shapes[(tableId - 1) % shapes.length];
        
        initialTables.add(RestaurantTable(
          id: tableId.toString(),
          number: 'T$tableId',
          capacity: capacity,
          shape: shape,
          status: TableStatus.available,
          row: row,
          column: col,
        ));
        
        tableId++;
      }
    }

    // Convert tables to map and save to Firebase
    final tablesMap = <String, dynamic>{};
    for (final table in initialTables) {
      tablesMap[table.id] = table.toJson();
    }
    
    await _database.child(_tablesPath).set(tablesMap);
  }

  // Get all tables
  static Stream<List<RestaurantTable>> getTables() {
    return _database.child(_tablesPath).onValue.map((event) {
      final data = event.snapshot.value;
      print('FirebaseService: Raw tables data type: ${data.runtimeType}');
      print('FirebaseService: Raw tables data exists: ${event.snapshot.exists}');
      
      if (data == null) {
        print('FirebaseService: No tables data found');
        return <RestaurantTable>[];
      }
      
      List<RestaurantTable> tables = [];
      
      // Handle both Map and List cases
      if (data is Map<dynamic, dynamic>) {
        print('FirebaseService: Processing tables as Map with ${data.entries.length} entries');
        tables = data.entries.map((entry) {
          final tableData = Map<String, dynamic>.from(entry.value as Map);
          return RestaurantTable.fromJson(tableData);
        }).toList();
      } else if (data is List) {
        print('FirebaseService: Processing tables as List with ${data.length} items');
        tables = data.whereType<Map<dynamic, dynamic>>().map((tableData) {
          return RestaurantTable.fromJson(Map<String, dynamic>.from(tableData));
        }).toList();
      }
      
      print('FirebaseService: Loaded ${tables.length} tables');
      final availableTables = tables.where((t) => t.status == TableStatus.available).length;
      final bookedTables = tables.where((t) => t.status == TableStatus.booked).length;
      print('FirebaseService: Available: $availableTables, Booked: $bookedTables, Total: ${tables.length}');
      
      return tables;
    });
  }

  // Update table status
  static Future<void> updateTableStatus(String tableId, TableStatus status) async {
    try {
      print('Updating table $tableId status to: ${status.name}');
      await _database.child(_tablesPath).child(tableId).update({'status': status.name});
      print('Table $tableId status updated successfully to: ${status.name}');
    } catch (e) {
      print('Error updating table status: $e');
      rethrow;
    }
  }

  // Create booking
  static Future<void> createBooking(Booking booking) async {
    try {
      print('Creating booking for user: ${booking.userId}, table: ${booking.table.id}');
      
      // Update table status to booked
      await updateTableStatus(booking.table.id, TableStatus.booked);
      
      // Create booking document
      final bookingData = {
        'userId': booking.userId,
        'table': booking.table.toJson(),
        'date': booking.date.toIso8601String(),
        'timeSlot': booking.timeSlot.toJson(),
        'guestCount': booking.guestCount,
        'status': booking.status.name,
        'createdAt': booking.createdAt.toIso8601String(),
        'specialRequests': booking.specialRequests,
      };
      
      print('Booking data to save: $bookingData');
      await _database.child(_bookingsPath).push().set(bookingData);
      print('Booking created successfully');
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  // Get user's bookings
  static Stream<List<Booking>> getUserBookings(String userId) {
    print('Getting bookings for user: $userId');
    return _database.child(_bookingsPath).onValue.map((event) {
      final data = event.snapshot.value;
      print('Raw bookings data: $data');
      
      if (data == null) {
        print('No bookings data found');
        return <Booking>[];
      }
      
      // Handle both Map and List cases
      List<MapEntry<dynamic, dynamic>> entries;
      
      if (data is Map<dynamic, dynamic>) {
        entries = data.entries.toList();
        print('Processing ${entries.length} booking entries');
      } else if (data is List) {
        entries = data.asMap().entries.map((entry) => 
          MapEntry(entry.key.toString(), entry.value)
        ).toList();
        print('Processing ${entries.length} booking entries from list');
      } else {
        print('Unexpected data type: ${data.runtimeType}');
        return <Booking>[];
      }
      
      final userBookings = entries
          .where((entry) {
            final entryValue = entry.value;
            return entryValue is Map && entryValue['userId'] == userId;
          })
          .map((entry) {
            final bookingData = entry.value as Map<dynamic, dynamic>;
            print('Processing booking: ${bookingData}');
            return Booking(
              id: entry.key.toString(),
              userId: bookingData['userId'],
              table: RestaurantTable.fromJson(Map<String, dynamic>.from(bookingData['table'] as Map)),
              date: DateTime.parse(bookingData['date']),
              timeSlot: TimeSlot.fromJson(Map<String, dynamic>.from(bookingData['timeSlot'] as Map)),
              guestCount: bookingData['guestCount'],
              status: _parseBookingStatus(bookingData['status']),
              createdAt: DateTime.parse(bookingData['createdAt']),
              specialRequests: bookingData['specialRequests'],
            );
          }).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Sort by date descending
          
      print('Found ${userBookings.length} bookings for user $userId');
      return userBookings;
    });
  }

  // Cancel booking
  static Future<void> cancelBooking(String bookingId, String tableId) async {
    try {
      // Update table status to available
      await updateTableStatus(tableId, TableStatus.available);
      
      // Update booking status
      await _database.child(_bookingsPath).child(bookingId).update({'status': 'cancelled'});
    } catch (e) {
      print('Error cancelling booking: $e');
      rethrow;
    }
  }

  // Check if table is available for given date and time
  static Future<bool> isTableAvailable(String tableId, DateTime date, TimeSlot timeSlot) async {
    try {
      final bookingsSnapshot = await _database.child(_bookingsPath).get();
      final data = bookingsSnapshot.value;
      if (data == null) return true;

      // Handle both Map and List cases
      Iterable<MapEntry<dynamic, dynamic>> entries;
      
      if (data is Map<dynamic, dynamic>) {
        entries = data.entries;
      } else if (data is List) {
        entries = data.asMap().entries.map((entry) => 
          MapEntry(entry.key.toString(), entry.value)
        );
      } else {
        return true;
      }

      for (final entry in entries) {
        if (entry.value is! Map) continue;
        
        final bookingData = Map<String, dynamic>.from(entry.value as Map);
        
        // Skip cancelled bookings
        if (bookingData['status'] == 'cancelled') continue;
        
        // Check if it's the same table
        final tableData = bookingData['table'];
        if (tableData is! Map || tableData['id'] != tableId) continue;
        
        final bookingDate = DateTime.parse(bookingData['date']);
        final bookingTimeSlot = TimeSlot.fromJson(bookingData['timeSlot']);

        // Check if dates are the same and time slots conflict
        if (_isSameDate(date, bookingDate) &&
            timeSlot.startTime == bookingTimeSlot.startTime) {
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error checking table availability: $e');
      return false;
    }
  }

  // Helper method to check if dates are the same
  static bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Parse booking status from string
  static BookingStatus _parseBookingStatus(String statusString) {
    switch (statusString.toLowerCase()) {
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'pending':
        return BookingStatus.pending;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.pending;
    }
  }

  // Get current user ID
  static String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

// Get current user email
  static String? getCurrentUserEmail() {
    return _auth.currentUser?.email;
  }
}
