// lib/models/asset_model.dart

class Asset {
  final String id;
  final String parentId;
  final String detailId;
  final String type;
  final String address;
  final double latitude;
  final double longitude;
  final String notes;
  final List<String> allPhotos; // <-- Tipe data yang benar: List<String>

  Asset({
    required this.id,
    required this.parentId,
    required this.detailId,
    required this.type,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.notes,
    required this.allPhotos,
  });

  // Factory constructor untuk mengubah JSON dari API PHP menjadi objek Asset
  factory Asset.fromJson(Map<String, dynamic> json) {
    List<String> photos = [];
    if (json['photos'] != null) {
      // Konversi data dari API menjadi List<String>
      photos = List<String>.from(json['photos']);
    }

    return Asset(
      id: json['id'].toString(),
      parentId: json['parent_id']?.toString() ?? '',
      detailId: json['detail_id'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] ?? '',
      allPhotos: photos,
    );
  }

  // --- TAMBAHKAN KEMBALI FUNGSI COPYWITH ---
  Asset copyWith({
    String? notes,
    List<String>? allPhotos,
  }) {
    return Asset(
      id: this.id,
      parentId: this.parentId,
      detailId: this.detailId,
      type: this.type,
      address: this.address,
      latitude: this.latitude,
      longitude: this.longitude,
      notes: notes ?? this.notes,
      allPhotos: allPhotos ?? this.allPhotos,
    );
  }
}
