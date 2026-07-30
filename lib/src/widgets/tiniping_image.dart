import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class TinipingImage extends StatelessWidget {
  const TinipingImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
  });

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _FallbackImage(iconSize: 48);
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) =>
          const Center(child: CircularProgressIndicator()),
      errorWidget: (context, url, error) => _FallbackImage(iconSize: 48),
    );
  }
}

class _FallbackImage extends StatelessWidget {
  const _FallbackImage({required this.iconSize});

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: iconSize,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
