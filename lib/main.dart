import 'package:flutter/material.dart';
import 'package:rider_delivery/SplashScreens/SplashScreen.dart';
import 'package:rider_delivery/pages/Chat.dart';
import 'package:rider_delivery/pages/DeliveryCompleted.dart';
import 'package:rider_delivery/pages/GoCustomer.dart';
import 'package:rider_delivery/pages/DeliveryConfirm.dart';
import 'package:rider_delivery/pages/GoRestaurant.dart';
import 'package:rider_delivery/pages/Home/Home.dart';
import 'package:rider_delivery/pages/Home/Income.dart';
import 'package:rider_delivery/pages/Home/MyCredit.dart';
import 'package:rider_delivery/pages/Home/RiderReview.dart';
import 'package:rider_delivery/pages/JobStart.dart';
import 'package:rider_delivery/pages/Home/Jobs.dart';
import 'package:rider_delivery/pages/Home/Trip.dart';
import 'package:rider_delivery/pages/Profile.dart';
import 'package:rider_delivery/pages/auth/Login.dart';
import 'package:rider_delivery/pages/auth/Register.dart';
import 'package:rider_delivery/pages/auth/Rider_identity.dart';
import 'package:rider_delivery/pages/auth/Wellcome.dart';
import 'package:rider_delivery/APIs/middleware/AuthGuard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // final auth = AuthService();
  // await auth.loadUser();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/wellcome': (_) => wellcomePage(),
        '/home': (_) => AuthGuard(child: const HomePage()),
        '/jobStart': (_) => AuthGuard(child: const JobStartPage()),
        '/GoRestaurant': (_) => AuthGuard(child: GoRestaurant()),
        '/chat': (_) => AuthGuard(child: const Chat()),
        '/goCustomer': (_) => AuthGuard(child: const GoCustomer()),
        '/deliveryConfirm': (_) =>
            AuthGuard(child: const DeliveryConfirmPage()),
        '/income': (_) => AuthGuard(child: IncomePage()),
        '/trip': (_) => AuthGuard(child: const TripPage()),
        '/jobs': (_) => AuthGuard(child: const JobsPage()),
        '/riderReview': (_) => AuthGuard(child: RiderReviewPage()),
        '/profile': (_) => AuthGuard(child: ProfilePage()),
        '/deliveryCompleted': (_) =>
            AuthGuard(child: const DeliveryCompletedPage()),
        '/myCredit': (_) => AuthGuard(child: const MyCreditPage()),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const Register(),
        '/riderIdentity': (_) => AuthGuard(child: const RiderIdentityPage()),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
