import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/expense_provider.dart';
import '../../../utils/currency_formatter.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/expense_list_tile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenseStats();
      context.read<ExpenseProvider>().loadUserExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExpenseProvider>().refreshExpenses();
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  // TODO: Navigate to profile
                  break;
                case 'logout':
                  _handleLogout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text(AppStrings.logout),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().refreshExpenses();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(AppColors.primaryColor),
                          Color(0xFF1E40AF),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          authProvider.user?.name ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          authProvider.userRole?.toUpperCase() ?? 'USER',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Stats Section
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, _) {
                  final stats = expenseProvider.stats;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: AppStrings.pendingAmount,
                        value: CurrencyFormatter.formatINR(stats['pendingAmount'] ?? 0.0),
                        icon: Icons.pending_actions,
                        color: const Color(AppColors.warningColor),
                        onTap: () => context.push('/expenses?status=submitted'),
                      ),
                      StatCard(
                        title: AppStrings.approvedAmount,
                        value: CurrencyFormatter.formatINR(stats['approvedAmount'] ?? 0.0),
                        icon: Icons.check_circle,
                        color: const Color(AppColors.successColor),
                        onTap: () => context.push('/expenses?status=approved'),
                      ),
                      StatCard(
                        title: 'Total Expenses',
                        value: '${stats['totalExpenses'] ?? 0}',
                        icon: Icons.receipt_long,
                        color: const Color(AppColors.primaryColor),
                        onTap: () => context.push('/expenses'),
                      ),
                      StatCard(
                        title: AppStrings.rejectedAmount,
                        value: CurrencyFormatter.formatINR(stats['rejectedAmount'] ?? 0.0),
                        icon: Icons.cancel,
                        color: const Color(AppColors.errorColor),
                        onTap: () => context.push('/expenses?status=rejected'),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/expenses/new'),
                      icon: const Icon(Icons.add),
                      label: const Text(AppStrings.newExpense),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(AppColors.primaryColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/expenses'),
                      icon: const Icon(Icons.list),
                      label: const Text('View All'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppColors.primaryColor),
                        side: const BorderSide(
                          color: Color(AppColors.primaryColor),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Expenses',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/expenses'),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, _) {
                  final recentExpenses = expenseProvider.expenses.take(5).toList();
                  
                  if (expenseProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (recentExpenses.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create your first expense to get started',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.push('/expenses/new'),
                              child: const Text(AppStrings.newExpense),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: recentExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = recentExpenses[index];
                      return ExpenseListTile(
                        expense: expense,
                        onTap: () => context.push('/expenses/${expense.id}'),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
