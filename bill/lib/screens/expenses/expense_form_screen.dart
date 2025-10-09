import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../constants/app_constants.dart';
import '../../../providers/expense_provider.dart';
import '../../../models/expense_model.dart';
import '../../../models/line_item_model.dart';
import '../../../models/attachment_model.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/custom_button.dart';
import '../../../utils/currency_formatter.dart';
import '../../../services/supabase_service.dart';

class ExpenseFormScreen extends StatefulWidget {
  final String? expenseId;
  
  const ExpenseFormScreen({super.key, this.expenseId});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _destinationController = TextEditingController();
  final _purposeController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  List<LineItemModel> _lineItems = [];
  List<AttachmentModel> _attachments = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  void _addLineItem() {
    setState(() {
      _lineItems.add(LineItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        expenseId: '',
        date: DateTime.now(),
        category: ExpenseCategory.other.value,
        amount: 0.0,
        description: '',
      ));
    });
  }

  void _removeLineItem(int index) {
    setState(() {
      _lineItems.removeAt(index);
    });
  }

  void _updateLineItem(int index, LineItemModel updatedItem) {
    setState(() {
      _lineItems[index] = updatedItem;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (image != null) {
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      
      setState(() {
        _attachments.add(AttachmentModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          expenseId: '',
          filename: image.name,
          fileUrl: image.path,
          contentType: 'image/jpeg',
          uploadedBy: '', // Will be set when saving
          createdAt: DateTime.now(),
        ));
      });
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  double _calculateTotal() {
    return _lineItems.fold(0.0, (sum, item) => sum + item.amount);
  }

  Future<void> _saveExpense(bool isDraft) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one expense item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final expenseProvider = context.read<ExpenseProvider>();
      
      // Create expense object
      final expense = ExpenseModel(
        id: '',
        userId: '',
        title: _titleController.text.trim(),
        tripStart: _startDate,
        tripEnd: _endDate,
        destination: _destinationController.text.trim(),
        purpose: _purposeController.text.trim(),
        status: isDraft ? 'draft' : 'submitted',
        totalAmount: _lineItems.fold(0.0, (sum, item) => sum + item.amount),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Create expense
      final success = await expenseProvider.createExpense(
        expense,
        _lineItems,
      );

      // Upload attachments (remote path and DB record)
      // Note: We already read bytes at pick-time; to keep memory small, re-read here for upload
      if (success) {
        final created = await SupabaseService.getExpenses(userId: null, status: null, startDate: null, endDate: null, limit: 1);
        final newId = created.isNotEmpty ? created.first.id : null;
        if (newId != null && _attachments.isNotEmpty) {
          for (final att in _attachments) {
            try {
              final file = File(att.fileUrl);
              if (!await file.exists()) continue;
              final bytes = await file.readAsBytes();
              final ext = att.filename.contains('.') ? '.${att.filename.split('.').last}' : '';
              final remotePath = '${newId}/${DateTime.now().millisecondsSinceEpoch}${ext}';
              final uploadedPath = await SupabaseService.uploadFile(remotePath, bytes, att.contentType);
              if (uploadedPath != null) {
                final publicUrl = await SupabaseService.getPublicUrl(uploadedPath);
                if (publicUrl != null) {
                  await SupabaseService.createAttachment(AttachmentModel(
                    id: '',
                    expenseId: newId,
                    lineItemId: null,
                    fileUrl: publicUrl,
                    filename: att.filename,
                    contentType: att.contentType,
                    uploadedBy: '',
                    createdAt: DateTime.now(),
                  ));
                }
              }
            } catch (_) {}
          }
        }
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isDraft ? 'Draft saved successfully' : 'Expense submitted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.expenseId != null;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Expense' : AppStrings.newExpense),
        backgroundColor: const Color(AppColors.primaryColor),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isEditing) ...[
            TextButton(
              onPressed: _isSubmitting ? null : () => _saveExpense(true),
              child: const Text(
                'Save Draft',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Card
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
                      
                      CustomTextField(
                        controller: _titleController,
                        label: 'Expense Title',
                        hint: 'Enter expense title',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _startDate != null 
                                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                                        : 'Select date',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _endDate ?? DateTime.now(),
                                  firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (date != null) {
                                  setState(() {
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      _endDate != null 
                                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                                        : 'Select date',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _destinationController,
                        label: 'Destination',
                        hint: 'Enter destination',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      CustomTextField(
                        controller: _purposeController,
                        label: 'Purpose',
                        hint: 'Enter purpose of expense',
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppStrings.required;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Line Items Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Expense Items',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addLineItem,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Item'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_lineItems.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.add_box_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No items added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add expense items to get started',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _lineItems.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _LineItemCard(
                              item: item,
                              onUpdate: (updatedItem) => _updateLineItem(index, updatedItem),
                              onRemove: () => _removeLineItem(index),
                            );
                          }).toList(),
                        ),
                      
                      if (_lineItems.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Amount:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.formatINR(_calculateTotal()),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(AppColors.primaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Attachments Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Receipts & Attachments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Add Receipt'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      if (_attachments.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.attach_file_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No receipts uploaded yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload receipts to support your expense claim',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: _attachments.asMap().entries.map((entry) {
                            final index = entry.key;
                            final attachment = entry.value;
                            return _AttachmentCard(
                              attachment: attachment,
                              onRemove: () => _removeAttachment(index),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Submit Button
              if (!isEditing)
                CustomButton(
                  text: 'Submit Expense',
                  onPressed: _isSubmitting ? null : () => _saveExpense(false),
                  isLoading: _isSubmitting,
                  width: double.infinity,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItemCard extends StatefulWidget {
  final LineItemModel item;
  final Function(LineItemModel) onUpdate;
  final VoidCallback onRemove;

  const _LineItemCard({
    required this.item,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<_LineItemCard> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  ExpenseCategory _selectedCategory = ExpenseCategory.other;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.item.description);
    _amountController = TextEditingController(text: widget.item.amount > 0 ? widget.item.amount.toString() : '');
    _selectedCategory = ExpenseCategory.fromString(widget.item.category);
    _selectedDate = widget.item.date;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateItem() {
    widget.onUpdate(LineItemModel(
      id: widget.item.id,
      expenseId: widget.item.expenseId,
      date: _selectedDate,
      category: _selectedCategory.value,
      amount: double.tryParse(_amountController.text) ?? 0.0,
      description: _descriptionController.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${widget.item.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Date
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                  _updateItem();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Category
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ExpenseCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                  _updateItem();
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Amount
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateItem(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Amount is required';
                }
                final amount = double.tryParse(value);
                if (amount == null || amount <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (_) => _updateItem(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentCard extends StatelessWidget {
  final AttachmentModel attachment;
  final VoidCallback onRemove;

  const _AttachmentCard({
    required this.attachment,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.image, size: 40),
        title: Text(attachment.filename),
        subtitle: Text(
          'Uploaded: ${attachment.uploadedAt.day}/${attachment.uploadedAt.month}/${attachment.uploadedAt.year}',
        ),
        trailing: IconButton(
          onPressed: onRemove,
          icon: const Icon(Icons.delete, color: Colors.red),
        ),
      ),
    );
  }
}