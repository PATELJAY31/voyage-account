class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://rrlgtsttazgzhkimksky.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJybGd0c3R0YXpnemhraW1rc2t5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk2ODQ3NjYsImV4cCI6MjA3NTI2MDc2Nn0.GsTbhKCdxhjClWugfC0GQ0sY9KnfCdIiqWkM6zhW0D4';
  
  // App Configuration
  static const String appName = 'Expense Manager';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = 'https://rrlgtsttazgzhkimksky.supabase.co';
  
  // Storage
  static const String receiptsBucket = 'receipts';
  static const String tempFolder = 'temp';
  
  // User Roles
  static const String roleAdmin = 'admin';
  static const String roleEngineer = 'engineer';
  static const String roleEmployee = 'employee';
  
  // Expense Status
  static const String statusDraft = 'draft';
  static const String statusSubmitted = 'submitted';
  static const String statusUnderReview = 'under_review';
  static const String statusVerified = 'verified';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusPaid = 'paid';
  
  // Expense Categories
  static const List<String> expenseCategories = [
    'travel',
    'lodging',
    'food',
    'transport',
    'office_supplies',
    'software',
    'utilities',
    'marketing',
    'training',
    'health_wellness',
    'equipment',
    'mileage',
    'internet_phone',
    'entertainment',
    'professional_services',
    'rent',
    'other',
  ];
  
  // File Upload
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/jpg', 'image/png'];
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

class AppColors {
  static const int primaryColor = 0xFF3B82F6;
  static const int secondaryColor = 0xFF64748B;
  static const int successColor = 0xFF10B981;
  static const int warningColor = 0xFFF59E0B;
  static const int errorColor = 0xFFEF4444;
  static const int backgroundColor = 0xFFF8FAFC;
  static const int surfaceColor = 0xFFFFFFFF;
  static const int textPrimary = 0xFF1E293B;
  static const int textSecondary = 0xFF64748B;
}

class AppStrings {
  // Common
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String view = 'View';
  static const String submit = 'Submit';
  static const String approve = 'Approve';
  static const String reject = 'Reject';
  
  // Auth
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  
  // Expense
  static const String expense = 'Expense';
  static const String expenses = 'Expenses';
  static const String newExpense = 'New Expense';
  static const String expenseDetails = 'Expense Details';
  static const String totalAmount = 'Total Amount';
  static const String category = 'Category';
  static const String description = 'Description';
  static const String date = 'Date';
  static const String amount = 'Amount';
  
  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String pendingAmount = 'Pending Amount';
  static const String approvedAmount = 'Approved Amount';
  static const String rejectedAmount = 'Rejected Amount';
  
  // Validation
  static const String required = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidAmount = 'Please enter a valid amount';
  static const String minAmount = 'Amount must be greater than 0';
}
