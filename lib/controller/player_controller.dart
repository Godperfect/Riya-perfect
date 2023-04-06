import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:get/get.dart';

import 'package:namida/class/track.dart';
import 'package:namida/controller/audio_handler.dart';
import 'package:namida/controller/queue_controller.dart';
import 'package:namida/controller/settings_controller.dart';
import 'package:namida/core/constants.dart';
import 'package:namida/core/functions.dart';

class Player {
  static Player inst = Player();

  NamidaAudioVideoHandler? _audioHandler;

  final Rx<Track> nowPlayingTrack = kDummyTrack.obs;
  final RxList<Track> currentQueue = <Track>[].obs;
  final RxInt currentIndex = 0.obs;
  final RxDouble currentVolume = SettingsController.inst.playerVolume.value.obs;
  final RxBool isPlaying = false.obs;
  final RxInt nowPlayingPosition = 0.obs;
  int latestInsertedIndex = 0;

  Future<void> initializePlayer() async {
    _audioHandler = await AudioService.init(
      builder: () => NamidaAudioVideoHandler(this),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.msob7y.namida',
        androidNotificationChannelName: 'Namida',
        androidNotificationChannelDescription: 'Namida Media Notification',
        androidNotificationIcon: 'drawable/ic_stat_musicnote',
        androidNotificationOngoing: true,
      ),
    );
  }

  void updateMediaItemForce() {
    _audioHandler?.updateCurrentMediaItem(null, true);
  }

  Future<void> updateVideoPlayingState() async {
    await _audioHandler?.updateVideoPlayingState();
  }

  Future<void> setVolume(double volume) async {
    await _audioHandler?.setVolume(volume);
  }

  void reorderTrack(int oldIndex, int newIndex) {
    _audioHandler?.reorderTrack(oldIndex, newIndex);
  }

  void shuffleNextTracks() {
    _audioHandler?.shuffleNextTracks();
  }

  // void shuffleAllQueue() {
  //   _audioHandler?.shuffleAllQueue();
  // }

  void removeDuplicatesFromQueue() {
    _audioHandler?.removeDuplicatesFromQueue();
  }

  void addToQueue(
    List<Track> tracks, {
    bool insertNext = false,
    bool insertAfterLatest = false,
  }) {
    _audioHandler?.addToQueue(
      tracks,
      insertNext: insertNext,
      insertAfterLatest: insertAfterLatest,
    );
  }

  void insertInQueue(List<Track> tracks, int index) {
    _audioHandler?.insertInQueue(tracks, index);
  }

  void removeFromQueue(int index) async {
    _audioHandler?.removeFromQueue(index);
  }

  void removeRangeFromQueue(int start, int end) {
    _audioHandler?.removeRangeFromQueue(start, end);
  }

  Future<void> play() async {
    await _audioHandler?.play();
  }

  Future<void> pause() async {
    await _audioHandler?.pause();
  }

  Future<void> next() async {
    await _audioHandler?.skipToNext();
  }

  Future<void> previous() async {
    await _audioHandler?.skipToPrevious();
  }

  Future<void> skipToQueueItem(int index) async {
    _audioHandler?.skipToQueueItem(index);
  }

  Future<void> seek(Duration position) async {
    await _audioHandler?.seek(position);
  }

  Future<void> seekSecondsForward([int seconds = 5]) async {
    await _audioHandler?.seek(Duration(milliseconds: nowPlayingPosition.value + seconds * 1000));
  }

  Future<void> seekSecondsBackward([int seconds = 5]) async {
    await _audioHandler?.seek(Duration(milliseconds: nowPlayingPosition.value - seconds * 1000));
  }

  Future<void> playOrPause(
    int index,
    List<Track> queue, {
    bool shuffle = false,
    bool startPlaying = true,
    bool dontAddQueue = false,
  }) async {
    List<Track> finalQueue = <Track>[];

    /// maximum 2000 track for performance.
    if (queue.length > 2000) {
      const trimCount = 1000;
      final start = (index - trimCount).clamp(0, queue.length - 1);
      final end = (index + trimCount).clamp(0, queue.length - 1);
      finalQueue.assignAll(queue.sublist(start, end + 1));
    } else {
      finalQueue.assignAll(queue);
    }

    if (finalQueue.isEmpty) {
      _audioHandler?.togglePlayPause();
      return;
    }

    final isQueueSame = checkIfQueueSameAsCurrent(finalQueue);

    if (index == currentIndex.value && isQueueSame) {
      _audioHandler?.togglePlayPause();
      return;
    }
    if (!isQueueSame) {
      latestInsertedIndex = index;
    }

    if (shuffle) {
      finalQueue.shuffle();
      index = 0;
    }

    if (!dontAddQueue) {
      QueueController.inst.addNewQueue(tracks: finalQueue.toList());
    }

    currentQueue.assignAll(finalQueue);

    await _audioHandler?.setAudioSource(index, startPlaying: startPlaying);
  }
}
