import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/a_dashboard_provider.dart';
import 'providers/a_login_provider.dart';
import 'providers/a_driver_provider.dart';
import 'providers/a_order_provider.dart';
import 'providers/a_user_provider.dart'; 
import 'providers/a_edit_provider.dart'; 
import 'views/a_login_view.dart';
import 'views/a_main_view.dart';

Future<void> main() async {
  await dotenv.load(fileName: "dotenv");
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => EditProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const WebApp(),
    ),
  );
}

class WebApp extends StatelessWidget {
  const WebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Logistics Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<LoginProvider>(
        builder: (context, auth, child) {
          return auth.isAuthenticated ? const MainView() : const LoginView();
        },
      ),
    );
  }
}