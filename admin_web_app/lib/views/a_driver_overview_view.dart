import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/a_driver_provider.dart';
import '../providers/a_login_provider.dart';
import '../models/a_driver_model.dart';
import '../models/a_rating_model.dart';
import 'a_driver_detail_view.dart';

class DriverOverviewView extends StatefulWidget {
  const DriverOverviewView({super.key});

  @override
  State<DriverOverviewView> createState() => _DriverOverviewViewState();
}

class _DriverOverviewViewState extends State<DriverOverviewView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _currentFilter = 'All'; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = Provider.of<LoginProvider>(context, listen: false).token;
      if (token != null) {
        final prov = Provider.of<DriverProvider>(context, listen: false);
        prov.fetchDrivers(token);
        prov.fetchRatings(token);
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
        title: const Text("Driver Overview"),
        // height for search + filter
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
      body: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          if (provider.drivers.isEmpty) {
            return const Center(child: Text("No drivers found"));
          }

          // apply filters
          final filteredDrivers = provider.drivers.where((d) {
            bool matchesSearch = true;
            if (_searchQuery.isNotEmpty) {
              matchesSearch = d.driverId.toString().contains(_searchQuery);
            }

            bool matchesStatus = true;
            // working if expectedRoute has task
            bool isWorking = d.expectedRoute.any((task) => task.isNotEmpty);
            
            if (_currentFilter == 'Working') {
              matchesStatus = isWorking;
            } else if (_currentFilter == 'Idle') {
              matchesStatus = !isWorking;
            }

            return matchesSearch && matchesStatus;
          }).toList();

          if (filteredDrivers.isEmpty) {
            return const Center(child: Text("No drivers match your criteria"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredDrivers.length,
            itemBuilder: (context, index) {
              final driver = filteredDrivers[index];
              final latestRating = provider.getLatestRatingForDriver(driver.driverId);
              return _buildDriverCard(context, driver, latestRating);
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by Driver ID...",
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty 
            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => _searchController.clear())
            : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  // filter bar
  Widget _buildFilterBar() {
    final filters = ["All", "Working", "Idle"];
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

  Widget _buildDriverCard(BuildContext context, Driver driver, Rating? rating) {
    // check status
    bool isWorking = driver.expectedRoute.any((task) => task.isNotEmpty);
    String statusText = isWorking ? "Working" : "Idle";
    Color statusColor = isWorking ? Colors.red : Colors.amber; 
    Color statusBgColor = isWorking ? Colors.red.shade50 : Colors.amber.shade50;

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
                    Text("Driver #${driver.driverId}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withOpacity(0.5))
                      ),
                      child: Text(
                        statusText, 
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    final allRatings = Provider.of<DriverProvider>(context, listen: false).getRatingsForDriver(driver.driverId);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverDetailView(driver: driver, ratings: allRatings),
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
            
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildInfoItem(Icons.person, "Name", driver.name),
                _buildInfoItem(Icons.local_shipping, "Vehicle", driver.vehicleDetails),
                _buildInfoItem(Icons.scale, "Max Weight", "${driver.maxWeight} kg"),
                _buildInfoItem(Icons.access_time, "Working Time", driver.workingTime ?? "N/A"),
                _buildInfoItem(Icons.star, "Avg Rating", "${driver.avgRating} ★"),
              ],
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: rating != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Latest Customer Rating:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.brown)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text("${rating.score} ★", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(rating.comment, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic))),
                          ],
                        )
                      ],
                    )
                  : const Text("No ratings yet", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text("$label: ", style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ],
    );
  }
}