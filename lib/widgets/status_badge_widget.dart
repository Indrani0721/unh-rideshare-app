import 'package:flutter/material.dart';

enum BadgeType { pending, accepted, declined, requested, cancelled }

class StatusBadgeWidget extends StatelessWidget {
  final BadgeType badgeType;
  final int? requestCount;
  final Widget child;

  const StatusBadgeWidget({
    super.key,
    required this.badgeType,
    required this.child,
    this.requestCount,
  }) : assert(
         badgeType != BadgeType.requested || requestCount != null,
         'requestCount must be provided when badgeType is requested',
       );

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (badgeType) {
      case BadgeType.pending:
        badgeColor = Colors.orange;
        break;
      case BadgeType.accepted:
        badgeColor = Colors.blue;
        break;
      case BadgeType.declined:
        badgeColor = Colors.red;
        break;
      case BadgeType.requested:
        if (requestCount == 0) {
          badgeColor = Colors.grey;
        } else {
          badgeColor = Colors.blue;
        }
        break;
      case BadgeType.cancelled:
        badgeColor = Colors.red;
    }

    return Container(
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 0, 0),
            child: Text(
              badgeType.toString().split('.').last.toUpperCase() +
                  (badgeType == BadgeType.requested ? ' ($requestCount)' : ''),
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
