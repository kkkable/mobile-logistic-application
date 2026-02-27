import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';
import '../controllers/driver_controller.dart';
import 'rating_view.dart';

class RecordView extends StatefulWidget {
  final int userId;
  final String token;
  const RecordView({super.key, required this.userId, required this.token});

  @override
  State<RecordView> createState() => RecordViewState();
}

class RecordViewState extends State<RecordView> {
  bool isLoading = false;
  String? trackingErrorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => isLoading = true);
    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      final driverController = Provider.of<DriverController>(context, listen: false);
      await orderController.fetchOrders(token: widget.token, userId: widget.userId);
      for (var order in orderController.orders) {
        if (order.driverId != null) {
           await driverController.fetchDriverDetails(order.driverId!, widget.token);
           await driverController.fetchDriverAverageRating(order.driverId!, widget.token);
        }
      }
    } catch (e) {
      if (mounted) setState(() => trackingErrorMessage = 'Fetch records error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = Provider.of<OrderController>(context);
    final driverController = Provider.of<DriverController>(context);
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: DefaultTabController(
                    length: 3,
                    child: Column(
                      children: [
                        TabBar(tabs: [
                          Tab(text: 'Pending'),
                          Tab(text: 'In Progress'),
                          Tab(text: 'Finished'),
                        ]),
                        Expanded(
                          child: TabBarView(
                            children: [
                              ListView.builder(
                                itemCount: orderController.orders.where((o) => o.status == 'pending').length,
                                itemBuilder: (context, index) {
                                  final order = orderController.orders.where((o) => o.status == 'pending').toList()[index];
                                  final driver = (order.driverId != null) ? driverController.drivers[order.driverId] : null;
                                  return Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order ID: ${order.orderId}'),
                                        Text('Status: ${order.status}'),
                                        Text('From: ${order.pickupLocation}'),
                                        Text('To: ${order.dropoffLocation}'),
                                        if (order.weight != null) Text('Weight: ${order.weight} kg'),
                                        Text('Driver: ${driver?.name ?? 'Assigning...'}'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              ListView.builder(
                                itemCount: orderController.orders.where((o) => o.status == 'in_progress').length,
                                itemBuilder: (context, index) {
                                  final order = orderController.orders.where((o) => o.status == 'in_progress').toList()[index];
                                  final driver = (order.driverId != null) ? driverController.drivers[order.driverId] : null;
                                  return Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order ID: ${order.orderId}'),
                                        Text('Status: ${order.status}'),
                                        Text('From: ${order.pickupLocation}'),
                                        Text('To: ${order.dropoffLocation}'),
                                        if (order.weight != null) Text('Weight: ${order.weight} kg'),
                                        Text('Driver: ${driver?.name ?? 'Unknown Driver'} (Avg Rating: ${(driver?.avgRating ?? 0) > 0 ? driver!.avgRating.toStringAsFixed(1) : 'No Rating Yet'})'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              ListView.builder(
                                itemCount: orderController.orders.where((o) => o.status == 'finished').length,
                                itemBuilder: (context, index) {
                                  final order = orderController.orders.where((o) => o.status == 'finished').toList()[index];
                                  final driver = (order.driverId != null) ? driverController.drivers[order.driverId] : null;
                                  return Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Order ID: ${order.orderId}'),
                                        Text('Status: ${order.status}'),
                                        Text('From: ${order.pickupLocation}'),
                                        Text('To: ${order.dropoffLocation}'),
                                        if (order.weight != null) Text('Weight: ${order.weight} kg'),
                                        Text('Driver: ${driver?.name ?? 'Unknown Driver'} (Avg Rating: ${(driver?.avgRating ?? 0) > 0 ? driver!.avgRating.toStringAsFixed(1) : 'No Rating Yet'})'),
                                        Align(
                                          alignment: Alignment.bottomRight,
                                          child: FutureBuilder<bool>(
                                            future: Provider.of<OrderController>(context, listen: false).checkIfRated(order.orderId, widget.token),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2));
                                              }
                                              final isRated = snapshot.data ?? false;
                                              return isRated
                                                  ? Text('Rated', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                                                  : ElevatedButton(
                                                      onPressed: () async {
                                                        await Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) => RatingView(
                                                              order: order,
                                                              userId: widget.userId,
                                                              token: widget.token,
                                                            ),
                                                          ),
                                                        );
                                                        if (mounted) {
                                                          setState(() {});
                                                        }
                                                      },
                                                      child: Text('Rate'),
                                                    );
                                            },
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}