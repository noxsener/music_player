// ============================================================
//  lib/player_controller.dart
//
//  Based on your v2 radio-enabled controller.
//
//  Key fix: stopTrack() now sets _isStopped = true.
//  togglePlay() checks _isStopped and re-calls player.play()
//  with DeviceFileSource / UrlSource instead of resume()
//  (audioplayers clears the source on stop(); resume() is a no-op).
// ============================================================

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/app_theme.dart';
import 'models/radio_song.dart';

class MusicPlayerController extends GetxController {
  final AudioPlayer player = AudioPlayer();

  final playlist         = <File>[].obs;
  final radioPlaylist    = <RadioSong>[].obs;
  final currentIndex     = (-1).obs;
  final isPlaying        = false.obs;
  final isRadioMode      = false.obs;
  final isLoading        = false.obs;
  final isDownloading    = false.obs;
  final position         = Duration.zero.obs;
  final duration         = Duration.zero.obs;
  final downloadProgress = 0.0.obs;

  // After player.stop() the audio source is cleared internally.
  // Calling resume() after stop() is a silent no-op.
  // We track this so togglePlay() re-loads the source.
  bool _isStopped = false;

  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _completeSub;

  @override
  void onInit() {
    super.onInit();
    _initStreams();
    fetchRadioSongs();
  }

  void _initStreams() {
    _posSub  = player.onPositionChanged.listen((p) => position.value = p);
    _durSub  = player.onDurationChanged.listen((d) => duration.value = d);
    _stateSub = player.onPlayerStateChanged.listen((s) {
      isPlaying.value = (s == PlayerState.playing);
      if (s == PlayerState.stopped) _isStopped = true;
    });
    _completeSub = player.onPlayerComplete.listen((_) => next());
  }

  // ── Radio ──────────────────────────────────────────────────

  Future<void> fetchRadioSongs() async {
    isLoading.value = true;
    try {
      final response = await http.get(Uri.parse(
          'https://studio-api.prod.suno.com/api/living_radio/thebetterdefault/song-list'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        radioPlaylist.assignAll(data.map((x) => RadioSong.fromJson(x)).toList());
      }
    } catch (e) {
      _showError('Radio Connection Error', 'Could not fetch the radio stream.');
    } finally {
      isLoading.value = false;
    }
  }

  // ── Local playback ─────────────────────────────────────────

  Future<void> playIndex(int index) async {
    isRadioMode.value = false;
    if (index < 0 || index >= playlist.length) return;
    currentIndex.value = index;
    _isStopped = false;
    try {
      await player.play(DeviceFileSource(playlist[index].path));
    } catch (e) {
      _showError('Error', 'Could not play: ${p.basename(playlist[index].path)}');
    }
  }

  // ── Radio playback ─────────────────────────────────────────

  Future<void> playRadioSong(int index) async {
    isRadioMode.value = true;
    if (index < 0 || index >= radioPlaylist.length) return;
    currentIndex.value = index;
    _isStopped = false;
    try {
      await player.play(UrlSource(radioPlaylist[index].songUrl));
    } catch (e) {
      _showError('Error', 'Could not start radio stream.');
    }
  }

  // ── Play/Pause toggle (stop-safe) ──────────────────────────

  void togglePlay() async {
    if (player.state == PlayerState.playing) {
      await player.pause();
      return;
    }
    final idx = currentIndex.value;
    if (idx == -1) return;

    if (_isStopped) {
      // Source was cleared by stop() — must reload
      _isStopped = false;
      if (isRadioMode.value) {
        await playRadioSong(idx);
      } else {
        await playIndex(idx);
      }
    } else {
      await player.resume();
    }
  }

  // ── Stop ───────────────────────────────────────────────────

  void stopTrack() {
    player.stop();
    _isStopped = true;
    position.value = Duration.zero;
  }

  // ── Navigation ─────────────────────────────────────────────

  void next() {
    if (isRadioMode.value) {
      if (radioPlaylist.isEmpty) return;
      playRadioSong((currentIndex.value + 1) % radioPlaylist.length);
    } else {
      if (playlist.isEmpty) return;
      playIndex((currentIndex.value + 1) % playlist.length);
    }
  }

  void prev() {
    if (isRadioMode.value) {
      if (radioPlaylist.isEmpty) return;
      playRadioSong(
          (currentIndex.value - 1 + radioPlaylist.length) % radioPlaylist.length);
    } else {
      if (playlist.isEmpty) return;
      playIndex((currentIndex.value - 1 + playlist.length) % playlist.length);
    }
  }

  void seek(double seconds) {
    if (_isStopped) return;
    player.seek(Duration(seconds: seconds.toInt()));
  }

  // ── Download ───────────────────────────────────────────────

  Future<void> downloadSong(RadioSong song) async {
    if (isDownloading.value) return;
    isDownloading.value    = true;
    downloadProgress.value = 0.0;
    try {
      final dir      = await getApplicationDocumentsDirectory();
      final safeName = song.winningStyle.replaceAll(RegExp(r'[^\w\s]+'), '_');
      final filePath = '${dir.path}/${safeName}_${song.songId.substring(0, 5)}.m4a';
      final client   = http.Client();
      final request  = http.Request('GET', Uri.parse(song.songUrl));
      final response = await client.send(request);
      final total    = response.contentLength ?? 0;
      int received   = 0;
      final file     = File(filePath);
      final sink     = file.openWrite();

      await response.stream.listen(
            (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) downloadProgress.value = received / total;
        },
        onDone: () async {
          await sink.close();
          client.close();
          isDownloading.value = false;
          _showSuccess('Download Complete', p.basename(filePath));
        },
        onError: (e) {
          sink.close();
          isDownloading.value = false;
          _showError('Download Error', 'File write error.');
        },
        cancelOnError: true,
      );
    } catch (e) {
      isDownloading.value = false;
      _showError('Connection Error', 'Could not reach the server.');
    }
  }

  // ── Snackbar helpers ───────────────────────────────────────

  void _showError(String title, String msg) => Get.snackbar(title, msg,
      backgroundColor: AppRawColors.red.withOpacity(0.8),
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15));

  void _showSuccess(String title, String msg) => Get.snackbar(title, msg,
      backgroundColor: AppRawColors.neonGreen.withOpacity(0.8),
      colorText: Colors.black,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(15));

  @override
  void onClose() {
    _posSub?.cancel(); _durSub?.cancel();
    _stateSub?.cancel(); _completeSub?.cancel();
    player.dispose();
    super.onClose();
  }
}