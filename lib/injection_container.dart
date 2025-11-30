import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/dio_client.dart';
import 'features/donor/home/data/datasources/donor_home_remote_data_source.dart';
import 'features/donor/home/data/repositories/donor_home_repository_impl.dart';
import 'features/donor/home/domain/repositories/donor_home_repository.dart';
import 'features/donor/home/domain/usecases/get_campaigns.dart';
import 'features/donor/home/domain/usecases/get_donations_request.dart';
import 'features/donor/home/domain/usecases/create_solicitud.dart';
import 'features/volunteer/data/datasources/inventory_remote_data_source.dart';
import 'features/volunteer/data/repositories/inventory_repository_impl.dart';
import 'features/volunteer/domain/repositories/inventory_repository.dart';
import 'features/volunteer/domain/usecases/download_excel_report.dart';
import 'features/volunteer/domain/usecases/get_donations.dart';
import 'features/volunteer/domain/usecases/get_shelves.dart';
import 'features/volunteer/domain/usecases/get_warehouses.dart';
import 'features/volunteer/domain/usecases/update_donation_status.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // //! Features - Donor
  // // Use cases
  sl.registerLazySingleton(() => GetDonationsRequest(sl()));
  sl.registerLazySingleton(() => GetCampaigns(sl()));
  sl.registerLazySingleton(() => CreateSolicitud(sl()));
  // sl.registerLazySingleton(() => GetShelves(sl()));
  // sl.registerLazySingleton(() => GetDonations(sl()));
  // sl.registerLazySingleton(() => UpdateDonationStatus(sl()));
  // sl.registerLazySingleton(() => DownloadExcelReport(sl()));

  // Repository
  sl.registerLazySingleton<DonorHomeRepository>(
    () => DonorHomeRepositoryImpl(remoteDataSource: sl()),
  );

  // // Data sources
  sl.registerLazySingleton<DonorHomeRemoteDataSource>(
    () =>
        DonorHomeRemoteDataSourceImpl(dioClient: sl(), sharedPreferences: sl()),
  );

  //! Features - Volunteer
  // Use cases
  sl.registerLazySingleton(() => GetWarehouses(sl()));
  sl.registerLazySingleton(() => GetShelves(sl()));
  sl.registerLazySingleton(() => GetDonations(sl()));
  sl.registerLazySingleton(() => UpdateDonationStatus(sl()));
  sl.registerLazySingleton(() => DownloadExcelReport(sl()));

  // Repository
  sl.registerLazySingleton<InventoryRepository>(
    () => InventoryRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<InventoryRemoteDataSource>(
    () =>
        InventoryRemoteDataSourceImpl(dioClient: sl(), sharedPreferences: sl()),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => DioClient(sharedPreferences: sl()));
}
