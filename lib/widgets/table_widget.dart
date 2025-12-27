import 'package:flutter/material.dart';
import '../models/models.dart';

class TableWidget extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;
  final bool isSelected;

  const TableWidget({
    super.key,
    required this.table,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    String statusText;

    switch (table.status) {
      case TableStatus.available:
        backgroundColor = isSelected ? Colors.blue.shade100 : Colors.white;
        borderColor = isSelected ? Colors.blue.shade600 : Colors.green.shade400;
        iconColor = isSelected ? Colors.blue.shade600 : Colors.green.shade600;
        statusText = 'Available';
        break;
      case TableStatus.booked:
        backgroundColor = Colors.grey.shade200;
        borderColor = Colors.grey.shade400;
        iconColor = Colors.grey.shade600;
        statusText = 'Booked';
        break;
      case TableStatus.selected:
        backgroundColor = Colors.blue.shade100;
        borderColor = Colors.blue.shade600;
        iconColor = Colors.blue.shade600;
        statusText = 'Selected';
        break;
    }

    return GestureDetector(
      onTap: table.status == TableStatus.available ? onTap : null,
      child: Container(
        margin: const EdgeInsets.all(3),
        child: Column(
          children: [
            // Table visual representation (like cinema seat)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Seat back rest (top part)
                  Positioned(
                    top: 2,
                    left: 8,
                    right: 8,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  // Table number
                  Center(
                    child: Text(
                      table.number,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                  ),
                  // Capacity indicator (small badge)
                  if (table.capacity > 2)
                    Positioned(
                      top: 1,
                      right: 1,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Center(
                          child: Text(
                            '${table.capacity}',
                            style: const TextStyle(
                              fontSize: 7,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Status indicator (small dot)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
