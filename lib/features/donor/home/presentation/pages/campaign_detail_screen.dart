import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_donaciones_1/features/donor/home/domain/entities/campaign.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'donation_money_screen.dart';
import 'donation_request_screen.dart';

class CampaignDetailScreen extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailScreen({super.key, required this.campaign});

  @override
  CampaignDetailScreenState createState() => CampaignDetailScreenState();
}

class CampaignDetailScreenState extends State<CampaignDetailScreen> {
  String? _token;
  bool _isLoadingImage = true;
  Uint8List? _imageBytes;

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
    _loadTokenAndImage();
  }

  Future<void> _loadTokenAndImage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');

    if (widget.campaign.imageUrl != null && widget.campaign.imageUrl!.isNotEmpty) {
      try {
        if (kDebugMode) {
          print('Loading image from: ${widget.campaign.imageUrl}');
        }
        
        final response = await http.get(
          Uri.parse(widget.campaign.imageUrl!),
        );

        if (kDebugMode) {
          print('Image response status: ${response.statusCode}');
        }

        if (response.statusCode == 200 && mounted) {
          setState(() {
            _imageBytes = response.bodyBytes;
            _isLoadingImage = false;
          });
        } else {
          if (mounted) {
            setState(() {
              _isLoadingImage = false;
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading image: $e');
        }
        if (mounted) {
          setState(() {
            _isLoadingImage = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingImage = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  int _daysRemaining() {
    final now = DateTime.now();
    final difference = widget.campaign.endDate.difference(now);
    return difference.inDays;
  }

  bool _isActive() {
    final now = DateTime.now();
    return now.isAfter(widget.campaign.startDate) &&
        now.isBefore(widget.campaign.endDate);
  }

  @override
  Widget build(BuildContext context) {
    final daysLeft = _daysRemaining();
    final isActive = _isActive();

    return Scaffold(
      backgroundColor: primaryDark,
      body: CustomScrollView(
        slivers: [
          // App Bar con imagen de fondo
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: primaryBlue,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryDark.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderImage(),
            ),
          ),

          // Contenido
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado de la campaña
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? accent : accentBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.campaign_rounded
                                    : Icons.schedule_rounded,
                                color: primaryDark,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive ? 'Activa' : 'Inactiva',
                                style: const TextStyle(
                                  color: primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (isActive && daysLeft > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  color: white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$daysLeft días restantes',
                                  style: const TextStyle(
                                    color: white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Título
                    Text(
                      widget.campaign.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fechas
                    _buildInfoRow(
                      Icons.calendar_today_rounded,
                      'Fecha de inicio',
                      _formatDate(widget.campaign.startDate),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.event_rounded,
                      'Fecha de fin',
                      _formatDate(widget.campaign.endDate),
                    ),
                    const SizedBox(height: 24),

                    // Descripción
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: lightBlue.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.campaign.description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: primaryDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botones de acción
                    if (isActive) ...[
                      const Text(
                        '¿Cómo quieres participar?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón Donar Dinero
                      _buildActionButton(
                        icon: Icons.volunteer_activism_rounded,
                        title: 'Donar Dinero',
                        description: 'Realiza una donación monetaria',
                        gradient: const LinearGradient(
                          colors: [accent, Color(0xFFFFD60A)],
                        ),
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DonationMoneyPage(
                                campaignId: widget.campaign.id,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Botón Solicitar Recolección
                      _buildActionButton(
                        icon: Icons.inventory_2_rounded,
                        title: 'Solicitar Recolección',
                        description: 'Dona artículos físicos',
                        gradient: const LinearGradient(
                          colors: [primaryBlue, accentBlue],
                        ),
                        textColor: white,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => DonationRequestPage(
                                campaignId: widget.campaign.id.toString(),
                                campaignName: widget.campaign.name,
                              ),
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: accentBlue.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 48,
                              color: accentBlue,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Campaña no disponible',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              daysLeft < 0
                                  ? 'Esta campaña ha finalizado'
                                  : 'Esta campaña aún no ha comenzado',
                              style: TextStyle(
                                fontSize: 14,
                                color: primaryDark.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isLoadingImage)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          )
        else if (_imageBytes != null)
          Image.memory(
            _imageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildImagePlaceholder();
            },
          )
        else
          _buildImagePlaceholder(),
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                primaryDark.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: white,
                size: 64,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin imagen de campaña',
              style: TextStyle(
                color: white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: lightBlue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryDark, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: primaryDark.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    color: primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
    Color textColor = primaryDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: textColor == white
                        ? white.withOpacity(0.2)
                        : primaryDark.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: textColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: textColor.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: textColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
