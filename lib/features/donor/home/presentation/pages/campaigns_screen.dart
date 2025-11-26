import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_donaciones_1/features/donor/home/domain/entities/campaign.dart';
import 'package:flutter_donaciones_1/features/donor/home/presentation/providers/campaigns_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/constants/colors.dart';
import 'donation_money_screen.dart';
import 'donation_request_screen.dart';
import '../../../map/presentation/pages/map_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CampaignsScreen extends ConsumerStatefulWidget {
  const CampaignsScreen({super.key});

  @override
  CampaignsScreenState createState() => CampaignsScreenState();
}

class CampaignsScreenState extends ConsumerState<CampaignsScreen>
    with TickerProviderStateMixin {
  List<Campaign> campaigns = [];
  bool isLoading = true;
  String? _token;
  late AnimationController _fadeController;
  late AnimationController _staggerController;
  bool _animationsInitialized = false;

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

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadToken();
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
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    // Recargar campañas automáticamente al obtener el token
    if (mounted) {
      ref.read(campaignsNotifierProvider.notifier).refreshCampaigns();
    }
  }

  void _startAnimations() {
    if (!_animationsInitialized) {
      _animationsInitialized = true;
      _fadeController.forward();
      _staggerController.forward();
    }
  }

  void _resetAnimations() {
    _animationsInitialized = false;
    _fadeController.reset();
    _staggerController.reset();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<Widget> _buildCampaignImage(String? imageUrl, String? token) async {
    if (imageUrl == null || token == null) {
      return _buildImagePlaceholder(
        icon: Icons.campaign_rounded,
        text: 'Imagen no disponible',
      );
    }

    try {
      final response = await http.get(
        Uri.parse(imageUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Image.memory(
            response.bodyBytes,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder(
                icon: Icons.image_not_supported_rounded,
                text: 'Error al cargar imagen',
              );
            },
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading image: $e');
      }
    }

    return _buildImagePlaceholder(
      icon: Icons.image_not_supported_rounded,
      text: 'Error al cargar imagen',
    );
  }

  Widget _buildImagePlaceholder({
    required IconData icon,
    required String text,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: white, size: 32),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                color: white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(20),
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
              'Cargando campañas...',
              style: TextStyle(
                color: primaryDark,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.campaign_outlined, size: 64, color: accent),
            ),
            const SizedBox(height: 24),
            const Text(
              'No hay campañas disponibles',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Desliza hacia abajo para actualizar',
              style: TextStyle(fontSize: 14, color: lightBlue),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en los mensajes de error/éxito
    ref.listen(campaignsNotifierProvider.select((state) => state.errorMessage), (
      previous,
      next,
    ) {
      if (next != null) {
        _showSnackBar(next, AppColors.errorColor, Icons.error_outline);
        // Corregido: usar campaignsNotifierProvider en lugar de inventoryNotifierProvider
        ref.read(campaignsNotifierProvider.notifier).clearMessages();
      }
    });

    ref.listen(
      campaignsNotifierProvider.select((state) => state.successMessage),
      (previous, next) {
        if (next != null) {
          _showSnackBar(
            next,
            AppColors.successColor,
            Icons.check_circle_outline,
          );
          // Corregido: usar campaignsNotifierProvider en lugar de inventoryNotifierProvider
          ref.read(campaignsNotifierProvider.notifier).clearMessages();
        }
      },
    );

    campaigns = ref.watch(campaignsProvider);
    final isLoading = ref.watch(isLoadingCampaignsProvider);

    // Iniciar animaciones cuando las campañas se cargan
    if (!isLoading && campaigns.isNotEmpty && !_animationsInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAnimations();
      });
    }

    if (isLoading) {
      return _buildLoadingState();
    }

    if (campaigns.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          HapticFeedback.lightImpact();
          ref.read(campaignsNotifierProvider.notifier).refreshCampaigns();
        },
        color: accent,
        backgroundColor: white,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: _buildEmptyState(),
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
          HapticFeedback.lightImpact();
          _resetAnimations();
          // Las animaciones se reiniciarán automáticamente cuando se recarguen las campañas
          await ref.read(campaignsNotifierProvider.notifier).refreshCampaigns();
        },
        color: accent,
        backgroundColor: white,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: campaigns.length,
          itemBuilder: (context, index) {
            if (kDebugMode) {
              print('Building item at index: $index');
            }
            final campaign = campaigns[index];
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
                          curve: Curves.easeOut,
                        ),
                      ),
                    ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 24),
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
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    MapScreen(campaignId: campaign.id),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
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
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen de la campaña
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20),
                              ),
                              child: FutureBuilder<Widget>(
                                future: _buildCampaignImage(
                                  campaign.imageUrl,
                                  _token,
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [primaryBlue, accentBlue],
                                        ),
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                accent,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }
                                  return snapshot.data ?? Container();
                                },
                              ),
                            ),
                          ),

                          // Contenido de la campaña
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título
                                Text(
                                  campaign.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: primaryDark,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Descripción
                                Text(
                                  campaign.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: accentBlue,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),

                                // Organizador
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cream,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: accent,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_rounded,
                                          size: 16,
                                          color: primaryDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Organizador: ${campaign.organizer}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: primaryDark,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // Botones de acción
                                Column(
                                  children: [
                                    Row(
                                      children: [
                                        // Botón donar dinero
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              gradient: const LinearGradient(
                                                colors: [
                                                  accent,
                                                  Color(0xFFFFD60A),
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: accent.withOpacity(
                                                    0.3,
                                                  ),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
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
                                                      pageBuilder:
                                                          (
                                                            context,
                                                            animation,
                                                            secondaryAnimation,
                                                          ) =>
                                                              DonationMoneyPage(
                                                                campaignId:
                                                                    campaign.id,
                                                              ),
                                                      transitionsBuilder:
                                                          (
                                                            context,
                                                            animation,
                                                            secondaryAnimation,
                                                            child,
                                                          ) {
                                                            return SlideTransition(
                                                              position: animation
                                                                  .drive(
                                                                    Tween(
                                                                      begin:
                                                                          const Offset(
                                                                            0.0,
                                                                            1.0,
                                                                          ),
                                                                      end: Offset
                                                                          .zero,
                                                                    ),
                                                                  ),
                                                              child: child,
                                                            );
                                                          },
                                                    ),
                                                  );
                                                },
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      const Icon(
                                                        Icons
                                                            .volunteer_activism_rounded,
                                                        size: 18,
                                                        color: primaryDark,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      const Text(
                                                        'Donar',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: primaryDark,
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
                                    const SizedBox(height: 12),
                                    // Botón solicitar donación
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        color: primaryBlue,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryBlue.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 0,
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
                                                pageBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                    ) => DonationRequestPage(
                                                      campaignId: campaign.id
                                                          .toString(),
                                                      campaignName:
                                                          campaign.name,
                                                    ),
                                                transitionsBuilder:
                                                    (
                                                      context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child,
                                                    ) {
                                                      return SlideTransition(
                                                        position: animation
                                                            .drive(
                                                              Tween(
                                                                begin:
                                                                    const Offset(
                                                                      0.0,
                                                                      1.0,
                                                                    ),
                                                                end:
                                                                    Offset.zero,
                                                              ),
                                                            ),
                                                        child: child,
                                                      );
                                                    },
                                              ),
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.request_page_rounded,
                                                  size: 18,
                                                  color: white,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Solicitar Donación',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
            );
          },
        ),
      ),
    );
  }
}
