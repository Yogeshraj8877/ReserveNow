import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/providers.dart';
import '../models/food_models.dart';
import '../models/models.dart';
import '../services/food_service.dart';

class TableOrdersView extends ConsumerStatefulWidget {
  const TableOrdersView({super.key});

  @override
  ConsumerState<TableOrdersView> createState() => _TableOrdersViewState();
}

class _TableOrdersViewState extends ConsumerState<TableOrdersView> {
  String? selectedTableId;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('TableOrdersView: Initializing and loading today orders');
      _loadOrdersWithSample();
    });
  }

  Future<void> _loadOrdersWithSample() async {
    // First try to load existing orders
    await ref.read(tableOrdersViewModelProvider.notifier).loadTodayOrders();
    
    // If no orders exist, create sample orders
    final orders = ref.read(tableOrdersViewModelProvider);
    if (orders.value?.isEmpty == true) {
      print('TableOrdersView: No orders found, creating sample orders');
      await FoodService.createSampleOrders();
      // Reload orders after creating samples
      await ref.read(tableOrdersViewModelProvider.notifier).loadTodayOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tableBookingViewModelProvider);
    final ordersAsync = ref.watch(tableOrdersViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Table Orders',style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
        backgroundColor: Colors.white,
        // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (selectedTableId != null) {
                ref.read(tableOrdersViewModelProvider.notifier)
                    .loadOrdersForTable(selectedTableId!, selectedDate);
              } else {
                ref.read(tableOrdersViewModelProvider.notifier).loadTodayOrders();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(tablesAsync),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (orders) => _buildOrdersList(orders),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<RestaurantTable>> tablesAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: tablesAsync.when(
                  loading: () => const Text('Loading tables...'),
                  error: (error, stack) => const Text('Error loading tables'),
                  data: (tables) => DropdownButtonFormField<String>(
                    value: selectedTableId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Table',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Tables'),
                      ),
                      ...tables.map((table) => DropdownMenuItem(
                        value: table.id,
                        child: Text(
                          'T${table.number} (${table.capacity} seats)',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedTableId = value;
                      });
                      _loadOrders();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      DateFormat('MMM d, yyyy').format(selectedDate),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedTableId != null 
                    ? 'Table ${selectedTableId} Orders'
                    : 'All Today\'s Orders',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedTableId = null;
                    selectedDate = DateTime.now();
                  });
                  ref.read(tableOrdersViewModelProvider.notifier).loadTodayOrders();
                },
                child: const Text('Clear Filters'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<FoodOrder> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No food orders for the selected criteria',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(FoodOrder order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Table ${order.tableId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Order #${order.id.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order Time
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM d, yyyy - h:mm a').format(order.orderTime),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order Items
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Order Items:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${item.quantity}x ${item.foodItemName}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '\$${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Total and Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                if (order.status != 'delivered' && order.status != 'cancelled')
                  _buildStatusActions(order)
                else if (order.deliveryTime != null)
                  Text(
                    'Delivered: ${DateFormat('h:mm a').format(order.deliveryTime!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
            
            // Special Instructions
            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.specialInstructions!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusActions(FoodOrder order) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (order.status == 'pending')
          OutlinedButton(
            onPressed: () => _updateOrderStatus(order.id, 'preparing'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: const BorderSide(color: Colors.orange),
            ),
            child: const Text('Start Preparing'),
          ),
        if (order.status == 'preparing')
          OutlinedButton(
            onPressed: () => _updateOrderStatus(order.id, 'ready'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
            ),
            child: const Text('Mark Ready'),
          ),
        if (order.status == 'ready')
          OutlinedButton(
            onPressed: () => _updateOrderStatus(order.id, 'delivered'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
              side: const BorderSide(color: Colors.green),
            ),
            child: const Text('Mark Delivered'),
          ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _updateOrderStatus(order.id, 'cancelled'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
          ),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'preparing':
        return Colors.blue;
      case 'ready':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      _loadOrders();
    }
  }

  void _loadOrders() {
    if (selectedTableId != null) {
      ref.read(tableOrdersViewModelProvider.notifier)
          .loadOrdersForTable(selectedTableId!, selectedDate);
    } else {
      ref.read(tableOrdersViewModelProvider.notifier).loadTodayOrders();
    }
  }

  void _updateOrderStatus(String orderId, String status) {
    ref.read(tableOrdersViewModelProvider.notifier).updateOrderStatus(orderId, status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order status updated to $status')),
    );
  }
}
