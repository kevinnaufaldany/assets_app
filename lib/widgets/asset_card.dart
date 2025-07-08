// lib/widgets/asset_card.dart

import 'package:asset_pt_timah/models/asset_model.dart';
import 'package:asset_pt_timah/pages/asset_detail_page.dart';
import 'package:flutter/material.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final int number;
  final VoidCallback? onGoBack;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onSelectionChanged;
  final VoidCallback? onLongPress;

  const AssetCard({
    super.key,
    required this.asset,
    required this.number,
    this.onGoBack,
    this.isSelectable = false,
    this.isSelected = false,
    this.onSelectionChanged,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected
            ? Border.all(color: const Color(0xFF4A6572), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isSelectable) {
              onSelectionChanged?.call();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetDetailPage(
                    assetId: asset.id,
                  ),
                ),
              ).then((_) => onGoBack?.call());
            }
          },
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (isSelectable) ...[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                        isSelected ? const Color(0xFF4A6572) : Colors.grey,
                        width: 2,
                      ),
                      color: isSelected
                          ? const Color(0xFF4A6572)
                          : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                        : null,
                  ),
                  const SizedBox(width: 12),
                ],

                // Nomor urut
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6572).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      number.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF4A6572),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informasi asset
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Detail ID dan tipe asset
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              asset.detailId,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4A6572).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.type,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4A6572),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Alamat
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              asset.address,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Foto dan catatan
                      Row(
                        children: [
                          if (asset.allPhotos.isNotEmpty) ...[
                            Icon(
                              Icons.photo_camera,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${asset.allPhotos.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],

                          if (asset.notes.isNotEmpty) ...[
                            Icon(
                              Icons.note,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Notes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],

                          const Spacer(),

                          if (!isSelectable)
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ],
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
