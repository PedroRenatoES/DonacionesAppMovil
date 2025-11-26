import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/inventory_providers.dart';
import '/features/volunteer/presentation/pages/article_detail_screen.dart';
import '/features/volunteer/presentation/pages/inventary_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerDashboardScreen extends ConsumerStatefulWidget {
  const VolunteerDashboardScreen({super.key});

  @override
  VolunteerDashboardScreenState createState() =>
      VolunteerDashboardScreenState();
}

class VolunteerDashboardScreenState
    extends ConsumerState<VolunteerDashboardScreen>
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

  int? totalDonations;
  List<dynamic> donationsByMonth = [];
  List<dynamic> stockItems = [];
  bool isLoading = true;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDashboardData();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Obtener total de donaciones
      final totalResponse = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/api/dashboard/total-donaciones',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (totalResponse.statusCode == 200) {
        final totalData = json.decode(totalResponse.body);
        setState(() {
          totalDonations = totalData['total'];
        });
      }

      // Obtener donaciones por mes (año actual)
      final currentYear = DateTime.now().year;
      final monthResponse = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/api/dashboard/donaciones-por-mes/$currentYear',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (monthResponse.statusCode == 200) {
        setState(() {
          donationsByMonth = json.decode(monthResponse.body);
        });
      }

      // Obtener vista rápida de stock
      final stockResponse = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/api/inventario/stock',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (stockResponse.statusCode == 200) {
        setState(() {
          stockItems = json.decode(stockResponse.body);
        });
      }

      setState(() {
        isLoading = false;
      });

      // Iniciar animaciones cuando los datos están cargados
      _fadeController.forward();
      _staggerController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Error al cargar datos del dashboard');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [cream, white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryDark.withOpacity(0.08),
                      blurRadius: 20,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cargando...',
                style: TextStyle(
                  fontSize: 16,
                  color: accentBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [cream, white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          _fadeController.reset();
          _staggerController.reset();
          await _loadDashboardData();
          ref.read(inventoryNotifierProvider.notifier).loadInitialData();
        },
        color: accent,
        backgroundColor: white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título principal
                _buildAnimatedItem(
                  index: 0,
                  child: const Text(
                    'Resumen de Donaciones',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: primaryDark,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Card de estadísticas principales
                _buildAnimatedItem(index: 1, child: _buildStatsCard()),
                const SizedBox(height: 32),

                // Título de inventario
                _buildAnimatedItem(
                  index: 2,
                  child: const Text(
                    'Inventario Rápido',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: primaryDark,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Grid de inventario
                _buildInventoryGrid(),
                const SizedBox(height: 24),

                // Botón de inventario completo
                _buildAnimatedItem(
                  index: stockItems.length + 3,
                  child: _buildInventoryButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _staggerController,
          curve: Interval(
            (index * 0.1).clamp(0.0, 1.0),
            ((index * 0.1) + 0.3).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        child: child,
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Donaciones',
                    totalDonations?.toString() ?? '0',
                    Icons.volunteer_activism_rounded,
                    successColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Este Mes',
                    donationsByMonth.isNotEmpty
                        ? donationsByMonth.last['cantidad'].toString()
                        : '0',
                    Icons.calendar_today_rounded,
                    accent,
                  ),
                ),
              ],
            ),
            if (donationsByMonth.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Donaciones por Mes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: accentBlue,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 200, child: _buildDonationsChart()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: lightBlue,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid() {
    if (stockItems.isEmpty) {
      return _buildAnimatedItem(
        index: 3,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_rounded, size: 48, color: lightBlue),
                SizedBox(height: 16),
                Text(
                  'No hay artículos en el inventario',
                  style: TextStyle(
                    fontSize: 16,
                    color: accentBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: stockItems.length,
      itemBuilder: (context, index) {
        final item = stockItems[index];
        return _buildAnimatedItem(
          index: index + 3,
          child: _buildInventoryCard(item),
        );
      },
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ArticleDetailScreen(articleId: item['id_articulo']),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ),
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['nombre_articulo'] ?? 'Sin nombre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: primaryDark,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Text(
                  '${item['total_restante']} ${item['medida_abreviada']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    height: 1.0,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: lightBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item['cantidad_estimada_por_persona']} ${item['medida_abreviada']}/pers',
                        style: const TextStyle(
                          fontSize: 12,
                          color: lightBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [accent, Color(0xFFFFD60A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const InventoryScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return SlideTransition(
                        position: animation.drive(
                          Tween(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ),
                        ),
                        child: child,
                      );
                    },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_rounded, color: primaryDark, size: 24),
                SizedBox(width: 12),
                Text(
                  'Ver Inventario Completo',
                  style: TextStyle(
                    color: primaryDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonationsChart() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: donationsByMonth.length,
      itemBuilder: (context, index) {
        final monthData = donationsByMonth[index];
        final monthName = _getMonthName(monthData['mes']);
        final donationCount = monthData['cantidad'];
        final maxCount = donationsByMonth.fold(
          0,
          (max, item) => item['cantidad'] > max ? item['cantidad'] : max,
        );

        return Container(
          width: 60,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                monthName,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: accentBlue,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: FractionallySizedBox(
                  heightFactor: maxCount > 0 ? donationCount / maxCount : 0,
                  child: Container(
                    width: 24,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [accent, Color(0xFFFFD60A)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                donationCount.toString(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: primaryDark,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Ene';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Abr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Ago';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dic';
      default:
        return '';
    }
  }
}
