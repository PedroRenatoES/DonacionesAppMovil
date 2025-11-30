// =============================================================================
// UI COMPONENTS
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../domain/entities/donation_request.dart';
import '../providers/donation_request_provider.dart';
import '../../../../../core/theme/adminlte_theme.dart';
import '../../../../../core/widgets/adminlte_widgets.dart';

// =============================================================================
// DESIGN SYSTEM CONSTANTS
// =============================================================================

class AppColors {
  static const Color primaryDark = Color(0xFF0D1B2A);
  static const Color primaryBlue = Color(0xFF1B263B);
  static const Color accentBlue = Color(0xFF415A77);
  static const Color lightBlue = Color(0xFF778DA9);
  static const Color cream = Color(0xFFE0E1DD);
  static const Color accent = Color(0xFFFFB700);
  static const Color white = Color(0xFFFFFFFE);
  static const Color errorColor = Color(0xFFE63946);
  static const Color successColor = Color(0xFF2A9D8F);
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [AppColors.primaryDark, AppColors.primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient background = LinearGradient(
    colors: [AppColors.cream, AppColors.white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient button = LinearGradient(
    colors: [AppColors.accent, Color(0xFFFFD60A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppShadows {
  static List<BoxShadow> standard = [
    BoxShadow(
      color: AppColors.primaryDark.withOpacity(0.08),
      blurRadius: 20,
      spreadRadius: 0,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> button = [
    BoxShadow(
      color: AppColors.accent.withOpacity(0.3),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
}

class AppTextStyles {
  static const TextStyle titleMain = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.primaryDark,
    height: 1.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.accentBlue,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 16,
    color: AppColors.accentBlue,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.lightBlue,
  );
}

// =============================================================================
// DONATION REQUEST CARD WIDGET
// =============================================================================

class DonationRequestCard extends StatelessWidget {
  final DonationRequest request;
  final int index;
  final AnimationController animationController;
  final VoidCallback? onTap;

  const DonationRequestCard({
    super.key,
    required this.request,
    required this.index,
    required this.animationController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
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
                parent: animationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.standard,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                onTap?.call();
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con foto y info básica
                    Row(
                      children: [
                        // Foto del request
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppShadows.standard,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: request.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.cream,
                                child: const Icon(
                                  Icons.image_outlined,
                                  color: AppColors.lightBlue,
                                  size: 24,
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.cream,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: AppColors.lightBlue,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Info del donante
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.donorName,
                                style: AppTextStyles.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppColors.lightBlue,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      request.location,
                                      style: AppTextStyles.caption,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppGradients.button,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Pendiente',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Detalle de la solicitud
                    Text(
                      'Detalle de la solicitud',
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      request.requestDetails,
                      style: AppTextStyles.bodyText,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    // Footer con acciones
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          // Botón ver ubicación
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.accent.withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    _showLocationDialog(context);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.map_outlined,
                                          size: 18,
                                          color: AppColors.accent,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Ver ubicación',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.accent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Botón aceptar solicitud
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: AppGradients.button,
                                boxShadow: AppShadows.button,
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _acceptRequest(context);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: AppColors.white,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Aceptar',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
        ),
      ),
    );
  }

  void _showLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Ubicación de recolección', style: AppTextStyles.subtitle),
        content: SizedBox(
          width: 300,
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(request.latitude, request.longitude),
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('ubicacion'),
                  position: LatLng(request.latitude, request.longitude),
                ),
              },
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled:
                  false, // Desactiva scroll para evitar conflictos
              zoomGesturesEnabled: false, // Desactiva zoom por gestos
              tiltGesturesEnabled: false, // Desactiva inclinación
              rotateGesturesEnabled: false, // Desactiva rotación
              mapType: MapType.normal,
            ),
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              gradient: AppGradients.button,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cerrar',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _acceptRequest(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('Solicitud aceptada correctamente')),
          ],
        ),
        backgroundColor: AppColors.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// =============================================================================
// MAIN DONATIONS REQUEST SCREEN
// =============================================================================

class DonationsRequestScreen extends ConsumerStatefulWidget {
  const DonationsRequestScreen({super.key});

  @override
  ConsumerState<DonationsRequestScreen> createState() =>
      _DonationsRequestScreenState();
}

class _DonationsRequestScreenState extends ConsumerState<DonationsRequestScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _searchController = TextEditingController();

    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(donationRequestNotifierProvider.notifier).loadDonationRequests();
    });
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

    _fadeController.forward();
    _staggerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final donationRequestState = ref.watch(donationRequestNotifierProvider);

    return Scaffold(
      backgroundColor: AdminLTETheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Mis Solicitudes',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: AdminLTETheme.navbarDark,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              ref
                  .read(donationRequestNotifierProvider.notifier)
                  .loadDonationRequests();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (donationRequestState.isLoadingDonationRequest) {
            return _buildLoadingState();
          } else if (donationRequestState.errorMessage != null) {
            return _buildErrorState(
              donationRequestState.errorMessage!,
            );
          } else if (donationRequestState.donationRequests.isEmpty) {
            return _buildEmptyState();
          } else {
            return _buildLoadedState(
              donationRequestState.donationRequests,
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRequestDialog(context),
        backgroundColor: AdminLTETheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nueva Solicitud',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showCreateRequestDialog(BuildContext context) {
    // Navegar directo al formulario de creación
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateRequestScreen(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: AdminLTETheme.backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AdminLTETheme.cardDecoration(),
              child: CircularProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AdminLTETheme.primary,
                ),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cargando solicitudes...',
              style: AdminLTETheme.bodyText.copyWith(color: AdminLTETheme.textPrimary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedState(List<DonationRequest> requests) {
    if (requests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await ref
            .read(donationRequestNotifierProvider.notifier)
            .loadDonationRequests();
      },
      color: AdminLTETheme.primary,
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          return DonationRequestCard(
            request: requests[index],
            index: index,
            animationController: _staggerController,
            onTap: () => _navigateToDetail(requests[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: AdminLTETheme.cardDecoration(),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: AdminLTETheme.info,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay solicitudes',
                    style: AdminLTETheme.h5.copyWith(color: AdminLTETheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No se encontraron solicitudes de recolección en este momento.',
                    style: AdminLTETheme.caption.copyWith(color: AdminLTETheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            AdminLTEButton(
              text: 'Actualizar',
              icon: Icons.refresh,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(donationRequestNotifierProvider.notifier)
                    .loadDonationRequests();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AdminLTEAlert(
              message: message,
              icon: Icons.error_outline,
              color: AdminLTETheme.danger,
            ),
            const SizedBox(height: 24),
            AdminLTEButton(
              text: 'Reintentar',
              icon: Icons.refresh,
              color: AdminLTETheme.primary,
              onPressed: () {
                HapticFeedback.lightImpact();
                ref
                    .read(donationRequestNotifierProvider.notifier)
                    .loadDonationRequests();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(DonationRequest request) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DonationRequestDetailScreen(request: request),
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

// =============================================================================
// DETAIL SCREEN (Placeholder)
// =============================================================================

class DonationRequestDetailScreen extends StatelessWidget {
  final DonationRequest request;

  const DonationRequestDetailScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminLTETheme.backgroundColor,
      appBar: AppBar(
        title: Text('Detalle de Solicitud'),
        backgroundColor: AdminLTETheme.navbarDark,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Text(
          'Detalle de la solicitud #${request.requestId}',
          style: AdminLTETheme.h4,
        ),
      ),
    );
  }
}

// =============================================================================
// CREATE REQUEST SCREEN
// =============================================================================

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ubicacionController = TextEditingController();
  final _detalleController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _ubicacionController.dispose();
    _detalleController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    await ref.read(donationRequestNotifierProvider.notifier).createDonationRequest(
          ubicacion: _ubicacionController.text.trim(),
          detalleSolicitud: _detalleController.text.trim(),
        );

    final state = ref.read(donationRequestNotifierProvider);

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(state.successMessage!)),
              ],
            ),
            backgroundColor: AdminLTETheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Volver a la pantalla anterior
        Navigator.of(context).pop();
      } else if (state.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(state.errorMessage!)),
              ],
            ),
            backgroundColor: AdminLTETheme.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminLTETheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Nueva Solicitud',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AdminLTETheme.navbarDark,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información
              AdminLTECard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AdminLTETheme.info),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Completa el formulario para solicitar la recolección de tu donación',
                        style: TextStyle(
                          fontSize: 14,
                          color: AdminLTETheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Formulario
              Text(
                'Datos de la Solicitud',
                style: AdminLTETheme.h6,
              ),
              const SizedBox(height: 12),
              // Campo Ubicación
              TextFormField(
                controller: _ubicacionController,
                decoration: InputDecoration(
                  labelText: 'Ubicación *',
                  hintText: 'Ej: Calle 123, Barrio Centro',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AdminLTETheme.inputBorderRadius,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La ubicación es requerida';
                  }
                  return null;
                },
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Campo Detalle
              TextFormField(
                controller: _detalleController,
                decoration: InputDecoration(
                  labelText: 'Detalle de la donación *',
                  hintText: 'Describe qué deseas donar',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AdminLTETheme.inputBorderRadius,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El detalle es requerido';
                  }
                  return null;
                },
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              // Botón enviar
              SizedBox(
                width: double.infinity,
                child: AdminLTEButton(
                  text: _isSubmitting ? 'Enviando...' : 'Enviar Solicitud',
                  icon: _isSubmitting ? null : Icons.send,
                  onPressed: _isSubmitting ? null : _submitRequest,
                  block: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

