import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/stat_card.dart';
import '../../../widgets/expense_list_tile.dart';
import '../../../utils/currency_formatter.dart';

class EngineerDashboardScreen extends StatefulWidget {
  const EngineerDashboardScreen({super.key});

  @override
  State<EngineerDashboardScreen> createState() => _EngineerDashboardScreenState();
}

class _EngineerDashboardScreenState extends State<EngineerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadEngineerExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Engineer Dashboard'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExpenseProvider>().loadEngineerExpenses();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().loadEngineerExpenses();
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
                      'Engineer Review',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Review and verify expense claims',
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
                'Review Overview',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<ExpenseProvider>(
                builder: (context, expenseProvider, _) {
                  final stats = expenseProvider.engineerStats;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.5,
                    children: [
                      StatCard(
                        title: 'Pending Review',
                        value: '${stats['pendingReview'] ?? 0}',
                        icon: Icons.pending_actions,
                        color: const Color(AppColors.warningColor),
                        onTap: () => context.push('/engineer/review?status=submitted'),
                      ),
                      StatCard(
                        title: 'Reviewed Today',
                        value: '${stats['reviewedToday'] ?? 0}',
                        icon: Icons.check_circle,
                        color: const Color(AppColors.successColor),
                        onTap: () => context.push('/engineer/review?status=verified'),
                      ),
                      StatCard(
                        title: 'Total Reviewed',
                        value: '${stats['totalReviewed'] ?? 0}',
                        icon: Icons.assignment_turned_in,
                        color: const Color(AppColors.primaryColor),
                        onTap: () => context.push('/engineer/review'),
                      ),
                      StatCard(
                        title: 'Avg Review Time',
                        value: '${stats['avgReviewTime'] ?? 0} min',
                        icon: Icons.timer,
                        color: const Color(AppColors.secondaryColor),
                        onTap: () => context.push('/engineer/review'),
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
                      onPressed: () => context.push('/engineer/review'),
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Review Expenses'),
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
                      onPressed: () => context.push('/engineer/review?status=verified'),
                      icon: const Icon(Icons.history),
                      label: const Text('Review History'),
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

              // Recent Assignments
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Assignments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(AppColors.textPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/engineer/review'),
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
                              Icons.assignment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No assignments yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Assigned expenses will appear here',
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
                        onTap: () => context.push('/engineer/review/${expense.id}'),
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