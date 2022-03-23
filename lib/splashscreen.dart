import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kanban_dashboard/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'dart:async';

import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadUser();
    // Timer(
    //     Duration(seconds: 3),
    //     () => Navigator.of(context).pushReplacement(MaterialPageRoute(
    //         builder: (BuildContext context) => LoginScreen())));
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('email') != null) {
      Timer(
          const Duration(seconds: 3),
          () => Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const DashboardPage())));
    } else {
      Timer(
          const Duration(seconds: 3),
          () => Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (BuildContext context) => const LoginScreen())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(children: [
          SizedBox(height: MediaQuery.of(context).size.height / 4),
          Image.asset('assets/images/splashscreen.png',
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.width * 0.7,
              fit: BoxFit.fitWidth),
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ]),
      ),
    );
  }
}
