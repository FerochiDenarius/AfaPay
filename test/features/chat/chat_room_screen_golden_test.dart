import 'dart:io';

import 'package:afa_pay/features/chat/presentation/chat_room_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    final flutterRoot =
        Platform.environment['FLUTTER_ROOT'] ??
        '/Users/kofibright/Desktop/flutter';
    final materialFonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

    await (FontLoader('Roboto')
          ..addFont(_loadFont('$materialFonts/Roboto-Regular.ttf'))
          ..addFont(_loadFont('$materialFonts/Roboto-Medium.ttf'))
          ..addFont(_loadFont('$materialFonts/Roboto-Bold.ttf')))
        .load();

    await (FontLoader(
      'MaterialIcons',
    )..addFont(_loadFont('$materialFonts/MaterialIcons-Regular.otf'))).load();
  });

  Future<void> setPhoneSurface(WidgetTester tester) async {
    tester.view.physicalSize = const Size(852, 1844);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('renders dark chat room preview', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ChatRoomScreen),
      matchesGoldenFile('goldens/chat_room_dark.png'),
    );
  });

  testWidgets('renders light chat room preview', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomLightPreview());
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ChatRoomScreen),
      matchesGoldenFile('goldens/chat_room_light.png'),
    );
  });

  testWidgets('hides camera button after typing starts', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Camera'), findsOneWidget);
    expect(find.byTooltip('Voice message'), findsOneWidget);
    expect(find.byTooltip('Send'), findsNothing);

    await tester.enterText(find.byType(EditableText), 'hello');
    await tester.pumpAndSettle();

    expect(find.byTooltip('Camera'), findsNothing);
    expect(find.byTooltip('Voice message'), findsNothing);
    expect(find.byTooltip('Send'), findsOneWidget);
  });

  testWidgets('send button appends typed mock message', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    const text = 'testing local send';
    await tester.enterText(find.byType(EditableText), text);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();

    expect(find.text(text), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
    expect(find.text('Type a message...'), findsOneWidget);
  });

  testWidgets('attachment button opens attachment actions', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Document'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Contact'), findsOneWidget);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Poll'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
  });

  testWidgets('gallery attachment opens media picker launcher', (tester) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Add'));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .ancestor(of: find.text('Gallery'), matching: find.byType(InkWell))
          .first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Recents'), findsOneWidget);
    expect(find.text('Device media'), findsOneWidget);
    expect(find.text('Add a caption...'), findsOneWidget);
  });
}

Future<ByteData> _loadFont(String path) async {
  final bytes = await File(path).readAsBytes();
  final typedBytes = Uint8List.fromList(bytes);
  return ByteData.view(typedBytes.buffer);
}
