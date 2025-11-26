import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_donaciones_1/features/donor/home/presentation/pages/donations_request_screen.dart';
import '/features/auth/presentation/pages/auth_wrapper_screen.dart';
import '../../../donor/home/presentation/pages/campaigns_screen.dart';
import '../../../donor/home/presentation/pages/my_donations_screen.dart';
import '../../../donor/home/presentation/pages/locations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _userName;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Paleta de colores profesional
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1B263B);
  static const Color accentBlue = Color(0xFF415A77);
  static const Color lightBlue = Color(0xFF778DA9);
  static const Color cream = Color(0xFFE0E1DD);
  static const Color accent = Color(0xFFFFB700);
  static const Color white = Color(0xFFFFFFFE);

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initAnimations();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('donante_nombre');
    });
  }

  Future<void> _logout() async {
    // Haptic feedback para mejor UX
    HapticFeedback.lightImpact();

    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AuthWrapper(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero),
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout_rounded, color: accent, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
              content: const Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: TextStyle(color: accentBlue),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancelar', style: TextStyle(color: lightBlue)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: primaryDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Buenos días';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CampaignsScreen(),
      MyDonationsScreen(),
      LocationsScreen(),
      DonationsRequestScreen(),
    ];

    return Scaffold(
      backgroundColor: cream,
      extendBodyBehindAppBar: false,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDark, primaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 100,
              title: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: lightBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _userName ?? "Usuario",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: white,
                        size: 24,
                      ),
                      onPressed: _logout,
                      tooltip: 'Cerrar sesión',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryBlue, primaryDark],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              HapticFeedback.selectionClick();
              setState(() => _currentIndex = index);
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: accent,
            unselectedItemColor: lightBlue,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            items: [
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_currentIndex == 0 ? 8 : 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == 0
                        ? accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _currentIndex == 0
                        ? Icons.campaign_rounded
                        : Icons.campaign_outlined,
                    size: 26,
                  ),
                ),
                label: 'Campañas',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_currentIndex == 1 ? 8 : 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == 1
                        ? accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _currentIndex == 1
                        ? Icons.history_rounded
                        : Icons.history_outlined,
                    size: 26,
                  ),
                ),
                label: 'Donaciones',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_currentIndex == 2 ? 8 : 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == 2
                        ? accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _currentIndex == 2
                        ? Icons.location_on
                        : Icons.location_on_outlined,
                    size: 26,
                  ),
                ),
                label: 'Ubicaciones',
              ),
              BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(_currentIndex == 3 ? 8 : 4),
                  decoration: BoxDecoration(
                    color: _currentIndex == 3
                        ? accent.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _currentIndex == 3
                        ? Icons.collections_bookmark
                        : Icons.collections_bookmark_outlined,
                    size: 26,
                  ),
                ),
                label: 'Solicitudes',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
