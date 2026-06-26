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

  testWidgets('emoji menu stays closed until emoji button is tapped', (
    tester,
  ) async {
    await setPhoneSurface(tester);
    await tester.pumpWidget(const ChatRoomDarkPreview());
    await tester.pumpAndSettle();

    expect(find.text('Emoji'), findsNothing);
    expect(find.text('GIF'), findsNothing);
    expect(find.text('Sticker'), findsNothing);

    await tester.tap(find.byTooltip('Emoji, GIF, or sticker'));
    await tester.pumpAndSettle();

    expect(find.text('Emoji'), findsOneWidget);
    expect(find.text('GIF'), findsOneWidget);
    expect(find.text('Sticker'), findsOneWidget);
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

  testWidgets('attachment menu includes local attachment actions', (
    tester,
  ) async {
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
    expect(find.text('Audio Recording'), findsOneWidget);
  });
}

Future<ByteData> _loadFont(String path) async {
  final bytes = await File(path).readAsBytes();
  final typedBytes = Uint8List.fromList(bytes);
  return ByteData.view(typedBytes.buffer);
}
