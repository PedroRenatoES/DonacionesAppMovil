import 'package:equatable/equatable.dart';

class DonationRequest extends Equatable {
  final int requestId;
  final int donorId;
  final String location;
  final String requestDetails;
  final String estado;
  final String fechaCreacion;
  final String? fechaProgramada;

  const DonationRequest({
    required this.requestId,
    required this.donorId,
    required this.location,
    required this.requestDetails,
    required this.estado,
    required this.fechaCreacion,
    this.fechaProgramada,
  });

  @override
  List<Object?> get props => [
    requestId,
    donorId,
    location,
    requestDetails,
    estado,
    fechaCreacion,
    fechaProgramada,
  ];
}
