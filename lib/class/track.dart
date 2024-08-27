// ignore_for_file: avoid_rx_value_getter_outside_obx
import 'dart:io';

import 'package:history_manager/history_manager.dart';
import 'package:intl/intl.dart';

import 'package:namida/class/faudiomodel.dart';
import 'package:namida/class/folder.dart';
import 'package:namida/class/split_config.dart';
import 'package:namida/class/video.dart';
import 'package:namida/controller/indexer_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/enums.dart';
import 'package:namida/core/extensions.dart';

class TrackWithDate extends Selectable<Map<String, dynamic>> implements ItemWithDate {
  @override
  Track get track => _track;

  @override
  TrackWithDate? get trackWithDate => this;

  final int dateAdded;
  final Track _track;
  final TrackSource source;

  const TrackWithDate({
    required this.dateAdded,
    required Track track,
    required this.source,
  }) : _track = track;

  factory TrackWithDate.fromJson(Map<String, dynamic> json) {
    final finalTrack = Track.fromJson(json['track'] as String, isVideo: json['v'] == true);
    return TrackWithDate(
      dateAdded: json['dateAdded'] ?? currentTimeMS,
      track: finalTrack,
      source: TrackSource.values.getEnum(json['source']) ?? TrackSource.local,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'dateAdded': dateAdded,
      'track': _track.path,
      'source': source.name,
      if (_track is Video) 'v': true,
    };
  }

  @override
  DateTime get dateTimeAdded => DateTime.fromMillisecondsSinceEpoch(dateAdded);

  @override
  bool operator ==(other) {
    if (other is TrackWithDate) {
      return dateAdded == other.dateAdded && source == other.source && track == other.track;
    }
    return false;
  }

  @override
  int get hashCode => "$track$source$dateAdded".hashCode;

  @override
  String toString() => "track: ${track.toString()}, source: $source, dateAdded: $dateAdded";
}

extension TWDUtils on List<TrackWithDate> {
  List<Track> toTracks() => mapped((e) => e.track);
}

class TrackStats {
  /// Path of the track.
  final Track track;

  /// Rating of the track out of 100.
  int rating = 0;

  /// List of tags for the track.
  List<String> tags = [];

  /// List of moods for the track.
  List<String> moods = [];

  /// Last Played Position of the track in Milliseconds.
  int lastPositionInMs = 0;

  TrackStats({
    required this.track,
    required this.rating,
    required this.tags,
    required this.moods,
    required this.lastPositionInMs,
  });

  factory TrackStats.fromJson(Map<String, dynamic> json) {
    return TrackStats(
      track: Track.fromJson(json['track'] ?? '', isVideo: json['v'] == true),
      rating: json['rating'] ?? 0,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      moods: (json['moods'] as List?)?.cast<String>() ?? [],
      lastPositionInMs: json['lastPositionInMs'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'track': track.path,
      'rating': rating,
      'tags': tags,
      'moods': moods,
      'lastPositionInMs': lastPositionInMs,
      if (track is Video) 'v': true,
    };
  }

  @override
  String toString() => '${track.toString()}, rating: $rating, tags: $tags, moods: $moods, lastPositionInMs: $lastPositionInMs';
}

abstract class Playable<T extends Object> {
  const Playable();

  T toJson();
}

abstract class Selectable<T extends Object> extends Playable<T> {
  const Selectable();

  Track get track;
  TrackWithDate? get trackWithDate;

  @override
  bool operator ==(other) {
    if (other is Selectable) {
      return track == other.track;
    }
    return false;
  }

  @override
  int get hashCode => track.hashCode;
}

extension SelectableListUtils on Iterable<Selectable> {
  Iterable<Track> get tracks => map((e) => e.track);
  Iterable<TrackWithDate> get tracksWithDates => whereType<TrackWithDate>();
}

class Track extends Selectable<String> {
  Folder get folder => Folder.explicit(folderPath);

