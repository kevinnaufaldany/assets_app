import 'package:asset_pt_timah/models/asset_model.dart';
import 'package:asset_pt_timah/pages/profile_page.dart';
import 'package:asset_pt_timah/services/api_service.dart';
import 'package:asset_pt_timah/widgets/asset_card.dart';
import 'package:flutter/material.dart';

class AssetListPage extends StatefulWidget {
  const AssetListPage({super.key});

  @override
  State<AssetListPage> createState() => _AssetListPageState();
}

class _AssetListPageState extends State<AssetListPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Asset> _allAssets = [];
  List<Asset> _filteredAssets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAssets();
    _searchController.addListener(_filterAssets);
  }

  Future<void> _fetchAssets() async {
    setState(() => _isLoading = true);
    final assets = await _apiService.getAssets();
    setState(() {
      _allAssets = assets;
      _filteredAssets = assets;
      _isLoading = false;
    });
  }

  void _filterAssets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAssets = _allAssets.where((asset) {
        return asset.address.toLowerCase().contains(query) ||
            asset.detailId.toLowerCase().contains(query) ||
            asset.id.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_filteredAssets.isEmpty) {
      return const Center(child: Text("Tidak ada aset yang ditemukan."));
    }
    return RefreshIndicator(
      onRefresh: _fetchAssets,
      child: ListView.builder(
        itemCount: _filteredAssets.length,
        itemBuilder: (context, index) {
          final asset = _filteredAssets[index];
          return AssetCard(asset: asset, number: index + 1);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN UTAMA DI SINI ---
    // Hapus Scaffold dan AppBar, kembalikan langsung kontennya (Column).
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1.5,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari berdasarkan ID, Kode, atau Alamat',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }
}
