import 'package:flutter/material.dart';

import '../models/tiniping.dart';
import '../repositories/tiniping_repository.dart';
import '../widgets/tiniping_image.dart';
import 'tiniping_detail_screen.dart';

class TinipingGridScreen extends StatefulWidget {
  const TinipingGridScreen({super.key, required this.repository});

  final TinipingRepository repository;

  @override
  State<TinipingGridScreen> createState() => _TinipingGridScreenState();
}

class _TinipingGridScreenState extends State<TinipingGridScreen> {
  late Future<List<Tiniping>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.fetchTinipings();
  }

  void _reload() {
    setState(() {
      _future = widget.repository.fetchTinipings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('티니핑 도감'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: '새로고침',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Tiniping>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorView(onRetry: _reload);
          }

          final tinipings = snapshot.data ?? const <Tiniping>[];
          if (tinipings.isEmpty) {
            return const Center(child: Text('표시할 티니핑 데이터가 없습니다.'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = switch (constraints.maxWidth) {
                > 1200 => 5,
                > 900 => 4,
                > 600 => 3,
                _ => 2,
              };

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: tinipings.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final item = tinipings[index];
                  final heroTag = 'tiniping-${item.id}-${item.name}';
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 1.5,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => TinipingDetailScreen(tiniping: item),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Hero(
                              tag: heroTag,
                              child: TinipingImage(imageUrl: item.imageUrl),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                            child: Text(
                              item.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (item.type.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                              child: Text(
                                item.type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            )
                          else
                            const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '데이터를 불러오지 못했어요.\n'
              '시트를 "링크가 있는 모든 사용자에게 공개" 또는 '
              '"웹에 게시"로 설정했는지 확인해주세요.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
