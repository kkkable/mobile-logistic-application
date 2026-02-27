import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DashboardProvider with ChangeNotifier {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8080';
  
  bool isLoading = false;
  Map<String, dynamic>? stats;
  String? error;
  
  // default widget layout
  List<String> widgetOrder = [
    'kpi_cards', 
    'volume_chart', 
    'rating_pie', 
    'total_orders', 
    'total_ratings', 
    'total_late',
    'working_drivers',
    'in_progress_orders', 
    'pending_orders',     
    'kpi_today'
  ];
  
  List<String> visibleWidgets = [
    'kpi_cards', 
    'volume_chart', 
    'rating_pie', 
    'total_orders', 
    'total_ratings',
    'total_late',
    'working_drivers',
    'in_progress_orders', 
    'pending_orders',     
    'kpi_today'
  ];

  Future<void> fetchStats(String token) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/web/dashboard/stats'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        stats = Map<String, dynamic>.from(jsonDecode(response.body));
      } else {
        error = "Server Error: ${response.statusCode} ${response.body}";
        stats = null;
      }
    } catch (e) {
      error = "Connection Error: $e";
      stats = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // load layout from db
  Future<void> loadPreferences(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/web/admin/preferences'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['widget_order'] != null && (data['widget_order'] as List).isNotEmpty) {
           List<String> savedOrder = List<String>.from(data['widget_order']);
           
           List<String> allKnownWidgets = [
             'kpi_cards', 'volume_chart', 'rating_pie', 'total_orders', 'total_ratings',
             'total_late', 'working_drivers', 'kpi_today',
             'in_progress_orders', 'pending_orders' 
           ];
           
           for (String id in allKnownWidgets) {
             if (!savedOrder.contains(id)) {
               savedOrder.add(id);
             }
           }
           widgetOrder = savedOrder;
        }

        if (data['visible_widgets'] != null && (data['visible_widgets'] as List).isNotEmpty) {
           visibleWidgets = List<String>.from(data['visible_widgets']);
        }
        notifyListeners();
      }
    } catch (e) {
      print("load prefs error: $e");
    }
  }

  // toggle visibility
  Future<void> toggleWidget(String widgetId, bool isVisible, String token) async {
    if (isVisible) {
      if (!visibleWidgets.contains(widgetId)) visibleWidgets.add(widgetId);
    } else {
      visibleWidgets.remove(widgetId);
    }
    notifyListeners();
    await _savePreferencesToBackend(token);
  }

  Future<void> reorderWidgets(int oldIndex, int newIndex, String token) async {
    final String item = widgetOrder.removeAt(oldIndex);
    widgetOrder.insert(newIndex, item);
    notifyListeners();
    await _savePreferencesToBackend(token);
  }

  Future<void> _savePreferencesToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/web/admin/preferences'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: jsonEncode({
          'widget_order': widgetOrder,
          'visible_widgets': visibleWidgets
        }),
      );
      if (response.statusCode != 200) {
        print("save layout failed: ${response.body}");
      }
    } catch (e) {
      print("save layout error: $e");
    }
  }
}