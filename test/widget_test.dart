import 'package:flutter_test/flutter_test.dart';
import 'package:homestash/main.dart';

void main() {
  testWidgets('App can launch smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HomeStashApp());
    // 启动画面应显示应用名称
    expect(find.text('家庭储物管家'), findsOneWidget);
    // 推进时间并让 SplashScreen 定时器完成，触发导航过渡
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
  });
}
