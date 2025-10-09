import 'attachment_model.dart';
import 'line_item_model.dart';

enum ExpenseStatus {
  draft,
  submitted,
  underReview,
  verified,
  approved,
  rejected,
  paid;

  String get displayName {
    switch (this) {
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

  String get value {
    switch (this) {
      case ExpenseStatus.draft:
        return 'draft';
      case ExpenseStatus.submitted:
        return 'submitted';
      case ExpenseStatus.underReview:
        return 'under_review';
      case ExpenseStatus.verified:
        return 'verified';
      case ExpenseStatus.approved:
        return 'approved';
      case ExpenseStatus.rejected:
        return 'rejected';
      case ExpenseStatus.paid:
        return 'paid';
    }
  }

  static ExpenseStatus fromString(String value) {
    switch (value) {
      case 'draft':
        return ExpenseStatus.draft;
      case 'submitted':
        return ExpenseStatus.submitted;
      case 'under_review':
        return ExpenseStatus.underReview;
      case 'verified':
        return ExpenseStatus.verified;
      case 'approved':
        return ExpenseStatus.approved;
      case 'rejected':
        return ExpenseStatus.rejected;
      case 'paid':
        return ExpenseStatus.paid;
      default:
        return ExpenseStatus.draft;
    }
  }
}

class ExpenseModel {
  final String id;
  final String userId;
  final String title;
  final DateTime? tripStart;
  final DateTime? tripEnd;
  
  // Alias properties for compatibility
  DateTime? get startDate => tripStart;
  DateTime? get endDate => tripEnd;
  final String destination;
  final String purpose;
  final String status;
  final double totalAmount;
  final String? assignedEngineerId;
  final String? adminComment;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userName;
  final String? engineerName;
  final List<LineItemModel> lineItems;
  final List<AttachmentModel> attachments;

  ExpenseModel({
    required this.id,
    required this.userId,
    required this.title,
    this.tripStart,
    this.tripEnd,
    required this.destination,
    required this.purpose,
    required this.status,
    required this.totalAmount,
    this.assignedEngineerId,
    this.adminComment,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.engineerName,
    this.lineItems = const [],
    this.attachments = const [],
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      tripStart: json['trip_start'] != null 
          ? DateTime.parse(json['trip_start']) 
          : null,
      tripEnd: json['trip_end'] != null 
          ? DateTime.parse(json['trip_end']) 
          : null,
      destination: json['destination'] ?? '',
      purpose: json['purpose'] ?? '',
      status: json['status'] ?? 'draft',
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      assignedEngineerId: json['assigned_engineer_id'],
      adminComment: json['admin_comment'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      userName: json['user_name'] ?? json['profiles']?['name'],
      engineerName: json['engineer_name'],
      lineItems: (json['line_items'] as List<dynamic>?)
          ?.map((item) => LineItemModel.fromJson(item))
          .toList() ?? [],
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((item) => AttachmentModel.fromJson(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'trip_start': tripStart?.toIso8601String(),
      'trip_end': tripEnd?.toIso8601String(),
      'destination': destination,
      'purpose': purpose,
      'status': status,
      'total_amount': totalAmount,
      'assigned_engineer_id': assignedEngineerId,
      'admin_comment': adminComment,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? tripStart,
    DateTime? tripEnd,
    String? destination,
    String? purpose,
    String? status,
    double? totalAmount,
    String? assignedEngineerId,
    String? adminComment,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? engineerName,
    List<LineItemModel>? lineItems,
    List<AttachmentModel>? attachments,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      tripStart: tripStart ?? this.tripStart,
      tripEnd: tripEnd ?? this.tripEnd,
      destination: destination ?? this.destination,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      assignedEngineerId: assignedEngineerId ?? this.assignedEngineerId,
      adminComment: adminComment ?? this.adminComment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      engineerName: engineerName ?? this.engineerName,
      lineItems: lineItems ?? this.lineItems,
      attachments: attachments ?? this.attachments,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isUnderReview => status == 'under_review';
  bool get isVerified => status == 'verified';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPaid => status == 'paid';

  String get statusDisplayName {
    switch (status) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      case 'under_review':
        return 'Under Review';
      case 'verified':
        return 'Verified';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'paid':
        return 'Paid';
      default:
        return 'Unknown';
    }
  }
}
