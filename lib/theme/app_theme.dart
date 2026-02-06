import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFF141525);
  static const foreground = Color(0xFFF9F9F9);
  static const card = Color(0xFF1E1F33);
  static const primary = Color(0xFF7C6AED);
  static const primaryFg = Color(0xFF141525);
  static const secondary = Color(0xFF2A2B3D);
  static const muted = Color(0xFF2A2B3D);
  static const mutedFg = Color(0xFFAAAAAA);
  static const accent = Color(0xFF312F50);
  static const destructive = Color(0xFFE5534B);
  static const warning = Color(0xFFE8A317);
  static const success = Color(0xFF3FB950);
}

class AppTheme {
  static final borderColor = Colors.white.withOpacity(0.10);
  static final inputColor = Colors.white.withOpacity(0.15);

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(color: AppColors.foreground),
      displayMedium: baseTextTheme.displayMedium?.copyWith(color: AppColors.foreground),
      displaySmall: baseTextTheme.displaySmall?.copyWith(color: AppColors.foreground),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        color: AppColors.foreground,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(color: AppColors.foreground),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        color: AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        color: AppColors.foreground,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(color: AppColors.foreground),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(color: AppColors.foreground),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(color: AppColors.foreground),
      bodySmall: baseTextTheme.bodySmall?.copyWith(color: AppColors.mutedFg),
      labelLarge: baseTextTheme.labelLarge?.copyWith(color: AppColors.foreground),
      labelMedium: baseTextTheme.labelMedium?.copyWith(color: AppColors.foreground),
      labelSmall: baseTextTheme.labelSmall?.copyWith(color: AppColors.mutedFg),
    );

    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryFg,
      secondary: AppColors.secondary,
      onSecondary: AppColors.foreground,
      error: AppColors.destructive,
      onError: AppColors.foreground,
      surface: AppColors.background,
      onSurface: AppColors.foreground,
      surfaceContainerHighest: AppColors.card,
      outline: Color(0x1AFFFFFF), // white 10%
      outlineVariant: Color(0x0DFFFFFF), // white 5%
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background.withOpacity(0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: AppColors.foreground),
      ),

      // Card
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor),
        ),
        margin: EdgeInsets.zero,
      ),

      // Input
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.destructive, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.mutedFg),
        hintStyle: const TextStyle(color: AppColors.mutedFg),
        prefixIconColor: AppColors.mutedFg,
        suffixIconColor: AppColors.mutedFg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryFg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryFg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.foreground,
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // NavigationBar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.mutedFg);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.inter(
            color: AppColors.mutedFg,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          );
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
      ),

      // BottomNavigationBar (fallback)
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.mutedFg,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.foreground,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.secondary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primaryFg;
            }
            return AppColors.foreground;
          }),
          side: WidgetStateProperty.all(BorderSide(color: borderColor)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),

      // Slider
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.muted,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withOpacity(0.12),
        valueIndicatorColor: AppColors.primary,
        valueIndicatorTextStyle: const TextStyle(color: AppColors.primaryFg),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.mutedFg;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.muted;
        }),
      ),

      // TabBar
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.mutedFg,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.secondary,
        contentTextStyle: const TextStyle(color: AppColors.foreground),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        behavior: SnackBarBehavior.floating,
      ),

      // ListTile
      listTileTheme: const ListTileThemeData(
        textColor: AppColors.foreground,
        iconColor: AppColors.mutedFg,
      ),

      // Icon
      iconTheme: const IconThemeData(color: AppColors.foreground),

      // Tooltip
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
