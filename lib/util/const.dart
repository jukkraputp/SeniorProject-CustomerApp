import 'package:customer/interfaces/payment.dart';
import 'package:customer/interfaces/prefs_key.dart';
import 'package:flutter/material.dart';

class Constants {
  static String appName = "Customer App";

  //Colors for theme
//  Color(0xfffcfcff);
  static Color lightPrimary = const Color(0xfffcfcff);
  static Color darkPrimary = Colors.black;
  static Color lightAccent = Colors.red;
  static Color darkAccent = Colors.red.shade400;
  static Color lightBG = const Color(0xfffcfcff);
  static Color darkBG = Colors.black;
  static Color ratingBG = Colors.yellow.shade600;

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      toolbarTextStyle: TextTheme(
        titleMedium: TextStyle(
          color: darkBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ).bodyText2,
      titleTextStyle: TextTheme(
        titleMedium: TextStyle(
          color: darkBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ).headline6,
//      iconTheme: IconThemeData(
//        color: lightAccent,
//      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: lightAccent),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: lightAccent),
  );

  static ThemeData darkTheme = ThemeData(
    //brightness: Brightness.dark,
    backgroundColor: darkBG,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBG,
    appBarTheme: AppBarTheme(
      toolbarTextStyle: TextTheme(
        titleMedium: TextStyle(
          color: lightBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ).bodyText2,
      titleTextStyle: TextTheme(
        titleMedium: TextStyle(
          color: lightBG,
          fontSize: 18.0,
          fontWeight: FontWeight.w800,
        ),
      ).headline6,
//      iconTheme: IconThemeData(
//        color: darkAccent,
//      ),
    ),
    textSelectionTheme: TextSelectionThemeData(cursorColor: darkAccent),
    colorScheme: ColorScheme.fromSwatch()
        .copyWith(secondary: darkAccent, brightness: Brightness.dark),
  );
}
