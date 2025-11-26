import '../../domain/entities/campaign.dart';

/*
    Nueva BD:
    {
        "id_campana": 1,
        "nombre": "Campaña de Reciclaje",
        "descripcion": "Reciclaje de ropa usada para familias necesitadas",
        "fecha_inicio": "2025-06-01",
        "fecha_fin": "2025-06-30",
        "imagen_banner": null
    },
*/
class CampaignModel extends Campaign {
  const CampaignModel({
    required super.id,
    required super.name,
    required super.description,
    required super.startDate,
    required super.endDate,
    required super.organizer,
    super.imageUrl,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) {
    return CampaignModel(
      id: json['id_campana'],
      name: json['nombre'] ?? '',
      description: json['descripcion'] ?? '',
      startDate: DateTime.parse(json['fecha_inicio']),
      endDate: DateTime.parse(json['fecha_fin']),
      organizer: 'Organización',
      imageUrl: json['imagen_banner'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_campana': id,
      'nombre': name,
      'descripcion': description,
      'fecha_inicio': startDate.toIso8601String(),
      'fecha_fin': endDate.toIso8601String(),
      'imagen_banner': imageUrl,
    };
  }
}
