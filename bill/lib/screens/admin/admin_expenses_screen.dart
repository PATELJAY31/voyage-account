import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/expense_list_tile.dart';
import '../../../models/expense_model.dart';
import '../../../utils/currency_formatter.dart';

class AdminExpensesScreen extends StatefulWidget {
  final String? status;
  
  const AdminExpensesScreen({super.key, this.status});

  @override
  State<AdminExpensesScreen> createState() => _AdminExpensesScreenState();
}

class _AdminExpensesScreenState extends State<AdminExpensesScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  List<ExpenseModel> _filteredExpenses = [];

  @override
  void initState() {
    super.initState();
    if (widget.status != null) {
      _selectedStatus = widget.status!;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadAllExpenses();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ExpenseModel> _getFilteredExpenses() {
    final expenses = context.read<ExpenseProvider>().expenses;
    var filtered = expenses.where((expense) {
      // Status filter
      if (_selectedStatus != 'all' && expense.status != _selectedStatus) {
        return false;
      }
      
      // Search filter
      if (_searchController.text.isNotEmpty) {
        final searchTerm = _searchController.text.toLowerCase();
        if (!expense.title.toLowerCase().contains(searchTerm) &&
            !expense.destination.toLowerCase().contains(searchTerm) &&
            !(expense.userName?.toLowerCase().contains(searchTerm) ?? false)) {
          return false;
        }
      }
      
      // Date range filter
      if (_startDate != null && expense.createdAt.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && expense.createdAt.isAfter(_endDate!)) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by creation date (newest first)
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return filtered;
  }

  void _applyFilters() {
    setState(() {
      _filteredExpenses = _getFilteredExpenses();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
      _filteredExpenses = _getFilteredExpenses();
    });
  }

  Future<void> _approveExpense(String expenseId) async {
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      await expenseProvider.approveExpense(expenseId, 'Approved by admin');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectExpense(String expenseId) async {
    final commentController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, commentController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final expenseProvider = context.read<ExpenseProvider>();
        await expenseProvider.rejectExpense(expenseId, result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense rejected successfully'),
              backgroundColor: Colors.orange,
            ),
          );
          _applyFilters();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error rejecting expense: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Expenses'),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ExpenseProvider>().loadAllExpenses();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search expenses by title, destination, or user...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => _applyFilters(),
            ),
          ),
          
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey[50],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    isSelected: _selectedStatus == 'all',
                    onSelected: () {
                      setState(() {
                        _selectedStatus = 'all';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Draft',
                    isSelected: _selectedStatus == 'draft',
                    onSelected: () {
                      setState(() {
                        _selectedStatus = 'draft';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Submitted',
                    isSelected: _selectedStatus == 'submitted',
                    onSelected: () {
                      setState(() {
                        _selectedStatus = 'submitted';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Approved',
                    isSelected: _selectedStatus == 'approved',
                    onSelected: () {
                      setState(() {
                        _selectedStatus = 'approved';
                      });
                      _applyFilters();
                    },
                  ),
                  _FilterChip(
                    label: 'Rejected',
                    isSelected: _selectedStatus == 'rejected',
                    onSelected: () {
                      setState(() {
                        _selectedStatus = 'rejected';
                      });
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          // Expenses List
          Expanded(
            child: Consumer<ExpenseProvider>(
              builder: (context, expenseProvider, _) {
                if (expenseProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final expenses = _filteredExpenses.isEmpty ? _getFilteredExpenses() : _filteredExpenses;
                
                if (expenses.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    await expenseProvider.loadAllExpenses();
                    _applyFilters();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return _AdminExpenseCard(
                        expense: expense,
                        onTap: () => context.push('/admin/expenses/${expense.id}'),
                        onApprove: expense.status == 'submitted' 
                          ? () => _approveExpense(expense.id)
                          : null,
                        onReject: expense.status == 'submitted'
                          ? () => _rejectExpense(expense.id)
                          : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No expenses found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adjust your filters to see more results',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Expenses'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date Range',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _startDate != null 
                              ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                              : 'Start Date',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setDialogState(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _endDate != null 
                              ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                              : 'End Date',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All')),
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'submitted', child: Text('Submitted')),
                    DropdownMenuItem(value: 'approved', child: Text('Approved')),
                    DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      _selectedStatus = value ?? 'all';
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _clearFilters();
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _applyFilters();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: const Color(AppColors.primaryColor).withOpacity(0.2),
        checkmarkColor: const Color(AppColors.primaryColor),
        labelStyle: TextStyle(
          color: isSelected 
            ? const Color(AppColors.primaryColor)
            : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

class _AdminExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _AdminExpenseCard({
    required this.expense,
    required this.onTap,
    this.onApprove,
    this.onReject,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'by ${expense.userName}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.formatINR(expense.totalAmount),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(AppColors.primaryColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(ExpenseStatus.fromString(expense.status)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(ExpenseStatus.fromString(expense.status)),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _getStatusText(ExpenseStatus.fromString(expense.status)),
                          style: TextStyle(
                            color: _getStatusColor(ExpenseStatus.fromString(expense.status)),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                expense.destination,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              if (onApprove != null || onReject != null)
                Row(
                  children: [
                    if (onApprove != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onApprove,
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (onApprove != null && onReject != null)
                      const SizedBox(width: 8),
                    if (onReject != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onReject,
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return Colors.grey;
      case ExpenseStatus.submitted:
        return Colors.orange;
      case ExpenseStatus.underReview:
        return Colors.blue;
      case ExpenseStatus.verified:
        return Colors.cyan;
      case ExpenseStatus.approved:
        return Colors.green;
      case ExpenseStatus.rejected:
        return Colors.red;
      case ExpenseStatus.paid:
        return Colors.purple;
    }
  }

  String _getStatusText(ExpenseStatus status) {
    switch (status) {
      case ExpenseStatus.draft:
        return 'Draft';
      case ExpenseStatus.submitted:
        return 'Submitted';
      case ExpenseStatus.underReview:
        return 'Under Review';
      case ExpenseStatus.verified:
        return 'Verified';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.rejected:
        return 'Rejected';
      case ExpenseStatus.paid:
        return 'Paid';
    }
  }
}