  bool hasInfoInLibrary() => toTrackExtOrNull() != null;
  TrackExtended toTrackExt() => toTrackExtOrNull() ?? kDummyExtendedTrack.copyWith(title: path.getFilenameWOExt, path: path);
  TrackExtended? toTrackExtOrNull() => Indexer.inst.allTracksMappedByPath[path];

  @override
  Track get track => this;

  @override
  TrackWithDate? get trackWithDate => null;

  final String path;
  const Track.explicit(this.path);

  factory Track.decide(String path, bool? isVideo) => isVideo == true ? Video.explicit(path) : Track.explicit(path);

  factory Track.orVideo(String path) {
    return path.isVideo() ? Video.explicit(path) : Track.explicit(path);
  }

  static T fromTypeParameter<T extends Track>(Type type, String path) {
    return type == Video ? Video.explicit(path) as T : Track.explicit(path) as T;
  }

  factory Track.fromJson(String path, {required bool isVideo}) {
    return isVideo ? Video.explicit(path) : Track.explicit(path);
  }

  @override
  bool operator ==(other) {
    if (other is Track) {
      return path == other.path;
    }
    return false;
  }

  @override
  int get hashCode => path.hashCode;

  @override
  String toString() => "path: $path";

  @override
  String toJson() => path;
}

class TrackExtended {
  final String title;
  final String originalArtist;
  final List<String> artistsList;
  final String album;
  final String albumArtist;
  final String originalGenre;
  final List<String> genresList;
  final String originalMood;
  final List<String> moodList;
  final String composer;
  final int trackNo;

  /// track's duration in milliseconds.
  final int durationMS;
  final int year;
  final int size;
  final int dateAdded;
  final int dateModified;
  final String path;
  final String comment;
  final int bitrate;
  final int sampleRate;
  final String format;
  final String channels;
  final int discNo;
  final String language;
  final String lyrics;
  final String label;
  final double rating;
  final String? originalTags;
  final List<String> tagsList;

  final bool isVideo;

  const TrackExtended({
    required this.title,
    required this.originalArtist,
    required this.artistsList,
    required this.album,
    required this.albumArtist,
    required this.originalGenre,
    required this.genresList,
    required this.originalMood,
    required this.moodList,
    required this.composer,
    required this.trackNo,
    required this.durationMS,
    required this.year,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    required this.path,
    required this.comment,
    required this.bitrate,
    required this.sampleRate,
    required this.format,
    required this.channels,
    required this.discNo,
    required this.language,
    required this.lyrics,
    required this.label,
    required this.rating,
    required this.originalTags,
    required this.tagsList,
    required this.isVideo,
  });

  static String _padInt(int val) => val.toString().padLeft(2, '0');

  static int? enforceYearFormat(String? fromYearString) {
    final intVal = fromYearString.getIntValue();
    if (intVal != null) return intVal;
    if (fromYearString != null) {
      try {
        final yearDate = DateTime.parse(fromYearString.replaceAll(RegExp(r'[\s]'), '-'));
        return int.parse("${yearDate.year}${_padInt(yearDate.month)}${_padInt(yearDate.day)}");
      } catch (_) {}
    }
    return null;
  }

