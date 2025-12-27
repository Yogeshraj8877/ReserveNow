import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/models.dart';
import 'food_menu_view.dart';

class BookingConfirmationView extends ConsumerWidget {
  const BookingConfirmationView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTableId = ref.watch(selectedTableIdProvider);
    final selectedStartDate = ref.watch(selectedStartDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final guestCount = ref.watch(guestCountProvider);
    final availableTables = ref.watch(availableTablesProvider);
    final foodCart = ref.watch(foodCartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Confirmation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (foodCart.isNotEmpty)
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.restaurant_menu),
                  onPressed: () => _showFoodCart(context, ref),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${foodCart.fold<int>(0, (sum, item) => sum + item.quantity)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: availableTables.isEmpty
        ? const Center(
            child: Text('No tables available. Please go back and select different options.'),
          )
        : availableTables.length == 1
            ? _buildBookingConfirmation(availableTables.first, selectedStartDate, selectedTimeSlot, guestCount, context, ref)
            : (selectedTableId != null)
                ? _buildBookingConfirmation(
                    availableTables.firstWhere(
                      (table) => table.id == selectedTableId,
                      orElse: () => availableTables.first, // Fallback to first available table
                    ),
                    selectedStartDate,
                    selectedTimeSlot,
                    guestCount,
                    context,
                    ref,
                  )
                : const Center(
                    child: Text('No table selected. Please go back and select a table.'),
                  ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingConfirmation(
    RestaurantTable selectedTable,
    DateTime? selectedStartDate,
    TimeSlot? selectedTimeSlot,
    int guestCount,
    BuildContext context,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Success Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green.shade600),
                const SizedBox(height: 12),
                Text(
                  'Ready to Confirm Booking',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Booking Summary Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Summary',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryRow(
                    'Table Number',
                    'Table ${selectedTable.number}',
                    Icons.table_bar,
                  ),
                  _buildSummaryRow(
                    'Date',
                    selectedStartDate != null ? DateFormat('EEEE, MMMM d, yyyy').format(selectedStartDate) : 'Not selected',
                    Icons.calendar_today,
                  ),
                  _buildSummaryRow(
                    'Time',
                    selectedTimeSlot?.displayTime ?? 'Not selected',
                    Icons.access_time,
                  ),
                  _buildSummaryRow(
                    'Duration',
                    selectedTimeSlot?.durationDisplay ?? 'Not selected',
                    Icons.hourglass_full,
                  ),
                  _buildSummaryRow(
                    'Guests',
                    '$guestCount',
                    Icons.people,
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final foodCart = ref.watch(foodCartProvider);
                      if (foodCart.isEmpty) {
                        return _buildSummaryRow(
                          'Food Order',
                          'No items selected',
                          Icons.restaurant_menu,
                          textColor: Colors.grey.shade600,
                        );
                      }
                      
                      final total = foodCart.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
                      return _buildSummaryRow(
                        'Food Order',
                        '${foodCart.length} items - \$${total.toStringAsFixed(2)}',
                        Icons.restaurant_menu,
                        textColor: Colors.green.shade700,
                      );
                    },
                  ),
                  _buildSummaryRow(
                    'Table Capacity',
                    '${selectedTable.capacity}',
                    Icons.event_seat,
                  ),
                  _buildSummaryRow(
                    'Table Shape',
                    selectedTable.shape.name,
                    Icons.table_chart,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Food Ordering Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Food Ordering',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FoodMenuView(),
                            ),
                          );
                        },
                        child: const Text('Browse Menu'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final foodCart = ref.watch(foodCartProvider);
                      if (foodCart.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.restaurant_menu, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'No food items selected',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final total = foodCart.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${foodCart.length} items selected - Total: \$${total.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Special Requests
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Special Requests (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Any special requirements or preferences...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
           SizedBox(height: 32),
          
          // Action Buttons
          Container(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.grey, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'Back',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final canProceed = ref.watch(canProceedToBookingProvider);
                      return ElevatedButton(
                        onPressed: canProceed ? () => _confirmBooking(context, ref) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: canProceed ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: canProceed ? 2 : 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Confirm Booking',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ],
      ),
    );
  }

  void _confirmBooking(BuildContext context, WidgetRef ref) async {
    // Check if all required values are selected
    final selectedTableId = ref.read(selectedTableIdProvider);
    final selectedStartDate = ref.read(selectedStartDateProvider);
    final selectedTimeSlot = ref.read(selectedTimeSlotProvider);
    final foodCart = ref.read(foodCartProvider);
    
    print('Checking selections - Table: $selectedTableId, Date: $selectedStartDate, Time: $selectedTimeSlot');
    
    if (selectedTableId == null || selectedStartDate == null || selectedTimeSlot == null) {
      print('Missing selections - Table is null: ${selectedTableId == null}, Date is null: ${selectedStartDate == null}, Time is null: ${selectedTimeSlot == null}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all selections before confirming.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Create the booking first
    final tableBookingViewModel = ref.read(tableBookingViewModelProvider.notifier);
    final success = await tableBookingViewModel.createBooking(ref);
    
    if (!success) {
      // Show error if booking failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to create booking. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create food order (even if cart is empty, create a default order)
    try {
      final userId = ref.read(userIdProvider);
      List<OrderItem> orderItems = foodCart;
      
      // If no food items in cart, add a default item
      if (orderItems.isEmpty) {
        orderItems = [
          OrderItem(
            foodItemId: '1',
            foodItemName: 'Water',
            price: 0.99,
            quantity: 1,
          ),
        ];
      }
      
      final foodOrder = FoodOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookingId: 'booking_${DateTime.now().millisecondsSinceEpoch}',
        tableId: selectedTableId,
        userId: userId,
        items: orderItems,
        totalAmount: orderItems.fold<double>(0.0, (sum, item) => sum + item.totalPrice),
        orderTime: DateTime.now(),
        status: 'pending',
      );
      
      print('Creating food order with ${orderItems.length} items');
      await ref.read(userFoodOrdersViewModelProvider.notifier).createFoodOrder(foodOrder);
      
      // Clear the cart after successful order
      if (foodCart.isNotEmpty) {
        ref.read(foodCartProvider.notifier).state = [];
      }
      
      print('Food order created successfully');
    } catch (e) {
      print('Error creating food order: $e');
      // Don't fail the booking if food order fails
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking confirmed but food order failed. Please order food separately.'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (contextError) {
        print('Context error showing snack: $contextError');
        // Ignore context errors - booking was still successful
      }
    }

    // Show success dialog
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green.shade600),
              const SizedBox(height: 16),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                foodCart.isNotEmpty 
                  ? 'Your table and food order have been successfully placed.'
                  : 'Your table has been successfully reserved.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              if (foodCart.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.restaurant_menu, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${foodCart.length} food items ordered - Total: \$${foodCart.fold<double>(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  // Reset booking state before navigating
                  ref.read(tableBookingViewModelProvider.notifier).resetSelection(ref);
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/main',
                    (route) => false,
                    arguments: 1, // Show booking history tab
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View My Bookings'),
              ),
            ),
          ],
        ),
      );
    } catch (contextError) {
      print('Context error showing dialog: $contextError');
      // Ignore context errors - booking was still successful
    }

    // Reset booking state is handled in the viewmodel after successful booking
  }

  void _showFoodCart(BuildContext context, WidgetRef ref) {
    final foodCart = ref.read(foodCartProvider);
    
    if (foodCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your cart is empty')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Food Order',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: foodCart.length,
                  itemBuilder: (context, index) {
                    final item = foodCart[index];
                    return _buildCartItem(item, ref);
                  },
                ),
              ),
              _buildFoodCartSummary(foodCart, ref, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartItem(OrderItem item, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.foodItemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '\$${item.price.toStringAsFixed(2)} x ${item.quantity}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${item.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            IconButton(
              onPressed: () {
                final cart = ref.read(foodCartProvider);
                ref.read(foodCartProvider.notifier).state = cart
                    .where((cartItem) => cartItem.foodItemId != item.foodItemId)
                    .toList();
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCartSummary(List<OrderItem> foodCart, WidgetRef ref, BuildContext context) {
    final total = foodCart.fold<double>(0.0, (sum, item) => sum + item.totalPrice);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Food Total:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FoodMenuView(),
                      ),
                    );
                  },
                  child: const Text('Add More Items'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
