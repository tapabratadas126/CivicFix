import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:civicfix/models/user_model.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserModel? _currentUser;
  bool _isLoading = true;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == UserRole.admin;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_user');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
      }
    } catch (e) {
      debugPrint('Failed to load current user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    String? phone,
    UserRole role = UserRole.citizen,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      if (users.any((u) => u['email'] == email)) {
        return false;
      }

      final newUser = UserModel(
        id: const Uuid().v4(),
        name: name,
        email: email,
        phone: phone,
        role: role,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      users.add(newUser.toJson());
      await prefs.setString('users', jsonEncode(users));
      await prefs.setString('password_$email', password);

      _currentUser = newUser;
      await prefs.setString('current_user', jsonEncode(newUser.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign up failed: $e');
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      final userMap = users.firstWhere(
        (u) => u['email'] == email,
        orElse: () => null,
      );

      if (userMap == null) return false;

      final savedPassword = prefs.getString('password_$email');
      if (savedPassword != password) return false;

      _currentUser = UserModel.fromJson(userMap);
      await prefs.setString('current_user', jsonEncode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Sign in failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_user');
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out failed: $e');
    }
  }

  Future<void> updateUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users') ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);

      final index = users.indexWhere((u) => u['id'] == user.id);
      if (index != -1) {
        users[index] = user.toJson();
        await prefs.setString('users', jsonEncode(users));
        
        if (_currentUser?.id == user.id) {
          _currentUser = user;
          await prefs.setString('current_user', jsonEncode(user.toJson()));
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Update user failed: $e');
    }
  }

  Future<void> seedDefaultUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString('users');
      
      if (usersJson != null) return;

      final defaultUsers = [
        UserModel(
          id: const Uuid().v4(),
          name: 'Admin User',
          email: 'admin@civicfix.com',
          phone: '+1234567890',
          role: UserRole.admin,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        UserModel(
          id: const Uuid().v4(),
          name: 'John Citizen',
          email: 'john@example.com',
          phone: '+1234567891',
          role: UserRole.citizen,
          gamificationPoints: 150,
          badges: ['Active Citizen'],
          createdAt: DateTime.now().subtract(const Duration(days: 30)),
          updatedAt: DateTime.now(),
        ),
      ];

      await prefs.setString(
        'users',
        jsonEncode(defaultUsers.map((u) => u.toJson()).toList()),
      );
      await prefs.setString('password_admin@civicfix.com', 'admin123');
      await prefs.setString('password_john@example.com', 'john123');
    } catch (e) {
      debugPrint('Failed to seed default users: $e');
    }
  }
}
