import 'package:flutter/material.dart';

// A reusable card widget for the dashboard that can display either a count or a custom body widget
class DashboardCard extends StatelessWidget {
  final String title;
  final Color cardColor;
  final VoidCallback onTap;
  final int? itemCount;
  final Widget? body;

  const DashboardCard({
    super.key,
    required this.title,
    required this.cardColor,
    required this.onTap,
    this.itemCount,
    this.body,
  }) : assert(
         itemCount != null || body != null,
         'Provide either itemCount or body for DashboardCard content.',
       );

  @override
  // Build the content of the card based on whether itemCount or body is provided
  Widget build(BuildContext context) {
    final content =
        body ??
        Text(
          '$itemCount',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 38,
          ),
        );

    // Return a Card widget with an InkWell to handle taps, and display the title and content
    return Card(
      elevation: 2,
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 7, 12, 23),
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}

// A helper function to create a DashboardCard with consistent styling and layout
Widget buildDashBoardCard({
  required String title,
  required Color cardColor,
  required VoidCallback onTap,
  int? itemCount,
  Widget? body,
}) {
  return Expanded(
    child: DashboardCard(
      title: title,
      cardColor: cardColor,
      onTap: onTap,
      itemCount: itemCount,
      body: body,
    ),
  );
}
