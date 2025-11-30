import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/donation_request_model.dart';
import '../models/campaign_model.dart';
import '/core/network/dio_client.dart';

abstract class DonorHomeRemoteDataSource {
  Future<List<CampaignModel>> getCampaigns();
  Future<List<DonationRequestModel>> getDonationRequests();
  Future<DonationRequestModel> createSolicitud({
    required String ubicacion,
    required String detalleSolicitud,
    required int idDonante,
    required int idCampana,
  });
}

class DonorHomeRemoteDataSourceImpl implements DonorHomeRemoteDataSource {
  final DioClient dioClient;
  final SharedPreferences sharedPreferences;

  DonorHomeRemoteDataSourceImpl({
    required this.dioClient,
    required this.sharedPreferences,
  });

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    final response = await dioClient.get('/campanas');
    final List<dynamic> jsonResponse = response.data;
    return jsonResponse.map((json) => CampaignModel.fromJson(json)).toList();
  }

  @override
  Future<List<DonationRequestModel>> getDonationRequests() async {
    final idDonor = sharedPreferences.getInt('donante_id');
    final response = await dioClient.get('/solicitudesRecoleccion/donante/$idDonor');
    final List<dynamic> jsonResponse = response.data;
    return jsonResponse
        .map((json) => DonationRequestModel.fromJson(json))
        .toList();
  }

  @override
  Future<DonationRequestModel> createSolicitud({
    required String ubicacion,
    required String detalleSolicitud,
    required int idDonante,
    required int idCampana,
  }) async {
    final response = await dioClient.post('/solicitudesRecoleccion', data: {
      'ubicacion': ubicacion,
      'detalle_solicitud': detalleSolicitud,
      'id_donante': idDonante,
      'id_campana': idCampana,
    });
    return DonationRequestModel.fromJson(response.data);
  }
}
