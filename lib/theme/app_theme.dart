import 'package:flutter/material.dart';

/// Central design system for the app.
///
/// Every colour, text style, radius and component style should come from here
/// (via `Theme.of(context)` or the [BuildContext] helpers below) instead of
/// being hard-coded in widgets. Light and dark themes are generated from one
/// brand seed colour using Material 3.
class AppTheme {
  AppTheme._();

  /// Brand purple. Everything else in the colour scheme is derived from it.
  static const Color seed = Color(0xFF6A1B9A);

  // Spacing scale (dp).
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 24;
  static const double space6 = 32;

  // Corner radii.
  static const double radiusSmall = 12;
  static const double radiusCard = 20;
  static const double radiusSheet = 28;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusCard),
    );
    final fieldRadius = BorderRadius.circular(radiusSmall);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      extensions: [brightness == Brightness.light ? AppColors.light : AppColors.dark],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall + 4)),
          textStyle: text.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall + 4)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall + 4)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(horizontal: space4, vertical: space4),
        border: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: fieldRadius, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: fieldRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        hintStyle: TextStyle(color: scheme.onSurfaceVariant),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => text.labelMedium?.copyWith(
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSheet)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall + 4)),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: scheme.onSecondaryContainer,
        unselectedLabelColor: scheme.onSurfaceVariant,
        labelStyle: text.labelLarge,
        indicator: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSmall)),
        iconColor: scheme.onSurfaceVariant,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 8,
        borderRadius: BorderRadius.circular(100),
      ),
    );
  }
}

/// Finance-specific colours that Material's [ColorScheme] has no slot for.
///
/// Each colour has a matching `on`/`container` pair so text on a tinted
/// background keeps WCAG AA contrast in both light and dark mode.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color income;
  final Color incomeContainer;
  final Color onIncomeContainer;
  final Color expense;
  final Color expenseContainer;
  final Color onExpenseContainer;
  final Color savings;
  final Color savingsContainer;
  final Color onSavingsContainer;
  final Color tax;
  final Color taxContainer;
  final Color onTaxContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  /// Distinct colours for chart categories, tuned for the current brightness.
  final List<Color> chartPalette;

  const AppColors({
    required this.income,
    required this.incomeContainer,
    required this.onIncomeContainer,
    required this.expense,
    required this.expenseContainer,
    required this.onExpenseContainer,
    required this.savings,
    required this.savingsContainer,
    required this.onSavingsContainer,
    required this.tax,
    required this.taxContainer,
    required this.onTaxContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.chartPalette,
  });

  static const light = AppColors(
    income: Color(0xFF1B7F4B),
    incomeContainer: Color(0xFFD6F5E1),
    onIncomeContainer: Color(0xFF00391C),
    expense: Color(0xFFBA1A1A),
    expenseContainer: Color(0xFFFFDAD6),
    onExpenseContainer: Color(0xFF410002),
    savings: Color(0xFF1E5FA8),
    savingsContainer: Color(0xFFD5E3FF),
    onSavingsContainer: Color(0xFF001B3C),
    tax: Color(0xFF7B3FA0),
    taxContainer: Color(0xFFF3DAFF),
    onTaxContainer: Color(0xFF2E004A),
    warning: Color(0xFF8A5100),
    warningContainer: Color(0xFFFFDCBE),
    onWarningContainer: Color(0xFF2C1600),
    chartPalette: [
      Color(0xFF6A4FC2),
      Color(0xFF2F8FD8),
      Color(0xFFE0861C),
      Color(0xFF1FA48C),
      Color(0xFFD9467A),
      Color(0xFF8E9A1B),
      Color(0xFF9C5ACF),
      Color(0xFF3E6E8E),
      Color(0xFFB8673A),
      Color(0xFF5B7F3A),
    ],
  );

  static const dark = AppColors(
    income: Color(0xFF7FDBA4),
    incomeContainer: Color(0xFF1C3A2A),
    onIncomeContainer: Color(0xFFD6F5E1),
    expense: Color(0xFFFFB4AB),
    expenseContainer: Color(0xFF4A2220),
    onExpenseContainer: Color(0xFFFFDAD6),
    savings: Color(0xFFA7C8FF),
    savingsContainer: Color(0xFF1E3250),
    onSavingsContainer: Color(0xFFD5E3FF),
    tax: Color(0xFFE3B5FF),
    taxContainer: Color(0xFF3D2852),
    onTaxContainer: Color(0xFFF3DAFF),
    warning: Color(0xFFFFB86E),
    warningContainer: Color(0xFF47300F),
    onWarningContainer: Color(0xFFFFDCBE),
    chartPalette: [
      Color(0xFFB4A1FF),
      Color(0xFF7CC4FF),
      Color(0xFFFFB866),
      Color(0xFF6ADBC3),
      Color(0xFFFF8FB4),
      Color(0xFFCAD65A),
      Color(0xFFD7A6FF),
      Color(0xFF8DB8D6),
      Color(0xFFF0A882),
      Color(0xFFA1C97E),
    ],
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      income: l(income, other.income),
      incomeContainer: l(incomeContainer, other.incomeContainer),
      onIncomeContainer: l(onIncomeContainer, other.onIncomeContainer),
      expense: l(expense, other.expense),
      expenseContainer: l(expenseContainer, other.expenseContainer),
      onExpenseContainer: l(onExpenseContainer, other.onExpenseContainer),
      savings: l(savings, other.savings),
      savingsContainer: l(savingsContainer, other.savingsContainer),
      onSavingsContainer: l(onSavingsContainer, other.onSavingsContainer),
      tax: l(tax, other.tax),
      taxContainer: l(taxContainer, other.taxContainer),
      onTaxContainer: l(onTaxContainer, other.onTaxContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      onWarningContainer: l(onWarningContainer, other.onWarningContainer),
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
    );
  }
}

/// Short-hands so widgets can write `context.colors.primary`,
/// `context.appColors.income` and `context.text.titleMedium`.
extension ThemeContext on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  AppColors get appColors => Theme.of(this).extension<AppColors>()!;
  TextTheme get text => Theme.of(this).textTheme;
}
