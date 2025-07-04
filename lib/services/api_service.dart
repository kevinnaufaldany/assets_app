// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:asset_pt_timah/models/asset_model.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiService {
  // PENTING: Gunakan IP ini untuk mengakses localhost dari emulator Android
  final String _baseUrl = 'http://192.168.207.86/api_asset';

  // Fungsi untuk mengambil semua data aset dari server
  Future<List<Asset>> getAssets() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/get_assets.php'));

      if (response.statusCode == 200) {
        // Jika server merespon OK, parse JSON
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Asset.fromJson(json)).toList();
      } else {
        // Jika server gagal, lempar error
        throw Exception('Gagal memuat aset dari server');
      }
    } catch (e) {
      print("Error di getAssets: $e");
      // Kembalikan list kosong jika terjadi error
      return [];
    }
  }

  // Fungsi untuk mengunggah satu foto
  Future<bool> uploadPhoto(String assetId, File photo) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/upload_photo.php'),
      );

      // Buat nama file yang unik berdasarkan waktu
      String fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(photo.path)}';

      request.fields['asset_id'] = assetId;
      request.files.add(await http.MultipartFile.fromPath(
        'photo',
        photo.path,
        filename: fileName, // Kirim dengan nama unik
      ));

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      print("Error di uploadPhoto: $e");
      return false;
    }
  }

  // Fungsi untuk menghapus foto
  Future<bool> deletePhoto(String photoUrl) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/delete_photo.php'),
        body: {'photo_url': photoUrl},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      print("Error di deletePhoto: $e");
      return false;
    }
  }

  // Fungsi untuk update catatan
  Future<bool> updateNotes(String assetId, String newNotes) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/update_notes.php'), // Anda perlu membuat file PHP ini
        body: {'id': assetId, 'notes': newNotes},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Error di updateNotes: $e");
      return false;
    }
  }
}