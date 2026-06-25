# Finance Tracker - Malaysian Tax Integrated

A robust Flutter application designed for Malaysian users to track personal finances with automated tax relief calculations.

## 🚀 Features

- **MVVM Architecture**: Clean separation of concerns using the Model-View-ViewModel pattern.
- **Multi-User System**: Secure authentication powered by Firebase Auth.
- **Real-time Synchronization**: Data persistence using Cloud Firestore with strict user isolation.
- **Malaysian Tax Integration**: 
    - Automated tax-deductible status for expenses based on Malaysian LHDN categories.
    - Visual feedback (Green/Red) for tax-eligible items.
    - Customizable Tax Relief Profile in user settings.
- **Comprehensive Financial Tracking**:
    - Income and Expense logging.
    - Monthly comparison charts.
    - Savings and Tax Reclaimable summaries.
- **Security**: Password reset flow integrated within the app and login screen.

## 🏗️ Architecture

The project follows the **MVVM (Model-View-ViewModel)** pattern with **Provider** for state management:

- **Models**: Plain Dart classes for data structures (`UserModel`, `ExpenseRecord`, `IncomeRecord`).
- **Views**: UI components decoupled from business logic.
- **ViewModels**: Logic handlers that bridge Models and Views (`HomeViewModel`, `AddExpenseViewModel`, etc.).
- **Services**: Abstracted data access layers (`AuthService`, `FinanceService`).

## 🛠️ Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase Authentication, Cloud Firestore
- **State Management**: Provider

## 🏁 Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Java 17 (Required for Android build)
- Firebase Account

### Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/CiFeR-01/finance_tracker.git
   cd finance_tracker
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**:
   - Create a new project in [Firebase Console](https://console.firebase.google.com/).
   - Add Android/iOS apps.
   - Download and place `google-services.json` in `android/app/`.
   - Enable **Email/Password** authentication.
   - Create a **Firestore Database**.

4. **Run the App**:
   ```bash
   flutter run
   ```
