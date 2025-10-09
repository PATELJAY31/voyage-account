# Expense Manager Mobile App

A Flutter mobile application for managing employee expenses, built to complement the web-based expense management system.

## Features

### Core Functionality
- **User Authentication**: Secure login with role-based access control
- **Expense Management**: Create, view, edit, and track expense claims
- **Receipt Upload**: Upload and manage receipt images
- **Role-based Access**: Different interfaces for Admin, Engineer, and Employee roles
- **Real-time Updates**: Live synchronization with Supabase backend

### User Roles
- **Employee**: Create and manage personal expense claims
- **Engineer**: Review and verify assigned expenses
- **Admin**: Full system access including user management and expense approval

### Key Screens
- **Splash Screen**: App initialization and authentication check
- **Login Screen**: Secure user authentication
- **Dashboard**: Role-based overview with statistics and quick actions
- **Expense Management**: Create, edit, and view expense details
- **Admin Panel**: User and expense management for administrators

## Technical Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **GoRouter**: Navigation and routing
- **Material Design 3**: Modern UI components

### Backend Integration
- **Supabase**: Authentication, database, and file storage
- **REST API**: Real-time data synchronization
- **Row Level Security**: Secure data access

### Key Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2                    # State management
  supabase_flutter: ^2.8.0           # Backend integration
  go_router: ^14.6.2                 # Navigation
  image_picker: ^1.1.2               # Camera and gallery access
  cached_network_image: ^3.4.1       # Image caching
  intl: ^0.19.0                      # Date and currency formatting
  uuid: ^4.5.1                       # Unique ID generation
```

## Project Structure

```
lib/
├── constants/           # App constants and configuration
├── models/             # Data models
├── providers/          # State management providers
├── services/           # API and backend services
├── screens/            # UI screens
│   ├── auth/          # Authentication screens
│   ├── dashboard/     # Dashboard screens
│   ├── expenses/      # Expense management screens
│   ├── admin/         # Admin functionality
│   └── engineer/      # Engineer functionality
├── widgets/            # Reusable UI components
├── utils/              # Utility functions
└── main.dart          # App entry point
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.6.0 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Supabase account and project

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bill
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Update `lib/constants/app_constants.dart` with your Supabase credentials:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuration

### Supabase Setup
1. Create a new Supabase project
2. Run the database migrations from the main project
3. Set up storage buckets for receipt images
4. Configure Row Level Security policies
5. Update the app constants with your project credentials

### Environment Variables
The app uses the following configuration:
- Supabase URL and API key
- Storage bucket names
- API endpoints
- App version and metadata

## Key Features Implementation

### Authentication Flow
1. **Splash Screen**: Checks existing authentication state
2. **Login**: Email/password authentication with Supabase
3. **Role Detection**: Automatic role-based routing after login
4. **Session Management**: Persistent authentication state

### Expense Management
1. **Create Expense**: Multi-step form with line items and attachments
2. **File Upload**: Camera and gallery integration for receipts
3. **Status Tracking**: Real-time status updates across all user roles
4. **Approval Workflow**: Role-based approval and rejection system

### Data Synchronization
- Real-time updates using Supabase subscriptions
- Offline capability with local caching
- Conflict resolution for concurrent edits
- Optimistic UI updates for better user experience

## Development Guidelines

### Code Structure
- **Models**: Immutable data classes with JSON serialization
- **Providers**: State management with ChangeNotifier pattern
- **Services**: API calls and business logic separation
- **Widgets**: Reusable UI components with consistent styling

### State Management
- Use Provider for global state management
- Local state for UI-specific concerns
- Clear separation between data and presentation layers

### Error Handling
- Comprehensive error handling with user-friendly messages
- Network error handling with retry mechanisms
- Validation errors with inline feedback

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Contributing

1. Follow Flutter and Dart style guidelines
2. Write comprehensive tests for new features
3. Update documentation for API changes
4. Use meaningful commit messages
5. Test on multiple devices and screen sizes

## Support

For issues and questions:
1. Check the main project documentation
2. Review Supabase configuration
3. Verify network connectivity
4. Check device permissions (camera, storage)

## License

This project is part of the Expense Management System and follows the same licensing terms.