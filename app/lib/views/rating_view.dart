import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../controllers/order_controller.dart';
import '../models/order.dart';

class RatingView extends StatefulWidget {
  final int userId;
  final String token;
  
  final Order order;

  const RatingView({
    super.key,
    required this.userId,
    required this.token,
    required this.order,
  });

  @override
  State<RatingView> createState() => _RatingViewState();
}

class _RatingViewState extends State<RatingView> {
  final TextEditingController _commentController = TextEditingController();
  double _rating = 0;
  bool _isRated = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkIfRated();
  }

  Future<void> _checkIfRated() async {
    final orderController = Provider.of<OrderController>(context, listen: false);
    try {
      final isRated = await orderController.checkIfRated(widget.order.orderId, widget.token);
      if (mounted) {
        setState(() {
          _isRated = isRated;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking rating status: $e')),
        );
      }
    }
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/ratings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'order_id': widget.order.orderId,
          'driver_id': widget.order.driverId,
          'score': _rating,
          'comment': _commentController.text.isEmpty ? null : _commentController.text,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _isRated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rating submitted successfully')),
        );
      } else {
        throw Exception('Failed to submit rating: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting rating: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Order #${widget.order.orderId}'),
        backgroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Details', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Pickup: ${widget.order.pickupLocation}'),
                  
                  Text('Dropoff: ${widget.order.dropoffLocation}'),
                  
                  if (widget.order.weight != null) Text('Weight: ${widget.order.weight} kg'),
                  SizedBox(height: 16),
                  if (_isRated)
                    Text('This order has already been rated.', style: TextStyle(color: Colors.grey)),
                  if (!_isRated) ...[
                    Text('Rating *', style: TextStyle(fontWeight: FontWeight.bold)),
                    Slider(
                      value: _rating,
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: _rating.toString(),
                      onChanged: (value) {
                        if (!_isRated) {
                          setState(() {
                            _rating = value;
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Comment (Optional)',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton(
                        onPressed: _isRated ? null : _submitRating,
                        child: Text('Submit Rating'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}