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
        '/home': (_) => const HomePage(),
        '/jobStart': (_) => const JobStartPage(),
        '/GoRestaurant': (_) => GoRestaurant(), // Adjust this route as needed
        '/chat': (_) => const Chat(),
        '/goCustomer': (_) => const GoCustomer(),
        '/deliveryConfirm': (_) => const DeliveryConfirmPage(),
        '/income': (_) => IncomePage(),
        '/trip': (_) => const TripPage(),
        '/jobs': (_) => const JobsPage(),
        '/riderReview': (_) => RiderReviewPage(),
        '/profile': (_) => ProfilePage(),
        '/deliveryCompleted': (_) => const DeliveryCompletedPage(),
        '/myCredit': (_) => const MyCreditPage(),
        '/login': (_) => const LoginPage(),
        '/register': (_) => const Register(),
        '/riderIdentity': (_) => const RiderIdentityPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
