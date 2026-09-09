import 'package:flutter_test/flutter_test.dart';
import 'package:video_downloader/models/audio_config.dart';

void main() {
  group('AudioConfig Model & Presets', () {
    test('default configuration has 320k MP3 with thumbnail and metadata enabled', () {
      const config = AudioConfig();
      expect(config.bitrate, AudioBitrate.kbps320);
      expect(config.format, AudioFormat.mp3);
      expect(config.embedThumbnail, isTrue);
      expect(config.embedMetadata, isTrue);
    });

    test('buildArgs generates expected yt-dlp arguments', () {
      const config = AudioConfig(
        bitrate: AudioBitrate.kbps320,
        format: AudioFormat.mp3,
        embedThumbnail: true,
        embedMetadata: true,
      );

      final args = config.buildArgs();
      expect(args, contains('-x'));
      expect(args, contains('--audio-format'));
      expect(args[args.indexOf('--audio-format') + 1], 'mp3');
      expect(args, contains('--audio-quality'));
      expect(args[args.indexOf('--audio-quality') + 1], '320K');
      expect(args, contains('--embed-thumbnail'));
      expect(args, contains('--convert-thumbnails'));
      expect(args[args.indexOf('--convert-thumbnails') + 1], 'jpg');
      expect(args, contains('--add-metadata'));
    });

    test('buildArgs omits thumbnail and metadata when disabled', () {
      const config = AudioConfig(
        bitrate: AudioBitrate.kbps192,
        format: AudioFormat.m4a,
        embedThumbnail: false,
        embedMetadata: false,
      );

      final args = config.buildArgs();
      expect(args, contains('-x'));
      expect(args[args.indexOf('--audio-format') + 1], 'm4a');
      expect(args[args.indexOf('--audio-quality') + 1], '192K');
      expect(args.contains('--embed-thumbnail'), isFalse);
      expect(args.contains('--convert-thumbnails'), isFalse);
      expect(args.contains('--add-metadata'), isFalse);
    });

    test('VBR quality flag outputs 0', () {
      const config = AudioConfig(bitrate: AudioBitrate.vbr);
      final args = config.buildArgs();
      expect(args[args.indexOf('--audio-quality') + 1], '0');
    });

    test('presets have correct values', () {
      expect(AudioConfig.studioMusic.bitrate, AudioBitrate.kbps320);
      expect(AudioConfig.studioMusic.format, AudioFormat.mp3);
      expect(AudioConfig.studioMusic.embedThumbnail, isTrue);
      expect(AudioConfig.studioMusic.embedMetadata, isTrue);

      expect(AudioConfig.podcast.bitrate, AudioBitrate.kbps192);
      expect(AudioConfig.podcast.format, AudioFormat.mp3);
      expect(AudioConfig.podcast.embedThumbnail, isTrue);
      expect(AudioConfig.podcast.embedMetadata, isTrue);

      expect(AudioConfig.vbrEfficient.bitrate, AudioBitrate.vbr);
      expect(AudioConfig.vbrEfficient.format, AudioFormat.mp3);

      expect(AudioConfig.losslessFlac.format, AudioFormat.flac);
      expect(AudioConfig.losslessFlac.format.isLossless, isTrue);

      expect(AudioConfig.studioWav.format, AudioFormat.wav);
      expect(AudioConfig.studioWav.format.isLossless, isTrue);
      expect(AudioConfig.studioWav.embedThumbnail, isFalse);

      expect(AudioConfig.opusStream.format, AudioFormat.opus);
      expect(AudioConfig.opusStream.format.isLossless, isFalse);
    });

    test('lossless formats force quality 0 in buildArgs', () {
      const flacConfig = AudioConfig(format: AudioFormat.flac);
      final flacArgs = flacConfig.buildArgs();
      expect(flacArgs, contains('--audio-format'));
      expect(flacArgs[flacArgs.indexOf('--audio-format') + 1], 'flac');
      expect(flacArgs, contains('--audio-quality'));
      expect(flacArgs[flacArgs.indexOf('--audio-quality') + 1], '0');

      const wavConfig = AudioConfig(format: AudioFormat.wav, embedThumbnail: true);
      final wavArgs = wavConfig.buildArgs();
      expect(wavArgs, contains('--audio-format'));
      expect(wavArgs[wavArgs.indexOf('--audio-format') + 1], 'wav');
      expect(wavArgs[wavArgs.indexOf('--audio-quality') + 1], '0');
      // Thumbnail conversion is omitted for WAV
      expect(wavArgs.contains('--embed-thumbnail'), isFalse);
    });

    test('opus format sets --audio-format opus with specified bitrate', () {
      const opusConfig = AudioConfig(
        format: AudioFormat.opus,
        bitrate: AudioBitrate.kbps192,
      );
      final opusArgs = opusConfig.buildArgs();
      expect(opusArgs[opusArgs.indexOf('--audio-format') + 1], 'opus');
      expect(opusArgs[opusArgs.indexOf('--audio-quality') + 1], '192K');
    });

    test('copyWith updates fields correctly', () {
      const config = AudioConfig();
      final updated = config.copyWith(
        bitrate: AudioBitrate.kbps256,
        format: AudioFormat.flac,
        embedThumbnail: false,
      );

      expect(updated.bitrate, AudioBitrate.kbps256);
      expect(updated.format, AudioFormat.flac);
      expect(updated.embedThumbnail, isFalse);
      expect(updated.embedMetadata, isTrue);
    });
  });
}
