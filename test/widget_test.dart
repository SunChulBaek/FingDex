import 'package:fingdex/main.dart';
import 'package:fingdex/src/models/tiniping.dart';
import 'package:fingdex/src/repositories/tiniping_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeTinipingRepository implements TinipingRepository {
  @override
  Future<List<Tiniping>> fetchTinipings() async {
    return const [
      Tiniping(
        id: '1',
        name: '하츄핑',
        imageUrl: '',
        type: '사랑',
        description: '사랑이 많은 티니핑',
        extraFields: {},
      ),
    ];
  }
}

void main() {
  testWidgets('티니핑 grid 화면이 렌더링된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      TingpingDexApp(repository: _FakeTinipingRepository()),
    );
    await tester.pumpAndSettle();

    expect(find.text('티니핑 도감'), findsOneWidget);
    expect(find.text('하츄핑'), findsOneWidget);
  });
}
