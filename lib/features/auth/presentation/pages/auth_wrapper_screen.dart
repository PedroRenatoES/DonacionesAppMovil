import 'package:flutter/material.dart';
import '/features/auth/presentation/pages/login_screen.dart';
import '/features/main/presentation/pages/main_screen.dart';
import '/features/main/presentation/pages/volunteer_main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  AuthWrapperState createState() => AuthWrapperState();
}

class AuthWrapperState extends State<AuthWrapper> {
  bool isLoggedIn = false;
  bool isLoading = true;
  String? userType;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final type = prefs.getString('user_type');
    setState(() {
      isLoggedIn = token != null;
      userType = type;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Color(0xFF000814),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC300)),
          ),
        ),
      );
    }

    if (!isLoggedIn) {
      return LoginScreen(userType: 'donante');
    }

    return userType == 'donante' ? MainScreen() : VolunteerMainScreen();
  }
}
