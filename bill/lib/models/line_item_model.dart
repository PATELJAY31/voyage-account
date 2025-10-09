enum ExpenseCategory {
  travel,
  lodging,
  food,
  transport,
  officeSupplies,
  software,
  utilities,
  marketing,
  training,
  healthWellness,
  equipment,
  mileage,
  internetPhone,
  entertainment,
  professionalServices,
  rent,
  other;

  String get displayName {
    switch (this) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.lodging:
        return 'Lodging';
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.officeSupplies:
        return 'Office Supplies';
      case ExpenseCategory.software:
        return 'Software';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.marketing:
        return 'Marketing';
      case ExpenseCategory.training:
        return 'Training';
      case ExpenseCategory.healthWellness:
        return 'Health & Wellness';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.mileage:
        return 'Mileage';
      case ExpenseCategory.internetPhone:
        return 'Internet & Phone';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.professionalServices:
        return 'Professional Services';
      case ExpenseCategory.rent:
        return 'Rent';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get value {
    switch (this) {
      case ExpenseCategory.travel:
        return 'travel';
      case ExpenseCategory.lodging:
        return 'lodging';
      case ExpenseCategory.food:
        return 'food';
      case ExpenseCategory.transport:
        return 'transport';
      case ExpenseCategory.officeSupplies:
        return 'office_supplies';
      case ExpenseCategory.software:
        return 'software';
      case ExpenseCategory.utilities:
        return 'utilities';
      case ExpenseCategory.marketing:
        return 'marketing';
      case ExpenseCategory.training:
        return 'training';
      case ExpenseCategory.healthWellness:
        return 'health_wellness';
      case ExpenseCategory.equipment:
        return 'equipment';
      case ExpenseCategory.mileage:
        return 'mileage';
      case ExpenseCategory.internetPhone:
        return 'internet_phone';
      case ExpenseCategory.entertainment:
        return 'entertainment';
      case ExpenseCategory.professionalServices:
        return 'professional_services';
      case ExpenseCategory.rent:
        return 'rent';
      case ExpenseCategory.other:
        return 'other';
    }
  }

  static ExpenseCategory fromString(String value) {
    switch (value) {
      case 'travel':
        return ExpenseCategory.travel;
      case 'lodging':
        return ExpenseCategory.lodging;
      case 'food':
        return ExpenseCategory.food;
      case 'transport':
        return ExpenseCategory.transport;
      case 'office_supplies':
        return ExpenseCategory.officeSupplies;
      case 'software':
        return ExpenseCategory.software;
      case 'utilities':
        return ExpenseCategory.utilities;
      case 'marketing':
        return ExpenseCategory.marketing;
      case 'training':
        return ExpenseCategory.training;
      case 'health_wellness':
        return ExpenseCategory.healthWellness;
      case 'equipment':
        return ExpenseCategory.equipment;
      case 'mileage':
        return ExpenseCategory.mileage;
      case 'internet_phone':
        return ExpenseCategory.internetPhone;
      case 'entertainment':
        return ExpenseCategory.entertainment;
      case 'professional_services':
        return ExpenseCategory.professionalServices;
      case 'rent':
        return ExpenseCategory.rent;
      default:
        return ExpenseCategory.other;
    }
  }
}

class LineItemModel {
  final String id;
  final String expenseId;
  final DateTime date;
  final String category;
  final double amount;
  final String description;

  LineItemModel({
    required this.id,
    required this.expenseId,
    required this.date,
    required this.category,
    required this.amount,
    required this.description,
  });

  factory LineItemModel.fromJson(Map<String, dynamic> json) {
    return LineItemModel(
      id: json['id'] ?? '',
      expenseId: json['expense_id'] ?? '',
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      category: json['category'] ?? 'other',
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expense_id': expenseId,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'description': description,
    };
  }

  LineItemModel copyWith({
    String? id,
    String? expenseId,
    DateTime? date,
    String? category,
    double? amount,
    String? description,
  }) {
    return LineItemModel(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
    );
  }

  String get categoryDisplayName {
    switch (category) {
      case 'travel':
        return 'Travel';
      case 'lodging':
        return 'Lodging';
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'office_supplies':
        return 'Office Supplies';
      case 'software':
        return 'Software';
      case 'utilities':
        return 'Utilities';
      case 'marketing':
        return 'Marketing';
      case 'training':
        return 'Training';
      case 'health_wellness':
        return 'Health & Wellness';
      case 'equipment':
        return 'Equipment';
      case 'mileage':
        return 'Mileage';
      case 'internet_phone':
        return 'Internet & Phone';
      case 'entertainment':
        return 'Entertainment';
      case 'professional_services':
        return 'Professional Services';
      case 'rent':
        return 'Rent';
      default:
        return 'Other';
    }
  }

  String get categoryIcon {
    switch (category) {
      case 'travel':
        return '✈️';
      case 'lodging':
        return '🏨';
      case 'food':
        return '🍽️';
      case 'transport':
        return '🚗';
      case 'office_supplies':
        return '📝';
      case 'software':
        return '💻';
      case 'utilities':
        return '⚡';
      case 'marketing':
        return '📢';
      case 'training':
        return '🎓';
      case 'health_wellness':
        return '🏥';
      case 'equipment':
        return '🔧';
      case 'mileage':
        return '🛣️';
      case 'internet_phone':
        return '📱';
      case 'entertainment':
        return '🎬';
      case 'professional_services':
        return '💼';
      case 'rent':
        return '🏠';
      default:
        return '📄';
    }
  }
}
