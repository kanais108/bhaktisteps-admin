import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'routing/app_router.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/admin_theme.dart';

class BhaktiStepsAdminApp extends StatelessWidget {
  const BhaktiStepsAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.createRouter();

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Bhakti Steps Admin',

      theme: AdminTheme.light.copyWith(textTheme: GoogleFonts.interTextTheme()),

      routerConfig: router,
    );
  }
}
