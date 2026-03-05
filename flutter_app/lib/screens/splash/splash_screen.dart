import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.7, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB), Color(0xFF0EA5E9)],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.work_rounded, size: 56, color: AppTheme.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text('RozgarX', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('Sarkari Naukri, Ek Click Mein', style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w400)),
                  const SizedBox(height: 60),
                  SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: Colors.white.withOpacity(0.7), strokeWidth: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
