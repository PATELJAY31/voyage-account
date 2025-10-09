import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../widgets/expense_list_tile.dart';
import '../../../widgets/custom_button.dart';
import '../../../models/expense_model.dart';
import '../../../utils/currency_formatter.dart';

class ExpensesScreen extends StatefulWidget {
  final String? status;
  
  const ExpensesScreen({super.key, this.status});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedCategory = 'all';
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
      context.read<ExpenseProvider>().loadUserExpenses();
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
            !expense.purpose.toLowerCase().contains(searchTerm)) {
          return false;
        }
      }
      
      // Date range filter
      if (_startDate != null && expense.startDate != null && expense.startDate!.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && expense.endDate != null && expense.endDate!.isAfter(_endDate!)) {
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
      _selectedCategory = 'all';
      _startDate = null;
      _endDate = null;
      _searchController.clear();
      _filteredExpenses = _getFilteredExpenses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.expenses),
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
              context.read<ExpenseProvider>().loadUserExpenses();
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
                hintText: 'Search expenses...',
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
                    await expenseProvider.loadUserExpenses();
                    _applyFilters();
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: expenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return ExpenseListTile(
                        expense: expense,
                        onTap: () => context.push('/expenses/${expense.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/expenses/new'),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newExpense),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
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
            'Create your first expense or adjust your filters',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/expenses/new'),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.newExpense),
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