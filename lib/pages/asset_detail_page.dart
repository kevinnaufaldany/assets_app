import 'dart:io';
import 'package:asset_pt_timah/models/asset_model.dart';
import 'package:asset_pt_timah/pages/custom_camera_page.dart';
import 'package:asset_pt_timah/widgets/profile_info_row.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:asset_pt_timah/pages/photo_viewer_page.dart';
import 'package:asset_pt_timah/services/api_service.dart';

class AssetDetailPage extends StatefulWidget {
  final String assetId;
  const AssetDetailPage({super.key, required this.assetId});

  @override
  State<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends State<AssetDetailPage> {
  Asset? _asset;
  bool _isLoading = true;
  bool _isProcessing = false; // Untuk loading indicator saat stamping
  late TextEditingController _notesController;
  final List<File> _stagedPhotos = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadAssetDetails();
  }
// Fungsi ini sekarang menerima String URL, bukan objek AssetPhoto
  Future<void> _deletePhoto(String photoUrl) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Foto?"),
        content: const Text("Foto ini akan dihapus dari server. Lanjutkan?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("Batal")),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    // Panggil service untuk hapus foto dengan URL
    bool success = await _apiService.deletePhoto(photoUrl);

    if (mounted) Navigator.pop(context);

    if (success) {
      await _loadAssetDetails(); // Muat ulang data dari server
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Foto berhasil dihapus."), backgroundColor: Colors.green));
      }
    } else {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal menghapus foto."), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _loadAssetDetails() async {
    setState(() => _isLoading = true);
    try {
      var allAssets = await _apiService.getAssets();
      if (!mounted) return;

      // Temukan aset yang sesuai dari data yang didapat
      final currentAsset = allAssets.firstWhere((a) => a.id == widget.assetId);

      setState(() {
        _asset = currentAsset;
        _notesController = TextEditingController(text: _asset!.notes);
        _isLoading = false;
      });
    } catch (e) {
      print("Error memuat detail aset: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _openCustomCamera() async {
    final result = await Navigator.push<File>(
      context,
      MaterialPageRoute(builder: (context) => const CustomCameraPage()),
    );
    if (result != null) {
      setState(() {
        _stagedPhotos.add(result);
        _showUploadPreview(); // Tampilkan halaman pratinjau
      });
    }
  }

// --- FUNGSI BARU UNTUK MENAMPILKAN DIALOG KONFIRMASI ---
  Future<bool> _showCancelConfirmationDialog() async {
    // Jika tidak ada foto, izinkan aksi "batal" tanpa konfirmasi
    if (_stagedPhotos.isEmpty) return true;

    // Tampilkan dialog dan tunggu respons dari pengguna
    final bool? shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan Foto?'),
        content: const Text('Foto yang baru diambil akan dihapus. Apakah Anda yakin?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Pengguna memilih "Tidak"
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Pengguna memilih "Ya"
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    // Jika pengguna menekan "Ya" (shouldCancel == true), hapus foto pratinjau
    if (shouldCancel ?? false) {
      setState(() {
        _stagedPhotos.clear();
      });
    }

    // Kembalikan pilihan pengguna
    return shouldCancel ?? false;
  }

  // HALAMAN PREVIEW BARU
  void _showUploadPreview() {
    // Fungsi ini akan menampilkan UI dari page saat add photo.png
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return PopScope(
            canPop: false,
            onPopInvoked: (didPop) async {
              if (didPop) return;
              final bool shouldPop = await _showCancelConfirmationDialog();
              if (shouldPop && mounted) {
                Navigator.pop(context);
              }
            },

            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Header (mirip AppBar)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, // spaceBetween
                      children: [
                        const SizedBox(width: 40), // spacer
                        Text(
                          _asset?.detailId ?? "Preview",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final shouldPop = await _showCancelConfirmationDialog();
                            if (shouldPop && mounted) {
                              Navigator.pop(context); } },
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _stagedPhotos.isEmpty
                          ? const Center(child: Text("Tidak ada foto untuk di-preview."))
                          : ListView.separated(
                        itemCount: 1, // Tetap paksa hanya 1 item
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_stagedPhotos.last), // <-- Gunakan .last bukan .first
                          );
                        },
                      ),
                    ),
                  ),
                  // Footer dengan tombol
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final bool shouldRepeat = await _showCancelConfirmationDialog();
                              if (shouldRepeat) {
                                if (mounted) Navigator.pop(context); // Tutup preview
                                _openCustomCamera(); // Buka lagi kamera
                              } // Tutup bottom sheet
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text("Ulang"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context); // Tutup bottom sheet
                              _showUploadConfirmation();
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Tambah"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  // --- TAMBAHKAN FUNGSI BARU INI ---
  Future<void> _performUpload() async {
    // Pastikan ada foto yang akan di-upload
    if (_stagedPhotos.isEmpty) return;

    // Tampilkan loading indicator menggunakan context halaman yang valid
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    bool success = false;
    try {
      // Panggil ApiService untuk menjalankan proses upload
      success = await _apiService.uploadPhoto(widget.assetId, _stagedPhotos.first);
    } catch (e) {
      print("Error saat performUpload: $e");
      success = false;
    } finally {
      // TUTUP loading indicator, baik prosesnya berhasil maupun gagal
      if (mounted) Navigator.pop(context);

      // Tampilkan notifikasi berdasarkan hasil
      if (success) {
        _stagedPhotos.clear();
        await _loadAssetDetails(); // Muat ulang data dari server
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Foto berhasil diunggah!"),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Gagal mengunggah foto."),
            backgroundColor: Colors.red,
          ));
        }
      }
    }
  }

  void _showUploadConfirmation() {
    if (_stagedPhotos.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) { // Menggunakan nama 'dialogContext' agar jelas
        return AlertDialog(
          title: const Text("Konfirmasi Tambah Foto"),
          content: const Text("Anda akan mengunggah foto ini. Lanjutkan?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal")),
            ElevatedButton(
              onPressed: () {
                // 1. Tutup dialog konfirmasi ini
                Navigator.pop(dialogContext);
                // 2. Panggil fungsi upload yang terpisah dan aman
                _performUpload();
              },
              child: const Text("Ya, Tambah"),
            ),
          ],
        );
      },
    );
  }

  void _editNotes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Catatan"),
        content: TextField(controller: _notesController, autofocus: true, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              // Panggil service untuk update catatan
              bool success = await _apiService.updateNotes(widget.assetId, _notesController.text);

              if (mounted) Navigator.pop(context);

              if (success) {
                _loadAssetDetails(); // Muat ulang data jika berhasil
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gagal memperbarui catatan.")));
                }
              }
            },
            child: const Text("Simpan"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? "Memuat..." : _asset?.detailId ?? 'Detail Aset'),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_asset == null)
            const Center(child: Text("Gagal memuat detail aset."))
          else
            RefreshIndicator(
              onRefresh: _loadAssetDetails,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildDescriptionCard(),
                    const SizedBox(height: 24),
                    _buildPhotoCard(),
                    const SizedBox(height: 24),
                    _buildAddPhotoCard(),
                  ],
                ),
              ),
            ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Memproses gambar...", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    // Siapkan data yang akan ditampilkan
    final details = [
      {'label': 'ID Induk', 'value': _asset!.parentId},
      {'label': 'ID Detail', 'value': _asset!.detailId},
      {'label': 'Type', 'value': _asset!.type},
      {'label': 'Alamat', 'value': _asset!.address},
      {'label': 'Latitude', 'value': _asset!.latitude.toString()},
      {'label': 'Longitude', 'value': _asset!.longitude.toString()},
      {'label': 'Catatan', 'value': _asset!.notes},
    ];

    return _buildCard(
      title: "Deskripsi",
      trailing: TextButton.icon(
        onPressed: _editNotes,
        icon: const Icon(Icons.edit, size: 18),
        label: const Text("Edit"),
      ),
      // --- PERUBAHAN UTAMA: MENGGUNAKAN WIDGET TABLE ---
      child: Table(
        // Atur lebar setiap kolom agar rapi
        columnWidths: const {
          0: IntrinsicColumnWidth(), // Lebar kolom label sesuai teks terpanjang
          1: FixedColumnWidth(12),    // Lebar kolom titik dua (:)
          2: FlexColumnWidth(),       // Lebar kolom nilai mengisi sisa ruang
        },
        children: details.map((item) {
          // Buat satu baris untuk setiap item data
          return TableRow(
            children: [
              // Sel 1: Label
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(item['label']!, style: TextStyle(color: Colors.grey[700])),
              ),
              // Sel 2: Titik Dua
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(':', style: TextStyle(color: Colors.grey[700])),
              ),
              // Sel 3: Nilai
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  item['value']!,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhotoCard() {
    final List<String> allPhotos = _asset?.allPhotos ?? [];

    return _buildCard(
      title: "Foto",
      child: allPhotos.isEmpty
          ? const Center(
          child: Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Text("Belum ada foto untuk aset ini.")))
          : GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
        itemCount: allPhotos.length,
        itemBuilder: (context, index) {
          final photoUrl = allPhotos[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewerPage(
                      imageUrls: allPhotos,
                      initialIndex: index,
                      title: 'Foto ${_asset?.detailId ?? "Aset"}',
                    ),
                  ),
                );
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: photoUrl,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        photoUrl, 
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / 
                                      loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stack) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _deletePhoto(photoUrl),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
                        child: const Icon(Icons.delete, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddPhotoCard() {
    return _buildCard(
      title: "Tambah Foto",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildAddPhotoButton(
            icon: Icons.camera_alt,
            label: "Ambil dari\nKamera",
            onTap: _openCustomCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[700]),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}