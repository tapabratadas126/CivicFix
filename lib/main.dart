import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:civicfix/services/auth_service.dart';
import 'package:civicfix/services/complaint_service.dart';
import 'theme.dart';
import 'nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final authService = AuthService();
  await authService.initialize();
  await authService.seedDefaultUsers();
  
  final complaintService = ComplaintService();
  await complaintService.loadComplaints();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ComplaintService()),
      ],
      child: MaterialApp.router(
        title: 'CivicFix',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
