// lib/pages/auth_wrapper.dart

import 'package:asset_pt_timah/pages/login_page.dart';
import 'package:asset_pt_timah/pages/need_access_page.dart';
import 'package:asset_pt_timah/pages/main_page.dart'; // <-- Pastikan MainPage diimpor
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      return const LoginPage();
    } else {
      return const _PermissionChecker();
    }
  }
}

class _PermissionChecker extends StatefulWidget {
  const _PermissionChecker();

  @override
  State<_PermissionChecker> createState() => _PermissionCheckerState();
}

class _PermissionCheckerState extends State<_PermissionChecker> {
  // --- TIDAK ADA PERUBAHAN DI SINI ---
  late Future<bool> _permissionFuture;

  @override
  void initState() {
    super.initState();
    _permissionFuture = _checkInitialPermissions();
  }
  // ------------------------------------

  // --- PERUBAHAN UTAMA DI SINI ---
  // Fungsi ini sekarang hanya memeriksa status, tidak lagi meminta izin
  Future<bool> _checkInitialPermissions() async {
    // Fungsi helper untuk mendapatkan izin galeri yang sesuai
    Future<Permission> getGalleryPermission() async {
      if (Platform.isAndroid) {
        final deviceInfo = await DeviceInfoPlugin().androidInfo;
        return deviceInfo.version.sdkInt >= 33 ? Permission.photos : Permission.storage;
      }
      return Permission.photos;
    }

    final galleryPermission = await getGalleryPermission();

    // Cek status izin saat ini tanpa memicu pop-up permintaan
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.locationWhenInUse.status;
    final galleryStatus = await galleryPermission.status;

    // Kembalikan true jika SEMUA izin sudah diberikan
    return cameraStatus.isGranted && locationStatus.isGranted && galleryStatus.isGranted;
  }
  // --- AKHIR PERUBAHAN ---

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _permissionFuture,
      builder: (context, snapshot) {
        // Tampilan loading tidak berubah
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memeriksa sesi & izin..."),
                ],
              ),
            ),
          );
        }

        // Jika snapshot punya data dan nilainya true (semua izin diberikan)
        if (snapshot.hasData && snapshot.data == true) {
          // Arahkan ke MainPage (halaman dengan swipe)
          return const MainPage();
        } else {
          // Jika ada izin yang ditolak, arahkan ke halaman NeedAccessPage
          return const NeedAccessPage();
        }
      },
    );
  }
}