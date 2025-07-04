import 'package:asset_pt_timah/pages/asset_list_page.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:asset_pt_timah/pages/main_page.dart';

class NeedAccessPage extends StatefulWidget {
  const NeedAccessPage({super.key});

  @override
  State<NeedAccessPage> createState() => _NeedAccessPageState();
}

class _NeedAccessPageState extends State<NeedAccessPage> {
  int? _androidSDKVersion;
  final Map<Permission, PermissionStatus> _permissionStatuses = {};

  // Fungsi untuk mendapatkan izin galeri yang tepat berdasarkan versi Android
  Permission get _galleryPermission {
    if (Platform.isAndroid) {
      // Jika Android 13 (API 33) atau lebih baru, gunakan .photos
      // Jika lebih lama, gunakan .storage
      return _androidSDKVersion != null && _androidSDKVersion! >= 33
          ? Permission.photos
          : Permission.storage;
    }
    // Default untuk platform lain (misalnya iOS)
    return Permission.photos;
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      _androidSDKVersion = deviceInfo.version.sdkInt;
    }
    await _checkInitialPermissions();
  }

  Future<void> _checkInitialPermissions() async {
    final permissionsToCheck = [
      Permission.camera,
      Permission.locationWhenInUse,
      _galleryPermission,
    ];

    for (var perm in permissionsToCheck) {
      final status = await perm.status;
      _permissionStatuses[perm] = status;
    }
    if (mounted) setState(() {});
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      _showAppSettingsDialog();
    }
    setState(() {
      _permissionStatuses[permission] = status;
    });
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Dibutuhkan'),
        content: const Text(
            'Izin ini telah ditolak secara permanen. Anda perlu mengaktifkannya secara manual di pengaturan aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allGranted = [
      _permissionStatuses[Permission.camera],
      _permissionStatuses[Permission.locationWhenInUse],
      _permissionStatuses[_galleryPermission],
    ].every((status) => status?.isGranted ?? false);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Kami memerlukan Akses!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Anda perlu memberikan akses ke kamera perangkat dan lokasi untuk menggunakan aplikasi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              _buildPermissionTile(
                title: 'Akses Kamera',
                subtitle:
                'Aplikasi memerlukan akses ke kamera untuk mengambil foto',
                icon: Icons.camera_alt_outlined,
                permission: Permission.camera,
              ),
              const SizedBox(height: 16),
              _buildPermissionTile(
                title: 'Akses Lokasi',
                subtitle:
                'Aplikasi memerlukan akses ke lokasi untuk menampilkan lokasi terkini',
                icon: Icons.location_on_outlined,
                permission: Permission.locationWhenInUse,
              ),
              const SizedBox(height: 16),
              _buildPermissionTile(
                title: 'Akses Galeri',
                subtitle:
                    'Aplikasi memerlukan akses ke galeri foto Anda untuk upload gambar',
                icon: Icons.photo_library_outlined,
                permission: _galleryPermission,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: allGranted
                    ? () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const MainPage()),
                  );
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF4A6572),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  textStyle: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600),
                ),
                child: const Text('Lanjut'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Permission permission,
  }) {
    final status = _permissionStatuses[permission] ?? PermissionStatus.denied;
    final isGranted = status.isGranted;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Switch(
            value: isGranted,
            onChanged: (value) {
              if (value) {
                _requestPermission(permission);
              } else {
                _showInfoDialog('Info',
                    'Untuk menonaktifkan izin, silakan lakukan melalui Pengaturan Aplikasi di HP Anda.');
              }
            },
            activeColor: const Color(0xFF4A6572),
          ),
        ],
      ),
    );
  }
}