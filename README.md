# Peer Support App

A comprehensive peer support application built with Flutter and Firebase, designed to facilitate community-based support, discussions, and real-time communication among users.

##  Features

### Core Functionality
- **User Authentication**: Secure Firebase Authentication with email/password
- **Community Management**: Create, join, and moderate communities
- **Post System**: Create, view, and interact with posts across communities
- **Real-time Chat**: Direct messaging between users with Firebase Firestore
- **User Profiles**: Comprehensive user profiles with role-based permissions
- **Search & Discovery**: Find users, communities, and posts
- **Admin Panel**: Advanced moderation tools for administrators

### User Roles & Permissions
- **User**: Basic community member with posting and commenting capabilities
- **Moderator**: Can moderate specific communities, delete comments
- **Admin**: Full moderation capabilities including post deletion and user management
- **Super Admin**: Complete system administration with role management

### Community Features
- Community creation and management
- Member management and moderation
- Community-specific post feeds
- Community discovery and joining

### Communication Features
- Real-time chat with individual users
- Conversation history and unread message tracking
- User online/offline status
- Message notifications

##  Architecture

### Technology Stack
- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Real-time Updates**: Firestore streams

### Project Structure
```
lib/
├── main.dart                 # App entry point and configuration
├── models/                   # Data models
│   ├── user_model.dart      # User data and role management
│   ├── post.dart           # Post data structure
│   ├── community.dart      # Community data structure
│   ├── chat_message.dart   # Chat message model
│   ├── chat_conversation.dart # Chat conversation model
│   └── chat_user.dart      # Chat user model
├── services/                # Business logic and API calls
│   ├── auth_service.dart   # Authentication management
│   ├── post_service.dart   # Post CRUD operations
│   ├── chat_service.dart   # Real-time chat functionality
│   ├── community_service.dart # Community management
│   ├── user_manager.dart   # User state management
│   └── admin_service.dart  # Admin functionality
├── screens/                 # UI screens
│   ├── auth/               # Authentication screens
│   ├── chat/               # Chat-related screens
│   ├── post/               # Post creation and feed
│   ├── admin/              # Admin dashboard
│   └── profile/            # User profile screens
├── navigation/              # App navigation
├── widgets/                 # Reusable UI components
└── utils/                   # Utilities and constants
```

##  Setup Instructions

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Firebase project setup
- Android Studio / VS Code

### Installation

1. **Clone the repository**
   ```bash
   git clone <https://github.com/NsengaNigel/peer-support_app.git>
   cd peer-support_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/u/0/project/peer-support-app-2cf36/overview?pli=1/)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Download `google-services.json` for Android
   - Download `GoogleService-Info.plist` for iOS
   - Place configuration files in appropriate directories

4. **Update Firebase Configuration**
   - Replace Firebase configuration in `lib/main.dart` with your project settings
   - Update `lib/firebase_options.dart` with your Firebase project details

5. **Run the application**
   ```bash
   flutter run
   ```

##  Usage Guide

### For Users

1. **Registration & Login**
   - Create an account with email and password
   - Verify email address
   - Login with credentials

2. **Exploring Communities**
   - Browse available communities
   - Join communities of interest
   - View community-specific posts

3. **Creating Content**
   - Create posts in joined communities
   - Add comments to existing posts
   - Save posts for later reading

4. **Chatting**
   - Search for users to chat with
   - Send direct messages
   - View conversation history

### For Moderators

1. **Community Moderation**
   - Moderate posts and comments
   - Remove inappropriate content
   - Manage community members

2. **User Management**
   - View user profiles
   - Manage user permissions within communities

### For Administrators

1. **System Administration**
   - Access admin dashboard
   - Manage all users and communities
   - System-wide moderation tools
   - User role management

2. **Analytics & Monitoring**
   - View system statistics
   - Monitor user activity
   - Track community growth

##  Configuration

### Firebase Setup
The app requires the following Firebase services:

1. **Authentication**
   - Email/Password authentication enabled
   - User profile management

2. **Cloud Firestore**
   - Collections: `users`, `posts`, `communities`, `messages`, `conversations`, `chat_users`
   - Security rules configured for role-based access

3. **Security Rules**
   ```javascript

   rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // This rule allows anyone with your Firestore database reference to view, edit,
    // and delete all data in your Firestore database. It is useful for getting
    // started, but it is configured to expire after 30 days because it
    // leaves your app open to attackers. At that time, all client
    // requests to your Firestore database will be denied.
    //
    // Make sure to write security rules for your app before that time, or else
    // all client requests to your Firestore database will be denied until you Update
    // your rules
    match /{document=**} {
      allow read, write: if request.time < timestamp.date(2025, 8, 9);
    }
  }
}
   ```

### Environment Variables
- Firebase configuration is embedded in the app
- For production, consider using environment-specific configurations

##  Deployment

### Android
1. Build APK: `flutter build apk`
2. Build App Bundle: `flutter build appbundle`
3. Deploy to Google Play Store

### iOS
1. Build iOS app: `flutter build ios`
2. Archive and upload to App Store Connect

### Web
1. Build web version: `flutter build web`
2. Deploy to Firebase Hosting or other web hosting

##  Security Features

- **Role-based Access Control**: Different permission levels for users, moderators, and admins
- **Content Moderation**: Tools for managing inappropriate content
- **User Verification**: Email verification system
- **Ban System**: Temporary and permanent user bans
- **Secure Authentication**: Firebase Auth with proper session management

##  Performance Optimizations

- **Lazy Loading**: Posts and content loaded on demand
- **Caching**: Local caching for improved performance
- **Stream Management**: Efficient real-time data streams
- **Image Optimization**: Optimized image loading and caching
- **Background Processing**: Non-blocking UI operations

##  Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart
```


##  Contributors

1. Nsenga Cosmas Nigel <n.nigel@alustudent.com>
2. Thierry Shyaka <t.shyaka1@alustudent.com>
3. Carine Umugabekazi <c.umugabeka@alustudent.com>
4. Ashina Cecilia Wesebebe <a.wesebebe@alustudent.com>
5. Agnes Adepa Berko <a.berko1@alustudent.com>

##  Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request
