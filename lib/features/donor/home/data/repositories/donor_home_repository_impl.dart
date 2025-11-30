import 'package:dartz/dartz.dart';
import 'package:flutter_donaciones_1/core/error/exceptions.dart';

import '../../domain/entities/campaign.dart';
import '../../domain/entities/donation_request.dart';
import '/core/error/failures.dart';
import '../../domain/repositories/donor_home_repository.dart';
import '../datasources/donor_home_remote_data_source.dart';

class DonorHomeRepositoryImpl implements DonorHomeRepository {
  final DonorHomeRemoteDataSource remoteDataSource;

  DonorHomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Campaign>>> getCampaigns() async {
    try {
      final campaigns = await remoteDataSource.getCampaigns();
      return Right(campaigns);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on TokenExpiredException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error'));
    }
  }

  @override
  Future<Either<Failure, List<DonationRequest>>> getDonationRequests() async {
    try {
      final donationRequests = await remoteDataSource.getDonationRequests();
      return Right(donationRequests);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on TokenExpiredException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e, stack) {
      print('Error inesperado en getDonationRequests: $e');
      print('Stack: $stack');
      return Left(ServerFailure('Unexpected error'));
    }
  }

  @override
  Future<Either<Failure, DonationRequest>> createSolicitud({
    required String ubicacion,
    required String detalleSolicitud,
    required int idDonante,
    required int idCampana,
  }) async {
    try {
      final solicitud = await remoteDataSource.createSolicitud(
        ubicacion: ubicacion,
        detalleSolicitud: detalleSolicitud,
        idDonante: idDonante,
        idCampana: idCampana,
      );
      return Right(solicitud);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on TokenExpiredException catch (e) {
      return Left(AuthenticationFailure(e.message));
    } catch (e, stack) {
      print('Error inesperado en createSolicitud: $e');
      print('Stack: $stack');
      return Left(ServerFailure('Error al crear la solicitud'));
    }
  }
}
