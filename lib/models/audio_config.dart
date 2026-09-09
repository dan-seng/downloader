/// Audio bitrates supported for extraction and conversion.
enum AudioBitrate {
  kbps320('320k', '320 kbps (Studio Max)', '320K'),
  kbps256('256k', '256 kbps (High Quality)', '256K'),
  kbps192('192k', '192 kbps (Standard)', '192K'),
  vbr('vbr', 'VBR (Best Variable)', '0');

  final String id;
  final String label;
  final String qualityFlag;

  const AudioBitrate(this.id, this.label, this.qualityFlag);
}

/// Output audio container formats.
enum AudioFormat {
  mp3('mp3', 'MP3 (Universal ID3v2)'),
  m4a('m4a', 'M4A (AAC / Apple)');

  final String id;
  final String label;

  const AudioFormat(this.id, this.label);
}

/// Advanced audio extraction and metadata configuration.
class AudioConfig {
  final AudioBitrate bitrate;
  final AudioFormat format;
  final bool embedThumbnail;
  final bool embedMetadata;

  const AudioConfig({
    this.bitrate = AudioBitrate.kbps320,
    this.format = AudioFormat.mp3,
    this.embedThumbnail = true,
    this.embedMetadata = true,
  });

  /// Preset for studio music and lossless-tier listening.
  static const studioMusic = AudioConfig(
    bitrate: AudioBitrate.kbps320,
    format: AudioFormat.mp3,
    embedThumbnail: true,
    embedMetadata: true,
  );

  /// Preset for podcasts, talks, and spoken-word lectures.
  static const podcast = AudioConfig(
    bitrate: AudioBitrate.kbps192,
    format: AudioFormat.mp3,
    embedThumbnail: true,
    embedMetadata: true,
  );

  /// Preset for high-efficiency variable bitrate listening.
  static const vbrEfficient = AudioConfig(
    bitrate: AudioBitrate.vbr,
    format: AudioFormat.mp3,
    embedThumbnail: true,
    embedMetadata: true,
  );

  /// Builds the CLI argument list for yt-dlp audio extraction.
  List<String> buildArgs() {
    return [
      '-x',
      '--audio-format',
      format.id,
      '--audio-quality',
      bitrate.qualityFlag,
      if (embedThumbnail) ...[
        '--embed-thumbnail',
        '--convert-thumbnails',
        'jpg',
      ],
      if (embedMetadata) '--add-metadata',
    ];
  }

  AudioConfig copyWith({
    AudioBitrate? bitrate,
    AudioFormat? format,
    bool? embedThumbnail,
    bool? embedMetadata,
  }) {
    return AudioConfig(
      bitrate: bitrate ?? this.bitrate,
      format: format ?? this.format,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedMetadata: embedMetadata ?? this.embedMetadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioConfig &&
          runtimeType == other.runtimeType &&
          bitrate == other.bitrate &&
          format == other.format &&
          embedThumbnail == other.embedThumbnail &&
          embedMetadata == other.embedMetadata;

  @override
  int get hashCode =>
      Object.hash(bitrate, format, embedThumbnail, embedMetadata);

  @override
  String toString() =>
      'AudioConfig(${format.id.toUpperCase()} ${bitrate.id}, art: $embedThumbnail, tags: $embedMetadata)';
}
