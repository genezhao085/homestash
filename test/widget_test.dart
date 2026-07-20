import 'package:flutter_test/flutter_test.dart';
import 'package:homestash/main.dart';

void main() {
  testWidgets('App can launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeStashApp());
    // 启动画面应显示应用名称
    expect(find.text('家庭储物管家'), findsOneWidget);
  });
}
