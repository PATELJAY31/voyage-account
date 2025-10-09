import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/expense_list_tile.dart';
import '../../../utils/currency_formatter.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadAllExpenses();
      context.read<ExpenseProvider>().loadExpenseStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExpenseProvider>().loadAllExpenses();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().loadAllExpenses();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
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
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage expenses and users',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
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
                  final stats = expenseProvider.adminStats;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: 'Pending Approvals',
                        value: '${stats['pendingCount'] ?? 0}',
                        icon: Icons.pending_actions,
                        color: const Color(AppColors.warningColor),
                        onTap: () => context.push('/admin/expenses?status=submitted'),
                      ),
                      StatCard(
                        title: 'Total Users',
                        value: '${stats['totalUsers'] ?? 0}',
                        icon: Icons.people,
                        color: const Color(AppColors.primaryColor),
                        onTap: () => context.push('/admin/users'),
                      ),
                      StatCard(
                        title: 'Monthly Spend',
                        value: CurrencyFormatter.formatINR(stats['monthlySpend'] ?? 0.0),
                        icon: Icons.account_balance_wallet,
                        color: const Color(AppColors.successColor),
                        onTap: () => context.push('/admin/expenses'),
                      ),
                      StatCard(
                        title: 'Active Engineers',
                        value: '${stats['activeEngineers'] ?? 0}',
                        icon: Icons.engineering,
                        color: const Color(AppColors.secondaryColor),
                        onTap: () => context.push('/admin/users?role=engineer'),
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
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: [
                  _ActionCard(
                    title: 'Manage Expenses',
                    subtitle: 'Approve/Reject expenses',
                    icon: Icons.receipt_long,
                    color: const Color(AppColors.primaryColor),
                    onTap: () => context.push('/admin/expenses'),
                  ),
                  _ActionCard(
                    title: 'User Management',
                    subtitle: 'Add/Manage users',
                    icon: Icons.people,
                    color: const Color(AppColors.successColor),
                    onTap: () => context.push('/admin/users'),
                  ),
                  _ActionCard(
                    title: 'Reports',
                    subtitle: 'Generate reports',
                    icon: Icons.assessment,
                    color: const Color(AppColors.warningColor),
                    onTap: () => context.push('/admin/reports'),
                  ),
                  _ActionCard(
                    title: 'Settings',
                    subtitle: 'System settings',
                    icon: Icons.settings,
                    color: const Color(AppColors.secondaryColor),
                    onTap: () => context.push('/settings'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Recent Expenses
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Submissions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/admin/expenses'),
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
                              'No expenses submitted yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Expenses will appear here once submitted',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
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
                        onTap: () => context.push('/admin/expenses/${expense.id}'),
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
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}