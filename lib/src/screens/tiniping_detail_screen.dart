import 'package:flutter/material.dart';

import '../models/tiniping.dart';
import '../widgets/tiniping_image.dart';

class TinipingDetailScreen extends StatelessWidget {
  const TinipingDetailScreen({super.key, required this.tiniping});

  final Tiniping tiniping;

  String get _heroTag => 'tiniping-${tiniping.id}-${tiniping.name}';

  @override
  Widget build(BuildContext context) {
    final visibleExtraEntries = tiniping.extraFields.entries.where((entry) {
      final normalizedKey = entry.key.toLowerCase().replaceAll(' ', '');
      return normalizedKey != 'c' &&
          normalizedKey != '번호' &&
          normalizedKey != 'id';
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(tiniping.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Hero(
            tag: _heroTag,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: TinipingImage(imageUrl: tiniping.imageUrl),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (tiniping.type.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Chip(
                avatar: const Icon(Icons.auto_awesome),
                label: Text(tiniping.type),
              ),
            ),
          if (tiniping.description.isNotEmpty)
            Text(
              tiniping.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          if (visibleExtraEntries.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('상세 정보', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...visibleExtraEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(entry.value)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
