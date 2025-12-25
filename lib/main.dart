import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'controllers/notification_controller.dart';

// Import all pages
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/user_type_page.dart';
import 'pages/sign_in_page.dart';
import 'pages/sign_up_page.dart';
import 'pages/client_main_page.dart';
import 'pages/provider_main_page.dart';
import 'pages/browse_services_page.dart';
import 'pages/my_bookings_page.dart';
import 'pages/add_service_page.dart';
import 'pages/create_booking_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Start notification checker
  _startNotificationChecker();
  
  runApp(const GlowApp());
}

// Background task to check for upcoming bookings every 10 minutes
void _startNotificationChecker() {
  final notificationController = NotificationController();
  
  // Run immediately on start
  notificationController.checkUpcomingBookings();
  
  // Then run every 10 minutes
  Timer.periodic(const Duration(minutes: 10), (timer) {
    notificationController.checkUpcomingBookings();
  });
}

class GlowApp extends StatelessWidget {
  const GlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => SplashPage(),
        '/welcome': (context) => WelcomePage(),
        '/user-type': (context) => UserTypePage(),
        '/sign-in': (context) => SignInPage(),
        '/sign-up': (context) => SignUpPage(),
        '/client-dashboard': (context) => ClientMainPage(),
        '/provider-dashboard': (context) => ProviderMainPage(),
        '/browse-services': (context) => BrowseServicesPage(),
        '/my-bookings': (context) => MyBookingsPage(),
        '/add-service': (context) => AddServicePage(),
        '/create-booking': (context) => CreateBookingPage(),
      },
    );
  }
}
