import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../models/expense_model.dart';
import '../../../models/line_item_model.dart';
import '../../../models/attachment_model.dart';
import '../../../utils/currency_formatter.dart';
import '../../../utils/date_formatter.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final String expenseId;
  
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseModel? _expense;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    try {
      final expenseProvider = context.read<ExpenseProvider>();
      final expense = await expenseProvider.getExpenseById(widget.expenseId);
      
      if (mounted) {
        setState(() {
          _expense = expense;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading expense: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: const Color(AppColors.primaryColor),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_expense == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Expense Not Found'),
          backgroundColor: const Color(AppColors.primaryColor),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Expense not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_expense!.title),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  context.push('/expenses/${widget.expenseId}/edit');
                  break;
                case 'delete':
                  _showDeleteDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(Icons.edit),
                  title: Text('Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(ExpenseStatus.fromString(_expense!.status)).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(ExpenseStatus.fromString(_expense!.status)),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusText(ExpenseStatus.fromString(_expense!.status)),
                        style: TextStyle(
                          color: _getStatusColor(ExpenseStatus.fromString(_expense!.status)),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      CurrencyFormatter.formatINR(_expense!.totalAmount),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(AppColors.primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Basic Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InfoRow(
                      label: 'Title',
                      value: _expense!.title,
                    ),
                    _InfoRow(
                      label: 'Destination',
                      value: _expense!.destination,
                    ),
                    _InfoRow(
                      label: 'Purpose',
                      value: _expense!.purpose,
                    ),
                    _InfoRow(
                      label: 'Start Date',
                      value: _expense!.startDate != null ? DateFormatter.formatDate(_expense!.startDate!) : 'N/A',
                    ),
                    _InfoRow(
                      label: 'End Date',
                      value: _expense!.endDate != null ? DateFormatter.formatDate(_expense!.endDate!) : 'N/A',
                    ),
                    _InfoRow(
                      label: 'Created',
                      value: DateFormatter.formatDate(_expense!.createdAt),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Line Items
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expense Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_expense!.lineItems.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No items found'),
                        ),
                      )
                    else
                      ..._expense!.lineItems.map((item) => _LineItemCard(item: item)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attachments
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Receipts & Attachments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_expense!.attachments.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text('No attachments found'),
                        ),
                      )
                    else
                      ..._expense!.attachments.map((attachment) => _AttachmentCard(attachment: attachment)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Comments/Audit Trail
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Comments & History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_expense!.adminComment != null && _expense!.adminComment!.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Admin Comment:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(AppColors.primaryColor),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(_expense!.adminComment!),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'Audit trail will be shown here',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final expenseProvider = context.read<ExpenseProvider>();
                await expenseProvider.deleteExpense(widget.expenseId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Expense deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  context.pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting expense: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItemCard extends StatelessWidget {
  final LineItemModel item;

  const _LineItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ExpenseCategory.fromString(item.category).displayName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormatter.formatDate(item.date),
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              CurrencyFormatter.formatINR(item.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(AppColors.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final AttachmentModel attachment;

  const _AttachmentCard({required this.attachment});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.image, size: 40),
        title: Text(attachment.filename),
        subtitle: Text(
          'Uploaded: ${DateFormatter.formatDate(attachment.uploadedAt)}',
        ),
        trailing: IconButton(
          onPressed: () => _showImageDialog(context),
          icon: const Icon(Icons.visibility),
        ),
        onTap: () => _showImageDialog(context),
      ),
    );
  }

  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(attachment.filename),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Flexible(
              child: Container(
                width: double.infinity,
                height: 400,
                color: Colors.black,
                child: attachment.fileUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: attachment.fileUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, color: Colors.white),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.white, size: 100),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}