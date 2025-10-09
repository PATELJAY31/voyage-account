import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import '../services/supabase_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  String? get userRole => _user?.role;
  bool get isAdmin => _user?.role == 'admin';
  bool get isEngineer => _user?.role == 'engineer';
  bool get isEmployee => _user?.role == 'employee';

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    SupabaseService.authStateChanges.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      print('Auth state change: $event, session: ${session?.user?.id}');

      if (event == AuthChangeEvent.signedIn && session != null) {
        print('User signed in, loading profile...');
        await _loadUserProfile();
      } else if (event == AuthChangeEvent.signedOut) {
        print('User signed out, clearing user data');
        _clearUser();
      }
    });

    // Check if user is already signed in
    final currentUser = SupabaseService.getCurrentUser();
    if (currentUser != null) {
      print('Found existing user, loading profile...');
      _loadUserProfile();
    } else {
      print('No existing user found');
    }
  }

  Future<void> _loadUserProfile() async {
    _setLoading(true);
    _clearError();

    try {
      print('Loading user profile...');
      final userProfile = await SupabaseService.getCurrentUserProfile();
      print('User profile result: ${userProfile?.name}');
      if (userProfile != null) {
        _user = userProfile;
        notifyListeners();
        print('User profile set successfully');
      } else {
        print('Failed to load user profile - null returned');
        _setError('Failed to load user profile');
      }
    } catch (e) {
      print('Error loading user profile: $e');
      _setError('Error loading user profile: $e');
    } finally {
      print('Profile loading finished, setting loading to false');
      _setLoading(false);
    }
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('Attempting to sign in with email: $email');
      final response = await SupabaseService.signInWithEmail(email, password);
      print('Sign in response: ${response.user?.id}');
      
      if (response.user != null) {
        print('User signed in successfully, loading profile...');
        await _loadUserProfile();
        print('Profile loaded: ${_user?.name}');
        return true;
      } else {
        print('Sign in failed - no user returned');
        _setError('Sign in failed');
        return false;
      }
    } on AuthException catch (e) {
      print('Auth exception: ${e.message}');
      _setError(e.message);
      return false;
    } catch (e) {
      print('Unexpected error: $e');
      _setError('An unexpected error occurred: $e');
      return false;
    } finally {
      print('Setting loading to false');
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await SupabaseService.signOut();
      _clearUser();
    } catch (e) {
      _setError('Error signing out: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _clearUser() {
    _user = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Helper methods for role-based access
  bool canCreateExpenses() {
    return isEmployee || isAdmin;
  }

  bool canReviewExpenses() {
    return isEngineer || isAdmin;
  }

  bool canApproveExpenses() {
    return isAdmin;
  }

  bool canManageUsers() {
    return isAdmin;
  }

  bool canViewAllExpenses() {
    return isAdmin || isEngineer;
  }

  // Navigation helpers
  String getInitialRoute() {
    if (!isAuthenticated) {
      return '/login';
    }

    switch (userRole) {
      case 'admin':
        return '/admin';
      case 'engineer':
        return '/engineer';
      case 'employee':
        return '/dashboard';
      default:
        return '/dashboard';
    }
  }

  List<String> getAccessibleRoutes() {
    if (!isAuthenticated) {
      return ['/login'];
    }

    final routes = ['/dashboard'];

    if (canCreateExpenses()) {
      routes.addAll(['/expenses', '/expenses/new']);
    }

    if (canReviewExpenses()) {
      routes.add('/review');
    }

    if (canApproveExpenses()) {
      routes.addAll(['/admin', '/admin/expenses', '/admin/users']);
    }

    return routes;
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      return await SupabaseService.getAllUsers();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<bool> createUser(String name, String email, String password, AppRole role) async {
    try {
      return await SupabaseService.createUser(name, email, password, role);
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      return await SupabaseService.updateUserStatus(userId, isActive);
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  Future<bool> updateUserRole(String userId, AppRole role) async {
    try {
      return await SupabaseService.updateUserRole(userId, role);
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}
