import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../controllers/order_controller.dart';

class OrderView extends StatefulWidget {
  final int userId;
  final String token;
  const OrderView({super.key, required this.userId, required this.token});

  @override
  State<OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends State<OrderView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Order'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PickupLocationView(
                      userId: widget.userId,
                      token: widget.token,
                    ),
                  ),
                );
              },
              child: const Text('Start New Delivery', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}

class PickupLocationView extends StatefulWidget {
  final int userId;
  final String token;
  const PickupLocationView({super.key, required this.userId, required this.token});

  @override
  State<PickupLocationView> createState() => _PickupLocationViewState();
}

class _PickupLocationViewState extends State<PickupLocationView> {
  final TextEditingController _addressController = TextEditingController(); 
  final TextEditingController _roomController = TextEditingController(); 
  final TextEditingController _weightController = TextEditingController();
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _isFetchingSuggestions = false;
  
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    try {
      if (dotenv.isInitialized) {
        _baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';
      }
    } catch (e) {}
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() {
        _suggestions = [];
        _isFetchingSuggestions = false;
      });
      return;
    }
    setState(() {
      _isFetchingSuggestions = true;
    });
    
    try {
      final body = {
        'input': input,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/places/find'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['predictions'] != null) {
          final suggestions = (data['predictions'] as List<dynamic>).map((p) {
            return {
              'description': p['description']?.toString() ?? '',
              'place_id': p['place_id']?.toString() ?? '',
            };
          }).toList();
          setState(() {
            _suggestions = suggestions;
          });
        }
      }
    } catch (e) {
      print(e);
    } finally {
       if (mounted) setState(() => _isFetchingSuggestions = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _roomController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pickup Location'), backgroundColor: Colors.white, elevation: 0),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search Address (Building/Street)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address *',
                hintText: 'e.g. City University of Hong Kong',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _isFetchingSuggestions ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () => _fetchSuggestions(value));
              },
            ),
            if (_suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(_suggestions[index]['description']!),
                      onTap: () {
                        setState(() {
                          _addressController.text = _suggestions[index]['description']!;
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              "Detail (Room/Floor - Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Unit/Floor',
                hintText: 'e.g. Room 123, 5/F',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: const InputDecoration(labelText: 'Weight (kg) *', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_addressController.text.isEmpty || _weightController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  
                  final fullAddress = _roomController.text.isNotEmpty 
                      ? "${_addressController.text}, ${_roomController.text}"
                      : _addressController.text;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DropoffLocationView(
                        userId: widget.userId,
                        token: widget.token,
                        pickupLocation: fullAddress, 
                        weight: double.tryParse(_weightController.text) ?? 1.0,
                      ),
                    ),
                  );
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DropoffLocationView extends StatefulWidget {
  final int userId;
  final String token;
  final String pickupLocation;
  final double weight;

  const DropoffLocationView({
    super.key,
    required this.userId,
    required this.token,
    required this.pickupLocation,
    required this.weight,
  });

  @override
  State<DropoffLocationView> createState() => _DropoffLocationViewState();
}

class _DropoffLocationViewState extends State<DropoffLocationView> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _isFetchingSuggestions = false;
  
  late final String _baseUrl;

  @override
  void initState() {
    super.initState();
    try {
      if (dotenv.isInitialized) {
        _baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';
      }
    } catch (e) {}
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.isEmpty) {
      setState(() { _suggestions = []; _isFetchingSuggestions = false; });
      return;
    }
    setState(() => _isFetchingSuggestions = true);
    
    try {
      final body = {
        'input': input,
      };
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/places/find'),
        headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}' },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['predictions'] != null) {
          setState(() {
            _suggestions = (data['predictions'] as List<dynamic>).map((p) {
              return { 'description': p['description']?.toString() ?? '', 'place_id': p['place_id']?.toString() ?? '' };
            }).toList();
          });
        }
      }
    } catch (e) {
      print(e);
    } finally {
      if(mounted) setState(() => _isFetchingSuggestions = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dropoff Location'), backgroundColor: Colors.white, elevation: 0),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Search Address (Building/Street)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address *',
                hintText: 'e.g. 123 Main Street, Central',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: _isFetchingSuggestions ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)) : null,
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 800), () => _fetchSuggestions(value));
              },
            ),
            if (_suggestions.isNotEmpty)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300)),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(_suggestions[index]['description']!),
                      onTap: () {
                        setState(() {
                          _addressController.text = _suggestions[index]['description']!;
                          _suggestions = [];
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              "Detail (Room/Floor - Optional)",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(
                labelText: 'Unit/Floor',
                hintText: 'e.g. Room 123, 5/F',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_addressController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
                    return;
                  }
                  
                  final fullAddress = _roomController.text.isNotEmpty 
                      ? "${_addressController.text}, ${_roomController.text}"
                      : _addressController.text;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ConfirmationView(
                        userId: widget.userId,
                        token: widget.token,
                        pickupLocation: widget.pickupLocation,
                        dropoffLocation: fullAddress,
                        weight: widget.weight,
                      ),
                    ),
                  );
                },
                child: const Text('Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConfirmationView extends StatelessWidget {
  final int userId;
  final String token;
  final String pickupLocation;
  final String dropoffLocation;
  final double weight;

  const ConfirmationView({
    super.key,
    required this.userId,
    required this.token,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.weight,
  });

  Future<void> _placeOrder(BuildContext context) async {
    try {
      final orderController = Provider.of<OrderController>(context, listen: false);
      
      await orderController.placeAndDistributeOrder(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        token: token,
        userId: userId,
        weight: weight,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order placed successfully')));
        Navigator.popUntil(context, ModalRoute.withName('/'));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to place order: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order'), backgroundColor: Colors.white, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildSummaryItem("Pickup", pickupLocation, Icons.location_on, Colors.green),
             const SizedBox(height: 20),
             _buildSummaryItem("Dropoff", dropoffLocation, Icons.location_on, Colors.red),
             const SizedBox(height: 20),
             _buildSummaryItem("Weight", "$weight kg", Icons.scale, Colors.orange),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _placeOrder(context),
                child: const Text('Confirm & Place Order'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 18)),
            ],
          ),
        )
      ],
    );
  }
}