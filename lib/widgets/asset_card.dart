import 'package:asset_pt_timah/models/asset_model.dart';
import 'package:asset_pt_timah/pages/asset_detail_page.dart';
import 'package:flutter/material.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final int number;

  const AssetCard({
    super.key,
    required this.asset,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AssetDetailPage(assetId: asset.id)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6572),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.detailId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(
                    asset.address,
                    style: TextStyle(color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text('${asset.allPhotos.length} Foto', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}