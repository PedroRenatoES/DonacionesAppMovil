import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/usecases/usecase.dart';
import '../entities/donation_request.dart';
import '../repositories/donor_home_repository.dart';

class CreateSolicitud extends UseCase<DonationRequest, CreateSolicitudParams> {
  final DonorHomeRepository repository;

  CreateSolicitud(this.repository);

  @override
  Future<Either<Failure, DonationRequest>> call(CreateSolicitudParams params) {
    return repository.createSolicitud(
      ubicacion: params.ubicacion,
      detalleSolicitud: params.detalleSolicitud,
      idDonante: params.idDonante,
      idCampana: params.idCampana,
    );
  }
}

class CreateSolicitudParams {
  final String ubicacion;
  final String detalleSolicitud;
  final int idDonante;
  final int idCampana;

  CreateSolicitudParams({
    required this.ubicacion,
    required this.detalleSolicitud,
    required this.idDonante,
    required this.idCampana,
  });
}
