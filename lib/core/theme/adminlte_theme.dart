import 'package:flutter/material.dart';

/// Tema inspirado en AdminLTE 3
/// Colores y estilos consistentes con la plantilla AdminLTE
class AdminLTETheme {
  // Colores principales de AdminLTE 3
  static const Color primary = Color(0xFF007BFF); // Blue
  static const Color secondary = Color(0xFF6C757D); // Gray
  static const Color success = Color(0xFF28A745); // Green
  static const Color info = Color(0xFF17A2B8); // Cyan
  static const Color warning = Color(0xFFFFC107); // Yellow
  static const Color danger = Color(0xFFDC3545); // Red
  static const Color light = Color(0xFFF8F9FA);
  static const Color dark = Color(0xFF343A40);
  static const Color white = Color(0xFFFFFFFF);
  
  // Colores de fondo
  static const Color backgroundColor = Color(0xFFF4F6F9);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color sidebarDark = Color(0xFF343A40);
  static const Color navbarDark = Color(0xFF343A40);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textMuted = Color(0xFF868E96);
  
  // Gradientes
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF007BFF), Color(0xFF0056B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF28A745), Color(0xFF1E7E34)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient infoGradient = LinearGradient(
    colors: [Color(0xFF17A2B8), Color(0xFF117A8B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFC107), Color(0xFFE0A800)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient dangerGradient = LinearGradient(
    colors: [Color(0xFFDC3545), Color(0xFFC82333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Sombras
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  // Border radius
  static const double cardBorderRadius = 8.0;
  static const double buttonBorderRadius = 4.0;
  static const double inputBorderRadius = 4.0;
  
  // Espaciado
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Tamaños de fuente
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  
  // Estilos de texto
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: textPrimary,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: textSecondary,
  );
  
  // Decoration para cards estilo AdminLTE
  static BoxDecoration cardDecoration({Color? color}) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: cardShadow,
    );
  }
  
  // Decoration para info boxes
  static BoxDecoration infoBoxDecoration(Color color) {
    return BoxDecoration(
      color: white,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: cardShadow,
      border: Border(
        left: BorderSide(color: color, width: 3),
      ),
    );
  }
  
  // Decoration para small boxes
  static BoxDecoration smallBoxDecoration(Gradient gradient) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(cardBorderRadius),
      boxShadow: elevatedShadow,
    );
  }
  
  // Theme data completo
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        error: danger,
        surface: cardBackground,
        onPrimary: white,
        onSecondary: white,
        onSurface: textPrimary,
        onError: white,
      ),
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: navbarDark,
        foregroundColor: white,
        elevation: 1,
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardBorderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputBorderRadius),
        ),
        filled: true,
        fillColor: white,
      ),
      textTheme: const TextTheme(
        displayLarge: h1,
        displayMedium: h2,
        displaySmall: h3,
        headlineMedium: h4,
        headlineSmall: h5,
        titleLarge: h6,
        bodyLarge: bodyText,
        bodyMedium: bodyText,
        bodySmall: caption,
      ),
    );
  }
}