  factory TrackExtended.fromJson(
    Map<String, dynamic> json, {
    required ArtistsSplitConfig artistsSplitConfig,
    required GenresSplitConfig genresSplitConfig,
  }) {
    return TrackExtended(
      title: json['title'] ?? '',
      originalArtist: json['originalArtist'] ?? '',
      artistsList: Indexer.splitArtist(
        title: json['title'],
        originalArtist: json['originalArtist'],
        config: artistsSplitConfig,
      ),
      album: json['album'] ?? '',
      albumArtist: json['albumArtist'] ?? '',
      originalGenre: json['originalGenre'] ?? '',
      genresList: Indexer.splitGenre(
        json['originalGenre'],
        config: genresSplitConfig,
      ),
      originalMood: json['originalMood'] ?? '',
      moodList: Indexer.splitGeneral(
        json['originalMood'],
        config: genresSplitConfig,
      ),
      composer: json['composer'] ?? '',
      trackNo: json['trackNo'] ?? 0,
      durationMS: json['durationMS'] ?? (json['duration'] is int ? json['duration'] * 1000 : 0),
      year: json['year'] ?? 0,
      size: json['size'] ?? 0,
      dateAdded: json['dateAdded'] ?? 0,
      dateModified: json['dateModified'] ?? 0,
      path: json['path'] ?? '',
      comment: json['comment'] ?? '',
      bitrate: json['bitrate'] ?? 0,
      sampleRate: json['sampleRate'] ?? 0,
      format: json['format'] ?? '',
      channels: json['channels'] ?? '',
      discNo: json['discNo'] ?? 0,
      language: json['language'] ?? '',
      lyrics: json['lyrics'] ?? '',
      label: json['label'] ?? '',
      rating: json['rating'] ?? 0.0,
      originalTags: json['originalTags'],
      tagsList: Indexer.splitGeneral(
        json['originalTags'],
        config: genresSplitConfig,
      ),
      isVideo: json['v'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'originalArtist': originalArtist,
      'album': album,
      'albumArtist': albumArtist,
      'originalGenre': originalGenre,
      'originalMood': originalMood,
      'composer': composer,
      'trackNo': trackNo,
      'durationMS': durationMS,
      'year': year,
      'size': size,
      'dateAdded': dateAdded,
      'dateModified': dateModified,
      'path': path,
      'comment': comment,
      'bitrate': bitrate,
      'sampleRate': sampleRate,
      'format': format,
      'channels': channels,
      'discNo': discNo,
      'language': language,
      'lyrics': lyrics,
      'label': label,
      'rating': rating,
      'originalTags': originalTags,
      'v': isVideo,
    };
  }

  @override
  bool operator ==(other) {
    if (other is Track) {
      return path == other.path;
    }
    return false;
  }

  @override
  int get hashCode => path.hashCode;
}

extension TrackExtUtils on TrackExtended {
  Track asTrack() => isVideo ? Video.explicit(path) : Track.explicit(path);
  bool get hasUnknownTitle => title == UnknownTags.TITLE;
  bool get hasUnknownAlbum => album == '' || album == UnknownTags.ALBUM;
  bool get hasUnknownAlbumArtist => albumArtist == '' || albumArtist == UnknownTags.ALBUMARTIST;
  bool get hasUnknownComposer => composer == '' || composer == UnknownTags.COMPOSER;
  bool get hasUnknownArtist => artistsList.isEmpty || artistsList.first == UnknownTags.ARTIST;
  bool get hasUnknownGenre => genresList.isEmpty || genresList.first == UnknownTags.GENRE;
  bool get hasUnknownMood => moodList.isEmpty || moodList.first == UnknownTags.MOOD || moodList.first == UnknownTags.GENRE; // cuz moods get parsed like genres

  String get filename => path.getFilename;
  String get filenameWOExt => path.getFilenameWOExt;
  String get extension => path.getExtension;
  String get folderPath => path.getDirectoryName;
  String get folderName => folderPath.splitLast(Platform.pathSeparator);
  String get pathToImage {
    final identifier = settings.groupArtworksByAlbum.value ? albumIdentifier : filename;
    return "${isVideo ? AppDirs.THUMBNAILS : AppDirs.ARTWORKS}$identifier.png";
  }

  String get albumIdentifier => getAlbumIdentifier(settings.albumIdentifiers.value);

  String getAlbumIdentifier(List<AlbumIdentifier> identifiers) {
    final n = identifiers.contains(AlbumIdentifier.albumName) ? album : '';
    final aa = identifiers.contains(AlbumIdentifier.albumArtist) ? albumArtist : '';
    final y = identifiers.contains(AlbumIdentifier.year) ? year : '';
    return "$n$aa$y";
  }

