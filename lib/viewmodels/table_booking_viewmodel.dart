import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/firebase_service.dart';
import '../providers/providers.dart';

class TableBookingViewModel extends StateNotifier<AsyncValue<List<RestaurantTable>>> {
  TableBookingViewModel() : super(const AsyncValue.loading()) {
    _loadTables();
  }

  List<RestaurantTable> _allTables = [];
  String? _selectedTableId;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeSlot? _selectedTimeSlot;
  int _guestCount = 2;

  // Getters
  String? get selectedTableId => _selectedTableId;
  DateTime? get selectedStartDate => _selectedStartDate;
  DateTime? get selectedEndDate => _selectedEndDate;
  DateTime? get selectedDate => _selectedStartDate; // Keep for compatibility
  TimeSlot? get selectedTimeSlot => _selectedTimeSlot;
  int get guestCount => _guestCount;

  // Notify listeners of state change
  void _notifyStateChange() {
    final currentState = state.value ?? [];
    state = AsyncValue.data(currentState);
  }

  // Load tables from Firebase
  void _loadTables() {
    print('TableBookingViewModel: Loading tables from Firebase...');
    
    // Initialize tables in Firebase if needed
    FirebaseService.initializeTables();
    
    // Listen to real-time table updates
    FirebaseService.getTables().listen((tables) {
      print('TableBookingViewModel: Received ${tables.length} tables from Firebase');
      _allTables = tables;
      state = AsyncValue.data(_allTables);
      
      // Log available tables count
      final availableCount = getAvailableTables().length;
      print('TableBookingViewModel: Available tables count: $availableCount');
    }, onError: (error) {
      print('TableBookingViewModel: Error loading tables: $error');
      state = AsyncValue.error(error, StackTrace.current);
    });
  }

  // Manual refresh method to force reload tables
  Future<void> refreshTables() async {
    try {
      print('Refreshing tables list...');
      final tables = await FirebaseService.getTables().first;
      print('TableBookingViewModel: Refreshed ${tables.length} tables from Firebase');
      _allTables = tables;
      state = AsyncValue.data(_allTables);
      
      // Log available tables count after refresh
      final availableCount = getAvailableTables().length;
      print('TableBookingViewModel: Available tables after refresh: $availableCount');
      
      print('Tables refreshed successfully');
    } catch (e) {
      print('Error refreshing tables: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void initializeTables() {
    _loadTables();
  }

  List<RestaurantTable> getAvailableTables() {
    return _allTables.where((table) => 
      table.status == TableStatus.available && 
      table.capacity >= _guestCount
    ).toList();
  }

  void selectTable(String tableId) {
    _selectedTableId = tableId;
    _updateTableStates();
  }

  void selectDateRange(DateTime startDate, DateTime endDate) {
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    // Update state to notify listeners
    _notifyStateChange();
  }

  void selectDate(DateTime date) {
    _selectedStartDate = date;
    _selectedEndDate = date; // For backwards compatibility
    // Update state to notify listeners
    _notifyStateChange();
  }

  void selectTimeSlot(TimeSlot timeSlot) {
    _selectedTimeSlot = timeSlot;
    // Update state to notify listeners
    _notifyStateChange();
  }

  void setGuestCount(int count) {
    _guestCount = count;
    _updateTableStates();
  }

  // Update external providers (call these from views)
  void updateSelectedTableId(String? tableId) {
    _selectedTableId = tableId;
    _updateTableStates();
  }

  void updateSelectedDate(DateTime? date) {
    _selectedStartDate = date;
    _selectedEndDate = date;
    _notifyStateChange();
  }

  void updateSelectedTimeSlot(TimeSlot? timeSlot) {
    _selectedTimeSlot = timeSlot;
    _notifyStateChange();
  }

  void updateGuestCount(int count) {
    _guestCount = count;
    _updateTableStates();
  }

  void _updateTableStates() {
    final updatedTables = _allTables.map((table) {
      if (table.id == _selectedTableId) {
        return table.copyWith(status: TableStatus.selected);
      } else if (table.status == TableStatus.selected) {
        return table.copyWith(status: TableStatus.available);
      }
      return table;
    }).toList();

    _allTables = updatedTables;
    _notifyStateChange();
  }

  bool canProceedToBooking() {
    return _selectedTableId != null && 
           _selectedStartDate != null && 
           _selectedTimeSlot != null && 
           _guestCount > 0;
  }

  // Create booking in Firebase
  Future<bool> createBooking(WidgetRef ref) async {
    try {
      // Get values from providers instead of internal state
      final selectedTableId = ref.read(selectedTableIdProvider);
      final selectedStartDate = ref.read(selectedStartDateProvider);
      final selectedTimeSlot = ref.read(selectedTimeSlotProvider);
      final guestCount = ref.read(guestCountProvider);
      
      print('Creating booking - Table: $selectedTableId, Date: $selectedStartDate, Time: $selectedTimeSlot, Guests: $guestCount');
      
      if (selectedTableId == null || selectedStartDate == null || selectedTimeSlot == null) {
        print('Missing required values for booking');
        return false;
      }

      final selectedTable = _allTables.firstWhere(
        (table) => table.id == selectedTableId,
        orElse: () => _allTables.first, // Fallback to first table
      );
      
      final booking = Booking(
        id: '', // Will be generated by Firebase
        userId: FirebaseService.getCurrentUserId() ?? '',
        table: selectedTable,
        date: selectedStartDate,
        timeSlot: selectedTimeSlot,
        guestCount: guestCount,
        status: BookingStatus.confirmed,
      );

      print('Calling FirebaseService.createBooking...');
      await FirebaseService.createBooking(booking);
      print('Booking created successfully');
      
      // Refresh the tables list to update the booked status
      await refreshTables();
      
      // Trigger manual refresh of available tables provider
      ref.read(availableTablesRefreshProvider.notifier).state++;
      
      // Log the updated table status
      final updatedTable = _allTables.firstWhere((t) => t.id == selectedTableId);
      print('Table ${selectedTableId} status after booking: ${updatedTable.status}');
      print('Available tables count: ${getAvailableTables().length}');
      
      // Don't reset selection immediately - let the success dialog show first
      // resetSelection(ref);
      
      return true;
    } catch (e) {
      print('Error creating booking: $e');
      return false;
    }
  }

  void resetSelection(WidgetRef ref) {
    ref.read(selectedTableIdProvider.notifier).state = null;
    ref.read(selectedDateProvider.notifier).state = null;
    ref.read(selectedStartDateProvider.notifier).state = null;
    ref.read(selectedEndDateProvider.notifier).state = null;
    ref.read(selectedTimeSlotProvider.notifier).state = null;
    ref.read(guestCountProvider.notifier).state = 2;
    
    // Also reset internal state for compatibility
    _selectedTableId = null;
    _selectedStartDate = null;
    _selectedEndDate = null;
    _selectedTimeSlot = null;
    _guestCount = 2;
  }
}
