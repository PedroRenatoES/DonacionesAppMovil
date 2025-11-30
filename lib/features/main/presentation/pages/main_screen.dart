import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_donaciones_1/features/donor/home/presentation/pages/donations_request_screen.dart';
import '/features/auth/presentation/pages/auth_wrapper_screen.dart';
import '../../../donor/home/presentation/pages/campaigns_screen.dart';
import '../../../donor/home/presentation/pages/my_donations_screen.dart';
import '../../../donor/home/presentation/pages/locations_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/adminlte_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  String? _userName;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
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
              backgroundColor: AdminLTETheme.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminLTETheme.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.logout, color: AdminLTETheme.warning, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Cerrar Sesión',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AdminLTETheme.textPrimary,
                    ),
                  ),
                ],
              ),
              content: const Text(
                '¿Estás seguro de que quieres cerrar sesión?',
                style: TextStyle(color: AdminLTETheme.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar', style: TextStyle(color: AdminLTETheme.secondary)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminLTETheme.danger,
                    foregroundColor: AdminLTETheme.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AdminLTETheme.buttonBorderRadius),
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
      backgroundColor: AdminLTETheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AdminLTETheme.navbarDark,
        elevation: 0,
        toolbarHeight: 70,
        title: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AdminLTETheme.light,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userName ?? "Usuario",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdminLTETheme.white,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FadeTransition(
            opacity: _fadeAnimation,
            child: IconButton(
              icon: const Icon(Icons.logout, color: AdminLTETheme.white),
              onPressed: _logout,
              tooltip: 'Cerrar sesión',
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AdminLTETheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            HapticFeedback.selectionClick();
            setState(() => _currentIndex = index);
          },
          backgroundColor: AdminLTETheme.white,
          elevation: 0,
          selectedItemColor: AdminLTETheme.primary,
          unselectedItemColor: AdminLTETheme.textMuted,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign),
              label: 'Campañas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Donaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on),
              label: 'Ubicaciones',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.request_page),
              label: 'Solicitudes',
            ),
          ],
        ),
      ),
    );
  }
}
