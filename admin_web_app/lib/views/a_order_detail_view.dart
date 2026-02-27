import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/a_order_model.dart';
import '../models/a_driver_model.dart';
import '../providers/a_login_provider.dart';
import '../repositories/a_edit_repository.dart';

class OrderDetailView extends StatefulWidget {
  final Order order;
  final Driver? driver; 

  const OrderDetailView({
    super.key,
    required this.order,
    this.driver,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  Map<String, dynamic>? _customerData;
  bool _isLoadingCustomer = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
  }

  Future<void> _fetchCustomerDetails() async {
    final token = Provider.of<LoginProvider>(context, listen: false).token;
    if (token == null) return;

    try {
      final data = await EditRepository().getRecord('customers', widget.order.userId, token);
      if (mounted) {
        setState(() {
          _customerData = data;
          _isLoadingCustomer = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load customer: $e";
          _isLoadingCustomer = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Order #${widget.order.orderId} Details"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionHeader("Order Information"),
            _buildOrderInfoCard(),
            const SizedBox(height: 20),

            if (_isOrderFinished()) ...[
              _buildSectionHeader("Proof of Delivery"),
              _buildPodCard(),
              const SizedBox(height: 20),
            ],

            if (_isDriverAssigned() && widget.driver != null) ...[
              _buildSectionHeader("Driver Information"),
              _buildDriverInfoCard(),
              const SizedBox(height: 20),
            ],

            _buildSectionHeader("Customer Information"),
            _buildCustomerInfoCard(),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _isOrderFinished() {
    final s = widget.order.status.toLowerCase();
    return s == 'finished' || s == 'completed';
  }

  bool _isDriverAssigned() {
    final s = widget.order.status.toLowerCase();
    return s != 'pending';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
      ),
    );
  }

  Widget _buildOrderInfoCard() {
    String timeStr = widget.order.timestamp;
    try {
      final dt = DateTime.parse(widget.order.timestamp);
      timeStr = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {}

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow("Order ID", "#${widget.order.orderId}"),
            _buildRow("Status", widget.order.status, isStatus: true),
            _buildRow("Weight", "${widget.order.weight ?? 'N/A'} kg"),
            _buildRow("Created Time", timeStr),
            const Divider(),
            _buildRow("Pickup Location", widget.order.pickupLocation),
            _buildRow("Dropoff Location", widget.order.dropoffLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildPodCard() {
    final pod = widget.order.proofOfDelivery;
    
    if (pod == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("No proof of delivery data available."),
        ),
      );
    }

    final String photoUrl = pod['photo_url']?.toString() ?? '';
    final String capturedAt = pod['captured_at']?.toString() ?? 'Unknown';
    
    // convert to meters
    final double distanceKm = double.tryParse(pod['distance_offset_km']?.toString() ?? '0') ?? 0.0;
    final double distanceMeters = distanceKm * 1000;
    
    String locStr = 'Unknown';
    if (pod['driver_location'] is Map) {
      final lat = pod['driver_location']['lat'];
      final lng = pod['driver_location']['lng'];
      locStr = "${(lat as num).toStringAsFixed(5)}, ${(lng as num).toStringAsFixed(5)}";
    }

    String displayTime = capturedAt;
    try {
      final dt = DateTime.parse(capturedAt);
      displayTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(dt);
    } catch (_) {}

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildRow("Captured At", displayTime),
                _buildRow("Distance Offset", "${distanceMeters.toStringAsFixed(1)} m"),
                _buildRow("Driver Location", locStr),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // show photo
          if (photoUrl.isNotEmpty && photoUrl != 'null')
            Container(
              height: 350,
              color: Colors.black12,
              child: Image.network(
                photoUrl,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.broken_image, size: 40, color: Colors.grey),
                      Text("Failed to load image"),
                    ],
                  ),
                ),
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text("No photo URL provided")),
            ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    final d = widget.driver!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow("Driver ID", "${d.driverId}"),
            _buildRow("Name", d.name),
            _buildRow("Email", d.email),
            _buildRow("Phone", d.phone),
            _buildRow("Vehicle", d.vehicleDetails),
            _buildRow("Avg Rating", "${d.avgRating.toStringAsFixed(1)} ★"),
            _buildRow("Max Weight", "${d.maxWeight} kg"),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    if (_isLoadingCustomer) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_customerData == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage ?? "Customer not found", style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final c = _customerData!;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow("Customer ID", "${c['id'] ?? c['user_id']}"),
            _buildRow("Name", "${c['name']}"),
            _buildRow("Email", "${c['email']}"),
            _buildRow("Phone", "${c['phone']}"),
            _buildRow("Address", "${c['address']}"),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStatus = false}) {
    Color? valueColor;
    if (isStatus) {
      if (value.toLowerCase() == 'pending') {
        valueColor = Colors.blue;
      } else if (value.toLowerCase() == 'in_progress') {
        valueColor = Colors.orange;
      } else if (value.toLowerCase() == 'finished') {
        valueColor = Colors.green;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, 
            child: Text(
              "$label:", 
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                color: valueColor ?? Colors.black87,
                fontSize: 15
              ),
            ),
          ),
        ],
      ),
    );
  }
}