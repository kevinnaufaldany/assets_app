import 'package:asset_pt_timah/services/auth_service.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // HANYA ADA SATU FUNGSI _handleSignIn YANG BENAR
  Future<void> _handleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signInWithGoogle();
      // Jika berhasil, AuthWrapper akan secara otomatis mengarahkan pengguna.
      // Kita tidak perlu melakukan navigasi manual di sini.
    } catch (error) {
      // Jika terjadi eror, tampilkan pesan ke pengguna.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan login: $error')),
        );
      }
    } finally {
      // Pastikan loading indicator berhenti meskipun terjadi eror.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4A6572),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Menggunakan ikon bawaan yang lebih konsisten
                Image.asset('assets/images/logo_pttimah.png', height: 125),
                const SizedBox(height: 16),
                const Text(
                  'Asset PT Timah',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Aplikasi pelaporan Asset setelah mengunjungi dari tempat asset',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 40),
                // Menampilkan loading indicator saat proses login berjalan
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton.icon(
                    onPressed: _handleSignIn,
                    // Pastikan path gambar Anda benar (di dalam folder assets/images)
                    icon: Image.asset('assets/images/logo_google.png', height: 22.0),
                    label: const Text('Login Akun PT Timah'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      backgroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      elevation: 2,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}