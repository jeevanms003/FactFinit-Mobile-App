# FactFinit Frontend

## Installation
```bash
flutter pub get
```

## Configuration

Update API endpoint in `lib/constants.dart`:
```dart
class Constants {
  static const String apiBaseUrl = 'https://your-backend-url.com';
}
```

## Run
```bash
# Development
flutter run

# Build APK
flutter build apk --release

# Build iOS
flutter build ios --release
```

## Features

### 1. Authentication
- Login and Register screens
- JWT token-based authentication
- Auto-logout on token expiration

### 2. Video Verification
- YouTube and Instagram URL support
- Financial content detection
- AI-powered fact-checking
- Normalized transcript display
- Copy transcript to clipboard

### 3. History
- View all verified videos
- Pagination support (10 items/page)
- Full fact-check details
- Source links (clickable)

### 4. URL Sharing
- Share YouTube/Instagram links from other apps
- Automatic verification on share

### 5. Theme Toggle
- Light/Dark mode support
- Poppins font family

## Screens

### Login/Register (`lib/screens/login_screen.dart`)
```dart
// Navigate after login
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const HomeScreen()),
);
```

### Home (`lib/main.dart` - HomeScreen)
- Video URL input form
- Real-time verification
- Fact-check results display

### History (`lib/screens/history_screen.dart`)
```dart
// Navigate to history
Navigator.pushNamed(context, '/history');
```

## API Integration

### Verify Video
```dart
final response = await _apiService.fetchTranscript(
  videoURL: 'https://youtube.com/watch?v=...',
  context: context,
);
```

**Response:**
```dart
VerifyResponse(
  message: 'Transcript processed successfully',
  data: VerifyData(
    videoURL: '...',
    platform: 'YouTube',
    normalizedTranscript: '...',
    isFinancial: true,
    factCheck: FactCheck(
      claims: [...],
      sources: [...]
    )
  )
)
```

### Login
```dart
final response = await _apiService.login(
  email: 'user@example.com',
  password: 'password123',
);
```

### Register
```dart
final response = await _apiService.register(
  email: 'user@example.com',
  password: 'password123',
);
```

### Fetch History
```dart
final response = await _apiService.fetchHistory(
  context: context,
  page: 1,
  limit: 10,
);
```

## State Management

### AuthProvider
```dart
// Login
Provider.of<AuthProvider>(context, listen: false).login(token);

// Logout
Provider.of<AuthProvider>(context, listen: false).logout();

// Check auth status
final isAuth = Provider.of<AuthProvider>(context).isAuthenticated;
```

### ThemeProvider
```dart
// Toggle theme
Provider.of<ThemeProvider>(context, listen: false).toggleTheme();

// Get current theme
final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
```

## Assets

Place logo at:
```
assets/images/logo.png
```

Place fonts at:
```
fonts/Poppins-Regular.ttf
fonts/Poppins-Medium.ttf
fonts/Poppins-SemiBold.ttf
fonts/Poppins-Bold.ttf
```

## Android Configuration

### Permissions (`android/app/src/main/AndroidManifest.xml`)
- `INTERNET` - Network access
- `QUERY_ALL_PACKAGES` - App linking

### Intent Filters
- `ACTION_SEND` - Receive shared URLs
- `ACTION_VIEW` - Open http/https links

## Dependencies
```yaml
dependencies:
  provider: ^6.1.2           # State management
  http: ^1.2.2               # API calls
  flutter_spinkit: ^5.2.1    # Loading indicators
  shimmer: ^3.0.0            # Skeleton loading
  flutter_animate: ^4.5.0    # Animations
  url_launcher: ^6.3.1       # Open URLs
  intl: ^0.19.0              # Date formatting
  receive_intent: ^0.2.7     # Handle shared URLs
  shared_preferences: ^2.5.3 # Local storage
```

## Error Handling
```dart
try {
  final response = await _apiService.fetchTranscript(...);
  // Handle response
} catch (e) {
  setState(() {
    _errorMessage = 'Failed to fetch data. Please try again.';
  });
}
```

## Responsive Design
```dart
final isWideScreen = MediaQuery.of(context).size.width > 600;
final padding = isWideScreen ? MediaQuery.of(context).size.width * 0.15 : 24.0;
```

## Routes
```dart
routes: {
  '/home': (context) => const HomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/history': (context) => const HistoryScreen(),
}
```

## Platform Support

- ✅ Android
- ✅ iOS
- ❌ Web (not configured)

## Minimum SDK

- Android: 21 (Lollipop 5.0)
- iOS: Check `ios/Podfile` for minimum version

## Notes

- JWT tokens stored in memory (cleared on app restart)
- History cached for 7 days on backend
- Instagram transcripts not yet supported
- Shared URLs auto-verified on app open
