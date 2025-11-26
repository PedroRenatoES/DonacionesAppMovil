import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Estado de las donaciones
class DonationsState {
  final List<Map<String, dynamic>> groupedDonations;
  final List<dynamic> moneyDonations;
  final bool isLoading;
  final String? error;

  const DonationsState({
    this.groupedDonations = const [],
    this.moneyDonations = const [],
    this.isLoading = false,
    this.error,
  });

  DonationsState copyWith({
    List<Map<String, dynamic>>? groupedDonations,
    List<dynamic>? moneyDonations,
    bool? isLoading,
    String? error,
  }) {
    return DonationsState(
      groupedDonations: groupedDonations ?? this.groupedDonations,
      moneyDonations: moneyDonations ?? this.moneyDonations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier para manejar las donaciones
class DonationsNotifier extends StateNotifier<DonationsState> {
  DonationsNotifier() : super(const DonationsState());

  Future<void> loadDonations() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final donanteId = prefs.getInt('donante_id');
      final token = prefs.getString('token');

      print('=== DEBUG DONATIONS ===');
      print('donanteId: $donanteId');
      print('token: $token');

      if (donanteId == null || token == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No se encontró información de sesión',
        );
        return;
      }

      // Cargar donaciones en especie
      final especieUrl = 'http://10.0.2.2:8000/api/donaciones/donante/$donanteId';
      print('URL especie: $especieUrl');
      
      final especieResponse = await http.get(
        Uri.parse(especieUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Especie response status: ${especieResponse.statusCode}');
      print('Especie response body: ${especieResponse.body}');

      // Cargar donaciones en dinero
      final dineroUrl = 'http://10.0.2.2:8000/api/donaciones/dinero/donante/$donanteId';
      print('URL dinero: $dineroUrl');
      
      final dineroResponse = await http.get(
        Uri.parse(dineroUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('Dinero response status: ${dineroResponse.statusCode}');
      print('Dinero response body: ${dineroResponse.body}');

      List<Map<String, dynamic>> groupedDonations = [];
      List<dynamic> moneyDonations = [];

      // Procesar donaciones en especie
      if (especieResponse.statusCode == 200) {
        final rawDonations = json.decode(especieResponse.body);
        // Filtrar solo donaciones de tipo 'especie' o 'ropa'
        final especieOnly = (rawDonations as List).where((d) => 
          d['tipo'] == 'especie' || d['tipo'] == 'ropa'
        ).toList();
        groupedDonations = _groupDonations(especieOnly);
      } else {
        throw Exception(
          'Error al cargar donaciones en especie: ${especieResponse.statusCode}',
        );
      }

      // Procesar donaciones en dinero
      if (dineroResponse.statusCode == 200) {
        final rawMoneyDonations = json.decode(dineroResponse.body);
        moneyDonations = rawMoneyDonations is List ? rawMoneyDonations : [];
      } else if (dineroResponse.statusCode != 404) {
        // 404 significa que no hay donaciones en dinero, lo cual es válido
        throw Exception(
          'Error al cargar donaciones en dinero: ${dineroResponse.statusCode}',
        );
      }

      state = state.copyWith(
        groupedDonations: groupedDonations,
        moneyDonations: moneyDonations,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar donaciones: ${e.toString()}',
      );
    }
  }

  List<Map<String, dynamic>> _groupDonations(List<dynamic> rawDonations) {
    List<Map<String, dynamic>> result = [];

    for (var donation in rawDonations) {
      int donationId = donation['id_donacion'];
      
      // Obtener el primer detalle para mostrar el nombre del producto principal
      String nombreArticulo = 'Donación en especie';
      int cantidadTotal = 0;
      
      if (donation['detalles'] != null && donation['detalles'] is List && donation['detalles'].isNotEmpty) {
        // Tomar el nombre del primer producto
        var primerDetalle = donation['detalles'][0];
        if (primerDetalle['producto'] != null) {
          nombreArticulo = primerDetalle['producto']['nombre'] ?? 'Artículo sin nombre';
        }
        
        // Si hay más de un producto, agregar "y X más"
        if (donation['detalles'].length > 1) {
          nombreArticulo += ' y ${donation['detalles'].length - 1} más';
        }
        
        // Calcular cantidad total de todos los detalles
        for (var detalle in donation['detalles']) {
          cantidadTotal += (detalle['cantidad'] ?? 0) as int;
        }
      }

      result.add({
        'id_donacion_especie': donationId,
        'nombre_articulo': nombreArticulo,
        'cantidad_total': cantidadTotal,
        'cantidad_restante_total': cantidadTotal, // Por ahora, igual que total (no hay sistema de distribución en nuevo backend)
        'distribuciones': <Map<String, dynamic>>[],
        'has_distributions': false,
        'detalles': donation['detalles'] ?? [],
        'fecha': donation['fecha'],
        'tipo': donation['tipo'],
      });
    }

    return result;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void refresh() {
    loadDonations();
  }
}

// Provider principal
final donationsProvider =
    StateNotifierProvider<DonationsNotifier, DonationsState>((ref) {
      return DonationsNotifier();
    });

// Providers específicos para cada tipo de donación
final groupedDonationsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(donationsProvider).groupedDonations;
});

final moneyDonationsProvider = Provider<List<dynamic>>((ref) {
  return ref.watch(donationsProvider).moneyDonations;
});

final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(donationsProvider).isLoading;
});

final errorProvider = Provider<String?>((ref) {
  return ref.watch(donationsProvider).error;
});

// Provider para el total de dinero donado
final totalMoneyDonatedProvider = Provider<double>((ref) {
  final moneyDonations = ref.watch(moneyDonationsProvider);
  return moneyDonations.fold(0.0, (sum, donation) {
    final dinero = donation['dinero'];
    if (dinero != null && dinero['monto'] != null) {
      return sum + (double.tryParse(dinero['monto'].toString()) ?? 0.0);
    }
    return sum;
  });
});

// Provider para estadísticas generales
final donationsStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final groupedDonations = ref.watch(groupedDonationsProvider);
  final moneyDonations = ref.watch(moneyDonationsProvider);
  final totalMoney = ref.watch(totalMoneyDonatedProvider);

  return {
    'totalInKind': groupedDonations.length,
    'totalMoney': moneyDonations.length,
    'totalAmount': totalMoney,
    'totalDonations': groupedDonations.length + moneyDonations.length,
  };
});
