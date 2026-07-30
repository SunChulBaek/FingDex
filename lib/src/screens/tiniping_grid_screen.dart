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
  static const String _allTabLabel = '전체';

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
    return FutureBuilder<List<Tiniping>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: _ErrorView(
              onRetry: _reload,
              errorMessage: snapshot.error.toString(),
            ),
          );
        }

        final tinipings = snapshot.data ?? const <Tiniping>[];
        if (tinipings.isEmpty) {
          return Scaffold(
            appBar: _buildAppBar(),
            body: const Center(child: Text('표시할 티니핑 데이터가 없습니다.')),
          );
        }

        final releaseTabs = _buildReleaseTabs(tinipings);
        return DefaultTabController(
          length: releaseTabs.length,
          child: Scaffold(
            appBar: _buildAppBar(
              bottom: TabBar(
                isScrollable: true,
                tabs: releaseTabs.map((tab) => Tab(text: tab)).toList(),
              ),
            ),
            body: TabBarView(
              children: releaseTabs.map((tab) {
                final filtered = tab == _allTabLabel
                    ? tinipings
                    : tinipings
                          .where((item) => item.releaseVersion == tab)
                          .toList();
                return _TinipingGrid(items: filtered);
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  AppBar _buildAppBar({PreferredSizeWidget? bottom}) {
    return AppBar(
      title: const Text('티니핑 도감'),
      bottom: bottom,
      actions: [
        IconButton(
          onPressed: _reload,
          tooltip: '새로고침',
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  List<String> _buildReleaseTabs(List<Tiniping> items) {
    final versions = items
        .map((item) => item.releaseVersion.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort(_compareReleaseVersionDesc);

    return [_allTabLabel, ...versions];
  }

  int _compareReleaseVersionDesc(String a, String b) {
    final aNum = _extractLeadingNumber(a);
    final bNum = _extractLeadingNumber(b);

    if (aNum != null && bNum != null && aNum != bNum) {
      return bNum.compareTo(aNum);
    }
    if (aNum != null && bNum == null) {
      return -1;
    }
    if (aNum == null && bNum != null) {
      return 1;
    }
    return b.compareTo(a);
  }

  int? _extractLeadingNumber(String value) {
    final match = RegExp(r'(\d+)').firstMatch(value);
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}

class _TinipingGrid extends StatelessWidget {
  const _TinipingGrid({required this.items});

  final List<Tiniping> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('해당 버전에 데이터가 없습니다.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = switch (constraints.maxWidth) {
          > 1200 => 5,
          > 900 => 4,
          > 600 => 3,
          _ => 3,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
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
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.onRetry,
    required this.errorMessage,
  });

  final VoidCallback onRetry;
  final String errorMessage;

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
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
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
