import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../config/app_theme.dart';
import 'models/radio_song.dart';

const _videoExts = {'.mp4', '.mkv', '.mov', '.avi', '.webm', '.m4v'};

const allSupportedExts = [
  'mp3',
  'm4a',
  'wav',
  'flac',
  'ogg',
  'aac',
  'mp4',
  'mkv',
  'mov',
  'avi',
  'webm',
  'm4v',
];

const _intentChannel = MethodChannel('com.codenfast.music_player/intent');

class MusicPlayerController extends GetxController {
  final Player player = Player(
    configuration: const PlayerConfiguration(
      pitch: false,
      bufferSize: 196 * 1024 * 1024, // 196 MB Buffer
      logLevel: MPVLogLevel.warn,
    ),
  );

  // VideoController is created in the screen, bound to `player`.
  // Kept here as null — the screen assigns it after creation.
  // (Not needed in the controller itself, only in the screen.)

  // ── Shared state ───────────────────────────────────────────
  final playlist = <File>[].obs;
  final radioPlaylist = <RadioSong>[].obs;
  final currentIndex = (-1).obs;
  final isPlaying = false.obs;
  final isRadioMode = false.obs;
  final isVideoMode = false.obs;
  final isLoading = false.obs;
  final position = Duration.zero.obs;
  final duration = Duration.zero.obs;

  // ── Download state ─────────────────────────────────────────
  final downloadingSongId = ''.obs;
  final downloadProgress = 0.0.obs;

  bool get isDownloading => downloadingSongId.value.isNotEmpty;

  // Current volume stored so it survives track changes (0.0–1.0)
  double _currentVolume = 1.0;

  StreamSubscription? _posSub, _durSub, _stateSub, _completeSub;

  @override
  void onInit() {
    super.onInit();
    _initStreams();
    // Set full volume at startup
    player.setVolume(100.0).then((_) async {
      try {
        await (player.platform as NativePlayer).setProperty(
          'hwdec',
          'auto-safe',
        );
      } catch (_) {
        // Ignore — web or unsupported platform
      }
      try {
        await (player.platform as NativePlayer).setProperty(
          'video-sync',
          'display-resample',
        );
      } catch (_) {
        // Ignore — web or unsupported platform
      }
    });

    fetchRadioSongs();
  }

  // ─────────────────────────────────────────────────────────
  //  Stream wiring — single player, much simpler than before
  // ─────────────────────────────────────────────────────────

  void _initStreams() {
    _posSub = player.stream.position.listen((pos) => position.value = pos);
    _durSub = player.stream.duration.listen((dur) => duration.value = dur);
    _stateSub = player.stream.playing.listen(
      (playing) => isPlaying.value = playing,
    );
    _completeSub = player.stream.completed.listen((completed) {
      if (completed) next();
    });
  }

  // ─────────────────────────────────────────────────────────
  //  Radio
  // ─────────────────────────────────────────────────────────

