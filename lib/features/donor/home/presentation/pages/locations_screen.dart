import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/theme/adminlte_theme.dart';
import '../../../../../core/widgets/adminlte_widgets.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen> {
  List<Map<String, dynamic>> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      // Cargar puntos de recolección
      final puntosResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/puntos-de-recoleccion'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      // Cargar almacenes
      final almacenesResponse = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/almacenes'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      List<Map<String, dynamic>> locations = [];

      if (puntosResponse.statusCode == 200) {
        final puntos = json.decode(puntosResponse.body) as List;
        for (var punto in puntos) {
          locations.add({
            'nombre': punto['nombre'] ?? 'Punto de Recolección',
            'direccion': punto['direccion'] ?? '',
            'latitud': punto['latitud'] != null ? double.tryParse(punto['latitud'].toString()) : null,
            'longitud': punto['longitud'] != null ? double.tryParse(punto['longitud'].toString()) : null,
            'tipo': 'Punto de Recolección',
            'color': AdminLTETheme.info,
            'icon': Icons.recycling,
          });
        }
      }

      if (almacenesResponse.statusCode == 200) {
        final almacenes = json.decode(almacenesResponse.body) as List;
        for (var almacen in almacenes) {
          locations.add({
            'nombre': almacen['nombre'] ?? 'Almacén',
            'direccion': almacen['direccion'] ?? '',
            'latitud': almacen['latitud'] != null ? double.tryParse(almacen['latitud'].toString()) : null,
            'longitud': almacen['longitud'] != null ? double.tryParse(almacen['longitud'].toString()) : null,
            'tipo': 'Almacén',
            'color': AdminLTETheme.danger,
            'icon': Icons.warehouse,
          });
        }
      }

      if (!mounted) return;
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: AdminLTETheme.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error al cargar ubicaciones: $e')),
              ],
            ),
            backgroundColor: AdminLTETheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(double? lat, double? lng, String nombre) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning, color: AdminLTETheme.white),
              SizedBox(width: 12),
              Expanded(child: Text('Coordenadas no disponibles para esta ubicación')),
            ],
          ),
          backgroundColor: AdminLTETheme.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
          ),
        ),
      );
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error, color: AdminLTETheme.white),
                SizedBox(width: 12),
                Expanded(child: Text('No se pudo abrir el mapa')),
              ],
            ),
            backgroundColor: AdminLTETheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminLTETheme.backgroundColor,
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
            decoration: BoxDecoration(
              color: AdminLTETheme.white,
              boxShadow: AdminLTETheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ubicaciones',
                      style: AdminLTETheme.h4,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AdminLTETheme.primary),
                      onPressed: _loadLocations,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: AdminLTEInfoBox(
                        title: 'Total',
                        value: '${_locations.length}',
                        icon: Icons.location_on,
                        color: AdminLTETheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Lista de ubicaciones
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AdminLTETheme.primary),
                    ),
                  )
                : _locations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 80,
                              color: AdminLTETheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No hay ubicaciones disponibles',
                              style: TextStyle(
                                color: AdminLTETheme.textMuted,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadLocations,
                        color: AdminLTETheme.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
                          itemCount: _locations.length,
                          itemBuilder: (context, index) {
                            final location = _locations[index];
                            final hasCoordinates = location['latitud'] != null && 
                                                 location['longitud'] != null;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: AdminLTETheme.paddingMedium),
                              decoration: AdminLTETheme.cardDecoration(),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: hasCoordinates
                                      ? () => _openInMaps(
                                            location['latitud'],
                                            location['longitud'],
                                            location['nombre'],
                                          )
                                      : null,
                                  borderRadius: BorderRadius.circular(AdminLTETheme.cardBorderRadius),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AdminLTETheme.paddingMedium),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: location['color'].withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            location['icon'],
                                            color: location['color'],
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: AdminLTETheme.paddingMedium),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                location['nombre'],
                                                style: AdminLTETheme.h6,
                                              ),
                                              const SizedBox(height: 4),
                                              AdminLTEBadge(
                                                text: location['tipo'],
                                                color: location['color'],
                                              ),
                                              if (location['direccion']
                                                  .toString()
                                                  .isNotEmpty) ...[
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.location_on,
                                                      size: 14,
                                                      color: AdminLTETheme.textMuted,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        location['direccion'],
                                                        style: const TextStyle(
                                                          fontSize: 13,
                                                          color: AdminLTETheme.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (hasCoordinates)
                                          Icon(
                                            Icons.arrow_forward_ios,
                                            size: 16,
                                            color: location['color'],
                                          )
                                        else
                                          const Icon(
                                            Icons.location_off,
                                            size: 16,
                                            color: AdminLTETheme.textMuted,
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
          ),
        ],
      ),
    );
  }
}
