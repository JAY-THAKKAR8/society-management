import 'package:flutter/material.dart';

import 'web/simple_website.dart';

void main() {
  runApp(const SocietyManagementWeb());
}

class SocietyManagementWeb extends StatelessWidget {
  const SocietyManagementWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Society Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF4A6FFF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A6FFF),
          primary: const Color(0xFF4A6FFF),
          secondary: const Color(0xFF4CAF50),
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
      ),
      home: const SimpleWebsite(),
    );
  }
}
