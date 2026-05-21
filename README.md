
# UNH RideShare App  

Team A5  

## Overview  

UNH RideShare is a Flutter-based mobile application that allows users to register and log in using phone number authentication (Firebase). The app supports secure OTP-based verification and maintains user sessions across app restarts.

---

## Implemented Features  


- Sign Up Screen  
- OTP Verification Screen  
- Resend Code Timer (30 seconds)  
- OTP Expiry (5 minutes logic handled)  
- Maximum 3 attempts handling  
- User creation in Firestore after successful verification  



- Sign In Screen  
- OTP Verification Screen  
- Session persistence  
- Home Screen  
- Logout functionality  

---

## Firebase Integration  

- Firebase Authentication enabled

- Phone number authentication configured

- Firestore database integrated

- User profile stored after successful OTP verification

---

## Screens Implemented  

- Welcome Screen  
- Sign In Screen  
- Sign Up Screen  
- OTP Verification Screen  
- Home Screen  

---

## Technologies Used  

- Flutter  
- Dart  
- Firebase Authentication  
- Cloud Firestore  
- Android Studio  
- Xcode  

---

## How to Run  

### Prerequisites  

- Flutter SDK installed  
- Dart SDK (included with Flutter)  
- Android Studio (for Android)  
- Xcode on macOS (for iOS)  

### Run on Android  

1. Open Android Studio and start an Android emulator  
   OR connect a physical Android device with USB debugging enabled  
2. Navigate to the project directory  
3. Run the following commands:

```
flutter pub get
flutter run
```

### Run on iOS  

1. Open Xcode and ensure command-line tools are installed  
2. Connect a physical iPhone using a USB cable  
   OR launch the iOS Simulator from Xcode  
3. Navigate to the project directory  
4. Run the following commands:

```
flutter pub get
flutter run
```