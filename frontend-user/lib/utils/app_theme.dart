import 'package:flutter/material.dart';

/// Единая система дизайна для приложения МВД
class AppTheme {
  // Основные цвета
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF1565C0);
  static const Color backgroundColor = Color(0xFFF5F7FA);
  static const Color surfaceColor = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textHint = Color(0xFF757575);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color successColor = Color(0xFF388E3C);
  static const Color warningColor = Color(0xFFF57C00);

  // Иконки
  static const IconData iconPerson = Icons.person;
  static const IconData iconPersonOutline = Icons.person_outline;
  static const IconData iconPhone = Icons.phone;
  static const IconData iconEmail = Icons.email;
  static const IconData iconLocation = Icons.location_on;
  static const IconData iconHome = Icons.home;
  static const IconData iconDescription = Icons.description;
  static const IconData iconCategory = Icons.category;
  static const IconData iconAssignment = Icons.assignment;
  static const IconData iconTime = Icons.access_time;
  static const IconData iconSend = Icons.send;
  static const IconData iconMap = Icons.map;
  static const IconData iconNotes = Icons.notes;
  static const IconData iconCheckCircle = Icons.check_circle;
  static const IconData iconCopy = Icons.content_copy;
  static const IconData iconInfo = Icons.info_outline;
  static const IconData iconEdit = Icons.edit;
  static const IconData iconPhoneInTalk = Icons.phone_in_talk;

  // Стили текста
  static TextStyle get headlineStyle => const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

  static TextStyle get sectionHeaderStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      );

  static TextStyle get bodyTextStyle => const TextStyle(
        fontSize: 16,
        color: textPrimary,
      );

  static TextStyle get hintTextStyle => const TextStyle(
        fontSize: 14,
        color: textHint,
      );

  static TextStyle get requestNumberStyle => const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
        letterSpacing: 2,
      );

  // Стили кнопок
  static ButtonStyle get primaryButtonStyle => FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(20),
        textStyle: const TextStyle(fontSize: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  static ButtonStyle get secondaryButtonStyle => TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      );

  // Стили полей ввода
  static InputDecoration get inputDecoration => InputDecoration(
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      );

  // Стили карточек
  static BoxDecoration get sectionCardDecoration => BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      );

  static BoxDecoration get infoCardDecoration => BoxDecoration(
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      );

  // Вспомогательные методы
  static Widget buildSectionHeader(String title, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: sectionCardDecoration,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: primaryColor),
            const SizedBox(width: 12),
          ],
          Text(
            title,
            style: sectionHeaderStyle,
          ),
        ],
      ),
    );
  }

  static Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffix,
    String? helperText,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: inputDecoration.copyWith(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,
        helperText: helperText,
        hintText: hintText,
        helperMaxLines: 2,
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }
}

