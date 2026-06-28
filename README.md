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

## 📁 Project Structure

The project is organized into a modular structure to ensure maintainability and scalability:

- **`lib/`**: Contains the core Dart source code.
  - **`models/`**: Data classes representing the application's domain models.
  - **`services/`**: Business logic for interacting with external services (Firebase, local storage, etc.).
  - **`viewmodels/`**: State management logic and UI-independent business logic.
  - **`views/`**: The visual layer consisting of Flutter widgets and screens.
  - **`widgets/`**: Reusable UI components shared across multiple views.
  - **`main.dart`**: The application entry point and root configuration.
- **`assets/`**: Images, fonts, and other static resources.

## 🛣️ Roadmap & Future Enhancements

We are continuously working to improve the Finance Tracker. Future updates will include:

- [ ] **Data Export**: Support for exporting financial reports in PDF and Excel formats.
- [ ] **Expense Categories**: Advanced categorization and tagging for better insights.
- [ ] **Budgeting**: Tools to set and monitor monthly budgets for different categories.
- [ ] **Notifications**: Reminders for recurring bills and tax filing deadlines.
- [ ] **Multi-currency Support**: For users who manage finances across different regions.

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
