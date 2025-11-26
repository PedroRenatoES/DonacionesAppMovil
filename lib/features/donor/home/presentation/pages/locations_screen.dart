import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
            'color': const Color(0xFF2A9D8F),
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
            'color': const Color(0xFFE63946),
            'icon': Icons.warehouse,
          });
        }
      }

      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar ubicaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _openInMaps(double? lat, double? lng, String nombre) async {
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coordenadas no disponibles para esta ubicación'),
          backgroundColor: Colors.orange,
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
          const SnackBar(
            content: Text('No se pudo abrir el mapa'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000814),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000814),
        elevation: 0,
        title: const Text(
          'Ubicaciones',
          style: TextStyle(
            color: Color(0xFFFFC300),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFC300)),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFC300)),
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
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay ubicaciones disponibles',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLocations,
                  color: const Color(0xFFFFC300),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final location = _locations[index];
                      final hasCoordinates = location['latitud'] != null && 
                                           location['longitud'] != null;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: location['color'].withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
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
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: location['color'].withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      location['icon'],
                                      color: location['color'],
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          location['nombre'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF000814),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          location['tipo'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: location['color'],
                                            fontWeight: FontWeight.w600,
                                          ),
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
                                                color: Color(0xFF778DA9),
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  location['direccion'],
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    color: Color(0xFF778DA9),
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
                                      color: Color(0xFF778DA9),
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
    );
  }
}