  String get youtubeLink {
    var comment = this.comment;
    if (comment.isNotEmpty) {
      var link = NamidaLinkUtils.extractYoutubeLink(comment);
      if (link != null) return link;
    }
    var filename = this.filename;
    if (filename.isNotEmpty) {
      var link = NamidaLinkUtils.extractYoutubeLink(filename);
      if (link != null) return link;
    }
    return '';
  }

  String get youtubeID => youtubeLink.getYoutubeID;

  TrackStats? get stats => Indexer.inst.trackStatsMap.value[asTrack()];

  String get yearPreferyyyyMMdd {
    final tostr = year.toString();
    final parsed = DateTime.tryParse(tostr);
    if (parsed != null) {
      return DateFormat('yyyyMMdd').format(parsed);
    }
    return tostr;
  }

  TrackExtended copyWithTag({
    required FTags tag,
    int? dateModified,
    String? path,
  }) {
    return TrackExtended(
      title: tag.title ?? title,
      originalArtist: tag.artist ?? originalArtist,
      artistsList: tag.artist != null ? [tag.artist!] : artistsList,
      album: tag.album ?? album,
      albumArtist: tag.albumArtist ?? albumArtist,
      originalGenre: tag.genre ?? originalGenre,
      genresList: tag.genre != null ? [tag.genre!] : genresList,
      originalMood: tag.mood ?? originalMood,
      moodList: tag.mood != null ? [tag.mood!] : moodList,
      composer: tag.composer ?? composer,
      trackNo: tag.trackNumber.getIntValue() ?? trackNo,
      year: TrackExtended.enforceYearFormat(tag.year) ?? year,
      dateModified: dateModified ?? this.dateModified,
      path: path ?? this.path,
      comment: tag.comment ?? comment,
      discNo: tag.discNumber.getIntValue() ?? discNo,
      language: tag.language ?? language,
      lyrics: tag.lyrics ?? lyrics,
      label: tag.recordLabel ?? label,
      rating: tag.ratingPercentage ?? rating,
      originalTags: tag.tags ?? originalTags,
      tagsList: tag.tags != null ? [tag.tags!] : tagsList,

      // -- uneditable fields
      bitrate: bitrate,
      channels: channels,
      dateAdded: dateAdded,
      durationMS: durationMS,
      format: format,
      sampleRate: sampleRate,
      size: size,
      isVideo: isVideo,
    );
  }

  TrackExtended copyWith({
    String? title,
    String? originalArtist,
    List<String>? artistsList,
    String? album,
    String? albumArtist,
    String? originalGenre,
    List<String>? genresList,
    String? originalMood,
    List<String>? moodList,
    String? composer,
    int? trackNo,

    /// track's duration in milliseconds.
    int? durationMS,
    int? year,
    int? size,
    int? dateAdded,
    int? dateModified,
    String? path,
    String? comment,
    int? bitrate,
    int? sampleRate,
    String? format,
    String? channels,
    int? discNo,
    String? language,
    String? lyrics,
    String? label,
    double? rating,
    String? originalTags,
    List<String>? tagsList,
    bool? isVideo,
  }) {
    return TrackExtended(
      title: title ?? this.title,
      originalArtist: originalArtist ?? this.originalArtist,
      artistsList: artistsList ?? this.artistsList,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      originalGenre: originalGenre ?? this.originalGenre,
      genresList: genresList ?? this.genresList,
      originalMood: originalMood ?? this.originalMood,
      moodList: moodList ?? this.moodList,
      composer: composer ?? this.composer,
      trackNo: trackNo ?? this.trackNo,
      durationMS: durationMS ?? this.durationMS,
      year: year ?? this.year,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      path: path ?? this.path,
      comment: comment ?? this.comment,
      bitrate: bitrate ?? this.bitrate,
      sampleRate: sampleRate ?? this.sampleRate,
      format: format ?? this.format,
      channels: channels ?? this.channels,
      discNo: discNo ?? this.discNo,
      language: language ?? this.language,
      lyrics: lyrics ?? this.lyrics,
      label: label ?? this.label,
      rating: rating ?? this.rating,
      originalTags: originalTags ?? this.originalTags,
      tagsList: tagsList ?? this.tagsList,
      isVideo: isVideo ?? this.isVideo,
    );
  }
}

extension TrackUtils on Track {
  String get yearPreferyyyyMMdd => toTrackExt().yearPreferyyyyMMdd;

