import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/utils.dart';
import 'package:provider/provider.dart';
import 'package:rider_delivery/APIs/ChatSocket/ChatControllerSK.dart';
import 'package:rider_delivery/APIs/Orders/OrdersSocket.dart';
import 'package:rider_delivery/APIs/middleware/authService.dart';
import 'package:rider_delivery/SplashScreens/SplashScreen.dart';
import 'package:rider_delivery/pages/Chats/Chat.dart';
import 'package:rider_delivery/pages/DeliveryCompleted.dart';
import 'package:rider_delivery/pages/GoCustomer.dart';
import 'package:rider_delivery/pages/DeliveryConfirm.dart';
import 'package:rider_delivery/pages/GoRestaurant.dart';
import 'package:rider_delivery/pages/Home/Home.dart';
import 'package:rider_delivery/pages/Home/Income.dart';
import 'package:rider_delivery/pages/Home/CreditGP/MyCredit.dart';
import 'package:rider_delivery/pages/Home/RiderReview.dart';
import 'package:rider_delivery/pages/JobStart.dart';
import 'package:rider_delivery/pages/Home/Jobs.dart';
import 'package:rider_delivery/pages/Home/Trip.dart';
import 'package:rider_delivery/pages/ProfilePage/ChatLists.dart';
// import 'package:rider_delivery/pages/Profile.dart';
import 'package:rider_delivery/pages/ProfilePage/Profile.dart';

import 'package:rider_delivery/pages/auth/Login.dart';
import 'package:rider_delivery/pages/auth/Register.dart';
import 'package:rider_delivery/pages/auth/Rider_identity.dart';
import 'package:rider_delivery/pages/auth/Wellcome.dart';
import 'package:rider_delivery/APIs/middleware/AuthGuard.dart';
import 'package:rider_delivery/pages/maps/MapNavigationPage.dart';
import 'package:rider_delivery/services/RiderStatusService.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthService();
  Get.put(RiderChatController(), permanent: true);
  // await auth.loadUser();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RiderControllerSocket()),
        ChangeNotifierProvider(create: (_) => RiderChatController()),
        // ...provider อื่นๆ
      ],
      child: const MyApp(),
    ),
  );
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
        '/jobStart': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments
                  as Map<String, dynamic>?;
          final riderId = args?['riderId'] as int?;
          final initialTabIndex = args?['initialTabIndex'] as int? ?? 0;
          return AuthGuard(
            child: riderId != null
                ? RiderJobsPage(
                    riderId: riderId,
                    initialTabIndex: initialTabIndex,
                  )
                : RiderJobsPage(riderId: 0, initialTabIndex: initialTabIndex),
          );
        },
        '/goRestaurant': (_) => AuthGuard(child: const GoRestaurant()),  // แก้ไขบรรทัดนี้
        '/mapNavigation': (_) => AuthGuard(child: const MapNavigationPage()),  // เพิ่มบรรทัดนี้
        '/chat-lists': (_) => AuthGuard(child: const RiderChatListPage()),
        '/rider-chat': (_) => AuthGuard(child: const RiderChatPage()),
        '/goCustomer': (_) => AuthGuard(child: const GoCustomer()),
        // '/deliveryConfirm': (_) =>
        //     AuthGuard(child: const DeliveryConfirmPage()),
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
