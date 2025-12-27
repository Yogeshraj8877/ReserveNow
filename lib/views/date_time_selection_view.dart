import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class DateTimeSelectionView extends ConsumerWidget {
  const DateTimeSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStartDate = ref.watch(selectedStartDateProvider);
    final selectedEndDate = ref.watch(selectedEndDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final timeSlots = ref.watch(timeSlotsProvider);
    final tableBookingViewModel = ref.watch(tableBookingViewModelProvider.notifier);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selection
            _buildDateRangeSelection(context, ref, selectedStartDate, selectedEndDate, tableBookingViewModel),
            
            const SizedBox(height: 32),
            
            // Time Slot Selection
            _buildTimeSlotSelection(context, ref, selectedTimeSlot, timeSlots, tableBookingViewModel),
            
            const SizedBox(height: 32),
            
            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  print('Button pressed - selectedStartDate: $selectedStartDate, selectedEndDate: $selectedEndDate, selectedTimeSlot: $selectedTimeSlot');
                  if (selectedStartDate != null && selectedEndDate != null && selectedTimeSlot != null) {
                    _proceedToConfirmation(context, ref);
                  } else {
                    print('Cannot proceed - missing selections');
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: selectedStartDate != null && selectedEndDate != null && selectedTimeSlot != null
                      ? Colors.blue
                      : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Continue to Confirmation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelection(
    BuildContext context,
    WidgetRef ref,
    DateTime? selectedStartDate,
    DateTime? selectedEndDate,
    dynamic tableBookingViewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date Range',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Selected Date Range Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(8),
            color: const Color(0xFFFAFAFA),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  selectedStartDate != null && selectedEndDate != null
                      ? '${DateFormat('MMM d, yyyy').format(selectedStartDate)} - ${DateFormat('MMM d, yyyy').format(selectedEndDate)}'
                      : 'No date range selected',
                  style: TextStyle(
                    fontSize: 16,
                    color: selectedStartDate != null ? Colors.black : Colors.grey,
                    fontWeight: selectedStartDate != null ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => _selectDateRange(context, ref),
                child: const Text('Choose Date Range'),
              ),
            ],
          ),
        ),
        
        // Quick Date Options
        const SizedBox(height: 16),
        const Text(
          'Quick Select:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildQuickDateRangeButton('Today', DateTime.now(), DateTime.now(), ref),
            _buildQuickDateRangeButton('This Weekend', _getThisWeekendStart(), _getThisWeekendEnd(), ref),
            _buildQuickDateRangeButton('Next Week', _getNextWeekStart(), _getNextWeekEnd(), ref),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickDateRangeButton(
    String label,
    DateTime startDate,
    DateTime endDate,
    WidgetRef ref,
  ) {
    final selectedStartDate = ref.watch(selectedStartDateProvider);
    final selectedEndDate = ref.watch(selectedEndDateProvider);
    
    final isSelected = selectedStartDate != null &&
        selectedEndDate != null &&
        _isSameDay(selectedStartDate, startDate) &&
        _isSameDay(selectedEndDate, endDate);
    
    return ElevatedButton(
      onPressed: () {
        ref.read(selectedStartDateProvider.notifier).state = startDate;
        ref.read(selectedEndDateProvider.notifier).state = endDate;
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : const Color(0xFFE0E0E0),
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      child: Text(label),
    );
  }

  Widget _buildTimeSlotSelection(
    BuildContext context,
    WidgetRef ref,
    TimeSlot? selectedTimeSlot,
    List<TimeSlot> timeSlots,
    dynamic tableBookingViewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Time Slot',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        // Time Slots Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: timeSlots.length,
          itemBuilder: (context, index) {
            final timeSlot = timeSlots[index];
            final isSelected = selectedTimeSlot?.id == timeSlot.id;
            
            return GestureDetector(
              onTap: timeSlot.isAvailable
                  ? () {
                      ref.read(selectedTimeSlotProvider.notifier).state = timeSlot;
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Colors.blue
                        : timeSlot.isAvailable
                            ? const Color(0xFFE0E0E0)
                            : const Color(0xFFFFCDD2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: isSelected
                      ? const Color(0xFFE3F2FD)
                      : timeSlot.isAvailable
                          ? Colors.white
                          : const Color(0xFFFFEBEE),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      timeSlot.displayTime,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.blue
                            : timeSlot.isAvailable
                                ? Colors.black
                                : const Color(0xFFD32F2F),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeSlot.durationDisplay,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected
                            ? const Color(0xFF1976D2)
                            : timeSlot.isAvailable
                                ? const Color(0xFF757575)
                                : const Color(0xFFD32F2F),
                      ),
                    ),
                    if (!timeSlot.isAvailable)
                      const Text(
                        'Unavailable',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      ref.read(selectedStartDateProvider.notifier).state = picked.start;
      ref.read(selectedEndDateProvider.notifier).state = picked.end;
    }
  }

  DateTime _getThisWeekendStart() {
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday + 7) % 7;
    return now.add(Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday));
  }

  DateTime _getThisWeekendEnd() {
    return _getThisWeekendStart().add(const Duration(days: 1));
  }

  DateTime _getNextWeekStart() {
    final now = DateTime.now();
    final daysUntilMonday = (1 - now.weekday + 7) % 7;
    return now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday + 7));
  }

  DateTime _getNextWeekEnd() {
    return _getNextWeekStart().add(const Duration(days: 6));
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  void _proceedToConfirmation(BuildContext context, WidgetRef ref) {
    Navigator.pushNamed(context, '/table_selection');
  }
}
