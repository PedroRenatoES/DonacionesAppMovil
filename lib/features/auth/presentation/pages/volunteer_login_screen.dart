import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '/features/auth/presentation/pages/login_type_screen.dart';
import '/features/main/presentation/pages/volunteer_main_screen.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class VolunteerLoginScreen extends StatefulWidget {
  const VolunteerLoginScreen({super.key});

  @override
  VolunteerLoginScreenState createState() => VolunteerLoginScreenState();
}

class VolunteerLoginScreenState extends State<VolunteerLoginScreen> {
  final _ciController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_ciController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor complete todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http
          .post(
            Uri.parse('http://10.0.2.2:8000/api/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'ci': _ciController.text,
              'contrasena': _passwordController.text,
            }),
          )
          .timeout(Duration(seconds: 10));

      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();

        // Corregido: Usa 'usuario' en lugar de 'user' (como viene en la respuesta)
        await prefs.setString('token', data['token']);
        await prefs.setInt(
          'user_id',
          data['usuario']['id'],
        ); // <- Cambiado aquí
        await prefs.setString('user_type', 'voluntario');
        await prefs.setString(
          'user_name',
          data['usuario']['nombres'],
        ); // Guarda el nombre

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => VolunteerMainScreen()),
        );
      } else {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${response.statusCode} - ${data['message'] ?? data['error']}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on TimeoutException catch (_) {
      print('⏳ Tiempo de espera agotado.');
    } on SocketException catch (e) {
      print('🌐 Error de red: $e');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error durante el login: $e'), // Muestra el error real
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFFFFC300),
            size: 22,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginTypeScreen()),
            );
          },
        ),
      ),
      backgroundColor: Color(0xFF000814),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                Container(
                  padding: EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFC300),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 64,
                    color: Color(0xFF000814),
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Como Voluntario',
                  style: TextStyle(fontSize: 18, color: Color(0xFFFFD60A)),
                ),
                SizedBox(height: 48),
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _ciController,
                        decoration: InputDecoration(
                          labelText: 'Cédula',
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF000814),
                                  ),
                                )
                              : Text(
                                  'Iniciar Sesión',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
