import 'package:flutter/material.dart';
import 'package:rider_delivery/SplashScreens/SplashScreen.dart';
import 'package:rider_delivery/pages/Chat.dart';
import 'package:rider_delivery/pages/GoRestaurant.dart';
import 'package:rider_delivery/pages/Home.dart';
import 'package:rider_delivery/pages/JobStart.dart';

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
        '/home': (_) => const HomePage(),
        '/jobStart': (_) => const JobStartPage(),
        '/GoRestaurant': (_) => GoRestaurant(), // Adjust this route as needed
        '/chat': (_) => const Chat(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
