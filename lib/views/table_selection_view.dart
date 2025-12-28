import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../widgets/table_widget.dart';
import '../models/models.dart';

class TableSelectionView extends ConsumerWidget {
  const TableSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tableBookingViewModelProvider);
    final availableTables = ref.watch(availableTablesProvider);
    final guestCount = ref.watch(guestCountProvider);
    final tableBookingViewModel = ref.watch(tableBookingViewModelProvider.notifier);
    final canProceed = ref.watch(canProceedToBookingProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tableBookingViewModel.initializeTables();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Table'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Guest Count Selection
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Number of Guests',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      onPressed: guestCount > 1 
                          ? () => ref.read(guestCountProvider.notifier).state = guestCount - 1
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$guestCount',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: guestCount < 8 
                          ? () => ref.read(guestCountProvider.notifier).state = guestCount + 1
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Available tables: ${availableTables.length}',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          
          // Tables Grid
          Expanded(
            child: tablesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (tables) {
                // Group tables by row
                final Map<int, List<RestaurantTable>> tablesByRow = {};
                for (final table in tables) {
                  if (!tablesByRow.containsKey(table.row)) {
                    tablesByRow[table.row] = [];
                  }
                  tablesByRow[table.row]!.add(table);
                }

                return tables.isEmpty 
                  ? _buildNoTablesAvailable(ref)
                  : _buildTablesGrid(tablesByRow, ref, guestCount, canProceed, context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildNoTablesAvailable(WidgetRef ref) {
    final guestCount = ref.watch(guestCountProvider);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.table_restaurant,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No tables available for $guestCount guests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try reducing the number of guests or try a different time',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Reset guest count to 2
              ref.read(guestCountProvider.notifier).state = 2;
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Guest Count'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTablesGrid(Map<int, List<RestaurantTable>> tablesByRow, WidgetRef ref, int guestCount, bool canProceed, BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend with improved styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Select Your Table',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem('Available', Colors.green),
                    _buildLegendItem('Booked', Colors.grey),
                    _buildLegendItem('Selected', Colors.blue),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Screen/Stage indicator (like cinema screen)
          Container(
            width: double.infinity,
            height: 60,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF2196F3), Colors.blue.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, color: Colors.white, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Restaurant Area',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Tables Layout (like cinema seats)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.grey.shade100],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Tables rows
                ...tablesByRow.entries.map((entry) {
                  final row = entry.key;
                  final rowTables = entry.value;
                  
                  return Column(
                    children: [
                      // Row indicator with cinema-style labeling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ROW ${String.fromCharCode(65 + row)}', // A, B, C, etc.
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Tables in row with better spacing
                      SizedBox(
                        height: 80, // Increased height to accommodate wrapped content
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: rowTables.map((table) {
                            final isSelected = ref.watch(selectedTableIdProvider) == table.id;
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1),
                              child: TableWidget(
                                table: table,
                                onTap: () {
                                  ref.read(selectedTableIdProvider.notifier).state = table.id;
                                },
                                isSelected: isSelected,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
                
                const SizedBox(height: 20),
                
                // Exit indicator
                // Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.symmetric(vertical: 12),
                //   decoration: BoxDecoration(
                //     color: Colors.green.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(8),
                //     border: Border.all(color: Colors.green.shade300),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Icon(Icons.exit_to_app, color: Colors.green.shade600, size: 20),
                //       const SizedBox(width: 8),
                //       Text(
                //         'EXIT',
                //         style: TextStyle(
                //           fontSize: 14,
                //           fontWeight: FontWeight.bold,
                //           color: Colors.green.shade600,
                //           letterSpacing: 2,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Continue to Confirmation Button
          Container(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
            ),
            child: Builder(
              builder: (context) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: canProceed
                        ? () {
                            Navigator.pushNamed(context, '/booking_confirmation');
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canProceed ? Colors.green : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      guestCount == 0 
                          ? 'Please select number of guests'
                          : !canProceed 
                              ? 'Please select a table'
                              : 'Continue to Confirmation',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
