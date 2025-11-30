import '../../domain/entities/donation_request.dart';

class DonationRequestModel extends DonationRequest {
  const DonationRequestModel({
    required super.requestId,
    required super.donorId,
    required super.location,
    required super.requestDetails,
    required super.estado,
    required super.fechaCreacion,
    super.fechaProgramada,
  });

  factory DonationRequestModel.fromJson(Map<String, dynamic> json) {
    return DonationRequestModel(
      requestId: json['id_solicitud'],
      donorId: json['id_donante'],
      location: json['direccion_recoleccion'] ?? '',
      requestDetails: json['observaciones'] ?? '',
      estado: json['estado'] ?? 'Pendiente',
      fechaCreacion: json['fecha_creacion'] ?? '',
      fechaProgramada: json['fecha_programada'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id_solicitud': requestId,
    'id_donante': donorId,
    'direccion_recoleccion': location,
    'observaciones': requestDetails,
    'estado': estado,
    'fecha_creacion': fechaCreacion,
    'fecha_programada': fechaProgramada,
  };
}
