import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DonationMoneyPage extends StatefulWidget {
  const DonationMoneyPage({super.key, required this.campaignId});
  final int campaignId;

  @override
  DonationMoneyPageState createState() => DonationMoneyPageState();
}

class DonationMoneyPageState extends State<DonationMoneyPage> {
  final _montoController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _qrKey = GlobalKey();

  File? _comprobanteFile;
  bool _isLoading = false;
  bool _isDownloading = false;
  String? _qrData;
  int _currentStep = 0;

  // Colores
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
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  void _generateQR() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      final monto = _montoController.text;
      // Generar datos del QR con información de pago
      final qrInfo = {
        'monto': monto,
        'moneda': 'BOB',
        'concepto': 'Donación',
        'id_campana': widget.campaignId,
      };
      setState(() {
        _qrData = json.encode(qrInfo);
        _currentStep = 1;
      });
    }
  }

  Future<void> _pickComprobante() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        HapticFeedback.lightImpact();
        setState(() {
          _comprobanteFile = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error al seleccionar imagen: $e');
    }
  }

  Future<void> _downloadQR() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      HapticFeedback.mediumImpact();
      final RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final String filePath =
          '${tempDir.path}/qr_donacion_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      await Gal.putImage(file.path);

      if (mounted) {
        _showSuccessSnackBar('QR guardado en la galería');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al guardar QR: $e');
      }
      _showErrorSnackBar('Error al guardar QR');
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _submitDonation() async {
    if (_comprobanteFile == null) {
      _showErrorSnackBar('Por favor sube el comprobante de pago');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final donanteId = prefs.getInt('donante_id');

      if (token == null || donanteId == null) {
        _showErrorSnackBar('Error de autenticación');
        return;
      }

      // 1. Crear la donación principal
      final donacionResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/donaciones'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'tipo_donacion': 'dinero',
          'fecha_donacion': DateTime.now().toIso8601String(),
          'id_donante': donanteId,
          'id_campana': widget.campaignId,
        }),
      );

      if (donacionResponse.statusCode != 201) {
        final error = json.decode(donacionResponse.body);
        _showErrorSnackBar(
            'Error al crear donación: ${error['message'] ?? 'Error desconocido'}');
        return;
      }

      final donacionData = json.decode(donacionResponse.body);
      final idDonacion = donacionData['id'];

      // 2. Subir comprobante
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/upload-comprobante'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('comprobante', _comprobanteFile!.path),
      );

      final uploadResponse = await request.send();
      final uploadResponseBody = await uploadResponse.stream.bytesToString();
      
      if (uploadResponse.statusCode != 200) {
        _showErrorSnackBar('Error al subir comprobante');
        return;
      }

      final uploadData = json.decode(uploadResponseBody);
      final comprobanteUrl = uploadData['path'];

      // 3. Crear donación en dinero
      final dineroResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/donaciones-en-dinero'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'id_donacion': idDonacion,
          'monto': double.parse(_montoController.text),
          'moneda': 'BOB',
          'metodo_pago': 'Pasarela',
          'referencia_pago': comprobanteUrl,
          'estado': 'pendiente',
        }),
      );

      if (dineroResponse.statusCode != 201 && dineroResponse.statusCode != 200) {
        final error = json.decode(dineroResponse.body);
        _showErrorSnackBar(
            'Error al registrar donación: ${error['message'] ?? 'Error desconocido'}');
        return;
      }

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error al procesar donación: $e');
      }
      _showErrorSnackBar('Error al procesar donación: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: white,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: successColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: successColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¡Donación registrada!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tu donación ha sido registrada exitosamente. Será revisada por nuestro equipo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Volver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: primaryDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donar Dinero',
          style: TextStyle(
            color: white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header con stepper
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryDark, primaryBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStepIndicator(0, 'Monto'),
                      _buildStepLine(0),
                      _buildStepIndicator(1, 'QR'),
                      _buildStepLine(1),
                      _buildStepIndicator(2, 'Comprobante'),
                    ],
                  ),
                ],
              ),
            ),

            // Contenido
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStep(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? accent : lightBlue.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? Icon(
                    step < _currentStep ? Icons.check : Icons.circle,
                    color: primaryDark,
                    size: 20,
                  )
                : Text(
                    '${step + 1}',
                    style: const TextStyle(
                      color: white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? white : lightBlue,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int step) {
    final isActive = _currentStep > step;
    return Container(
      width: 40,
      height: 2,
      color: isActive ? accent : lightBlue.withOpacity(0.3),
      margin: const EdgeInsets.only(bottom: 30),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildMontoForm();
      case 1:
        return _buildQRView();
      case 2:
        return _buildComprobanteForm();
      default:
        return _buildMontoForm();
    }
  }

  Widget _buildMontoForm() {
    return Container(
      key: const ValueKey('monto'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa el monto a donar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La donación será en Bolivianos (BOB)',
              style: TextStyle(
                fontSize: 14,
                color: accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _montoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Monto (BOB)',
                prefixIcon: const Icon(Icons.attach_money, color: accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: accent, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa un monto';
                }
                final monto = double.tryParse(value);
                if (monto == null || monto <= 0) {
                  return 'Ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _generateQR,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: primaryDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Generar QR de Pago',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRView() {
    return Container(
      key: const ValueKey('qr'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Escanea este QR para pagar',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Monto: ${_montoController.text} BOB',
            style: const TextStyle(
              fontSize: 18,
              color: accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          RepaintBoundary(
            key: _qrKey,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: lightBlue.withOpacity(0.3), width: 2),
              ),
              child: PrettyQrView.data(
                data: _qrData ?? '',
                decoration: const PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(
                    color: primaryDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadQR,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryDark),
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isDownloading ? 'Guardando...' : 'Descargar QR'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentStep = 2;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: primaryDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continuar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComprobanteForm() {
    return Container(
      key: const ValueKey('comprobante'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sube tu comprobante de pago',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Adjunta una captura o foto del comprobante',
            style: TextStyle(
              fontSize: 14,
              color: accentBlue,
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _pickComprobante,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _comprobanteFile != null ? accent : lightBlue.withOpacity(0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _comprobanteFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _comprobanteFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 64,
                          color: lightBlue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Toca para seleccionar imagen',
                          style: TextStyle(
                            fontSize: 16,
                            color: accentBlue,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitDonation,
              style: ElevatedButton.styleFrom(
                backgroundColor: successColor,
                foregroundColor: white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(white),
                      ),
                    )
                  : const Text(
                      'Enviar Donación',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
