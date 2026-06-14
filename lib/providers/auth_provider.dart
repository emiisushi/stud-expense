import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({required AuthService authService}) : _authService = authService {
    _authStateSubscription = _authService.authStateChanges().listen((user) {
      _currentUser = user;
      notifyListeners();
    });
  }

  final AuthService _authService;
  late final StreamSubscription<User?> _authStateSubscription;
  User? _currentUser;
  bool _isBusy = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isBusy => _isBusy;

  Future<String?> signIn({required String email, required String password}) async {
    _setBusy(true);
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    _setBusy(true);
    try {
      await _authService.signUpWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (error) {
      return error.toString();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }
}
