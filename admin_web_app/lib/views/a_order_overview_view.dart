import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/a_order_provider.dart';
import '../providers/a_driver_provider.dart';
import '../providers/a_login_provider.dart';
import '../models/a_order_model.dart';
import '../models/a_driver_model.dart';
import 'a_order_detail_view.dart';

class OrderOverviewView extends StatefulWidget {
  const OrderOverviewView({super.key});

  @override
  State<OrderOverviewView> createState() => _OrderOverviewViewState();
}

class _OrderOverviewViewState extends State<OrderOverviewView> {
  String _currentFilter = 'All'; 
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<LoginProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(token);
        Provider.of<DriverProvider>(context, listen: false).fetchDrivers(token);
      }
    });

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Overview"),
        // height for search and filter
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110), 
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: Consumer2<OrderProvider, DriverProvider>(
        builder: (context, orderProv, driverProv, child) {
          if (orderProv.orders.isEmpty) {
            return const Center(child: Text("No orders found"));
          }

          final filteredOrders = _applyFilter(orderProv.orders);

          if (filteredOrders.isEmpty) {
             return const Center(child: Text("No orders match your search"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredOrders.length,
            itemBuilder: (context, index) {
              final order = filteredOrders[index];
              
              final driver = driverProv.drivers.firstWhere(
                (d) => d.driverId == order.driverId,
                orElse: () => Driver(
                  driverId: 0, name: "Unknown", email: "", phone: "", 
                  vehicleDetails: "", username: "", avgRating: 0
                ),
              );

              return _buildOrderCard(context, order, driver);
            },
          );
        },
      ),
    );
  }

  // search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by Order ID...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  FocusScope.of(context).unfocus();
                },
              )
            : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ["All", "Pending", "Delivering", "Finished"];
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _currentFilter == filter;
          return ChoiceChip(
            label: Text(filter),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _currentFilter = filter);
            },
            selectedColor: Colors.blue.shade100,
            labelStyle: TextStyle(
              color: isSelected ? Colors.blue.shade900 : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        },
      ),
    );
  }

  List<Order> _applyFilter(List<Order> allOrders) {
    return allOrders.where((order) {
      // status filter
      final status = order.status.toLowerCase();
      bool statusMatches = false;
      if (_currentFilter == 'All') {
        statusMatches = true;
      } else if (_currentFilter == 'Pending') {
        statusMatches = (status == 'pending');
      } else if (_currentFilter == 'Delivering') {
        statusMatches = (status == 'in_progress');
      } else if (_currentFilter == 'Finished') {
        statusMatches = (status == 'finished' || status == 'completed');
      }
      if (!statusMatches) {
        return false;
      }

      // search filter
      if (_searchQuery.isNotEmpty) {
        return order.orderId.toString().contains(_searchQuery);
      }

      return true;
    }).toList();
  }

  Widget _buildOrderCard(BuildContext context, Order order, Driver driver) {
    String formattedTime = order.timestamp;
    try {
      final dt = DateTime.parse(order.timestamp);
      formattedTime = DateFormat('yyyy-MM-dd HH:mm').format(dt);
    } catch (_) {}

    String displayStatus = order.status;
    Color statusColor = Colors.grey;
    
    if (order.status == 'in_progress') {
      displayStatus = 'Delivering';
      statusColor = Colors.orange;
    } else if (order.status == 'finished' || order.status == 'completed') {
      displayStatus = 'Finished';
      statusColor = Colors.green;
    } else if (order.status == 'pending') {
      displayStatus = 'Pending';
      statusColor = Colors.blue;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Order #${order.orderId}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5))
                      ),
                      child: Text(displayStatus, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderDetailView(
                          order: order,
                          driver: order.driverId > 0 ? driver : null,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text("Detail", style: TextStyle(fontSize: 12)),
                )
              ],
            ),
            const Divider(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoItem(Icons.person_outline, "User ID", "${order.userId}"),
                      const SizedBox(height: 8),
                      _buildInfoItem(Icons.drive_eta_outlined, "Driver", "${order.driverId} (${driver.name})"),
                      const SizedBox(height: 8),
                      _buildInfoItem(Icons.access_time, "Created", formattedTime),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLocationRow(Icons.my_location, "Pickup", order.pickupLocation),
                      const SizedBox(height: 12),
                      _buildLocationRow(Icons.location_on, "Dropoff", order.dropoffLocation),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: label == "Pickup" ? Colors.blue : Colors.red),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}