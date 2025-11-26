import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  final int campaignId;

  const MapScreen({super.key, required this.campaignId});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
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

  List<dynamic> collectionPoints = [];
  bool isLoading = true;
  GoogleMapController? mapController;
  Set<Marker> markers = {};
  int? selectedPointIndex;
  bool showPointsList = false;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _headerController;
  late AnimationController _listController;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadCollectionPoints();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeController.forward();
    _headerController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadCollectionPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isLoading = false;
        });
        if (!mounted) return;
        _showErrorSnackBar('Token no encontrado');
        return;
      }

      final response = await http.get(
        Uri.parse(
          'http://10.0.2.2:8000/api/puntos-de-recoleccion/campana/${widget.campaignId}',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final points = json.decode(response.body);
        setState(() {
          collectionPoints = points;
          _createMarkers();
          isLoading = false;
        });
        _slideController.forward();
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (!mounted) return;
      _showErrorSnackBar('Error al cargar puntos de recolección');
    }
  }

  void _createMarkers() {
    markers.clear();
    for (int i = 0; i < collectionPoints.length; i++) {
      final point = collectionPoints[i];
      final coordinates = point['direccion'].split(', ');
      if (coordinates.length == 2) {
        final lat = double.tryParse(coordinates[0]);
        final lng = double.tryParse(coordinates[1]);

        if (lat != null && lng != null) {
          markers.add(
            Marker(
              markerId: MarkerId(point['id_punto'].toString()),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: point['nombre_punto'],
                snippet: 'Punto de recolección',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange,
              ),
              onTap: () {
                setState(() {
                  selectedPointIndex = i;
                });
                HapticFeedback.selectionClick();
              },
            ),
          );
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _animateToPoint(int index) {
    final point = collectionPoints[index];
    final coordinates = point['direccion'].split(', ');
    if (coordinates.length == 2) {
      final lat = double.tryParse(coordinates[0]);
      final lng = double.tryParse(coordinates[1]);

      if (lat != null && lng != null && mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
        );
        setState(() {
          selectedPointIndex = index;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              _buildCustomAppBar(),
              if (!isLoading) _buildStatsHeader(),
              Expanded(
                child: isLoading ? _buildLoadingState() : _buildMapContent(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: !isLoading && collectionPoints.isNotEmpty
          ? _buildFloatingActionButtons()
          : null,
    );
  }

  Widget _buildCustomAppBar() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _headerController,
              curve: Curves.easeOutBack,
            ),
          ),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryDark, primaryBlue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: primaryDark, blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.location_on, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Puntos de Recolección',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: white,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accent, const Color(0xFFFFD60A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.location_on, color: white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${collectionPoints.length}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: white,
                      height: 1,
                    ),
                  ),
                  Text(
                    'puntos ${collectionPoints.length == 1 ? 'encontrado' : 'encontrados'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      showPointsList = !showPointsList;
                    });
                    if (showPointsList) {
                      _listController.forward();
                    } else {
                      _listController.reverse();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: AnimatedRotation(
                      turns: showPointsList ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(
                        Icons.expand_more,
                        color: white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
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
              padding: const EdgeInsets.all(24),
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
              'Cargando puntos de recolección...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: accentBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    if (markers.isEmpty) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        _buildMap(),
        if (showPointsList) _buildPointsList(),
        if (selectedPointIndex != null) _buildSelectedPointCard(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
          ),
      child: Container(
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
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: errorColor,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No hay puntos disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'No se encontraron puntos de recolección\npara esta campaña',
                style: TextStyle(fontSize: 16, color: lightBlue, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _slideController,
              curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: primaryDark.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: markers.first.position,
              zoom: 12,
            ),
            markers: markers,
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: (_) {
              setState(() {
                selectedPointIndex = null;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPointsList() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _listController, curve: Curves.easeOutBack),
          ),
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          height: 200,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryDark.withOpacity(0.05), Colors.transparent],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: primaryDark, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Lista de Puntos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: collectionPoints.length,
                  itemBuilder: (context, index) {
                    final point = collectionPoints[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selectedPointIndex == index
                            ? accent.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: selectedPointIndex == index
                            ? Border.all(color: accent.withOpacity(0.3))
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _animateToPoint(index);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: accent,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        point['nombre_punto'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: primaryDark,
                                        ),
                                      ),
                                      Text(
                                        point['direccion'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: lightBlue,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
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
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedPointCard() {
    final point = collectionPoints[selectedPointIndex!];
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryDark.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, const Color(0xFFFFD60A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.location_on, color: white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      point['nombre_punto'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordenadas: ${point['direccion']}',
                      style: TextStyle(fontSize: 14, color: lightBlue),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        selectedPointIndex = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.close,
                        color: errorColor,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (collectionPoints.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [successColor, Color(0xFF20B2AA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: successColor.withOpacity(0.3),
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
                  if (mapController != null) {
                    mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(markers.first.position, 12),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  child: const Icon(Icons.my_location, color: white, size: 24),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accent, Color(0xFFFFD60A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
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
                _loadCollectionPoints();
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: const Icon(Icons.refresh, color: white, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
