import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../models/line_item_model.dart';
import '../models/attachment_model.dart';
import '../services/supabase_service.dart';
import '../providers/auth_provider.dart';

class ExpenseProvider extends ChangeNotifier {
  List<ExpenseModel> _expenses = [];
  ExpenseModel? _selectedExpense;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};

  List<ExpenseModel> get expenses => _expenses;
  ExpenseModel? get selectedExpense => _selectedExpense;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;

  // Filtered expenses getters
  List<ExpenseModel> get pendingExpenses => 
      _expenses.where((e) => e.status == 'submitted' || e.status == 'under_review').toList();
  
  List<ExpenseModel> get approvedExpenses => 
      _expenses.where((e) => e.status == 'approved' || e.status == 'paid').toList();
  
  List<ExpenseModel> get rejectedExpenses => 
      _expenses.where((e) => e.status == 'rejected').toList();

  List<ExpenseModel> get draftExpenses => 
      _expenses.where((e) => e.status == 'draft').toList();

  // Load expenses for current user
  Future<void> loadUserExpenses({String? status}) async {
    final user = SupabaseService.getCurrentUser();
    if (user == null) return;

    _setLoading(true);
    _clearError();

    try {
      final expenses = await SupabaseService.getExpenses(
        userId: user.id,
        status: status,
      );
      
      _expenses = expenses;
      notifyListeners();
    } catch (e) {
      _setError('Error loading expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load all expenses (admin/engineer view)
  Future<void> loadAllExpenses({String? status, String? userId}) async {
    _setLoading(true);
    _clearError();

    try {
      final expenses = await SupabaseService.getAllExpenses(
        status: status,
        userId: userId,
      );
      
      _expenses = expenses;
      notifyListeners();
    } catch (e) {
      _setError('Error loading expenses: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load expense details
  Future<void> loadExpenseDetails(String expenseId) async {
    _setLoading(true);
    _clearError();

    try {
      final expense = await SupabaseService.getExpenseById(expenseId);
      if (expense != null) {
        _selectedExpense = expense;
      } else {
        _setError('Expense not found');
      }
    } catch (e) {
      _setError('Error loading expense details: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create new expense
  Future<bool> createExpense(ExpenseModel expense, List<LineItemModel> lineItems) async {
    _setLoading(true);
    _clearError();

    try {
      final expenseId = await SupabaseService.createExpense(expense, lineItems);
      if (expenseId != null) {
        // Reload expenses to show the new one
        await loadUserExpenses();
        return true;
      } else {
        _setError('Failed to create expense');
        return false;
      }
    } catch (e) {
      _setError('Error creating expense: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update expense status
  Future<bool> updateExpenseStatus(String expenseId, String status, {String? comment}) async {
    _setLoading(true);
    _clearError();

    try {
      final success = await SupabaseService.updateExpenseStatus(
        expenseId, 
        status, 
        comment: comment,
      );
      
      if (success) {
        // Update local expense
        final index = _expenses.indexWhere((e) => e.id == expenseId);
        if (index != -1) {
          _expenses[index] = _expenses[index].copyWith(
            status: status,
            adminComment: comment,
            updatedAt: DateTime.now(),
          );
          notifyListeners();
        }
        
        // Update selected expense if it's the same
        if (_selectedExpense?.id == expenseId) {
          _selectedExpense = _selectedExpense!.copyWith(
            status: status,
            adminComment: comment,
            updatedAt: DateTime.now(),
          );
        }
        
        return true;
      } else {
        _setError('Failed to update expense status');
        return false;
      }
    } catch (e) {
      _setError('Error updating expense status: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Load expense statistics
  Future<void> loadExpenseStats() async {
    final user = SupabaseService.getCurrentUser();
    if (user == null) return;

    try {
      final stats = await SupabaseService.getExpenseStats(user.id);
      _stats = stats;
      notifyListeners();
    } catch (e) {
      print('Error loading expense stats: $e');
    }
  }

  // Upload file and create attachment
  Future<AttachmentModel?> uploadFile(String filePath, Uint8List fileBytes, String contentType) async {
    try {
      final uploadedPath = await SupabaseService.uploadFile(filePath, fileBytes, contentType);
      if (uploadedPath != null) {
        final publicUrl = await SupabaseService.getPublicUrl(uploadedPath);
        if (publicUrl != null) {
          final attachment = AttachmentModel(
            id: '', // Will be set by the database
            expenseId: _selectedExpense?.id ?? '',
            fileUrl: publicUrl,
            filename: filePath.split('/').last,
            contentType: contentType,
            uploadedBy: SupabaseService.getCurrentUser()?.id ?? '',
            createdAt: DateTime.now(),
          );

          final createdAttachment = await SupabaseService.createAttachment(attachment);
          if (createdAttachment != null && _selectedExpense != null) {
            // Update selected expense with new attachment
            final updatedAttachments = List<AttachmentModel>.from(_selectedExpense!.attachments);
            updatedAttachments.add(createdAttachment);
            _selectedExpense = _selectedExpense!.copyWith(attachments: updatedAttachments);
            notifyListeners();
          }
          
          return createdAttachment;
        }
      }
      return null;
    } catch (e) {
      _setError('Error uploading file: $e');
      return null;
    }
  }

  // Delete attachment
  Future<bool> deleteAttachment(String attachmentId) async {
    try {
      final success = await SupabaseService.deleteAttachment(attachmentId);
      if (success && _selectedExpense != null) {
        // Remove attachment from selected expense
        final updatedAttachments = _selectedExpense!.attachments
            .where((a) => a.id != attachmentId)
            .toList();
        _selectedExpense = _selectedExpense!.copyWith(attachments: updatedAttachments);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Error deleting attachment: $e');
      return false;
    }
  }

  // Filter expenses by various criteria
  List<ExpenseModel> filterExpenses({
    String? status,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? searchQuery,
  }) {
    return _expenses.where((expense) {
      if (status != null && expense.status != status) return false;
      if (startDate != null && expense.createdAt.isBefore(startDate)) return false;
      if (endDate != null && expense.createdAt.isAfter(endDate)) return false;
      if (minAmount != null && expense.totalAmount < minAmount) return false;
      if (maxAmount != null && expense.totalAmount > maxAmount) return false;
      if (searchQuery != null) {
        final query = searchQuery.toLowerCase();
        if (!expense.title.toLowerCase().contains(query) &&
            !expense.destination.toLowerCase().contains(query) &&
            !expense.purpose.toLowerCase().contains(query)) {
          return false;
        }
      }
      if (category != null) {
        final hasCategory = expense.lineItems.any((item) => item.category == category);
        if (!hasCategory) return false;
      }
      return true;
    }).toList();
  }

  // Get expenses by status
  List<ExpenseModel> getExpensesByStatus(String status) {
    return _expenses.where((e) => e.status == status).toList();
  }

  // Get expenses for current month
  List<ExpenseModel> getCurrentMonthExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return _expenses.where((expense) {
      return expense.createdAt.isAfter(startOfMonth) && 
             expense.createdAt.isBefore(endOfMonth);
    }).toList();
  }

  // Calculate total amount for filtered expenses
  double calculateTotalAmount(List<ExpenseModel> expenses) {
    return expenses.fold(0.0, (sum, expense) => sum + expense.totalAmount);
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

  void clearSelectedExpense() {
    _selectedExpense = null;
    notifyListeners();
  }

  Future<void> refreshExpenses() async {
    await loadUserExpenses();
    await loadExpenseStats();
  }

  // Admin methods
  Map<String, dynamic> get adminStats => {
    'pendingCount': _expenses.where((e) => e.status == 'submitted').length,
    'totalUsers': 0, // TODO: Implement user count
    'monthlySpend': _expenses
        .where((e) => e.status == 'approved' && 
                     e.createdAt.month == DateTime.now().month)
        .fold(0.0, (sum, e) => sum + e.totalAmount),
    'activeEngineers': 0, // TODO: Implement engineer count
  };

  // Engineer methods
  Map<String, dynamic> get engineerStats => {
    'pendingReview': _expenses.where((e) => e.status == 'submitted').length,
    'reviewedToday': _expenses
        .where((e) => e.status == 'verified' && 
                     e.updatedAt.day == DateTime.now().day)
        .length,
    'totalReviewed': _expenses.where((e) => e.status == 'verified').length,
    'avgReviewTime': 15, // TODO: Calculate actual review time
  };


  Future<void> loadEngineerExpenses() async {
    try {
      _isLoading = true;
      notifyListeners();

      // For now, load all expenses - in real app, filter by assigned engineer
      final expenses = await SupabaseService.getAllExpenses();
      _expenses = expenses;
    } catch (e) {
      print('Error loading engineer expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveExpense(String expenseId, String comment) async {
    try {
      final success = await SupabaseService.updateExpenseStatus(
        expenseId, 
        'approved',
        comment: comment
      );
      
      if (success) {
        await loadAllExpenses();
      }
      
      return success;
    } catch (e) {
      print('Error approving expense: $e');
      return false;
    }
  }

  Future<bool> rejectExpense(String expenseId, String comment) async {
    try {
      final success = await SupabaseService.updateExpenseStatus(
        expenseId, 
        'rejected',
        comment: comment
      );
      
      if (success) {
        await loadAllExpenses();
      }
      
      return success;
    } catch (e) {
      print('Error rejecting expense: $e');
      return false;
    }
  }

  Future<bool> verifyExpense(String expenseId, String comment) async {
    try {
      final success = await SupabaseService.updateExpenseStatus(
        expenseId, 
        'verified',
        comment: comment
      );
      
      if (success) {
        await loadEngineerExpenses();
      }
      
      return success;
    } catch (e) {
      print('Error verifying expense: $e');
      return false;
    }
  }

  Future<bool> deleteExpense(String expenseId) async {
    try {
      // TODO: Implement deleteExpense in SupabaseService
      _expenses.removeWhere((e) => e.id == expenseId);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error deleting expense: $e');
      return false;
    }
  }

  Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      return await SupabaseService.getExpenseById(expenseId);
    } catch (e) {
      print('Error fetching expense by ID: $e');
      return null;
    }
  }
}
