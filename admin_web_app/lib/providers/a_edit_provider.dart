import 'package:flutter/material.dart';
import '../repositories/a_edit_repository.dart';

class EditProvider with ChangeNotifier {
  final EditRepository _editRepository = EditRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Map<String, dynamic>? _fetchedRecord;
  Map<String, dynamic>? get fetchedRecord => _fetchedRecord;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearState() {
    _fetchedRecord = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> getRecord(String table, int id, String token) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      _fetchedRecord = await _editRepository.getRecord(table, id, token);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addRecord(String table, Map<String, dynamic> data, String token) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _editRepository.addRecord(table, data, token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateRecord(String table, int id, Map<String, dynamic> data, String token) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _editRepository.updateRecord(table, id, data, token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteRecord(String table, int id, String token) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _editRepository.deleteRecord(table, id, token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }
}