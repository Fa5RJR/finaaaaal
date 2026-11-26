import 'package:al_sharif/features/dashBoard/dashBoard.dart';
import 'package:al_sharif/features/home/home_screen.dart';
import 'package:al_sharif/features/price/price_screen.dart';
import 'package:flutter/material.dart';
import 'package:al_sharif/features/auth/screens/signin_screen.dart';
import 'package:al_sharif/features/auth/screens/signup_screen.dart';
import 'package:al_sharif/features/onboarding/onboarding_first.dart';
import 'package:al_sharif/features/onboarding/onboarding_second.dart';
import 'package:al_sharif/features/onboarding/onboarding_third.dart';
import 'package:al_sharif/features/ai_estimator/ai_screen.dart';
class AppRoutes {
  AppRoutes._();

  static const String onboarding = '/onboarding';
  static const String onboarding2 = '/onboarding2';
  static const String onboarding3 = '/onboarding3';
  static const String signin = '/signin';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String assistant = '/assistant';
  static const String priceEstimation = '/priceEstimation';
  static const String adminDashboard = '/adminDashboard';

  static Map<String, WidgetBuilder> get routes => {
    onboarding: (context) => const OnboardingOne(),
    onboarding2: (context) => const OnboardingTwo(),
    onboarding3: (context) => const OnboardingThree(),
    signin: (context) => const LoginScreen(),
    signup: (context) => const Signup(),
    home: (context) => const HomeScreen(),
    assistant: (context) => const SmartAssistantScreen(),
    priceEstimation: (context) => const PriceEstimationScreen(),
    adminDashboard: (context) => const AdminDashboardScreen(),
  };
}

