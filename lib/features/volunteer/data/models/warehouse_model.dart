import '../../domain/entities/warehouse.dart';

class WarehouseModel extends Warehouse {
  const WarehouseModel({
    required super.id,
    required super.name,
    required super.location,
    required super.latitud,
    required super.longitud,
  });

  factory WarehouseModel.fromJson(Map<String, dynamic> json) => WarehouseModel(
    /*
    Nueva BD:
    {
        "id_almacen": 1,
        "nombre": "Almacen Central",
        "direccion": "Av. 7mo Anillo, Calle 1",
        "latitud": -17.783,
        "longitud": -63.182
    },
  */
    id: json['id_almacen'],
    name: json['nombre'] ?? '',
    location: json['direccion'] ?? '',
    latitud: (json['latitud'] is String) ? double.tryParse(json['latitud']) ?? 0.0 : (json['latitud']?.toDouble() ?? 0.0),
    longitud: (json['longitud'] is String) ? double.tryParse(json['longitud']) ?? 0.0 : (json['longitud']?.toDouble() ?? 0.0),
  );
}
