import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/expense_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/expenses/expense_form_screen.dart';
import 'screens/expenses/expense_detail_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_expenses_screen.dart';
import 'screens/admin/user_management_screen.dart';
import 'screens/engineer/engineer_dashboard_screen.dart';
import 'screens/engineer/review_screen.dart';
import 'screens/settings/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ExpenseManagerApp());
}

class ExpenseManagerApp extends StatelessWidget {
  const ExpenseManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(),
            routerConfig: _buildRouter(authProvider),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(AppColors.primaryColor),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  GoRouter _buildRouter(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/splash',
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoading = authProvider.isLoading;
        final currentLocation = state.matchedLocation;
        
        print('Router redirect - isAuthenticated: $isAuthenticated, isLoading: $isLoading, location: $currentLocation');
        
        // Don't redirect if still loading
        if (isLoading) {
          print('Still loading, not redirecting');
          return null;
        }
        
        // Redirect to login if not authenticated and not already on login page
        if (!isAuthenticated && currentLocation != '/login' && currentLocation != '/splash') {
          print('Not authenticated, redirecting to login');
          return '/login';
        }
        
        // Redirect to appropriate dashboard if authenticated and on login page
        if (isAuthenticated && currentLocation == '/login') {
          final initialRoute = authProvider.getInitialRoute();
          print('Authenticated, redirecting to: $initialRoute');
          return initialRoute;
        }
        
        print('No redirect needed');
        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/expenses',
          builder: (context, state) {
            final status = state.uri.queryParameters['status'];
            return ExpensesScreen(status: status);
          },
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => const ExpenseFormScreen(),
        ),
        GoRoute(
          path: '/expenses/:id',
          builder: (context, state) {
            final expenseId = state.pathParameters['id']!;
            return ExpenseDetailScreen(expenseId: expenseId);
          },
        ),
        GoRoute(
          path: '/expenses/:id/edit',
          builder: (context, state) {
            final expenseId = state.pathParameters['id']!;
            return ExpenseFormScreen(expenseId: expenseId);
          },
        ),
        // Admin routes
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/expenses',
          builder: (context, state) {
            final status = state.uri.queryParameters['status'];
            return AdminExpensesScreen(status: status);
          },
        ),
        GoRoute(
          path: '/admin/expenses/:id',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ExpenseDetailScreen(expenseId: id);
          },
        ),
        GoRoute(
          path: '/admin/users',
          builder: (context, state) {
            final role = state.uri.queryParameters['role'];
            return UserManagementScreen(role: role);
          },
        ),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        // Engineer routes
        GoRoute(
          path: '/engineer',
          builder: (context, state) => const EngineerDashboardScreen(),
        ),
        GoRoute(
          path: '/engineer/review',
          builder: (context, state) => const ReviewScreen(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
          title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
            const Text(
                'Page not found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Error: ${state.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
      ),
    );
  }
}