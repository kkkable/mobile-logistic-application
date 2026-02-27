import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../controllers/driver_controller.dart';
import '../repositories/order_repository.dart';
import '../repositories/driver_repository.dart';
import 'order_view.dart';
import 'record_view.dart';
import 'personal_view.dart';
import '../models/driver.dart';

extension HktDateFormat on DateFormat {
  DateFormat addHKT() => addPattern(' HKT');
}

class TrackingView extends StatefulWidget {
  final int userId;
  final String token;
  const TrackingView({super.key, required this.userId, required this.token});

  @override
  State<TrackingView> createState() => _TrackingViewState();
}

class _TrackingViewState extends State<TrackingView> {
  late GoogleMapController mapController;
  final OrderRepository _orderRepository = OrderRepository();
  final DriverRepository _driverRepository = DriverRepository();
  late Timer _driverTimer;
  Map<int, Set<Polyline>> polylines = {};
  Map<int, Set<Marker>> markers = {};
  Map<int, Marker> driverMarkers = {};
  Map<int, String?> estimatedTimes = {};
  Map<int, List<String>> driverRoutes = {};
  String? trackingErrorMessage;
  int _selectedIndex = 0; 

  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = [
      OrderView(userId: widget.userId, token: widget.token),
      Container(), 
      RecordView(userId: widget.userId, token: widget.token),
      PersonalView(userId: widget.userId, token: widget.token),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderController = Provider.of<OrderController>(context, listen: false);
      _driverTimer = Timer.periodic(Duration(seconds: 10), (timer) {
          if (_selectedIndex == 1) {
            final activeOrders = orderController.orders.where((o) => 
              o.userId == widget.userId && 
              (o.status == 'in_progress' || o.status == 'assigned') 
            );

            // filter duplicate drivers
            final uniqueDriverIds = <int>{};
            for (var order in activeOrders) {
              if (order.driverId != null) {
                uniqueDriverIds.add(order.driverId!);
                _fetchDriverDetails(order.driverId!); 
              }
            }
            
            // update locations
            for (var driverId in uniqueDriverIds) {
              _fetchDriverLocation(driverId);
            }
          }
      });
      
      _initializeMapData();
    });
  }

  @override
  void dispose() {
    _driverTimer.cancel();
    mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeMapData() async {
    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      
      await orderController.fetchOrders(token: widget.token, userId: widget.userId);
      
      final activeOrders = orderController.orders.where((o) => o.userId == widget.userId && o.status != 'finished');
      List<Future> tasks = [];

      for (var order in activeOrders) {
        tasks.add(_fetchEstimatedTime(order.orderId));
        
        if (order.driverId != null) {
          tasks.add(_fetchDriverLocation(order.driverId!));
          tasks.add(_fetchDriverDetails(order.driverId!));
          tasks.add(_fetchDriverAverageRating(order.driverId!));
        }
      }

      // wait all tasks to finish
      if (tasks.isNotEmpty) {
        await Future.wait(tasks);
      }
      
    } catch (e) {
      print("Refresh Error: $e");
    } finally {
      // force UI update
      if (mounted) setState(() {});
    }
  }

  Future<void> _fetchDriverLocation(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('${_orderRepository.baseUrl}/api/drivers/$driverId/location'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['current_lat'] != null && data['current_lng'] != null) {
          
          double lat = (data['current_lat'] is String) ? double.parse(data['current_lat']) : (data['current_lat'] + 0.0);
          double lng = (data['current_lng'] is String) ? double.parse(data['current_lng']) : (data['current_lng'] + 0.0);
          final driverController = Provider.of<DriverController>(context, listen: false);
          final String driverName = driverController.drivers[driverId]?.name ?? 'Driver';
          if (mounted) {
            setState(() {
              driverMarkers[driverId] = Marker(
                markerId: MarkerId('driver_$driverId'),
                position: LatLng(lat, lng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                infoWindow: InfoWindow(title: driverName, snippet: 'Delivering your order'),
                zIndex: 10, 
              );
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching location for driver $driverId: $e");
    }
  }

  Future<void> _fetchRoute(int orderId, String origin, String destination) async {
    if (origin.isEmpty || destination.isEmpty) {
      if (mounted) setState(() => trackingErrorMessage = 'Invalid origin or destination for order $orderId');
      return;
    }
    try {
      final pickupPosition = await _geocodeAddress(origin) ?? LatLng(0, 0);
      final dropoffPosition = await _geocodeAddress(destination) ?? LatLng(0, 0);
      
      final response = await http.post(
        Uri.parse('${_orderRepository.baseUrl}/api/routes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'origin': origin, 'destination': destination}),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['path'] != null) {
          if (mounted) {
            setState(() {
              polylines[orderId] = {
                Polyline(
                  polylineId: PolylineId('route_$orderId'),
                  points: PolylinePoints().decodePolyline(data['path'])
                      .map((point) => LatLng(point.latitude, point.longitude))
                      .toList(),
                  color: Colors.blue,
                  width: 5,
                ),
              };
              markers[orderId] = {
                Marker(
                  markerId: MarkerId('pickup_$orderId'),
                  position: pickupPosition,
                  infoWindow: InfoWindow(title: 'Pickup: $origin'),
                ),
                Marker(
                  markerId: MarkerId('dropoff_$orderId'),
                  position: dropoffPosition,
                  infoWindow: InfoWindow(title: 'Dropoff: $destination'),
                ),
              };
            });
          }
        } else {
          if (mounted) setState(() => trackingErrorMessage = 'Invalid route data for order $orderId');
        }
      } else {
        if (mounted) setState(() => trackingErrorMessage = 'Failed to fetch route for order $orderId: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) setState(() => trackingErrorMessage = 'Route error for order $orderId: $e');
    }
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final response = await http.post(
        Uri.parse('${_orderRepository.baseUrl}/api/geocode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({'address': address}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LatLng(data['lat'], data['lng']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _fetchEstimatedTime(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${_orderRepository.baseUrl}/api/orders/$orderId/estimated_time'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['estimated_delivery_time'] != null) {
          final estimatedTime = DateTime.parse(data['estimated_delivery_time']).toUtc().add(Duration(hours: 8));
          if (mounted) {
            setState(() {
              estimatedTimes[orderId] = DateFormat('EEEE, MMMM d, y, h:mm a').addHKT().format(estimatedTime);
            });
          }
        } else {
          if (mounted) setState(() => estimatedTimes[orderId] = 'N/A');
        }
      } else {
        if (mounted) setState(() => estimatedTimes[orderId] = 'Error');
      }
    } catch (e) {
      if (mounted) setState(() => estimatedTimes[orderId] = 'Error');
    }
  }

  Future<void> _fetchDriverDetails(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('${_driverRepository.baseUrl}/api/drivers/$driverId'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (mounted) {
          setState(() {
            if (data['name'] != null) {
              final driverController = Provider.of<DriverController>(context, listen: false);
              if (!driverController.drivers.containsKey(driverId)) {
                driverController.drivers[driverId] = Driver(driverId: driverId, name: data['name'], avgRating: 0.0);
              } else {
                driverController.drivers[driverId]!.name = data['name'];
              }
            }

            if (data['expected_route'] != null) {
              driverRoutes[driverId] = List<String>.from(data['expected_route'].map((x) => x.toString()));
            }
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _fetchDriverAverageRating(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('${_driverRepository.baseUrl}/api/drivers/$driverId/average_rating'),
        headers: {'Authorization': 'Bearer ${widget.token}'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rating = data['average_rating'] is String
            ? double.tryParse(data['average_rating']) ?? 0.0
            : (data['average_rating'] ?? 0.0) as double;
        final driverController = Provider.of<DriverController>(context, listen: false);
        if (!driverController.drivers.containsKey(driverId)) {
          driverController.drivers[driverId] = Driver(driverId: driverId, name: 'Unknown Driver', avgRating: rating);
        } else {
          driverController.drivers[driverId]!.avgRating = rating;
        }
        if (mounted) setState(() {});
      }
    } catch (e) {
      print(e);
    }
  }

  void _resetMapToAllOrders() {
    if (polylines.isNotEmpty) {
      final allPoints = polylines.values.expand((set) => set.first.points).toList();
      if (driverMarkers.isNotEmpty) {
        allPoints.addAll(driverMarkers.values.map((m) => m.position));
      }
      if (allPoints.isNotEmpty) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            allPoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
            allPoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            allPoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
            allPoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
          ),
        );
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
      }
    }
  }

  void _zoomToOrder(int orderId) {
    if (polylines.containsKey(orderId) && polylines[orderId]!.isNotEmpty) {
      
      // copy points to fix reference bug
      final points = polylines[orderId]!.first.points.toList(); 
      
      final order = Provider.of<OrderController>(context, listen: false).orders.firstWhere((o) => o.orderId == orderId);
      
      if (order.driverId != null && driverMarkers.containsKey(order.driverId)) {
        points.add(driverMarkers[order.driverId]!.position);
      }
      
      if (points.isNotEmpty) {
        final bounds = LatLngBounds(
          southwest: LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
            points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
          ),
          northeast: LatLng(
            points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
            points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
          ),
        );
        mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      final orderController = Provider.of<OrderController>(context, listen: false);
      for (var order in orderController.orders.where((o) => o.userId == widget.userId && o.status != 'finished')) {
        _fetchRoute(order.orderId, order.pickupLocation, order.dropoffLocation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderController = Provider.of<OrderController>(context);
    final driverController = Provider.of<DriverController>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: _selectedIndex == 1
          ? Column(
              children: [
                // Map View
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(target: LatLng(22.3193, 114.1694), zoom: 11),
                        onMapCreated: (controller) {
                          mapController = controller;
                          _resetMapToAllOrders();
                        },
                        polylines: polylines.values.expand((x) => x).toSet(),
                        markers: {...markers.values.expand((x) => x), ...driverMarkers.values.whereType<Marker>()}.toSet(),
                      ),
                      Positioned(
                        bottom: 8.0,
                        left: MediaQuery.of(context).size.width / 2 - 60,
                        child: ElevatedButton(
                          onPressed: _resetMapToAllOrders,
                          child: Text('Overview'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Order List
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 1), 
                            ),
                          ],
                        ),
                        width: double.infinity,
                        child: const Text(
                          'Your Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      
                      Expanded(
                        child: orderController.orders.where((o) => o.userId == widget.userId && o.status != 'finished').isEmpty
                            ? const Center(child: Text("No active orders", style: TextStyle(color: Colors.grey)))
                            : RefreshIndicator( 
                              onRefresh: _initializeMapData, 
                              child: ListView.builder(
                                padding: const EdgeInsets.only(top: 8.0),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: orderController.orders.where((o) => o.userId == widget.userId && o.status != 'finished').length,
                                itemBuilder: (context, index) {
                                  final order = orderController.orders.where((o) => o.userId == widget.userId && o.status != 'finished').toList()[index];
                                  final driver = driverController.drivers[order.driverId];
                                  
                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    child: InkWell( 
                                      onTap: () => _zoomToOrder(order.orderId),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('Order #${order.orderId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(order.status).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(20),
                                                    border: Border.all(color: _getStatusColor(order.status).withOpacity(0.5)),
                                                  ),
                                                  child: Text(
                                                    order.status.toUpperCase(),
                                                    style: TextStyle(color: _getStatusColor(order.status), fontSize: 12, fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Divider(height: 24),
                                            _buildInfoRow(Icons.my_location, 'From', order.pickupLocation),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.location_on, 'To', order.dropoffLocation),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.access_time, 'ETA', estimatedTimes[order.orderId] ?? 'Calculating...'),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.drive_eta, 'Driver', 
                                              '${driver?.name ?? 'Assigning...'} ${driver != null && driver.avgRating > 0 ? '⭐ ${driver.avgRating.toStringAsFixed(1)}' : ''}'
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                  )],
                  ),
                ),
                
                if (trackingErrorMessage != null) 
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(trackingErrorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
              ],
            )
          : _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Tracking'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Records'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Personal'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'finished': return Colors.green;
      default: return Colors.grey;
    }
  }
}

Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
}