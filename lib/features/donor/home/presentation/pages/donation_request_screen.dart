import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class DonationRequestPage extends StatefulWidget {
  final String campaignId;
  final String campaignName;

  const DonationRequestPage({
    super.key,
    required this.campaignId,
    required this.campaignName,
  });

  @override
  DonationRequestPageState createState() => DonationRequestPageState();
}

class DonationRequestPageState extends State<DonationRequestPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _ubicacionController = TextEditingController();
  final _detalleController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  double? _latitud;
  double? _longitud;
  File? _selectedImage;
  String? _imageUrl;
  String? _token;
  String? _userId;

  late AnimationController _slideController;
  late AnimationController _fadeController;

  GoogleMapController? _mapController;
  LatLng? _selectedLatLng;

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
    _loadUserData();
    _getCurrentLocation();
  }

  void _initAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideController.forward();
    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('donante_id').toString();
    print('_token: $_token, _userId: $_userId');
    if (_token == null || _userId == null) {
      _showErrorSnackBar(
        'Datos de usuario no encontrados. Inicia sesión nuevamente.',
      );
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _ubicacionController.dispose();
    _detalleController.dispose();
    _mapController?.dispose();
    super.dispose();
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: white),
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
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {});

    try {
      bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isLocationServiceEnabled) {
        setState(() {
          _latitud = null;
          _longitud = null;
        });
        _showLocationWarning('Los servicios de ubicación están deshabilitados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _latitud = null;
            _longitud = null;
          });
          _showLocationWarning('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _latitud = null;
          _longitud = null;
        });
        _showLocationWarning('Permisos de ubicación denegados permanentemente. Por favor, habilítalos en la configuración del dispositivo.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _selectedLatLng = LatLng(_latitud!, _longitud!);
        _ubicacionController.text =
            '${_latitud!.toStringAsFixed(6)}, ${_longitud!.toStringAsFixed(6)}';
      });

      _showSuccessSnackBar('Ubicación obtenida correctamente');
    } catch (e) {
      print('Error al obtener ubicación: $e');
      setState(() {
        _latitud = null;
        _longitud = null;
      });
      _showLocationWarning('Error al obtener la ubicación. Por favor, inténtalo de nuevo.');
    }
  }

  void _showLocationWarning(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.location_off, color: errorColor),
            const SizedBox(width: 8),
            const Text('Ubicación Requerida'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 12),
            const Text(
              'Para continuar con la solicitud de donación, necesitamos acceder a tu ubicación.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getCurrentLocation();
            },
            child: const Text('Reintentar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Geolocator.openAppSettings();
              if (!context.mounted) return;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Abrir Configuración'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar la imagen: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
        await _uploadImage();
      }
    } catch (e) {
      _showErrorSnackBar('Error al tomar la foto: $e');
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null || _token == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://10.0.2.2:8000/api/imagenes-solicitud-recogida',
        ),
      );

      request.headers['Authorization'] = 'Bearer $_token';
      request.files.add(
        await http.MultipartFile.fromPath('image', _selectedImage!.path),
      );

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      if (response.statusCode == 201) {
        setState(() {
          _imageUrl = jsonResponse['url'];
        });
        _showSuccessSnackBar('Imagen subida correctamente');
      } else {
        _showErrorSnackBar(
          'Error al subir la imagen: ${jsonResponse['error']}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al subir la imagen: $e');
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitud == null || _longitud == null) {
      _showLocationWarning('Para enviar la solicitud, necesitamos tu ubicación actual');
      return;
    }
    if (_token == null || _userId == null) {
      print('Datos de usuario: ${_token}, ${_userId}');
      _showErrorSnackBar('Datos de usuario no disponibles');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://10.0.2.2:8000/api/solicitudesRecoleccion',
        ),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_donante': int.parse(_userId!),
          'ubicacion': _ubicacionController.text.trim(),
          'detalle_solicitud': _detalleController.text.trim(),
          'latitud': _latitud,
          'longitud': _longitud,
          'foto_url': _imageUrl,
        }),
      );
      print('''
'id_donante': ${int.parse(_userId!)},
'ubicacion': ${_ubicacionController.text.trim()},
'detalle_solicitud': ${_detalleController.text.trim()},
'latitud': $_latitud,
'longitud': $_longitud,
'foto_url': $_imageUrl,
''');
      if (response.statusCode == 201) {
        _showSuccessSnackBar('Solicitud de donación enviada correctamente');
        if (!mounted) return;
        Navigator.of(context).pop();
      } else {
        final errorData = json.decode(response.body);
        _showErrorSnackBar(
          'Error: ${errorData['error'] ?? 'Error desconocido'}',
        );
      }
    } catch (e) {
      _showErrorSnackBar('Error al enviar la solicitud: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: lightBlue.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Seleccionar imagen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    onTap: () {
                      Navigator.pop(context);
                      _takePhoto();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildImageOptionButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galería',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: accent.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapSelector() {
    final initialLatLng =
        _selectedLatLng ??
        const LatLng(-17.722552, -63.174224); // CDMX por defecto
    return SizedBox(
      height: 250,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialLatLng,
            zoom: 15,
          ),
          myLocationEnabled: true,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          markers: _selectedLatLng == null
              ? {}
              : {
                  Marker(
                    markerId: const MarkerId('selected'),
                    position: _selectedLatLng!,
                    draggable: true,
                    onDragEnd: (newPos) {
                      setState(() {
                        _selectedLatLng = newPos;
                        _latitud = newPos.latitude;
                        _longitud = newPos.longitude;
                      });
                    },
                  ),
                },
          onTap: (latLng) {
            setState(() {
              _selectedLatLng = latLng;
              _latitud = latLng.latitude;
              _longitud = latLng.longitude;
            });
          },
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Asegura que el contenido se mueva con el teclado
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: primaryDark.withOpacity(0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: primaryDark,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Solicitar Donación',
          style: TextStyle(
            color: primaryDark,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeController,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
              .animate(
                CurvedAnimation(
                  parent: _slideController,
                  curve: Curves.easeOut,
                ),
              ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta de información
                  Container(
                    width: double.infinity,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: accent,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Información de la solicitud',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: cream,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.campaign_rounded,
                                color: primaryBlue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Campaña: ${widget.campaignName}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo de ubicación
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMapSelector(),
                        const SizedBox(height: 12),
                        if (_selectedLatLng == null)
                          const Text(
                            'Toca el mapa para seleccionar tu ubicación',
                            style: TextStyle(color: accentBlue, fontSize: 13),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo de detalle
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle de la solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _detalleController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            hintText:
                                'Describe qué tipo de donación necesitas...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(
                                Icons.description_rounded,
                                color: accent,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: lightBlue.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: lightBlue.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: accent,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: cream.withOpacity(0.5),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El detalle de la solicitud es requerido';
                            }
                            if (value.trim().length < 10) {
                              return 'El detalle debe tener al menos 10 caracteres';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sección de imagen
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Imagen de la solicitud',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedImage != null) ...[
                          Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: accent.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isUploadingImage)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cream,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Subiendo imagen...',
                                    style: TextStyle(
                                      color: primaryDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isUploadingImage
                                ? null
                                : _showImagePickerDialog,
                            icon: const Icon(
                              Icons.add_a_photo_rounded,
                              color: white,
                            ),
                            label: Text(
                              _selectedImage == null
                                  ? 'Agregar imagen'
                                  : 'Cambiar imagen',
                              style: const TextStyle(
                                color: white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Botón de envío
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor: accent.withOpacity(0.3),
                      ),
                      child: _isLoading
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      primaryDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Enviando solicitud...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: primaryDark,
                                  ),
                                ),
                              ],
                            )
                          : const Text(
                              'Enviar Solicitud',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryDark,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
