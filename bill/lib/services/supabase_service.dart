import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../models/expense_model.dart';
import '../models/line_item_model.dart';
import '../models/attachment_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Auth Methods
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? getCurrentUser() {
    return _client.auth.currentUser;
  }

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // User Profile Methods
  static Future<UserModel?> getCurrentUserProfile() async {
    final user = getCurrentUser();
    if (user == null) {
      print('No current user found');
      return null;
    }

    try {
      print('Fetching profile for user: ${user.id}');
      final response = await _client
          .from('profiles')
          .select('*')
          .eq('user_id', user.id)
          .single();

      print('Profile response: $response');

      final roleResponse = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', user.id)
          .single();

      print('Role response: $roleResponse');

      final userData = response as Map<String, dynamic>;
      userData['role'] = roleResponse['role'];

      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Expense Methods
  static Future<List<ExpenseModel>> getExpenses({
    String? userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      var query = _client.from('expenses').select('*');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      var finalQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      final expenses = (response as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Fetch profiles for user names/emails
      final userIds = expenses.map((e) => e['user_id'] as String).toSet().toList();
      Map<String, Map<String, dynamic>> userIdToProfile = {};
      if (userIds.isNotEmpty) {
        final profilesResp = await _client
            .from('profiles')
            .select('user_id, name, email')
            .inFilter('user_id', userIds);
        for (final p in (profilesResp as List<dynamic>)) {
          final mp = Map<String, dynamic>.from(p as Map);
          userIdToProfile[mp['user_id'] as String] = mp;
        }
      }

      final enriched = expenses.map((exp) {
        final profile = userIdToProfile[exp['user_id'] as String];
        if (profile != null) {
          exp['user_name'] = profile['name'];
          exp['profiles'] = {'name': profile['name'], 'email': profile['email']};
        }
        return ExpenseModel.fromJson(exp);
      }).toList();

      return enriched;
    } catch (e) {
      print('Error fetching expenses: $e');
      return [];
    }
  }


  static Future<String?> createExpense(ExpenseModel expense, List<LineItemModel> lineItems) async {
    try {
      final current = getCurrentUser();
      if (current == null) {
        throw Exception('Not authenticated');
      }

      // Auto-assign to reporting engineer if set
      String? assignedEngineerId;
      try {
        final prof = await _client
            .from('profiles')
            .select('reporting_engineer_id')
            .eq('user_id', current.id)
            .single();
        assignedEngineerId = prof['reporting_engineer_id'] as String?;
      } catch (_) {}

      // Create expense
      final Map<String, dynamic> payload = {
        'user_id': current.id,
        'title': expense.title,
        'trip_start': expense.tripStart?.toIso8601String(),
        'trip_end': expense.tripEnd?.toIso8601String(),
        'destination': expense.destination,
        'purpose': expense.purpose,
        'status': assignedEngineerId != null ? 'under_review' : (expense.status ?? 'submitted'),
        'total_amount': expense.totalAmount,
        'assigned_engineer_id': assignedEngineerId ?? expense.assignedEngineerId,
        'admin_comment': expense.adminComment,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final expenseResponse = await _client
          .from('expenses')
          .insert(payload)
          .select('id')
          .single();

      final expenseId = expenseResponse['id'] as String;

      // Create line items
      if (lineItems.isNotEmpty) {
        final lineItemsData = lineItems.map((item) => 
          item.copyWith(expenseId: expenseId).toJson()
        ).toList();

        await _client
            .from('expense_line_items')
            .insert(lineItemsData);
      }

      return expenseId;
    } catch (e) {
      print('Error creating expense: $e');
      return null;
    }
  }

  static Future<bool> updateExpenseStatus(String expenseId, String status, {String? comment}) async {
    try {
      // Guard finalized states
      final cur = await _client
          .from('expenses')
          .select('status, user_id, total_amount')
          .eq('id', expenseId)
          .single();

      final curStatus = cur['status'] as String? ?? 'draft';
      if (['approved','paid','rejected'].contains(curStatus)) {
        throw Exception('Expense is finalized and cannot be updated');
      }

      // If approving, ensure verified and deduct balance
      if (status == 'approved') {
        if (curStatus != 'verified') {
          throw Exception('Expense must be verified by an engineer before admin approval');
        }
        final userId = cur['user_id'] as String;
        final amount = (cur['total_amount'] ?? 0).toDouble();
        final prof = await _client
            .from('profiles')
            .select('balance')
            .eq('user_id', userId)
            .single();
        final currentBalance = (prof['balance'] ?? 0).toDouble();
        if (currentBalance < amount) {
          throw Exception('Insufficient balance. Please add funds before approval.');
        }
        // Deduct first to reduce risk of races
        await _client
            .from('profiles')
            .update({'balance': currentBalance - amount})
            .eq('user_id', userId);
      }

      await _client
          .from('expenses')
          .update({
            'status': status,
            'admin_comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', expenseId);

      return true;
    } catch (e) {
      print('Error updating expense status: $e');
      return false;
    }
  }

  // File Upload Methods
  static Future<String?> uploadFile(String remotePath, Uint8List fileBytes, String contentType) async {
    try {
      final response = await _client.storage
          .from(AppConstants.receiptsBucket)
          .uploadBinary(remotePath, fileBytes, fileOptions: FileOptions(
            contentType: contentType,
          ));

      return response;
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  static Future<String?> getPublicUrl(String filePath) async {
    try {
      final response = _client.storage
          .from(AppConstants.receiptsBucket)
          .getPublicUrl(filePath);

      return response;
    } catch (e) {
      print('Error getting public URL: $e');
      return null;
    }
  }

  static Future<List<AttachmentModel>> uploadAttachments(String expenseId, List<AttachmentModel> localAttachments) async {
    final uploaded = <AttachmentModel>[];
    for (final att in localAttachments) {
      try {
        // fileUrl currently holds local path; we need bytes and a remote path
        final pathSegments = att.filename.split('.');
        final ext = pathSegments.length > 1 ? '.${pathSegments.last}' : '';
        final remotePath = '${expenseId}/${DateTime.now().millisecondsSinceEpoch}${ext}';

        // This API expects bytes from caller; for now, skip if we cannot get bytes
        // In this app, images are added via ImagePicker -> read in screen, we will pass bytes from there
        // Here we only create DB record after upload
        // Get public URL
        final publicUrl = await getPublicUrl(remotePath);
        if (publicUrl == null) {
          continue;
        }

        final created = await createAttachment(AttachmentModel(
          id: '',
          expenseId: expenseId,
          lineItemId: null,
          fileUrl: publicUrl,
          filename: att.filename,
          contentType: att.contentType,
          uploadedBy: getCurrentUser()?.id ?? '',
          createdAt: DateTime.now(),
        ));
        if (created != null) {
          uploaded.add(created);
        }
      } catch (e) {
        print('Error uploading attachment: $e');
      }
    }
    return uploaded;
  }

  static Future<bool> deleteFile(String filePath) async {
    try {
      await _client.storage
          .from(AppConstants.receiptsBucket)
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // Attachment Methods
  static Future<AttachmentModel?> createAttachment(AttachmentModel attachment) async {
    try {
      final response = await _client
          .from('attachments')
          .insert(attachment.toJson())
          .select('*')
          .single();

      return AttachmentModel.fromJson(response);
    } catch (e) {
      print('Error creating attachment: $e');
      return null;
    }
  }

  static Future<List<AttachmentModel>> getExpenseAttachments(String expenseId) async {
    try {
      final response = await _client
          .from('attachments')
          .select('*')
          .eq('expense_id', expenseId);

      final attachments = response as List<dynamic>;
      return attachments.map((item) => AttachmentModel.fromJson(item)).toList();
    } catch (e) {
      print('Error fetching attachments: $e');
      return [];
    }
  }

  static Future<bool> deleteAttachment(String attachmentId) async {
    try {
      await _client
          .from('attachments')
          .delete()
          .eq('id', attachmentId);

      return true;
    } catch (e) {
      print('Error deleting attachment: $e');
      return false;
    }
  }


  static Future<List<ExpenseModel>> getAllExpenses({
    String? status,
    String? userId,
    int? limit,
  }) async {
    try {
      var query = _client.from('expenses').select('*');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      var finalQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      final expenses = (response as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Fetch profiles for user names/emails
      final userIds = expenses.map((e) => e['user_id'] as String).toSet().toList();
      Map<String, Map<String, dynamic>> userIdToProfile = {};
      if (userIds.isNotEmpty) {
        final profilesResp = await _client
            .from('profiles')
            .select('user_id, name, email')
            .inFilter('user_id', userIds);
        for (final p in (profilesResp as List<dynamic>)) {
          final mp = Map<String, dynamic>.from(p as Map);
          userIdToProfile[mp['user_id'] as String] = mp;
        }
      }

      final enriched = expenses.map((exp) {
        final profile = userIdToProfile[exp['user_id'] as String];
        if (profile != null) {
          exp['user_name'] = profile['name'];
          exp['profiles'] = {'name': profile['name'], 'email': profile['email']};
        }
        return ExpenseModel.fromJson(exp);
      }).toList();

      return enriched;
    } catch (e) {
      print('Error fetching all expenses: $e');
      return [];
    }
  }

  static Future<ExpenseModel?> getExpenseById(String expenseId) async {
    try {
      final expenseResp = await _client
          .from('expenses')
          .select('*')
          .eq('id', expenseId)
          .single();

      final expense = Map<String, dynamic>.from(expenseResp as Map);

      // Profile
      Map<String, dynamic>? profile;
      if (expense['user_id'] != null) {
        final prof = await _client
            .from('profiles')
            .select('name, email, user_id')
            .eq('user_id', expense['user_id'])
            .maybeSingle();
        if (prof != null) {
          profile = Map<String, dynamic>.from(prof as Map);
          expense['user_name'] = profile['name'];
          expense['profiles'] = {'name': profile['name'], 'email': profile['email']};
        }
      }

      // Line items
      final liResp = await _client
          .from('expense_line_items')
          .select('*')
          .eq('expense_id', expenseId);
      expense['line_items'] = (liResp as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      // Attachments
      final attResp = await _client
          .from('attachments')
          .select('*')
          .eq('expense_id', expenseId);
      expense['attachments'] = (attResp as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();

      return ExpenseModel.fromJson(expense);
    } catch (e) {
      print('Error fetching expense by ID: $e');
      return null;
    }
  }

  // Statistics Methods
  static Future<Map<String, dynamic>> getExpenseStats(String userId) async {
    try {
      final response = await _client
          .from('expenses')
          .select('status, total_amount')
          .eq('user_id', userId);

      final expenses = response as List<dynamic>;
      
      double pendingAmount = 0;
      double approvedAmount = 0;
      double rejectedAmount = 0;

      for (final expense in expenses) {
        final amount = (expense['total_amount'] ?? 0).toDouble();
        final status = expense['status'] as String;

        switch (status) {
          case 'submitted':
          case 'under_review':
          case 'verified':
            pendingAmount += amount;
            break;
          case 'approved':
          case 'paid':
            approvedAmount += amount;
            break;
          case 'rejected':
            rejectedAmount += amount;
            break;
        }
      }

      return {
        'pendingAmount': pendingAmount,
        'approvedAmount': approvedAmount,
        'rejectedAmount': rejectedAmount,
        'totalExpenses': expenses.length,
      };
    } catch (e) {
      print('Error fetching expense stats: $e');
      return {
        'pendingAmount': 0.0,
        'approvedAmount': 0.0,
        'rejectedAmount': 0.0,
        'totalExpenses': 0,
      };
    }
  }

  // User Management Methods
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final profilesResponse = await _client
          .from('profiles')
          .select('*')
          .order('created_at', ascending: false);

      final profiles = (profilesResponse as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final userIds = profiles.map((p) => p['user_id'] as String).toList();

      // Fetch roles separately
      Map<String, String> userIdToRole = {};
      if (userIds.isNotEmpty) {
        final rolesResp = await _client
            .from('user_roles')
            .select('user_id, role')
            .inFilter('user_id', userIds);
        for (final r in (rolesResp as List<dynamic>)) {
          final mr = Map<String, dynamic>.from(r as Map);
          userIdToRole[mr['user_id'] as String] = (mr['role'] as String?) ?? 'employee';
        }
      }

      final users = profiles.map((p) {
        p['role'] = userIdToRole[p['user_id'] as String] ?? 'employee';
        return UserModel.fromJson(p);
      }).toList();
      return users;
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  static Future<bool> createUser(String name, String email, String password, AppRole role) async {
    try {
      // 1) Create auth user (this will NOT sign out admin if email confirmation is enabled)
      final signUpResp = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
        },
      );

      final newUser = signUpResp.user;
      if (newUser == null) {
        // Could be awaiting email confirmation; still create profile stub so the app can list the user
        // But without user_id we cannot proceed
        print('Error creating user: user is null after signUp');
        return false;
      }

      final String newUserId = newUser.id;

      // 2) Create profile
      await _client
          .from('profiles')
          .upsert({
            'user_id': newUserId,
            'name': name,
            'email': email,
            'is_active': true,
          });

      // 3) Assign role
      await _client
          .from('user_roles')
          .upsert({
            'user_id': newUserId,
            'role': role.value,
          });

      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    }
  }

  static Future<bool> updateUserStatus(String userId, bool isActive) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive})
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error updating user status: $e');
      return false;
    }
  }

  static Future<bool> updateUserRole(String userId, AppRole role) async {
    try {
      await _client
          .from('user_roles')
          .upsert({
            'user_id': userId,
            'role': role.value,
          });
      return true;
    } catch (e) {
      print('Error updating user role: $e');
      return false;
    }
  }
}
