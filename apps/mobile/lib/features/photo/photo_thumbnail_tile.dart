import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_database.dart';

/// Shared thumbnail used by both session and series photo strips.
class PhotoThumbnailTile extends StatelessWidget {
  const PhotoThumbnailTile({
    required this.image,
    required this.badgeLabel,
    required this.onTap,
    required this.onLongPress,
    this.width = 112,
    this.imageExtent = 92,
    super.key,
  });

  final ImageAssetRecord image;
  final String badgeLabel;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final double width;
  final double imageExtent;

  @override
  Widget build(BuildContext context) {
    final caption = image.caption?.trim();
    final semantics = [
      badgeLabel,
      if (caption != null && caption.isNotEmpty) caption,
    ].join(', ');
    return Semantics(
      label: semantics,
      hint: 'Tik om te bekijken. Houd ingedrukt voor fotoacties.',
      button: true,
      onLongPress: _handleLongPress,
      child: SizedBox(
        width: width,
        child: InkWell(
          onTap: onTap,
          onLongPress: _handleLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      File(image.path),
                      width: imageExtent,
                      height: imageExtent,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => SizedBox.square(
                        dimension: imageExtent,
                        child: const ColoredBox(
                          color: Colors.black12,
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 4,
                    top: 4,
                    right: 4,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            badgeLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (caption != null && caption.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleLongPress() {
    HapticFeedback.lightImpact();
    onLongPress();
  }
}
