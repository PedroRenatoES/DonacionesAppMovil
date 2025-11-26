import '../../domain/entities/donation.dart';

class DonationModel extends Donation {
  const DonationModel({
    required super.id,
    required super.type,
    required super.validationStatus,
    required super.donationDate,
    super.campaignId,
    super.donorId,
  });

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    /*
    Nueva BD:
    {
        "id_donacion": 1,
        "tipo": "dinero",
        "fecha": "2024-11-26",
        "id_donante": 1,
        "id_campana": 1,
        "dinero": {
            "estado": "pendiente"
        }
    }
    */
    return DonationModel(
      id: json['id_donacion'],
      type: json['tipo'] ?? '',
      validationStatus: (json['dinero'] != null && json['dinero']['estado'] != null) 
          ? json['dinero']['estado'] 
          : 'pendiente',
      donationDate: DateTime.parse(json['fecha']),
      campaignId: json['id_campana'],
      donorId: json['id_donante'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_donacion': id,
      'tipo': type,
      'fecha': donationDate.toIso8601String().split('T')[0],
      'id_campana': campaignId,
      'id_donante': donorId,
    };
  }
}
