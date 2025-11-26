import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import '/features/auth/presentation/pages/login_type_screen.dart';
import '/features/volunteer/presentation/pages/dashboard_screen.dart';
import '/features/volunteer/presentation/pages/inventary_screen.dart';
import '/features/volunteer/presentation/pages/volunteer_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerMainScreen extends StatefulWidget {
  const VolunteerMainScreen({super.key});

  @override
  VolunteerMainScreenState createState() => VolunteerMainScreenState();
}

class VolunteerMainScreenState extends State<VolunteerMainScreen>
    with TickerProviderStateMixin {
  // Colores del sistema de diseño
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1B263B);
  static const Color accentBlue = Color(0xFF415A77);
  static const Color lightBlue = Color(0xFF778DA9);
  static const Color cream = Color(0xFFE0E1DD);
  static const Color accent = Color(0xFFFFB700);
  static const Color white = Color(0xFFFFFFFE);
  static const Color errorColor = Color(0xFFE63946);
  static const Color successColor = Color(0xFF2A9D8F);

  int _currentIndex = 0;
  String? _userName;
  bool _isLoading = true;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('token');

    if (userId == null || token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        setState(() {
          _userName = userData['NombreCompleto'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    HapticFeedback.lightImpact();

    // Mostrar diálogo de confirmación
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cerrar Sesión',
            style: TextStyle(fontWeight: FontWeight.w700, color: primaryDark),
          ),
          content: const Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: accentBlue, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: lightBlue, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [errorColor, Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Cerrar Sesión',
                  style: TextStyle(color: white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginTypeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      const VolunteerDashboardScreen(),
      const InventoryScreen(),
      const VolunteerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: cream,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryDark, primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: false,
                title: _isLoading
                    ? Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Cargando...',
                            style: TextStyle(
                              color: white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.volunteer_activism_rounded,
                              color: accent,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Voluntario',
                                  style: TextStyle(
                                    color: lightBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _userName ?? 'Usuario',
                                  style: const TextStyle(
                                    color: white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _logout,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: IndexedStack(index: _currentIndex, children: screens),
      ),
      bottomNavigationBar: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                ),
              ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryDark, primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabTapped,
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedItemColor: accent,
              unselectedItemColor: lightBlue,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.dashboard_rounded, 0),
                  activeIcon: _buildActiveNavIcon(Icons.dashboard_rounded, 0),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.inventory_2_rounded, 1),
                  activeIcon: _buildActiveNavIcon(Icons.inventory_2_rounded, 1),
                  label: 'Inventario',
                ),
                BottomNavigationBarItem(
                  icon: _buildNavIcon(Icons.person_rounded, 2),
                  activeIcon: _buildActiveNavIcon(Icons.person_rounded, 2),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(6),
      child: Icon(
        icon,
        size: 24,
        color: _currentIndex == index ? accent : lightBlue,
      ),
    );
  }

  Widget _buildActiveNavIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent.withOpacity(0.2), accent.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.3), width: 1),
      ),
      child: Icon(icon, size: 24, color: accent),
    );
  }
}
