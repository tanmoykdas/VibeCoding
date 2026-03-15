# Moneyco – Personal Finance Tracker

> A modern personal money management app built with Flutter

Software Development I (Fifth Semester)  
**This project was developed with assistance from AI tools**

---

## Application Screenshots

<p align="center">
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-25.jpg" width="200" alt="Home Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-15_17-49-28.jpg" width="200" alt="Add Transaction Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-29.jpg" width="200" alt="Profile Screen"/>
	<img src="Moneyco/assets/screenshots/photo_2026-03-16_03-11-39.jpg" width="200" alt="Profile Dark Mode Screen"/>
</p>

---

## About the Project

Moneyco is a mobile application that helps users track income, expenses, and budget goals in one place. Users can continue in guest mode with local storage or sign in with Google to sync data with Firebase.

### Problem Statement
- Students and individuals need a simple way to track daily finances
- Manual expense tracking is inconsistent and hard to maintain
- Many users need both offline usage and cloud sync
- Budget overspending often happens without timely alerts

### Solution
- Simple income/expense transaction flow
- Local-first guest mode with optional Google sign-in
- Real-time Firestore sync for signed-in users
- Budget monitoring with monthly and daily spending alerts

---

## Core Features

### Authentication System
- Google sign-in and sign-out
- Guest mode support
- Profile details (name, email, photo)

### Transaction Management
- Add income and expense transactions
- Category, amount, note, and date support
- Recent transactions on home dashboard
- Delete transactions

### Analytics
- Monthly income vs expense bar chart
- Expense distribution pie chart
- Balance trend chart

### Budget & Alerts
- Set monthly spending limit
- Set daily expense goal
- Alert on 90% monthly usage and limit exceed
- Alert when daily goal is exceeded

### App Experience
- Dark and light mode
- Offline connectivity awareness
- Pull-to-refresh and smooth animated UI

---

## Technology Stack

| Component | Technology |
|-----------|-----------|
| **Framework** | Flutter 3.x |
| **Language** | Dart 3.x |
| **Backend** | Firebase Authentication + Cloud Firestore |
| **State Management** | Provider |
| **Charts** | fl_chart |
| **Platform Support** | Android, iOS, Web, Desktop |

### Dependencies
```yaml
flutter:
	sdk: flutter
firebase_core: ^3.13.1
firebase_auth: ^5.5.3
cloud_firestore: ^5.6.6
google_sign_in: ^6.2.2
firebase_crashlytics: ^4.3.6
provider: ^6.1.5
fl_chart: ^0.70.2
shared_preferences: ^2.5.3
flutter_secure_storage: ^9.2.4
intl: ^0.20.2
google_fonts: ^6.2.1
uuid: ^4.5.1
connectivity_plus: ^6.1.4
shimmer: ^3.0.0
```

---

## Project Structure

```text
Moneyco/
├── lib/
│   ├── core/
│   ├── data/
│   ├── domain/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── widgets/
│   ├── app.dart
│   └── main.dart
├── assets/
├── android/
├── ios/
├── web/
├── linux/
├── macos/
├── windows/
└── test/
```

---

## Setup Instructions

### Prerequisites
- Flutter SDK 3.0+
- Dart SDK 3.0+
- Android Studio / Xcode / VS Code
- Firebase project

### Installation Steps

1. Clone the repository
```bash
git clone <your-repository-url>
cd VibeCoding/Moneyco
```

2. Install dependencies
```bash
flutter pub get
```

3. Firebase configuration
	 - Create Firebase project in Firebase Console
	 - Enable Authentication (Google provider)
	 - Enable Cloud Firestore
	 - Place `google-services.json` in `android/app/`
	 - Place `GoogleService-Info.plist` in `ios/Runner/`

4. Run the app
```bash
flutter run
```

---

## Database Schema

### User Transactions
```text
users/{userId}/transactions/{transactionId}
├── amount: number
├── type: "income" | "expense"
├── category: string
├── note: string? (optional, max 160)
└── date: timestamp
```

### User Budget Settings
```text
users/{userId}/settings/monthlyLimit
└── value: number

users/{userId}/settings/dailyGoal
└── value: number
```

---

## Security

Firestore rules ensure:
- Only signed-in owners can read/write their own data
- Transaction payload is validated (keys, type, sizes, positive values)
- Budget settings are validated (numeric, non-negative)
- All other document paths are denied

```javascript
rules_version = '2';
service cloud.firestore {
	match /databases/{database}/documents {
		function isSignedIn() {
			return request.auth != null;
		}

		function isOwner(userId) {
			return isSignedIn() && request.auth.uid == userId;
		}

		match /users/{userId}/transactions/{transactionId} {
			allow read, delete: if isOwner(userId);
			allow create, update: if isOwner(userId);
		}

		match /users/{userId}/settings/{settingId} {
			allow read, delete: if isOwner(userId);
			allow create, update: if isOwner(userId);
		}
	}
}
```

---

## Testing

Run tests:
```bash
flutter test
flutter test --coverage
```

Current test files:
- `widget_test.dart`

---

## Development Status

### Completed
- App architecture with clean folder separation
- Authentication flow with Google sign-in + guest mode
- Transaction CRUD and analytics dashboard
- Budget limits/goals and alert notifications
- Dark/light theme support

### In Progress
- More automated tests
- UX polish and performance refinements

### Planned Features
- Export reports (PDF/CSV)
- Advanced filtering and search
- Recurring transactions
- Push notifications

---

## License

Educational project developed for Software Development I course.  
For academic and educational purposes only.

---

## Developer

**Tanmoy Kumar Das**  
Software Development I (Fifth Semester)

**GitHub:** [@tanmoykdas](https://github.com/tanmoykdas)

---

## Acknowledgments

- AI tools for development assistance
- Firebase for backend infrastructure
- Flutter framework
- Course instructors and mentors
