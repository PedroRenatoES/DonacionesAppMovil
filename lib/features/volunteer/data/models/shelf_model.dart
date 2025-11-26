import '../../domain/entities/shelf.dart';

class ShelfModel extends Shelf {
  const ShelfModel({
    required super.id,
    required super.name,
    required super.rows,
    required super.columns,
  });

  factory ShelfModel.fromJson(Map<String, dynamic> json) {
    /*
    Nueva BD:
    {
        "id_estante": 1,
        "id_almacen": 1,
        "codigo_estante": "EST-A01",
        "descripcion": "Estante para ropa"
    }
    */
    return ShelfModel(
      id: json['id_estante'],
      name: json['codigo_estante'] ?? 'Estante sin nombre',
      rows: 5,
      columns: 4,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_estante': id,
      'nombre': name,
      'cantidad_filas': rows,
      'cantidad_columnas': columns,
    };
  }
}
