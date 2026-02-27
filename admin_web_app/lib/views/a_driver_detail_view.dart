import 'package:flutter/material.dart';
import '../models/a_driver_model.dart';
import '../models/a_rating_model.dart';

class DriverDetailView extends StatefulWidget {
  final Driver driver;
  final List<Rating> ratings;

  const DriverDetailView({super.key, required this.driver, required this.ratings});

  @override
  State<DriverDetailView> createState() => _DriverDetailViewState();
}

class _DriverDetailViewState extends State<DriverDetailView> {
  String _selectedFilter = 'All';
  String _selectedSort = 'Latest';

  final List<String> _filterOptions = ['All', '5 star', '4 star', '3 star', '2 star', '1 star'];
  final List<String> _sortOptions = ['Latest', 'Oldest'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Driver #${widget.driver.driverId} Details"),
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
            _buildSectionHeader("Driver Information"),
            _buildInfoCard(),
            const SizedBox(height: 20),
            
            _buildSectionHeader("Customer Ratings (${widget.ratings.length})"),
            
            // filter sort row
            _buildFilterSortRow(),
            
            const SizedBox(height: 10),
            
            _buildRatingList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildRow("Driver ID", "${widget.driver.driverId}"),
            _buildRow("Name", widget.driver.name),
            _buildRow("Username", widget.driver.username),
            _buildRow("Email", widget.driver.email),
            _buildRow("Phone", widget.driver.phone),
            _buildRow("Vehicle", widget.driver.vehicleDetails),
            _buildRow("Max Weight", "${widget.driver.maxWeight} kg"),
            _buildRow("Working Time", widget.driver.workingTime ?? "N/A"),
            _buildRow("Avg Rating", "${widget.driver.avgRating.toStringAsFixed(1)} ★"),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSortRow() {
    return SizedBox(
      height: 50, 
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = _selectedFilter == filter;
                return ChoiceChip(
                  label: _buildChipLabel(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = filter);
                  },
                  selectedColor: Colors.blue.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue.shade900 : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(width: 12), 

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSort,
                icon: const Icon(Icons.sort, size: 20, color: Colors.blue),
                isDense: true, 
                items: _sortOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) setState(() => _selectedSort = newValue);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // show rating count
  Widget _buildChipLabel(String filter) {
    if (filter == 'All') {
      return const Text("All", style: TextStyle(fontSize: 13));
    }

    int count = int.tryParse(filter.split(' ')[0]) ?? 0;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count, 
        (index) => const Icon(Icons.star, size: 16, color: Colors.amber),
      ),
    );
  }

  Widget _buildRatingList() {
    // filter
    List<Rating> filteredList = widget.ratings.where((r) {
      if (_selectedFilter == 'All') return true;
      int star = int.parse(_selectedFilter.split(' ')[0]); 
      return r.score.round() == star;
    }).toList();

    if (filteredList.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(child: Text("No ratings found matching criteria.")),
        ),
      );
    }

    // sorting
    filteredList.sort((a, b) {
      if (_selectedSort == 'Latest') {
        return b.createTime.compareTo(a.createTime); 
      } else {
        return a.createTime.compareTo(b.createTime); 
      }
    });

    return ListView.builder(
      shrinkWrap: true, 
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final rating = filteredList[index];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rating #${rating.ratingId}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    Text(rating.createTime.split('T')[0], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(5, (i) => Icon(
                      i < rating.score ? Icons.star : Icons.star_border,
                      size: 18,
                      color: Colors.amber,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      "${rating.score}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 10),
                const SizedBox(height: 4),
                Text(
                  rating.comment.isEmpty ? "(No comment provided)" : rating.comment,
                  style: TextStyle(
                    fontStyle: rating.comment.isEmpty ? FontStyle.italic : FontStyle.normal,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text("Order ID: #${rating.orderId}", style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87))),
        ],
      ),
    );
  }
}