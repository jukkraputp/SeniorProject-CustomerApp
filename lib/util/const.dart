import 'package:customer/interfaces/payment.dart';
import 'package:customer/interfaces/prefs_key.dart';
import 'package:flutter/material.dart';

class Constants {
  static String appName = "Customer App";

  //Colors for theme
//  Color(0xfffcfcff);
  static Color lightPrimary = Colors.black87;
  static Color darkPrimary = Colors.white;
  static Color lightAccent = Colors.blueAccent;
  static Color darkAccent = Colors.deepPurpleAccent;
  static Color lightBG = const Color(0xfffcfcff);
  static Color darkBG = Colors.black;
  static Color ratingBG = Colors.yellow.shade600;

  static ThemeData lightTheme = ThemeData(
    backgroundColor: lightBG,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBG,
    appBarTheme: AppBarTheme(
      backgroundColor: lightAccent,
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
      backgroundColor: darkAccent,
      toolbarTextStyle: TextTheme(
        titleMedium: TextStyle(
          color: darkPrimary,
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
