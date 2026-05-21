import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/widgets/ride_list_item_widget.dart';

enum BadgeType { pending, accepted, rejected, requested, cancelled, pastRide }

// Helper functions to determine badge color and label based on the badge type
Color _badgeColorForType(BadgeType badgeType, [int? requestCount]) {
  switch (badgeType) {
    case BadgeType.pending:
      return Colors.orange;
    case BadgeType.accepted:
      return Colors.green;
    case BadgeType.rejected:
      return Colors.red;
    case BadgeType.requested:
      return requestCount == 0 ? Colors.grey : Colors.blue;
    case BadgeType.cancelled:
      return Colors.red;
    case BadgeType.pastRide:
      return Colors.grey;
  }
}

// Helper function to determine badge label based on the badge type
String _badgeLabelForType(BadgeType badgeType, [int? requestCount]) {
  if (badgeType == BadgeType.pastRide) {
    return 'PAST RIDE';
  }

  return badgeType.toString().split('.').last.toUpperCase() +
      (badgeType == BadgeType.requested ? ' ($requestCount)' : '');
}

class RideStatusBadgeWidget extends StatelessWidget {
  final BadgeType badgeType;
  final RideModel ride;
  final int? requestCount;
  final bool showBadge;
  final VoidCallback? onTap;

  const RideStatusBadgeWidget({
    super.key,
    required this.badgeType,
    required this.ride,
    this.requestCount,
    this.showBadge =
        true, // Default to true, but can be set to false if you want to hide the badge
    this.onTap,
  }) : assert(
         badgeType != BadgeType.requested || requestCount != null,
         'requestCount must be provided when badgeType is requested',
       );

  @override
  Widget build(BuildContext context) {
    // If showBadge is false, just return the RideItemWidget without the badge
    Widget content;
    if (!showBadge) {
      content = Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: RideItemWidget(ride: ride),
      );
    } else {
      final badgeColor = _badgeColorForType(badgeType, requestCount);

      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4, 0, 0),
                child: Text(
                  _badgeLabelForType(badgeType, requestCount),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              RideItemWidget(ride: ride), // Add the RideItemWidget here
            ],
          ),
        ),
      );
    }

    // If onTap is null, we just return the content without wrapping it in a GestureDetector
    if (onTap == null) return content;

    // Wrap the content in a GestureDetector to handle taps,
    //but use AbsorbPointer to prevent the tap from affecting the RideItemWidget
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AbsorbPointer(child: content),
    );
  }
}
