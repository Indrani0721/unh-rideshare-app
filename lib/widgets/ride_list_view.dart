import 'package:flutter/material.dart';
import 'package:unh_rideshare_app/models/ride_model.dart';
import 'package:unh_rideshare_app/widgets/ride_list_item_widget.dart';

class RideListView extends StatefulWidget {
  final Future<List<RideModel>> rides;
  const RideListView({super.key, required this.rides});

  @override
  State<RideListView> createState() => _RideListViewState();
}

class _RideListViewState extends State<RideListView> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(10),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: FutureBuilder<List<RideModel>>(
                  future: widget.rides,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text('Error loading rides: ${snapshot.error}'),
                        ),
                      );
                    }

                    final rides = snapshot.data ?? [];
                    if (rides.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('No rides found')),
                      );
                    }

                    return Column(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(
                        rides.length,
                        (index) => RideItemWidget(ride: rides[index]),
                      ),
                    );
                  },
                ),
              ),
            );
        },
      );
  }
}

