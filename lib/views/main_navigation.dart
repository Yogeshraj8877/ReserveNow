import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import 'booking_history_view.dart';
import 'profile_screen.dart';
import 'table_orders_view.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _pages = [
    const HomeView(),
    const BookingHistoryView(),
    const TableOrdersView(),
  ];

  @override
  Widget build(BuildContext context) {
    final userEmail = AuthService.getCurrentUserEmail();
    final userInitial = userEmail?.isNotEmpty == true ? userEmail![0].toUpperCase() : 'U';
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: _currentIndex == 0 ? AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.restaurant,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'ReserveNow',
              style: TextStyle(
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
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
      ) : null,
      // appBar: _currentIndex == 0 ? AppBar(
      //   title: const Text('Reserve Now',style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   actions: [
      //     IconButton(
      //       icon: CircleAvatar(
      //         backgroundColor: const Color(0xFF2196F3),
      //         child: Text(
      //           userInitial,
      //           style: const TextStyle(
      //             color: Colors.white,
      //             fontWeight: FontWeight.bold,
      //             fontSize: 16,
      //           ),
      //         ),
      //       ),
      //       onPressed: () {
      //         Navigator.of(context).push(
      //           MaterialPageRoute(
      //             builder: (context) => const ProfileScreen(),
      //           ),
      //         );
      //       },
      //     ),
      //     // PopupMenuButton<String>(
      //     //   icon: const Icon(Icons.more_vert),
      //     //   itemBuilder: (context) => [
      //     //     PopupMenuItem(
      //     //       value: 'logout',
      //     //       child: ListTile(
      //     //         leading: const Icon(Icons.logout, color: Colors.red),
      //     //         title: const Text('Logout'),
      //     //       ),
      //     //     ),
      //     //   ],
      //     //   onSelected: (value) async {
      //     //     if (value == 'logout') {
      //     //       await _handleLogout(context);
      //     //     }
      //     //   },
      //     // ),
      //   ],
      // ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Book Table',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Table Orders',
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canProceedToTableSelection = ref.watch(canProceedToBookingProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final selectedTimeSlot = ref.watch(selectedTimeSlotProvider);
    final selectedTableId = ref.watch(selectedTableIdProvider);
    final guestCount = ref.watch(guestCountProvider);

    // Initialize tables when home view loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tableBookingViewModel = ref.read(tableBookingViewModelProvider.notifier);
      tableBookingViewModel.initializeTables();
    });

    Future<void> refreshTables() async {
      final tableBookingViewModel = ref.read(tableBookingViewModelProvider.notifier);
      tableBookingViewModel.initializeTables();
      // Add a small delay to show the refresh indicator
      await Future.delayed(const Duration(milliseconds: 500));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refreshTables,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Enable refresh
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Welcome Message
            // Container(
            //   width: double.infinity,
            //   padding: const EdgeInsets.all(20),
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       colors: [Colors.blue.shade400, Colors.blue.shade600],
            //       begin: Alignment.topLeft,
            //       end: Alignment.bottomRight,
            //     ),
            //     borderRadius: BorderRadius.circular(16),
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.start,
            //     children: [
            //       const Text(
            //         'Welcome to Reserve Now!',
            //         style: TextStyle(
            //           fontSize: 24,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.white,
            //         ),
            //       ),
            //       const SizedBox(height: 8),
            //       const Text(
            //         'Book your perfect table in just a few taps',
            //         style: TextStyle(
            //           fontSize: 16,
            //           color: Colors.white70,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            const SizedBox(height: 24),

            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Guests',
                    '$guestCount',
                    Icons.people,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, child) {
                      final tablesAsync = ref.watch(tableBookingViewModelProvider);
                      return tablesAsync.when(
                        data: (tables) {
                          final availableCount = tables.where((t) => t.status == TableStatus.available).length;
                          return _buildStatCard(
                            'Tables Available',
                            '$availableCount',
                            Icons.table_bar,
                            Colors.orange,
                          );
                        },
                        loading: () => _buildStatCard(
                          'Tables Available',
                          '...',
                          Icons.table_bar,
                          Colors.orange,
                        ),
                        error: (_, __) => _buildStatCard(
                          'Tables Available',
                          '0',
                          Icons.table_bar,
                          Colors.orange,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Booking Steps
            const Text(
              'Booking Steps',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildStepCard(
              1,
              'Select Date & Time',
              'Choose your preferred date and time slot',
              selectedDate != null && selectedTimeSlot != null,
              () => Navigator.pushNamed(context, '/date_time_selection'),
            ),

            const SizedBox(height: 12),

            _buildStepCard(
              2,
              'Choose Table',
              'Select a table that fits your guest count',
              selectedTableId != null,
              () {
                if (selectedDate != null && selectedTimeSlot != null) {
                  Navigator.pushNamed(context, '/table_selection');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select date and time first')),
                  );
                }
              },
            ),

            const SizedBox(height: 12),

            _buildStepCard(
              3,
              'Confirm Booking',
              'Review and confirm your reservation',
              canProceedToTableSelection,
              () {
                if (canProceedToTableSelection) {
                  Navigator.pushNamed(context, '/booking_confirmation');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete all steps first')),
                  );
                }
              },
            ),

            const SizedBox(height: 32),

            // Current Selection Summary
            if (selectedDate != null || selectedTimeSlot != null || selectedTableId != null)
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Selection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (selectedDate != null)
                        _buildSummaryItem(
                          'Date',
                          '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        ),
                      if (selectedTimeSlot != null)
                        _buildSummaryItem('Time', selectedTimeSlot.displayTime),
                      if (selectedTableId != null)
                        _buildSummaryItem('Table', 'Table $selectedTableId'),
                      if (guestCount > 0)
                        _buildSummaryItem('Guests', '$guestCount'),
                    ],
                  ),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    int stepNumber,
    String title,
    String description,
    bool isCompleted,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '$stepNumber',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? Colors.green : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