  Future<void> fetchRadioSongs() async {
    isLoading.value = true;
    try {
      final response = await http.get(
        Uri.parse(
          'https://studio-api.prod.suno.com/api/living_radio/thebetterdefault/song-list',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        radioPlaylist.assignAll(
          data.map((x) => RadioSong.fromJson(x)).toList(),
        );
      }
    } catch (_) {
      _showError('Radio Connection Error', 'Could not fetch the radio stream.');
    } finally {
      isLoading.value = false;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Local playback
  // ─────────────────────────────────────────────────────────

  Future<void> playIndex(int index) async {
    isRadioMode.value = false;
    if (index < 0 || index >= playlist.length) return;
    currentIndex.value = index;

    final ext = p.extension(playlist[index].path).toLowerCase();
    isVideoMode.value = _videoExts.contains(ext);

    try {
      await player.open(Media(playlist[index].path), play: true);
      // Re-apply user volume after open (media_kit resets on open)
      await player.setVolume(_currentVolume * 100.0);
    } catch (e) {
      _showError(
        'Error',
        'Could not play: ${p.basename(playlist[index].path)}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Radio playback
  // ─────────────────────────────────────────────────────────

  Future<void> playRadioSong(int index) async {
    isRadioMode.value = true;
    isVideoMode.value = false;
    if (index < 0 || index >= radioPlaylist.length) return;
    currentIndex.value = index;
    try {
      await player.open(Media(radioPlaylist[index].songUrl), play: true);
      await player.setVolume(_currentVolume * 100.0);
    } catch (_) {
      _showError('Error', 'Could not start radio stream.');
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Open With intent
  // ─────────────────────────────────────────────────────────

  Future<void> handleOpenWithIntent() async {
    try {
      final uri = await _intentChannel.invokeMethod<String>('getInitialUri');
      if (uri == null || uri.isEmpty) return;
      await _openUri(uri);
    } catch (_) {}

    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onNewUri') {
        final uri = call.arguments as String?;
        if (uri != null && uri.isNotEmpty) await _openUri(uri);
      }
    });
  }

  Future<void> _openUri(String uri) async {
    File? file;
    if (uri.startsWith('file://')) {
      file = File(Uri.decodeComponent(uri.replaceFirst('file://', '')));
    } else if (uri.startsWith('content://')) {
      file = await _copyContentUriToCache(uri);
    } else if (uri.startsWith('/')) {
      file = File(uri);
    }

    if (file == null || !await file.exists()) {
      _showError('Open With', 'Could not open the file.');
      return;
    }

    final alreadyIn = playlist.any((f) => f.path == file!.path);
    if (!alreadyIn) playlist.add(file);
    final idx = playlist.indexWhere((f) => f.path == file!.path);
    await playIndex(idx);
  }

  Future<File?> _copyContentUriToCache(String contentUri) async {
    try {
      final cachedPath = await _intentChannel.invokeMethod<String>(
        'copyContentUri',
        {'uri': contentUri},
      );
      if (cachedPath == null) return null;
      return File(cachedPath);
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Play / Pause
  // ─────────────────────────────────────────────────────────

  Future<void> togglePlay() async {
    await player.playOrPause();
  }

  // ─────────────────────────────────────────────────────────
  //  Stop
  // ─────────────────────────────────────────────────────────

  Future<void> stopTrack() async {
    await player.pause();
    await player.seek(Duration.zero);
    position.value = Duration.zero;
  }

  // ─────────────────────────────────────────────────────────
  //  Navigation
  // ─────────────────────────────────────────────────────────

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
        (currentIndex.value - 1 + radioPlaylist.length) % radioPlaylist.length,
      );
    } else {
      if (playlist.isEmpty) return;
      playIndex((currentIndex.value - 1 + playlist.length) % playlist.length);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Seek
  // ─────────────────────────────────────────────────────────

  Future<void> seek(double seconds) async {
    await player.seek(Duration(seconds: seconds.toInt()));
  }

  // ─────────────────────────────────────────────────────────
  //  Volume  (0.0–1.0 from slider → 0.0–100.0 for media_kit)
  // ─────────────────────────────────────────────────────────

  Future<void> setVolume(double v) async {
    _currentVolume = v.clamp(0.0, 1.0);
    await player.setVolume(_currentVolume * 100.0);
  }

  // Balance is not supported by media_kit — no-op kept so the
  // screen compiles without changes. Hide the BAL slider in UI.
  Future<void> setBalance(double b) async {}

  // ─────────────────────────────────────────────────────────
  //  Download
  // ─────────────────────────────────────────────────────────

  Future<void> downloadSong(RadioSong song) async {
    if (isDownloading) return;
    downloadingSongId.value = song.songId;
    downloadProgress.value = 0.0;
    try {
      final dir = await _resolveDownloadDir();
      final safeName = (song.title.isNotEmpty ? song.title : song.winningStyle)
          .replaceAll(RegExp(r'[^\w\s\-]+'), '_')
          .trim();
      final shortId = song.songId.length >= 5
          ? song.songId.substring(0, 5)
          : song.songId;
      final fileName = '${safeName}_$shortId.m4a';
      final filePath = p.join(dir.path, fileName);
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(song.songUrl));
      final response = await client.send(request);
      final total = response.contentLength ?? 0;
      int received = 0;
      final sink = File(filePath).openWrite();
      final done = Completer<void>();

      response.stream.listen(
        (chunk) {
          sink.add(chunk);
          received += chunk.length;
          if (total > 0) downloadProgress.value = received / total;
        },
        onDone: () async {
          await sink.flush();
          await sink.close();
          client.close();
          done.complete();
        },
        onError: (e) {
          sink.close();
          client.close();
          done.completeError(e);
        },
        cancelOnError: true,
      );

      await done.future;
      downloadingSongId.value = '';
      _showSuccess('Download Complete', '$fileName\nSaved to: ${dir.path}');
    } catch (e) {
      downloadingSongId.value = '';
      _showError('Download Error', e.toString());
    }
  }

  Future<Directory> _resolveDownloadDir() async {
    Directory base;
    if (Platform.isAndroid) {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final root = ext.path.split('Android').first;
        base = Directory('${root}Music');
      } else {
        base = await getApplicationDocumentsDirectory();
      }
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    final dir = Directory(p.join(base.path, 'Codenfast'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ─────────────────────────────────────────────────────────
  //  Snackbars
  // ─────────────────────────────────────────────────────────

  void _showError(String title, String msg) => Get.snackbar(
    title,
    msg,
    backgroundColor: AppRawColors.red.withOpacity(0.8),
    colorText: Colors.white,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(15),
  );

  void _showSuccess(String title, String msg) => Get.snackbar(
    title,
    msg,
    backgroundColor: AppRawColors.neonGreen.withOpacity(0.8),
    colorText: Colors.black,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 6),
    margin: const EdgeInsets.all(15),
  );

  @override
  void onClose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _completeSub?.cancel();
    player.dispose();
    super.onClose();
  }
}
