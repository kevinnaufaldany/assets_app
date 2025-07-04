// lib/pages/profile_page.dart

import 'package:asset_pt_timah/pages/login_page.dart';
import 'package:asset_pt_timah/services/auth_service.dart';
import 'package:asset_pt_timah/widgets/profile_info_row.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Diubah menjadi StatelessWidget agar lebih ringkas dan efisien
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Pindahkan logika untuk mendapatkan data ke dalam build method
    final AuthService authService = AuthService();
    final User? user = authService.currentUser;
    final String userName = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? "Pengguna";
    final Map<String, String> userDetails = {
      "Nama": userName,
      "NIK": "122140", // Contoh data
      "Divisi": "IT",      // Contoh data
      "Jabatan": "Mahasiswa", // Contoh data
      "Email": user?.email ?? "Tidak ada email",
    };

    // Hapus Scaffold & AppBar, kembalikan langsung kontennya (Padding)
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 10)],
            ),
            child: Column(
              children: userDetails.entries
                  .map((entry) => ProfileInfoRow(label: entry.key, value: entry.value))
                  .toList(),
            ),
          ),
          const Spacer(), // Mendorong tombol ke bawah
          ElevatedButton(
            onPressed: () async {
              // Logika konfirmasi tidak berubah
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Konfirmasi Keluar"),
                  content: const Text("Apakah Anda yakin ingin keluar dari akun?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Batal")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text("Keluar"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  // Panggil metode signOut() yang benar
                  await authService.signOut();
                  // Navigasi kembali ke halaman login setelah logout berhasil
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                          (route) => false, // Hapus semua halaman sebelumnya
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal logout: $e")),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
            child: const Text("Keluar"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}