  String get title => toTrackExt().title;
  String get originalArtist => toTrackExt().originalArtist;
  List<String> get artistsList => toTrackExt().artistsList;
  String get album => toTrackExt().album;
  String get albumArtist => toTrackExt().albumArtist;
  String get originalGenre => toTrackExt().originalGenre;
  List<String> get genresList => toTrackExt().genresList;
  String get originalMood => toTrackExt().originalMood;
  List<String> get moodList => toTrackExt().moodList;
  String get composer => toTrackExt().composer;
  int get trackNo => toTrackExt().trackNo;
  int get durationMS => toTrackExt().durationMS;
  int get year => toTrackExt().year;
  int get size => toTrackExt().size;
  int get dateAdded => toTrackExt().dateAdded;
  int get dateModified => toTrackExt().dateModified;
  String get comment => toTrackExt().comment;
  int get bitrate => toTrackExt().bitrate;
  int get sampleRate => toTrackExt().sampleRate;
  String get format => toTrackExt().format;
  String get channels => toTrackExt().channels;
  int get discNo => toTrackExt().discNo;
  String get language => toTrackExt().language;
  String get lyrics => toTrackExt().lyrics;
  String get label => toTrackExt().label;

  int? get lastPlayedPositionInMs => _stats?.lastPositionInMs;
  TrackStats? get _stats => Indexer.inst.trackStatsMap[this];
  int get effectiveRating {
    int? r = _stats?.rating;
    if (r != null && r > 0) return r;
    var percentageRatingEmbedded = toTrackExt().rating;
    return (percentageRatingEmbedded * 100).round();
  }

  List<String> get effectiveMoods {
    List<String>? m = _stats?.moods;
    if (m != null && m.isNotEmpty) return m;
    var moodsEmbedded = toTrackExt().moodList;
    return moodsEmbedded;
  }

  List<String> get effectiveTags {
    List<String>? s = _stats?.tags;
    if (s != null && s.isNotEmpty) return s;
    var tagsEmbedded = toTrackExt().tagsList;
    return tagsEmbedded;
  }

  String get filename => path.getFilename;
  String get filenameWOExt => path.getFilenameWOExt;
  String get extension => path.getExtension;
  String get folderPath => path.getDirectoryName;
  String get folderName => folderPath.splitLast(Platform.pathSeparator);
  String get pathToImage {
    final identifier = settings.groupArtworksByAlbum.value ? albumIdentifier : filename;
    return "${this is Video ? AppDirs.THUMBNAILS : AppDirs.ARTWORKS}$identifier.png";
  }

  String get youtubeLink => toTrackExt().youtubeLink;
  String get youtubeID => youtubeLink.getYoutubeID;

  String get audioInfoFormatted {
    final trExt = toTrackExt();
    return [
      trExt.durationMS.milliSecondsLabel,
      trExt.size.fileSizeFormatted,
      "${trExt.bitrate} kps",
      "${trExt.sampleRate} hz",
    ].join(' • ');
  }

  String get audioInfoFormattedCompact {
    final trExt = toTrackExt();
    return [
      trExt.format,
      "${trExt.channels} ch",
      "${trExt.bitrate} kps",
      "${trExt.sampleRate / 1000} khz",
    ].join(' • ');
  }

  String get albumIdentifier => toTrackExt().albumIdentifier;
  String getAlbumIdentifier(List<AlbumIdentifier> identifiers) => toTrackExt().getAlbumIdentifier(identifiers);
}
