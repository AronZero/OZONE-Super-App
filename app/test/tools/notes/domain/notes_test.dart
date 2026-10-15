import 'package:flutter_test/flutter_test.dart';
import 'package:ozone/core/domain/validation.dart';
import 'package:ozone/tools/notes/domain/notes.dart';

void main() {
  group('plain text (F2-02 §2)', () {
    test('formatting is dropped; checklist items get boxes', () {
      final ops = [
        {'insert': 'Flights on the '},
        {'insert': '24th', 'attributes': {'bold': true}},
        {'insert': '\nBefore leaving'},
        {'insert': '\n', 'attributes': {'header': 2}},
        {'insert': 'Book flights'},
        {'insert': '\n', 'attributes': {'list': 'checked'}},
        {'insert': 'Reserve hotel'},
        {'insert': '\n', 'attributes': {'list': 'unchecked'}},
        {'insert': 'Passport'},
        {'insert': '\n', 'attributes': {'list': 'bullet'}},
        {'insert': '\n\n'},
      ];
      expect(plainTextFromDelta(ops), 'Flights on the 24th\nBefore leaving\n☑ Book flights\n☐ Reserve hotel\nPassport');
    });

    test('empty document is empty text', () {
      expect(plainTextFromDelta([{'insert': '\n'}]), '');
      expect(isBlankNote(null, plainTextFromDelta([{'insert': '  \n'}])), isTrue);
      expect(isBlankNote('Trip', ''), isFalse);
    });

    test('preview is one line', () => expect(previewOf('☑ Rice\n☐ Eggs\n\n☐ Coffee'), '☑ Rice ☐ Eggs ☐ Coffee'));
  });

  group('sanitize (only what the toolbar makes)', () {
    test('keeps allowed formats, drops links, fonts, sizes and embeds', () {
      final out = sanitizeDelta([
        {'insert': 'a', 'attributes': {'bold': true, 'link': 'https://x.test', 'font': 'serif', 'size': 'huge'}},
        {'insert': {'image': 'x.png'}},
        {'insert': 'b', 'attributes': {'color': '#5b3e99', 'background': '#FFE98A'}},
        {'insert': 'c', 'attributes': {'color': '#123456'}},
        {'insert': '\n', 'attributes': {'header': 1}},
        {'insert': 'q\n', 'attributes': {'blockquote': true}},
      ]);
      expect(out, [
        {'insert': 'a', 'attributes': {'bold': true}},
        {'insert': 'b', 'attributes': {'color': '#5B3E99', 'background': '#FFE98A'}},
        {'insert': 'c'},
        {'insert': '\n', 'attributes': {'header': 2}},
        {'insert': 'q\n'},
      ]);
    });

    test('always ends with a newline', () {
      expect(sanitizeDelta(const []), [{'insert': '\n'}]);
      expect(sanitizeDelta([{'insert': 'x'}]), [{'insert': 'x'}, {'insert': '\n'}]);
    });

    test('palette colours have dark values', () {
      expect(darkColourOf('#5b3e99'), '#C2AEF0');
      expect(darkColourOf('#FFE98A'), '#6B5A12');
      expect(darkColourOf('#000000'), isNull);
    });
  });

  group('tags and folders (F1-01)', () {
    test('tags are lower case without #', () {
      expect(parseTag(' #Travel ').valueOrNull, 'travel');
      expect(parseTag('trip-2026_b').valueOrNull, 'trip-2026_b');
      expect(parseTag('Café').valueOrNull, 'café');
      expect(parseTag('two words'), isA<Invalid<String>>());
      expect(parseTag('#'), isA<Invalid<String>>());
      expect(parseTag('a' * 41), isA<Invalid<String>>());
      expect(parseTag('a' * 40).isOk, isTrue);
    });

    test('folder names are unique ignoring case', () {
      expect(parseFolderName(' Travel ', ['Work']).valueOrNull, 'Travel');
      expect(parseFolderName('work', ['Work']), isA<Invalid<String>>());
      expect(parseFolderName('', []), isA<Invalid<String>>());
      expect(parseFolderName('x' * 81, []), isA<Invalid<String>>());
    });

    test('titles are trimmed, capped at 200, empty is null', () {
      expect(normaliseTitle('  Trip plan '), 'Trip plan');
      expect(normaliseTitle('   '), isNull);
      expect(normaliseTitle('x' * 250)!.length, 200);
    });
  });

  group('trash (F2-02 §5)', () {
    const day = Duration.millisecondsPerDay;
    test('days left = 30 − days since trashed, at least 1', () {
      expect(trashDaysLeft(0, 0), 30);
      expect(trashDaysLeft(0, 4 * day + 5), 26);
      expect(trashDaysLeft(0, 29 * day), 1);
      expect(trashDaysLeft(0, 45 * day), 1);
    });

    test('purge cutoff is 30 days back', () => expect(purgeCutoff(40 * day), 10 * day));
  });
}
