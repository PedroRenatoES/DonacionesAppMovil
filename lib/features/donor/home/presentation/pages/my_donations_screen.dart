import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/donations_provider.dart';

class MyDonationsScreen extends ConsumerStatefulWidget {
  const MyDonationsScreen({super.key});

  @override
  MyDonationsScreenState createState() => MyDonationsScreenState();
}

class MyDonationsScreenState extends ConsumerState<MyDonationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late AnimationController _statsController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _statsAnimation;
  bool _showErrorBanner = true;

  // Paleta de colores consistente
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1B263B);
  static const Color accentBlue = Color(0xFF415A77);
  static const Color lightBlue = Color(0xFF778DA9);
  static const Color cream = Color(0xFFE0E1DD);
  static const Color accent = Color(0xFFFFB700);
  static const Color white = Color(0xFFFFFFFE);
  static const Color errorColor = Color(0xFFE63946);
  static const Color successColor = Color(0xFF2A9D8F);
  static const Color warningColor = Color(0xFFE76F51);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initAnimations();

    // Cargar donaciones al iniciar
    Future.microtask(
      () => ref.read(donationsProvider.notifier).loadDonations(),
    );
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _statsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _statsController.forward(from: 0);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _statsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(double progress) {
    if (progress <= 0.2) return errorColor;
    if (progress <= 0.6) return warningColor;
    return successColor;
  }

  String _getStatusText(double progress) {
    if (progress <= 0.2) return "Crítico";
    if (progress <= 0.6) return "En proceso";
    return "Disponible";
  }

  IconData _getStatusIcon(double progress) {
    if (progress <= 0.2) return Icons.warning_amber_rounded;
    if (progress <= 0.6) return Icons.hourglass_empty_rounded;
    return Icons.check_circle_rounded;
  }

  double _getTotalMoneyDonated(List<dynamic> moneyDonations) {
    return moneyDonations.fold(0.0, (sum, donation) {
      return sum + (donation['monto'] ?? 0.0);
    });
  }

  Widget _buildLoadingState() {
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: primaryDark.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(accent),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Cargando tus donaciones...',
              style: TextStyle(
                color: primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preparando el resumen de tu impacto',
              style: TextStyle(color: lightBlue, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent.withOpacity(0.1), accent.withOpacity(0.05)],
                ),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.volunteer_activism_rounded,
                size: 80,
                color: accent,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Sin donaciones registradas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¡Empieza a generar impacto con tu primera donación!',
              style: TextStyle(fontSize: 16, color: lightBlue, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String error) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Dismissible(
        key: const Key('error-banner'),
        direction: DismissDirection.up,
        onDismissed: (_) {
          HapticFeedback.lightImpact();
          setState(() => _showErrorBanner = false);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                warningColor.withOpacity(0.1),
                warningColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: warningColor.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: warningColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: warningColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: warningColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Datos no actualizados',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: lightBlue),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _showErrorBanner = false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No se pudieron cargar las donaciones más recientes: $error',
                style: TextStyle(fontSize: 14, color: accentBlue),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(donationsProvider.notifier).loadDonations();
                },
                icon: Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: warningColor,
                ),
                label: Text(
                  'Reintentar',
                  style: TextStyle(
                    color: warningColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Agregar esta variable de estado en tu clase
  bool _isStatsExpanded = false;

  Widget _buildStatsHeader(
    List<dynamic> groupedDonations,
    List<dynamic> moneyDonations,
  ) {
    final totalMoney = _getTotalMoneyDonated(moneyDonations);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _statsAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [primaryDark, primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header que siempre se muestra
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isStatsExpanded = !_isStatsExpanded;
                  });
                },
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.analytics_rounded,
                        color: white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tu Impacto',
                            style: TextStyle(
                              color: white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Resumen de todas tus contribuciones',
                            style: TextStyle(color: lightBlue, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: _isStatsExpanded ? 0.5 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido expandible con animación
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isStatsExpanded
                    ? Column(
                        children: [
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatContainer(
                                  value: '${groupedDonations.length}',
                                  label: 'Donaciones\nen Especie',
                                  icon: Icons.inventory_2_rounded,
                                  color: accent,
                                ),
                              ),
                              Container(
                                height: 60,
                                width: 1,
                                color: white.withOpacity(0.2),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              Expanded(
                                child: _buildStatContainer(
                                  value: '${moneyDonations.length}',
                                  label: 'Donaciones\nen Dinero',
                                  icon: Icons.attach_money_rounded,
                                  color: successColor,
                                ),
                              ),
                              Container(
                                height: 60,
                                width: 1,
                                color: white.withOpacity(0.2),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                              ),
                              Expanded(
                                child: _buildStatContainer(
                                  value: '\$${totalMoney.toStringAsFixed(0)}',
                                  label: 'Total\nDonado',
                                  icon: Icons.volunteer_activism_rounded,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatContainer({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            color: lightBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTabBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          labelPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          indicatorPadding: const EdgeInsets.all(4),
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [accent, Color(0xFFFFD60A)]),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          labelColor: primaryDark,
          unselectedLabelColor: lightBlue,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
          onTap: (index) => HapticFeedback.selectionClick(),
          tabs: const [
            Tab(icon: Icon(Icons.inventory_2_rounded), text: 'En Especie'),
            Tab(icon: Icon(Icons.attach_money_rounded), text: 'En Dinero'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar providers específicos para mejor rendimiento
    final isLoading = ref.watch(isLoadingProvider);
    final error = ref.watch(errorProvider);
    final groupedDonations = ref.watch(groupedDonationsProvider);
    final moneyDonations = ref.watch(moneyDonationsProvider);

    if (isLoading) {
      return _buildLoadingState();
    }

    // Error completo sin datos
    if (error != null && groupedDonations.isEmpty && moneyDonations.isEmpty) {
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: errorColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Error al cargar donaciones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'No pudimos cargar tu historial de donaciones',
                style: TextStyle(fontSize: 16, color: lightBlue),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(donationsProvider.notifier).loadDonations();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Estado vacío
    if (groupedDonations.isEmpty && moneyDonations.isEmpty) {
      return _buildEmptyState();
    }

    return Scaffold(
      backgroundColor: cream,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [cream, white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // Banner de error si existe pero tenemos datos
            if (error != null &&
                (groupedDonations.isNotEmpty || moneyDonations.isNotEmpty) &&
                _showErrorBanner)
              _buildErrorBanner(error),

            // Header con estadísticas
            _buildStatsHeader(groupedDonations, moneyDonations),

            // TabBar personalizado
            _buildCustomTabBar(),

            const SizedBox(height: 16),

            // TabBarView
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildInKindDonationsTab(groupedDonations),
                  _buildMoneyDonationsTab(moneyDonations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInKindDonationsTab(List<dynamic> groupedDonations) {
    if (groupedDonations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.inventory_2_rounded,
                size: 64,
                color: lightBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin donaciones en especie',
              style: TextStyle(
                fontSize: 18,
                color: accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán tus artículos donados',
              style: TextStyle(fontSize: 14, color: lightBlue),
            ),
          ],
        ),
      );
    }

    _staggerController.forward();

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref.read(donationsProvider.notifier).loadDonations();
      },
      color: accent,
      backgroundColor: white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groupedDonations.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                ),
              ),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(
                        (index * 0.1).clamp(0.0, 1.0),
                        ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
              child: _buildInKindDonationCard(groupedDonations[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInKindDonationCard(Map<String, dynamic> donation) {
    final totalQuantity = (donation['cantidad_total'] as num).toDouble();
    final remainingQuantity = (donation['cantidad_restante_total'] as num)
        .toDouble();
    final usedQuantity = totalQuantity - remainingQuantity;
    final progress = totalQuantity > 0
        ? remainingQuantity / totalQuantity
        : 0.0;
    final statusColor = _getStatusColor(progress);
    final distributions =
        donation['distribuciones'] as List<Map<String, dynamic>>;
    final hasDistributions = donation['has_distributions'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del producto
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [accent, Color(0xFFFFD60A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.inventory_2_rounded,
                    color: primaryDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['nombre_articulo'] ?? 'Artículo sin nombre',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: cream,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasDistributions
                              ? 'Distribuido en ${distributions.length} destino${distributions.length > 1 ? 's' : ''}'
                              : 'Pendiente de distribución',
                          style: const TextStyle(
                            fontSize: 12,
                            color: primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getStatusIcon(progress),
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getStatusText(progress),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Contenido detallado
            _buildInKindDonationContent(
              donation,
              distributions,
              hasDistributions,
              totalQuantity,
              usedQuantity,
              remainingQuantity,
              progress,
              statusColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInKindDonationContent(
    Map<String, dynamic> donation,
    List<Map<String, dynamic>> distributions,
    bool hasDistributions,
    double totalQuantity,
    double usedQuantity,
    double remainingQuantity,
    double progress,
    Color statusColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas en fila
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Donado',
                totalQuantity.toInt().toString(),
                Icons.volunteer_activism_rounded,
                successColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Utilizado',
                usedQuantity.toInt().toString(),
                Icons.people_alt_rounded,
                primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Disponible',
                remainingQuantity.toInt().toString(),
                Icons.inventory_rounded,
                statusColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Sección de destinos o estado
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cream.withOpacity(0.5), cream.withOpacity(0.2)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: lightBlue.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      hasDistributions
                          ? Icons.location_on_rounded
                          : Icons.schedule_rounded,
                      color: accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    hasDistributions
                        ? 'Destinos de distribución'
                        : 'Estado actual',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (hasDistributions)
                ...distributions.map(
                  (dist) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: lightBlue.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.local_shipping_rounded,
                            size: 16,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dist['nombre_paquete'] ?? 'Paquete sin nombre',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: primaryDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                dist['ubicacion'] ??
                                    'Ubicación no especificada',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: accentBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: warningColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: warningColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: warningColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Tu donación está en proceso de distribución',
                          style: TextStyle(
                            fontSize: 14,
                            color: primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Barra de progreso de impacto
        if (totalQuantity > 0) _buildImpactProgress(progress, hasDistributions),
      ],
    );
  }

  Widget _buildImpactProgress(double progress, bool hasDistributions) {
    final impactProgress = (1 - progress).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Impacto generado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            Text(
              '${(impactProgress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: lightBlue.withOpacity(0.2),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: impactProgress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [successColor, accent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          hasDistributions
              ? 'Tu donación está ayudando a personas en necesidad'
              : 'Tu donación será distribuida pronto',
          style: TextStyle(
            fontSize: 12,
            color: lightBlue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildMoneyDonationsTab(List<dynamic> moneyDonations) {
    if (moneyDonations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.attach_money_rounded,
                size: 64,
                color: lightBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin donaciones en dinero',
              style: TextStyle(
                fontSize: 18,
                color: accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aquí aparecerán tus contribuciones monetarias',
              style: TextStyle(fontSize: 14, color: lightBlue),
            ),
          ],
        ),
      );
    }

    _staggerController.forward();

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref.read(donationsProvider.notifier).loadDonations();
      },
      color: accent,
      backgroundColor: white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: moneyDonations.length,
        itemBuilder: (context, index) {
          return FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _staggerController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                ),
              ),
            ),
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: _staggerController,
                      curve: Interval(
                        (index * 0.1).clamp(0.0, 1.0),
                        ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                      ),
                    ),
                  ),
              child: _buildMoneyDonationCard(moneyDonations[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoneyDonationCard(Map<String, dynamic> donation) {
    final dinero = donation['dinero'] ?? {};
    final amount = double.tryParse(dinero['monto']?.toString() ?? '0') ?? 0.0;
    final moneda = dinero['moneda'] ?? 'BOB';
    final fecha = donation['fecha'] ?? '';
    final metodoPago = dinero['metodo_pago'] ?? 'No especificado';
    final referencia = dinero['referencia_pago'];
    final estado = dinero['estado'] ?? 'pendiente';
    
    // Determinar color según estado
    final Color estadoColor;
    final String estadoTexto;
    final IconData estadoIcon;
    
    switch (estado.toLowerCase()) {
      case 'validado':
      case 'confirmado':
        estadoColor = successColor;
        estadoTexto = 'Validado';
        estadoIcon = Icons.check_circle_rounded;
        break;
      case 'rechazado':
        estadoColor = errorColor;
        estadoTexto = 'Rechazado';
        estadoIcon = Icons.cancel_rounded;
        break;
      default:
        estadoColor = warningColor;
        estadoTexto = 'Pendiente';
        estadoIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [successColor, Color(0xFF38B2A4)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: successColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.attach_money_rounded,
                    color: white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$moneda ${amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: successColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Donación en dinero',
                        style: const TextStyle(
                          fontSize: 16,
                          color: primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fecha.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: lightBlue),
                            const SizedBox(width: 4),
                            Text(
                              fecha.substring(0, fecha.length > 16 ? 16 : fecha.length),
                              style: TextStyle(fontSize: 12, color: lightBlue),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        estadoIcon,
                        size: 16,
                        color: estadoColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: estadoColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Detalles de pago
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cream.withOpacity(0.5), cream.withOpacity(0.2)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lightBlue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.payment_rounded,
                          color: accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Detalles de pago',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow('Método de pago', metodoPago, Icons.credit_card),
                  if (referencia != null && referencia.toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow('Referencia', referencia.toString(), Icons.confirmation_number),
                  ],
                  const SizedBox(height: 12),
                  _buildDetailRow('Moneda', moneda, Icons.monetization_on),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mensaje de agradecimiento
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    successColor.withOpacity(0.05),
                    successColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: successColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: successColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: successColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tu donación está financiando proyectos de apoyo social',
                      style: TextStyle(
                        fontSize: 14,
                        color: primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryBlue),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: lightBlue,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
