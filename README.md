# 📱 ChatApp - A Real-Time Flutter Messaging App

ChatApp is a modern, feature-rich messaging application built with **Flutter** and **Firebase**. It offers a seamless real-time communication experience with a focus on clean UI and robust backend integration.

---

## 🚀 Features

### 🔐 Authentication
*   **Email & Password**: Standard login and signup flow.
*   **Phone Authentication**: Secure login using OTP (One-Time Password) via Firebase Phone Auth.
*   **Password Recovery**: Forgot password functionality for email-based accounts.
*   **Persistent Login**: Automatically detects and restores user sessions.

### 💬 Messaging
*   **User Search**: Find other users by their email or username.
*   **Real-time Chatting**: Instant message delivery and updates powered by Cloud Firestore.
*   **Push Notifications**: Receive alerts for new messages even when the app is in the background.

### 🎨 UI/UX
*   **Premium "About Us" Page**: A beautifully designed page showcasing the developer and mission.
*   **Custom UI Utilities**: Consistent styling with a custom `UiHelper` class for buttons, text fields, and alerts.
*   **Responsive Design**: Optimized for various screen sizes.

### 👤 Profile
*   **Profile Management**: Option to upload profile pictures to Firebase Storage.

---

## 🛠️ Tech Stack

*   **Frontend**: [Flutter](https://flutter.dev/) (Dart)
*   **Backend**: [Firebase](https://firebase.google.com/)
    *   **Firebase Auth**: For secure user authentication.
    *   **Cloud Firestore**: For real-time database and chat history.
    *   **Firebase Storage**: For storing profile pictures and media.
    *   **Firebase Messaging (FCM)**: For cross-platform push notifications.
*   **State Management**: `StatefulWidget` / `setState` (Native Flutter).

---

## 📂 Project Structure

```text
lib/
├── aboutuspage.dart        # Premium About Us screen
├── chat_room.dart          # Real-time chat interface
├── checkuser.dart          # Auth state management / entry logic
├── forgotpassword.dart     # Password reset screen
├── home_page.dart          # Main dashboard & contact list
├── loginpage.dart          # User login screen
├── main.dart               # App entry point & Firebase initialization
├── notificationservices.dart # Firebase Messaging setup
├── otpscreen.dart          # OTP verification screen
├── phoneauth.dart          # Phone number entry for OTP
├── search_page.dart        # User search functionality
├── signuppage.dart         # User registration screen
└── ui_helper.dart          # Common UI components & reusable widgets
```

---

## ⚙️ Getting Started

### Prerequisites
*   Flutter SDK installed ([Guide](https://docs.flutter.dev/get-started/install))
*   Firebase Project set up on the [Firebase Console](https://console.firebase.google.com/)

### Installation

1.  **Clone the repository**:
    ```bash
    git clone https://github.com/ShubhangDoley/ChatApp.git
    cd ChatApp
    ```

2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**:
    *   Follow the [FlutterFire guide](https://firebase.flutter.dev/docs/overview) to configure your app for Android and iOS.
    *   Add your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) to the respective directories.

4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 👷 Developer

**Shubhang Doley**
*   [GitHub](https://github.com/ShubhangDoley)
*   Made with ❤️ in Flutter

---

## 📜 License
This project is for educational purposes. Feel free to use and modify it!
## use this link to download and use on Android devices: https://github.com/ShubhangDoley/ChatApp/releases/download/v1.0.0/app-release.apk
