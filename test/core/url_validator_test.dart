import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/core/errors/app_exceptions.dart';
import 'package:video_downloader/core/utils/url_validator.dart';

void main() {
  group('UrlValidator', () {
    test('accepts valid https URL', () {
      const url = 'https://www.youtube.com/watch?v=aqz-KE-bpKQ';
      expect(UrlValidator.validate(url), equals(url));
      expect(UrlValidator.isValid(url), isTrue);
    });

    test('accepts valid http URL', () {
      const url = 'http://vimeo.com/12345678';
      expect(UrlValidator.validate(url), equals(url));
      expect(UrlValidator.isValid(url), isTrue);
    });

    test('trims surrounding whitespace', () {
      const raw = '   https://example.com/video   ';
      expect(UrlValidator.validate(raw), equals('https://example.com/video'));
    });

    test('rejects empty and null URLs', () {
      expect(
        () => UrlValidator.validate(''),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(
        () => UrlValidator.validate('   '),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(
        () => UrlValidator.validate(null),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(UrlValidator.isValid(''), isFalse);
    });

    test('rejects argument injection flags disguised as URLs', () {
      expect(
        () => UrlValidator.validate('--dump-json'),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(
        () => UrlValidator.validate('-f best'),
        throwsA(isA<InvalidUrlException>()),
      );
    });

    test('rejects unsupported schemes like file:// or ftp://', () {
      expect(
        () => UrlValidator.validate('file:///etc/passwd'),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(
        () => UrlValidator.validate('ftp://files.example.com/video.mp4'),
        throwsA(isA<InvalidUrlException>()),
      );
    });

    test('rejects malformed domains', () {
      expect(
        () => UrlValidator.validate('https://localhost'),
        throwsA(isA<InvalidUrlException>()),
      );
      expect(
        () => UrlValidator.validate('https://not-a-domain'),
        throwsA(isA<InvalidUrlException>()),
      );
    });
  });
}
