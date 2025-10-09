class AttachmentModel {
  final String id;
  final String expenseId;
  final String? lineItemId;
  final String fileUrl;
  final String filename;
  final String contentType;
  final String uploadedBy;
  final DateTime createdAt;
  
  // Alias property for compatibility
  DateTime get uploadedAt => createdAt;

  AttachmentModel({
    required this.id,
    required this.expenseId,
    this.lineItemId,
    required this.fileUrl,
    required this.filename,
    required this.contentType,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory AttachmentModel.fromJson(Map<String, dynamic> json) {
    return AttachmentModel(
      id: json['id'] ?? '',
      expenseId: json['expense_id'] ?? '',
      lineItemId: json['line_item_id'],
      fileUrl: json['file_url'] ?? '',
      filename: json['filename'] ?? '',
      contentType: json['content_type'] ?? '',
      uploadedBy: json['uploaded_by'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'line_item_id': lineItemId,
      'file_url': fileUrl,
      'filename': filename,
      'content_type': contentType,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AttachmentModel copyWith({
    String? id,
    String? expenseId,
    String? lineItemId,
    String? fileUrl,
    String? filename,
    String? contentType,
    String? uploadedBy,
    DateTime? createdAt,
  }) {
    return AttachmentModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      lineItemId: lineItemId ?? this.lineItemId,
      fileUrl: fileUrl ?? this.fileUrl,
      filename: filename ?? this.filename,
      contentType: contentType ?? this.contentType,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';
  bool get isDocument => contentType.contains('word') || contentType.contains('document');

  String get fileIcon {
    if (isImage) return '🖼️';
    if (isPdf) return '📄';
    if (isDocument) return '📝';
    return '📎';
  }

  String get fileSizeDisplay {
    // This would need to be calculated from actual file size
    // For now, return a placeholder
    return 'Unknown size';
  }
}
