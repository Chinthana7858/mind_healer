import 'package:flutter/material.dart';
import 'package:mind_healer/models/user_model.dart';
import '../service/FirestoreService.dart';

class UserProfileViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  AppUser? _user; // Updated type
  AppUser? get user => _user;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadUserProfile(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Fetch data from FirestoreService and map to AppUser model
      final userData = await _firestoreService.getUserData(userId);
      if (userData != null) {
        _user = AppUser.fromMap(userData); // Updated to use AppUser
      } else {
        _errorMessage = "User data not found";
      }
    } catch (e) {
      _errorMessage = "Error loading user profile: $e";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
