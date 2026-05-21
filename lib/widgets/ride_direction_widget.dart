import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/theme/colors.dart';

enum RouteDirection { manchesterToDurham, durhamToManchester }

class RouteDirectionWidget extends StatelessWidget {
  const RouteDirectionWidget({super.key, required this.direction});

  final RouteDirection direction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: UNHColorsPalette.unhWildcatBlue,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            spacing: 6,
            children: [
              Text(
                'Manchester',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: UNHColorsPalette.freshSnow,
                ),
              ),
              Icon(
                direction == RouteDirection.manchesterToDurham
                    ? Icons.drive_eta
                    : Icons.location_on,
                size: 20,
                color: UNHColorsPalette.freshSnow,
              ),
            ],
          ),
          Transform.flip(
            flipX: direction == RouteDirection.durhamToManchester,
            child: Icon(
              Icons.arrow_forward,
              size: 20,
              color: UNHColorsPalette.freshSnow,
            ),
          ),
          Row(
            spacing: 6,
            children: [
              Icon(
                direction == RouteDirection.durhamToManchester
                    ? Icons.drive_eta
                    : Icons.location_on,
                size: 20,
                color: UNHColorsPalette.freshSnow,
              ),
              Text(
                'Durham',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: UNHColorsPalette.freshSnow,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

