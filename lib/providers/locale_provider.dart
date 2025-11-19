import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  static const String _key = 'locale';

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_key) ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    notifyListeners();
  }

  String t(String key) {
    return _translations[_locale.languageCode]?[key] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'en': {
      // Common
      'app_name': 'Routine Ranger',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'back': 'Back',
      'next': 'Next',
      'skip': 'Skip',
      'done': 'Done',
      'retry': 'Retry',

      // Auth
      'login': 'Login',
      'signup': 'Sign up',
      'sign_out': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
      'welcome_back': 'Welcome Back',
      'sign_in_to_continue': 'Sign in to continue',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': 'Don\'t have an account? ',

      // Navigation
      'home': 'Home',
      'analytics': 'Analytics',
      'calendar': 'Calendar',
      'goals': 'Goals',
      'settings': 'Settings',
      'my_routines': 'My Routines',

      // Onboarding
      'onboarding_title_1': 'Welcome to Routine Ranger',
      'onboarding_desc_1':
          'Build better habits and stay consistent with your daily routines',
      'onboarding_title_2': 'Track Your Progress',
      'onboarding_desc_2':
          'Monitor your streaks, view analytics, and celebrate your achievements',
      'onboarding_title_3': 'Stay Motivated',
      'onboarding_desc_3':
          'Get reminders, use templates, and export to your calendar',
      'onboarding_title_4': 'Ready to Start?',
      'onboarding_desc_4':
          'Let\'s create your first routine and begin your journey to success',
      'get_started': 'Get Started',

      // Home Screen
      'today': 'Today',
      'total': 'Total',
      'active': 'Active',
      'no_routines': 'No routines yet. Tap + to add one.',
      'browse_templates': 'Browse Templates',
      'search_by_title': 'Search by title...',
      'category': 'Category',
      'priority': 'Priority',
      'all': 'All',
      'marked_as_done': 'Marked as done',
      'undo': 'Undo',

      // Settings
      'notifications': 'Notifications',
      'preferences': 'Preferences',
      'theme': 'Theme',
      'light_dark_mode': 'Light / Dark mode',
      'language': 'Language',
      'about': 'About',
      'version': 'Version 1.0.0',
    },
    'bn': {
      // Common (Bengali)
      'app_name': 'রুটিন রেঞ্জার',
      'cancel': 'বাতিল',
      'save': 'সংরক্ষণ',
      'delete': 'মুছুন',
      'edit': 'সম্পাদনা',
      'add': 'যোগ করুন',
      'back': 'পিছনে',
      'next': 'পরবর্তী',
      'skip': 'এড়িয়ে যান',
      'done': 'সম্পন্ন',
      'retry': 'পুনরায় চেষ্টা',

      // Auth
      'login': 'লগইন',
      'signup': 'সাইন আপ',
      'sign_out': 'সাইন আউট',
      'email': 'ইমেইল',
      'password': 'পাসওয়ার্ড',
      'welcome_back': 'আবার স্বাগতম',
      'sign_in_to_continue': 'চালিয়ে যেতে সাইন ইন করুন',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'dont_have_account': 'অ্যাকাউন্ট নেই? ',

      // Navigation
      'home': 'হোম',
      'analytics': 'বিশ্লেষণ',
      'calendar': 'ক্যালেন্ডার',
      'goals': 'লক্ষ্য',
      'settings': 'সেটিংস',
      'my_routines': 'আমার রুটিন',

      // Onboarding
      'onboarding_title_1': 'রুটিন রেঞ্জারে স্বাগতম',
      'onboarding_desc_1':
          'আপনার দৈনন্দিন রুটিনের সাথে আরও ভাল অভ্যাস তৈরি করুন এবং সামঞ্জস্যপূর্ণ থাকুন',
      'onboarding_title_2': 'আপনার অগ্রগতি ট্র্যাক করুন',
      'onboarding_desc_2':
          'আপনার স্ট্রিক মনিটর করুন, বিশ্লেষণ দেখুন এবং আপনার অর্জন উদযাপন করুন',
      'onboarding_title_3': 'অনুপ্রাণিত থাকুন',
      'onboarding_desc_3':
          'অনুস্মারক পান, টেমপ্লেট ব্যবহার করুন এবং আপনার ক্যালেন্ডারে রপ্তানি করুন',
      'onboarding_title_4': 'শুরু করতে প্রস্তুত?',
      'onboarding_desc_4':
          'আসুন আপনার প্রথম রুটিন তৈরি করি এবং সাফল্যের যাত্রা শুরু করি',
      'get_started': 'শুরু করুন',

      // Home Screen
      'today': 'আজ',
      'total': 'মোট',
      'active': 'সক্রিয়',
      'no_routines': 'এখনও কোন রুটিন নেই। যোগ করতে + চাপুন।',
      'browse_templates': 'টেমপ্লেট ব্রাউজ করুন',
      'search_by_title': 'শিরোনাম দিয়ে খুঁজুন...',
      'category': 'শ্রেণী',
      'priority': 'অগ্রাধিকার',
      'all': 'সব',
      'marked_as_done': 'সম্পন্ন হিসাবে চিহ্নিত',
      'undo': 'পূর্বাবস্থায়',

      // Settings
      'notifications': 'বিজ্ঞপ্তি',
      'preferences': 'পছন্দসমূহ',
      'theme': 'থিম',
      'light_dark_mode': 'হালকা / গাঢ় মোড',
      'language': 'ভাষা',
      'about': 'সম্পর্কে',
      'version': 'সংস্করণ 1.0.0',
    },
  };
}
