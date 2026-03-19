// ============================================================
//  lib/music_player_screen.dart
//
//  NEW in this version:
//   ① Playlist window has a LOCAL / RADIO tab switcher
//   ② Radio tab shows radioPlaylist from controller (Suno AI)
//   ③ Auto-refresh every 60 s via a Timer in initState()
//   ④ Radio rows: tap-to-play, cover art, style chip, duration
//   ⑤ Per-row download button with circular progress indicator
//   ⑥ Suno AI branding badge in radio header
//   ⑦ Track card reads both local and radio state correctly
//
//  Design tokens / all other widgets — UNCHANGED from v2.0
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:music_player/player_controller.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import '../config/app_theme.dart';
import '../models/radio_song.dart';

// ─────────────────────────────────────────────────────────────
//  PLATFORM TIER
// ─────────────────────────────────────────────────────────────

enum _PerfTier { desktop, ios, android }

_PerfTier get _tier {
  if (kIsWeb) return _PerfTier.desktop;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    return _PerfTier.desktop;
  }
  if (Platform.isIOS) return _PerfTier.ios;
  return _PerfTier.android;
}

bool get _isDesktopTier => _tier == _PerfTier.desktop;

bool get _isAndroidTier => _tier == _PerfTier.android;

// ─────────────────────────────────────────────────────────────
//  DESIGN TOKENS — identical to v2.0
// ─────────────────────────────────────────────────────────────

abstract class _FC {
  static const Color bg = Color(0xFF07090F);
  static const Color panelBg = Color(0xFF0C1018);
  static const Color cardBg = Color(0xFF101520);
  static const Color headerBg = Color(0xFF111928);
  static const Color border = Color(0xFF1B2840);

  static const Color ledOff = Color(0xFF081510);
  static const Color ledLow = Color(0xFF69FF47);
  static const Color ledMid = Color(0xFFFFCB6B);
  static const Color ledPeak = Color(0xFFFF5370);

  static const Color scrubBg = Color(0xFF0A1520);
  static const Color btnBg = Color(0xFF101D30);
  static const Color btnBorder = Color(0xFF1E3050);

  // Radio-specific accent (warm violet to distinguish from local cyan)
  static const Color radioAccent = Color(0xFF7C4DFF);

  static const double rXs = 6.0;
  static const double rSm = 10.0;
  static const double rMd = 14.0;
  static const double rLg = 18.0;

  static const String font = 'Inter';
}

// ─────────────────────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────────────────────

class MusicPlayerScreen extends StatefulWidget {
  const MusicPlayerScreen({super.key});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  final controller = Get.put(MusicPlayerController());

  // ── Animation controllers (same as v2.0) ──────────────────

  late final AnimationController _listAnim;
  late final AnimationController _radioListAnim; // separate entrance for radio
  late final AnimationController _vuAnim;
  late final AnimationController _glowAnim;
  late final AnimationController _eqAnim;
  late final AnimationController _shimmerAnim;

  // EQ state
  final List<double> _eq = List.filled(10, 0.0);
  final List<double> _peaks = List.filled(10, 0.0);
  final List<int> _peakHold = List.filled(10, 0);
  final math.Random _rng = math.Random();
  int _skip = 0;

  // ── Radio auto-refresh ─────────────────────────────────────
  Timer? _radioRefreshTimer;

  // ── Playlist tab state (0 = LOCAL, 1 = RADIO) ─────────────
  int _tab = 0;

  // ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _listAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _radioListAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _vuAnim = AnimationController(
      vsync: this,
      duration: _isAndroidTier
          ? const Duration(milliseconds: 150)
          : const Duration(milliseconds: 80),
    )..repeat();

    _glowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (!_isAndroidTier) _glowAnim.repeat(reverse: true);

    _eqAnim =
        AnimationController(
            vsync: this,
            duration: _isAndroidTier
                ? const Duration(milliseconds: 300)
                : const Duration(milliseconds: 200),
          )
          ..addListener(_tickEq)
          ..repeat();

    _shimmerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (!_isAndroidTier) _shimmerAnim.repeat(reverse: true);

    // ── Radio: initial load already done in controller.onInit()
    // Start periodic refresh every 60 seconds
    _radioRefreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      controller.fetchRadioSongs();
      // Replay entrance animation when list refreshes
      _radioListAnim
        ..reset()
        ..forward();
    });

    // Animate radio list on first arrival when tab switches
    ever(controller.radioPlaylist, (_) {
      if (_tab == 1) {
        _radioListAnim
          ..reset()
          ..forward();
      }
    });
  }

  void _tickEq() {
    if (!controller.isPlaying.value) {
      for (int i = 0; i < 10; i++) {
        _eq[i] = (_eq[i] - 0.022).clamp(0.0, 1.0);
        if (_peakHold[i] <= 0) {
          _peaks[i] = (_peaks[i] - 0.012).clamp(0.0, 1.0);
        } else {
          _peakHold[i]--;
        }
      }
      return;
    }
    if (_isAndroidTier) {
      _skip = (_skip + 1) % 2;
      if (_skip != 0) return;
    }
    const bias = [1.0, 0.92, 0.88, 0.78, 0.68, 0.62, 0.55, 0.50, 0.44, 0.38];
    for (int i = 0; i < 10; i++) {
      final target = (_rng.nextDouble() * bias[i] * 0.9 + 0.08).clamp(0.0, 1.0);
      _eq[i] = (_eq[i] * 0.78 + target * 0.22).clamp(0.0, 1.0);
      if (_eq[i] >= _peaks[i]) {
        _peaks[i] = _eq[i];
        _peakHold[i] = 14;
      } else if (_peakHold[i] > 0) {
        _peakHold[i]--;
      } else {
        _peaks[i] = (_peaks[i] - 0.012).clamp(0.0, 1.0);
      }
    }
  }

  @override
  void dispose() {
    _radioRefreshTimer?.cancel();
    _listAnim.dispose();
    _radioListAnim.dispose();
    _vuAnim.dispose();
    _glowAnim.dispose();
    _eqAnim.dispose();
    _shimmerAnim.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════
  //  BUILD
  // ══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _FC.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, c) {
            final wide = c.maxWidth > c.maxHeight || c.maxWidth > 600;
            return wide ? _wideLayout(c) : _narrowLayout();
          },
        ),
      ),
    );
  }

  Widget _wideLayout(BoxConstraints c) => Row(
    children: [
      SizedBox(width: math.min(400.0, c.maxWidth * 0.45), child: _mainWindow()),
      Container(
        width: 1,
        margin: const EdgeInsets.symmetric(vertical: 14),
        color: _FC.border,
      ),
      Expanded(child: _playlistWindow()),
    ],
  );

  Widget _narrowLayout() => Column(
    children: [
      _mainWindow(),
      Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: _FC.border,
      ),
      Expanded(child: _playlistWindow()),
    ],
  );

  // ══════════════════════════════════════════════════════════
  //  MAIN WINDOW  (unchanged from v2.0 — only _trackCard differs)
  // ══════════════════════════════════════════════════════════

  Widget _mainWindow() => Container(
    color: _FC.panelBg,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        const SizedBox(height: 8),
        _trackCard(),
        const SizedBox(height: 8),
        _visualizerCard(),
        const SizedBox(height: 8),
        _seekBar(),
        _timeRow(),
        const SizedBox(height: 6),
        _transportRow(),
        const SizedBox(height: 6),
        _volBalRow(),
        const SizedBox(height: 12),
      ],
    ),
  );

  // ── Header ─────────────────────────────────────────────────

  Widget _header() => AnimatedBuilder(
    animation: _glowAnim,
    builder: (_, __) {
      final g = _isAndroidTier ? 0.0 : _glowAnim.value;
      return Container(
        height: 46,
        decoration: BoxDecoration(
          color: _FC.headerBg,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(_FC.rMd),
            bottomRight: Radius.circular(_FC.rMd),
          ),
          border: Border.all(color: _FC.border),
          boxShadow: _isDesktopTier
              ? [
                  BoxShadow(
                    color: AppRawColors.cyan.withOpacity(0.05 + g * 0.10),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppRawColors.cyan,
                boxShadow: _isAndroidTier
                    ? null
                    : [
                        BoxShadow(
                          color: AppRawColors.cyan.withOpacity(0.35 + g * 0.45),
                          blurRadius: 7,
                        ),
                      ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CODENFAST PLAYER',
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppRawColors.cyan,
                letterSpacing: 2.2,
              ),
            ),
            const Spacer(),
            Text(
              'v2.0',
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 10,
                color: AppRawColors.cyan.withOpacity(0.40),
                letterSpacing: 1.4,
              ),
            ),
          ],
        ),
      );
    },
  );

  // ── Track card — shows local OR radio track info ─────────

  Widget _trackCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _FC.cardBg,
        borderRadius: BorderRadius.circular(_FC.rMd),
        border: Border.all(color: _FC.border),
        boxShadow: _isDesktopTier
            ? [
                BoxShadow(
                  color: AppRawColors.cyan.withOpacity(0.035),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Obx(() {
        final idx = controller.currentIndex.value;
        final isRadio = controller.isRadioMode.value;
        final hasTrack = idx >= 0;

        // ── Determine display values ──────────────────────
        String trackName;
        String? coverUrl;
        String tag1, tag2, tag3;

        if (!hasTrack) {
          trackName = 'No track selected';
          tag1 = '–';
          tag2 = '–';
          tag3 = '';
          coverUrl = null;
        } else if (isRadio) {
          final song = controller.radioPlaylist[idx];
          trackName = song.title;
          coverUrl = song.imageUrl.isNotEmpty ? song.imageUrl : null;
          tag1 = song.winningStyle;
          tag2 = _fmtSec(song.duration);
          tag3 = 'SUNO';
        } else {
          final file = controller.playlist[idx];
          trackName = p.basenameWithoutExtension(file.path);
          coverUrl  = null;
          tag1 = '320 kbps';
          tag2 = '44.1 kHz';
          tag3 = p.extension(file.path).replaceFirst('.', '').toUpperCase();
        }

        return Row(
          children: [
            // Cover art or index pill
            if (coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(_FC.rSm),
                child: Image.network(
                  coverUrl,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _trackPill(
                    hasTrack ? '${idx + 1}' : '--',
                    isRadio ? _FC.radioAccent : AppRawColors.cyan,
                  ),
                ),
              )
            else
              _trackPill(
                hasTrack ? (idx + 1).toString().padLeft(2, '0') : '--',
                isRadio ? _FC.radioAccent : AppRawColors.cyan,
              ),

            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isAndroidTier
                      ? Text(
                          trackName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: _FC.font,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppRawColors.darkTextPrimary,
                          ),
                        )
                      : _Marquee(text: trackName),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _Tag(
                        label: tag1,
                        color: isRadio
                            ? _FC.radioAccent
                            : AppRawColors.neonGreen,
                      ),
                      const SizedBox(width: 6),
                      _Tag(label: tag2, color: AppRawColors.cyan),
                      if (tag3.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _Tag(label: tag3, color: AppRawColors.violet),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _trackPill(String text, Color color) => Container(
    width: 36,
    height: 36,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_FC.rSm),
      color: color.withOpacity(0.08),
      border: Border.all(color: color.withOpacity(0.28)),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontFamily: _FC.font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  // ── Visualizer (unchanged) ─────────────────────────────────

  Widget _visualizerCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    height: 64,
    decoration: BoxDecoration(
      color: const Color(0xFF060C12),
      borderRadius: BorderRadius.circular(_FC.rMd),
      border: Border.all(color: _FC.border),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    child: Row(
      children: [
        AnimatedBuilder(
          animation: _vuAnim,
          builder: (_, __) {
            final on = controller.isPlaying.value;
            final lv = on ? _rng.nextDouble() * 0.75 + 0.15 : 0.0;
            final rv = on ? _rng.nextDouble() * 0.75 + 0.15 : 0.0;
            return Row(
              children: [
                _VuMeter(value: lv, label: 'L'),
                const SizedBox(width: 5),
                _VuMeter(value: rv, label: 'R'),
                const SizedBox(width: 12),
                Container(width: 1, height: 38, color: _FC.border),
                const SizedBox(width: 12),
              ],
            );
          },
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: _eqAnim,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(10, (i) {
                final color = i < 3
                    ? AppRawColors.neonGreen
                    : i < 7
                    ? AppRawColors.cyan
                    : AppRawColors.violet;
                return _EqBar(value: _eq[i], peak: _peaks[i], color: color);
              }),
            ),
          ),
        ),
      ],
    ),
  );

  // ── Seek bar (unchanged) ───────────────────────────────────

  Widget _seekBar() => Obx(() {
    final pos = controller.position.value;
    final dur = controller.duration.value;
    final total = dur.inMilliseconds.toDouble();
    final cur = pos.inMilliseconds.toDouble().clamp(
      0.0,
      total > 0 ? total : 1.0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Container(
        height: 22,
        decoration: BoxDecoration(
          color: _FC.cardBg,
          borderRadius: BorderRadius.circular(_FC.rSm),
          border: Border.all(color: _FC.border),
        ),
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            trackShape: const _RoundTrack(),
            thumbShape: const _GlowThumb(),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: AppRawColors.cyan,
            inactiveTrackColor: _FC.scrubBg,
            thumbColor: AppRawColors.cyan,
            overlayColor: AppRawColors.cyan.withOpacity(0.14),
          ),
          child: Slider(
            min: 0,
            max: total > 0 ? total : 1.0,
            value: cur,
            onChanged: (v) => controller.seek(v / 1000.0),
          ),
        ),
      ),
    );
  });

  // ── Time row (unchanged) ───────────────────────────────────

  Widget _timeRow() => Obx(() {
    final pos = controller.position.value;
    final dur = controller.duration.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _TimeLabel(duration: pos),
          Obx(
            () => AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                controller.isPlaying.value
                    ? Icons.graphic_eq_rounded
                    : Icons.pause_rounded,
                key: ValueKey(controller.isPlaying.value),
                color: AppRawColors.cyan.withOpacity(0.45),
                size: 14,
              ),
            ),
          ),
          _TimeLabel(duration: dur, negate: true),
        ],
      ),
    );
  });

  // ── Transport row (unchanged) ──────────────────────────────

  Widget _transportRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Btn(
          icon: Icons.skip_previous_rounded,
          onTap: controller.prev,
          tip: 'Prev',
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: Icons.fast_rewind_rounded,
          onTap: () => controller.seek(
            (controller.position.value.inSeconds - 5).toDouble(),
          ),
          tip: '-5s',
        ),
        const SizedBox(width: 6),
        Obx(
          () => _Btn(
            icon: controller.isPlaying.value
                ? Icons.pause_rounded
                : Icons.play_arrow_rounded,
            onTap: controller.togglePlay,
            isPrimary: true,
            tip: controller.isPlaying.value ? 'Pause' : 'Play',
          ),
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: Icons.stop_rounded,
          onTap: controller.stopTrack,
          tip: 'Stop',
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: Icons.fast_forward_rounded,
          onTap: () => controller.seek(
            (controller.position.value.inSeconds + 5).toDouble(),
          ),
          tip: '+5s',
        ),
        const SizedBox(width: 6),
        _Btn(
          icon: Icons.skip_next_rounded,
          onTap: controller.next,
          tip: 'Next',
        ),
        const Spacer(),
        _Btn(
          icon: Icons.folder_open_rounded,
          onTap: _pickDirectory,
          tip: 'Open folder',
          color: AppRawColors.amber,
          small: true,
        ),
      ],
    ),
  );

  // ── Volume / balance row (unchanged) ──────────────────────

  Widget _volBalRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: [
        Icon(
          Icons.volume_up_rounded,
          color: AppRawColors.cyan.withOpacity(0.45),
          size: 14,
        ),
        Expanded(
          flex: 3,
          child: _ThinSlider(
            value: controller.player.volume,
            onChanged: (v) async {
              await controller.player.setVolume(v);
              setState(() {});
            },
            color: AppRawColors.cyan,
            label: 'VOL',
          ),
        ),
        const SizedBox(width: 10),
        Icon(
          Icons.tune_rounded,
          color: AppRawColors.violet.withOpacity(0.45),
          size: 14,
        ),
        Expanded(
          flex: 2,
          child: _ThinSlider(
            max: 2,
            min: 0,
            value: controller.player.balance + 1,
            onChanged: (v) async {
              await controller.player.setBalance(
                v - 1,
              ); // -1 left, 1 right, 0 center
              setState(() {});
            },
            color: AppRawColors.violet,
            label: 'BAL',
          ),
        ),
      ],
    ),
  );

  // ══════════════════════════════════════════════════════════
  //  PLAYLIST WINDOW  ← UPDATED: LOCAL / RADIO tabs
  // ══════════════════════════════════════════════════════════

  Widget _playlistWindow() => Container(
    color: _FC.panelBg,
    child: Column(
      children: [
        _playlistHeader(),
        Expanded(child: _tab == 0 ? _localBody() : _radioBody()),
        _playlistFooter(),
      ],
    ),
  );

  // ── Header with tab switcher ───────────────────────────────

  Widget _playlistHeader() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _FC.headerBg,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(_FC.rMd),
          bottomRight: Radius.circular(_FC.rMd),
        ),
        border: Border.all(color: _FC.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          // ── LOCAL tab ───────────────────────────────────────
          _TabBtn(
            label: 'LOCAL',
            icon: Icons.queue_music_rounded,
            active: _tab == 0,
            color: AppRawColors.cyan,
            onTap: () {
              if (_tab != 0) setState(() => _tab = 0);
            },
          ),
          const SizedBox(width: 6),
          // ── RADIO tab ───────────────────────────────────────
          _TabBtn(
            label: 'RADIO',
            icon: Icons.radio_rounded,
            active: _tab == 1,
            color: _FC.radioAccent,
            onTap: () {
              if (_tab != 1) {
                setState(() => _tab = 1);
                _radioListAnim
                  ..reset()
                  ..forward();
                // Fetch fresh data when user opens the tab
                if (controller.radioPlaylist.isEmpty) {
                  controller.fetchRadioSongs();
                }
              }
            },
          ),
          const Spacer(),
          // Track count badge
          Obx(() {
            final n = _tab == 0
                ? controller.playlist.length
                : controller.radioPlaylist.length;
            return _CountBadge(
              n,
              color: _tab == 0 ? AppRawColors.cyan : _FC.radioAccent,
            );
          }),
        ],
      ),
    );
  }

  // ── LOCAL body (unchanged logic) ───────────────────────────

  Widget _localBody() => Obx(() {
    if (controller.playlist.isEmpty) {
      return _emptyState(
        icon: Icons.folder_open_rounded,
        title: 'No tracks loaded',
        hint: 'Tap "Add folder" or the folder button above',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      itemCount: controller.playlist.length,
      itemBuilder: (ctx, i) {
        final file = controller.playlist[i];
        return Obx(() {
          final isCurrent =
              !controller.isRadioMode.value &&
              controller.currentIndex.value == i;
          return _PlaylistRow(
            key: ValueKey(file.path),
            index: i,
            listAnim: _listAnim,
            shimmerAnim: _shimmerAnim,
            filename: p.basenameWithoutExtension(file.path),
            extension: p
                .extension(file.path)
                .replaceFirst('.', '')
                .toUpperCase(),
            isCurrent: isCurrent,
            showEffects: !_isAndroidTier,
            onTap: () => controller.playIndex(i),
          );
        });
      },
    );
  });

  // ── RADIO body ─────────────────────────────────────────────

  Widget _radioBody() => Obx(() {
    if (controller.isLoading.value && controller.radioPlaylist.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _FC.radioAccent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Fetching Suno AI radio…',
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 12,
                color: _FC.radioAccent.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.radioPlaylist.isEmpty) {
      return _emptyState(
        icon: Icons.wifi_off_rounded,
        title: 'Radio unavailable',
        hint: 'Could not reach the Suno AI stream.\nTap the refresh button.',
        color: _FC.radioAccent,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      itemCount: controller.radioPlaylist.length,
      itemBuilder: (ctx, i) {
        final song = controller.radioPlaylist[i];
        return Obx(() {
          final isCurrent =
              controller.isRadioMode.value &&
              controller.currentIndex.value == i;
          return _RadioRow(
            key: ValueKey(song.songId),
            index: i,
            song: song,
            listAnim: _radioListAnim,
            shimmerAnim: _shimmerAnim,
            isCurrent: isCurrent,
            showEffects: !_isAndroidTier,
            onTap: () => controller.playRadioSong(i),
            onDownload: () => controller.downloadSong(song),
          );
        });
      },
    );
  });

  // ── Empty state helper ─────────────────────────────────────

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String hint,
    Color? color,
  }) {
    final c = color ?? AppRawColors.cyan;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.withOpacity(0.18), size: 52),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              fontFamily: _FC.font,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.withOpacity(0.32),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: _FC.font,
              fontSize: 11,
              color: AppRawColors.darkTextSecondary.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────

  Widget _playlistFooter() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _FC.headerBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_FC.rMd),
          topRight: Radius.circular(_FC.rMd),
        ),
        border: Border.all(color: _FC.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: _tab == 0 ? _localFooterContent() : _radioFooterContent(),
    );
  }

  Widget _localFooterContent() => Row(
    children: [
      _FBtn(
        label: 'Add files',
        icon: Icons.audiotrack_rounded,
        onTap: _pickFiles,
      ),
      const SizedBox(width: 8),
      _FBtn(
        label: 'Add folder',
        icon: Icons.folder_rounded,
        onTap: _pickDirectory,
      ),
      const SizedBox(width: 8),
      _FBtn(
        label: 'Clear',
        icon: Icons.delete_sweep_rounded,
        color: AppRawColors.red,
        onTap: () {
          controller.stopTrack();
          controller.playlist.clear();
          controller.currentIndex.value = -1;
        },
      ),
      const Spacer(),
      Obx(
        () => Text(
          _fmt(controller.duration.value),
          style: TextStyle(
            fontFamily: _FC.font,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppRawColors.neonGreen,
          ),
        ),
      ),
    ],
  );

  Widget _radioFooterContent() => Row(
    children: [
      // Refresh button
      _FBtn(
        label: 'Refresh',
        icon: Icons.refresh_rounded,
        color: _FC.radioAccent,
        onTap: () {
          controller.fetchRadioSongs();
          _radioListAnim
            ..reset()
            ..forward();
        },
      ),
      const SizedBox(width: 8),
      // Suno AI branding badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_FC.rSm),
          gradient: LinearGradient(
            colors: [
              _FC.radioAccent.withOpacity(0.18),
              AppRawColors.cyan.withOpacity(0.10),
            ],
          ),
          border: Border.all(color: _FC.radioAccent.withOpacity(0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 11, color: _FC.radioAccent),
            const SizedBox(width: 4),
            Text(
              'Powered by Suno AI',
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: _FC.radioAccent.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
      const Spacer(),
      // Download progress indicator (global)
      Obx(() {
        if (!controller.isDownloading.value) return const SizedBox.shrink();
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                value: controller.downloadProgress.value > 0
                    ? controller.downloadProgress.value
                    : null,
                strokeWidth: 2,
                color: AppRawColors.neonGreen,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              controller.downloadProgress.value > 0
                  ? '${(controller.downloadProgress.value * 100).toInt()}%'
                  : 'Downloading…',
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 10,
                color: AppRawColors.neonGreen,
              ),
            ),
          ],
        );
      }),
    ],
  );

  // ══════════════════════════════════════════════════════════
  //  PERMISSION-AWARE FILE PICKERS  (unchanged from v2.0)
  // ══════════════════════════════════════════════════════════

  Future<bool> _requestAndroidPerm() async {
    if (!Platform.isAndroid) return true;
    Permission perm = Permission.audio;
    var status = await perm.status;
    if (!status.isGranted) {
      if (status.isDenied) {
        status = await perm.request();
        if (!status.isGranted) {
          final legacyStatus = await Permission.storage.request();
          if (!legacyStatus.isGranted) {
            _snack(
              'Permission denied',
              'Storage permission is required to read audio files.',
              err: true,
            );
            return false;
          }
          return true;
        }
      } else if (status.isPermanentlyDenied) {
        _snack(
          'Permission required',
          'Please enable storage access in app Settings.',
          err: true,
          settingsBtn: true,
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _pickDirectory() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (!await _requestAndroidPerm()) return;
    }
    try {
      String? dirPath = await FilePicker.platform.getDirectoryPath();
      if (dirPath == null) return;
      if (dirPath.startsWith('content://')) {
        _snack(
          'Android Limitation',
          'Android security prevents reading folders directly. '
              'Please use "Add Files" and select multiple files instead.',
          err: true,
        );
        return;
      }
      controller.isLoading.value = true;
      final entities = await Directory(dirPath).list(recursive: false).toList();
      const exts = ['.mp3', '.m4a', '.wav', '.flac', '.ogg', '.aac'];
      final files = entities
          .whereType<File>()
          .where((f) => exts.contains(p.extension(f.path).toLowerCase()))
          .toList();
      if (files.isEmpty) {
        _snack(
          'No Music Found',
          'No supported audio files were found in this folder.',
        );
      } else {
        files.sort(
          (a, b) => p
              .basename(a.path)
              .toLowerCase()
              .compareTo(p.basename(b.path).toLowerCase()),
        );
        controller.playlist.assignAll(files);
        _listAnim
          ..reset()
          ..forward();
        // Switch to local tab automatically
        if (_tab != 0) setState(() => _tab = 0);
      }
    } catch (e) {
      _snack(
        'Folder Error',
        'Could not read directory. This is often due to system security settings.',
        err: true,
      );
    } finally {
      controller.isLoading.value = false;
    }
  }

  Future<void> _pickFiles() async {
    if (!kIsWeb && Platform.isAndroid) {
      if (!await _requestAndroidPerm()) return;
    }
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'flac', 'ogg', 'aac'],
      );
      if (result == null || result.paths.isEmpty) return;
      final files = result.paths.whereType<String>().map(File.new).toList();
      controller.playlist.addAll(files);
      controller.playlist.sort(
        (a, b) => p.basename(a.path).compareTo(p.basename(b.path)),
      );
      _listAnim
        ..reset()
        ..forward();
      if (_tab != 0) setState(() => _tab = 0);
    } catch (e) {
      _snack('Error picking files', e.toString(), err: true);
    }
  }

  void _snack(
    String title,
    String msg, {
    bool err = false,
    bool settingsBtn = false,
  }) {
    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: err
          ? AppRawColors.red.withOpacity(0.88)
          : AppRawColors.darkSurfaceRaised,
      colorText: Colors.white,
      borderRadius: _FC.rMd,
      margin: const EdgeInsets.all(12),
      mainButton: settingsBtn
          ? TextButton(
              onPressed: openAppSettings,
              child: const Text(
                'Settings',
                style: TextStyle(color: AppRawColors.cyan),
              ),
            )
          : null,
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtSec(double sec) {
    final d = Duration(seconds: sec.toInt());
    return _fmt(d);
  }
}

// ══════════════════════════════════════════════════════════════
//  TAB BUTTON WIDGET
// ══════════════════════════════════════════════════════════════

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_FC.rSm),
          color: active ? color.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: active ? color.withOpacity(0.40) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: active ? color : color.withOpacity(0.35),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : color.withOpacity(0.38),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  RADIO ROW WIDGET
// ══════════════════════════════════════════════════════════════

class _RadioRow extends StatefulWidget {
  final int index;
  final RadioSong song;
  final AnimationController listAnim;
  final AnimationController shimmerAnim;
  final bool isCurrent;
  final bool showEffects;
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _RadioRow({
    super.key,
    required this.index,
    required this.song,
    required this.listAnim,
    required this.shimmerAnim,
    required this.isCurrent,
    required this.showEffects,
    required this.onTap,
    required this.onDownload,
  });

  @override
  State<_RadioRow> createState() => _RadioRowState();
}

class _RadioRowState extends State<_RadioRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(_RadioRow old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !old.isCurrent) {
      _bounce.forward().then((_) => _bounce.reverse());
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Staggered slide-in entrance (same formula as local rows)
    final delay = (widget.index * 0.04).clamp(0.0, 0.72);
    final end = (delay + 0.28).clamp(0.0, 1.0);
    final slide = CurvedAnimation(
      parent: widget.listAnim,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([slide, _bounce, widget.shimmerAnim]),
      builder: (ctx, _) {
        final sv = slide.value;
        final bv = _bounce.value;
        final shimmer = widget.isCurrent && widget.showEffects
            ? widget.shimmerAnim.value
            : 0.0;

        return Transform.translate(
          offset: Offset(28.0 * (1.0 - sv), 0),
          child: Opacity(
            opacity: sv.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: widget.isCurrent ? (1.0 + bv * 0.016) : 1.0,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_FC.rSm),
                      color: widget.isCurrent
                          ? _FC.radioAccent.withOpacity(0.08)
                          : _hovered
                          ? _FC.radioAccent.withOpacity(0.04)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isCurrent
                            ? _FC.radioAccent.withOpacity(0.28)
                            : _hovered
                            ? _FC.radioAccent.withOpacity(0.10)
                            : Colors.transparent,
                      ),
                      gradient: widget.showEffects && widget.isCurrent
                          ? LinearGradient(
                              begin: Alignment(shimmer * 2.2 - 1.0, 0),
                              end: Alignment(shimmer * 2.2 + 0.6, 0),
                              colors: [
                                Colors.transparent,
                                _FC.radioAccent.withOpacity(0.06),
                                Colors.transparent,
                              ],
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Cover art thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(_FC.rXs),
                          child: widget.song.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.song.imageUrl,
                                  width: 38,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _radioIndexBox(widget.index),
                                )
                              : _radioIndexBox(widget.index),
                        ),
                        const SizedBox(width: 10),
                        // Title + style + duration
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: _FC.font,
                                  fontSize: 12,
                                  fontWeight: widget.isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: widget.isCurrent
                                      ? Colors.white
                                      : AppRawColors.darkTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  _Tag(
                                    label: widget.song.winningStyle.length > 18
                                        ? '${widget.song.winningStyle.substring(0, 16)}…'
                                        : widget.song.winningStyle,
                                    color: _FC.radioAccent,
                                  ),
                                  const SizedBox(width: 5),
                                  _Tag(
                                    label: _fmtSec(widget.song.duration),
                                    color: AppRawColors.cyan,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Currently playing indicator
                        if (widget.isCurrent) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 13,
                            color: AppRawColors.neonGreen,
                          ),
                        ],
                        const SizedBox(width: 6),
                        // Download button
                        _DownloadBtn(onTap: widget.onDownload),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _radioIndexBox(int i) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(_FC.rXs),
      color: _FC.radioAccent.withOpacity(0.10),
      border: Border.all(color: _FC.radioAccent.withOpacity(0.24)),
    ),
    child: Text(
      '${i + 1}',
      style: TextStyle(
        fontFamily: _FC.font,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: _FC.radioAccent,
      ),
    ),
  );

  String _fmtSec(double sec) {
    final d = Duration(seconds: sec.toInt());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

// ── Small circular download button ────────────────────────────

class _DownloadBtn extends StatefulWidget {
  final VoidCallback onTap;

  const _DownloadBtn({required this.onTap});

  @override
  State<_DownloadBtn> createState() => _DownloadBtnState();
}

class _DownloadBtnState extends State<_DownloadBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<MusicPlayerController>();

    return Tooltip(
      message: 'Download',
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) {
          _press.reverse();
          widget.onTap();
        },
        onTapCancel: () => _press.reverse(),
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, __) => Transform.scale(
            scale: 1.0 - _press.value * 0.08,
            child: Obx(() {
              final downloading = ctrl.isDownloading.value;
              final progress = ctrl.downloadProgress.value;

              return Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppRawColors.neonGreen.withOpacity(
                    0.07 + _press.value * 0.06,
                  ),
                  border: Border.all(
                    color: AppRawColors.neonGreen.withOpacity(0.28),
                  ),
                ),
                child: downloading
                    ? Padding(
                        padding: const EdgeInsets.all(6),
                        child: CircularProgressIndicator(
                          value: progress > 0 ? progress : null,
                          strokeWidth: 2,
                          color: AppRawColors.neonGreen,
                        ),
                      )
                    : Icon(
                        Icons.download_rounded,
                        size: 15,
                        color: AppRawColors.neonGreen,
                      ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  LOCAL PLAYLIST ROW  (unchanged from v2.0)
// ══════════════════════════════════════════════════════════════

class _PlaylistRow extends StatefulWidget {
  final int index;
  final AnimationController listAnim;
  final AnimationController shimmerAnim;
  final String filename;
  final String extension;
  final bool isCurrent;
  final bool showEffects;
  final VoidCallback onTap;

  const _PlaylistRow({
    super.key,
    required this.index,
    required this.listAnim,
    required this.shimmerAnim,
    required this.filename,
    required this.extension,
    required this.isCurrent,
    required this.showEffects,
    required this.onTap,
  });

  @override
  State<_PlaylistRow> createState() => _PlaylistRowState();
}

class _PlaylistRowState extends State<_PlaylistRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounce;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
  }

  @override
  void didUpdateWidget(_PlaylistRow old) {
    super.didUpdateWidget(old);
    if (widget.isCurrent && !old.isCurrent) {
      _bounce.forward().then((_) => _bounce.reverse());
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final delay = (widget.index * 0.04).clamp(0.0, 0.72);
    final end = (delay + 0.28).clamp(0.0, 1.0);
    final slide = CurvedAnimation(
      parent: widget.listAnim,
      curve: Interval(delay, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([slide, _bounce, widget.shimmerAnim]),
      builder: (ctx, _) {
        final sv = slide.value;
        final bv = _bounce.value;
        final shimmer = widget.isCurrent && widget.showEffects
            ? widget.shimmerAnim.value
            : 0.0;

        return Transform.translate(
          offset: Offset(28.0 * (1.0 - sv), 0),
          child: Opacity(
            opacity: sv.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: widget.isCurrent ? (1.0 + bv * 0.016) : 1.0,
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_FC.rSm),
                      color: widget.isCurrent
                          ? AppRawColors.cyan.withOpacity(0.07)
                          : _hovered
                          ? AppRawColors.cyan.withOpacity(0.03)
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isCurrent
                            ? AppRawColors.cyan.withOpacity(0.24)
                            : _hovered
                            ? AppRawColors.cyan.withOpacity(0.09)
                            : Colors.transparent,
                      ),
                      boxShadow: widget.showEffects && widget.isCurrent
                          ? [
                              BoxShadow(
                                color: AppRawColors.cyan.withOpacity(
                                  0.04 + shimmer * 0.09,
                                ),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                      gradient: widget.showEffects && widget.isCurrent
                          ? LinearGradient(
                              begin: Alignment(shimmer * 2.2 - 1.0, 0),
                              end: Alignment(shimmer * 2.2 + 0.6, 0),
                              colors: [
                                Colors.transparent,
                                AppRawColors.cyan.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 26,
                          child: Text(
                            '${widget.index + 1}',
                            style: TextStyle(
                              fontFamily: _FC.font,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: widget.isCurrent
                                  ? AppRawColors.cyan
                                  : AppRawColors.darkTextSecondary.withOpacity(
                                      0.38,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 16,
                          child: widget.isCurrent
                              ? Icon(
                                  Icons.bar_chart_rounded,
                                  size: 13,
                                  color: AppRawColors.neonGreen,
                                )
                              : null,
                        ),
                        Expanded(
                          child: Text(
                            widget.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: _FC.font,
                              fontSize: 12,
                              fontWeight: widget.isCurrent
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: widget.isCurrent
                                  ? AppRawColors.darkTextPrimary
                                  : AppRawColors.darkTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(_FC.rXs),
                            color: AppRawColors.cyan.withOpacity(0.06),
                            border: Border.all(
                              color: AppRawColors.cyan.withOpacity(0.20),
                            ),
                          ),
                          child: Text(
                            widget.extension,
                            style: TextStyle(
                              fontFamily: _FC.font,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppRawColors.cyan.withOpacity(0.65),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  VU METER  (unchanged)
// ══════════════════════════════════════════════════════════════

class _VuMeter extends StatelessWidget {
  final double value;
  final String label;

  const _VuMeter({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      SizedBox(
        width: 7,
        height: 32,
        child: CustomPaint(painter: _VuPainter(value)),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: TextStyle(
          fontFamily: _FC.font,
          fontSize: 7,
          fontWeight: FontWeight.w700,
          color: AppRawColors.cyan.withOpacity(0.45),
        ),
      ),
    ],
  );
}

class _VuPainter extends CustomPainter {
  final double value;

  const _VuPainter(this.value);

  static const int _n = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final segH = (size.height - (_n - 1) * 2.0) / _n;
    final active = (value * _n).round();
    for (int i = 0; i < _n; i++) {
      final y = size.height - (i + 1) * segH - i * 2.0;
      final rr = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, size.width, segH),
        const Radius.circular(2),
      );
      Color c;
      if (i >= active)
        c = _FC.ledOff;
      else if (i >= _n - 2)
        c = _FC.ledPeak;
      else if (i >= _n - 4)
        c = _FC.ledMid;
      else
        c = _FC.ledLow;
      canvas.drawRRect(rr, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(_VuPainter old) => old.value != value;
}

// ══════════════════════════════════════════════════════════════
//  EQ BAR  (unchanged)
// ══════════════════════════════════════════════════════════════

class _EqBar extends StatelessWidget {
  final double value, peak;
  final Color color;

  const _EqBar({required this.value, required this.peak, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 6,
    height: 44,
    child: CustomPaint(painter: _EqPainter(value, peak, color)),
  );
}

class _EqPainter extends CustomPainter {
  final double value, peak;
  final Color color;

  const _EqPainter(this.value, this.peak, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final barH = size.height * value;
    if (barH > 1) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, size.height - barH, size.width, barH),
          const Radius.circular(3),
        ),
        Paint()
          ..shader =
              LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [color.withOpacity(0.85), color.withOpacity(0.35)],
              ).createShader(
                Rect.fromLTWH(0, size.height - barH, size.width, barH),
              ),
      );
    }
    if (peak > 0.03) {
      final py = size.height * (1.0 - peak) - 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, py, size.width, 3),
          const Radius.circular(1.5),
        ),
        Paint()..color = Colors.white.withOpacity(0.72),
      );
    }
  }

  @override
  bool shouldRepaint(_EqPainter old) =>
      old.value != value || old.peak != peak || old.color != color;
}

// ══════════════════════════════════════════════════════════════
//  TRANSPORT BUTTON  (unchanged)
// ══════════════════════════════════════════════════════════════

class _Btn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary, small;
  final Color? color;
  final String? tip;

  const _Btn({
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.small = false,
    this.color,
    this.tip,
  });

  @override
  State<_Btn> createState() => _BtnState();
}

class _BtnState extends State<_Btn> with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.color ?? AppRawColors.cyan;
    final sz = widget.isPrimary
        ? 52.0
        : widget.small
        ? 32.0
        : 40.0;
    final isz = widget.isPrimary
        ? 28.0
        : widget.small
        ? 16.0
        : 20.0;
    final r = widget.isPrimary ? _FC.rLg : _FC.rSm;

    return Tooltip(
      message: widget.tip ?? '',
      child: GestureDetector(
        onTapDown: (_) => _press.forward(),
        onTapUp: (_) {
          _press.reverse();
          widget.onTap();
        },
        onTapCancel: () => _press.reverse(),
        child: AnimatedBuilder(
          animation: _press,
          builder: (_, __) {
            final v = _press.value;
            return Transform.scale(
              scale: 1.0 - v * 0.07,
              child: Container(
                width: sz,
                height: sz,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  color: Color.lerp(
                    _FC.btnBg,
                    accent.withOpacity(0.18),
                    v + (widget.isPrimary ? 0.10 : 0),
                  ),
                  border: Border.all(
                    color: Color.lerp(
                      _FC.btnBorder,
                      accent.withOpacity(0.65),
                      0.28 + v * 0.5,
                    )!,
                    width: widget.isPrimary ? 1.5 : 1.0,
                  ),
                  boxShadow: (!_isAndroidTier && widget.isPrimary)
                      ? [
                          BoxShadow(
                            color: accent.withOpacity(0.18 + v * 0.18),
                            blurRadius: 14 + v * 6,
                          ),
                        ]
                      : null,
                ),
                child: Icon(widget.icon, size: isz, color: accent),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
//  SMALL REUSABLE WIDGETS  (all unchanged from v2.0)
// ══════════════════════════════════════════════════════════════

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(4),
      color: color.withOpacity(0.08),
      border: Border.all(color: color.withOpacity(0.24)),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: _FC.font,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color.withOpacity(0.82),
      ),
    ),
  );
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color? color;

  const _CountBadge(this.count, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppRawColors.cyan;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(_FC.rSm),
        border: Border.all(color: c.withOpacity(0.22)),
      ),
      child: Text(
        '$count tracks',
        style: TextStyle(
          fontFamily: _FC.font,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

class _TimeLabel extends StatelessWidget {
  final Duration duration;
  final bool negate;

  const _TimeLabel({required this.duration, this.negate = false});

  @override
  Widget build(BuildContext context) {
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text(
      '${negate ? "-" : ""}$m:$s',
      style: TextStyle(
        fontFamily: _FC.font,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppRawColors.neonGreen,
        letterSpacing: 1.5,
        shadows: _isDesktopTier
            ? const [Shadow(color: AppRawColors.neonGreen, blurRadius: 6)]
            : null,
      ),
    );
  }
}

class _Marquee extends StatefulWidget {
  final String text;

  const _Marquee({required this.text});

  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _anim = Tween<double>(
      begin: 0,
      end: -1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.linear));
  }

  @override
  void didUpdateWidget(_Marquee old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) {
      _ctrl.reset();
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => FractionalTranslation(
        translation: Offset(_anim.value, 0),
        child: Text(
          widget.text,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: TextStyle(
            fontFamily: _FC.font,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppRawColors.darkTextPrimary,
          ),
        ),
      ),
    ),
  );
}

class _ThinSlider extends StatelessWidget {
  final double value;
  final double? max;
  final double? min;
  final ValueChanged<double> onChanged;
  final Color color;
  final String label;

  const _ThinSlider({
    required this.value,
    required this.onChanged,
    required this.color,
    required this.label,
    this.max,
    this.min,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const SizedBox(width: 4),
      Text(
        label,
        style: TextStyle(
          fontFamily: _FC.font,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color.withOpacity(0.45),
          letterSpacing: 0.8,
        ),
      ),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            activeTrackColor: color,
            inactiveTrackColor: _FC.scrubBg,
            thumbColor: color,
            overlayColor: color.withOpacity(0.12),
          ),
          child: max != null && min != null
              ? Slider(value: value, max: max!, min: min!, onChanged: onChanged)
              : Slider(value: value, onChanged: onChanged),
        ),
      ),
    ],
  );
}

class _FBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  const _FBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppRawColors.cyan;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_FC.rSm),
          color: c.withOpacity(0.07),
          border: Border.all(color: c.withOpacity(0.23)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: c),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: _FC.font,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  CUSTOM SLIDER SHAPES  (unchanged)
// ─────────────────────────────────────────────────────────────

class _RoundTrack extends RoundedRectSliderTrackShape {
  const _RoundTrack();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = true,
    bool isDiscrete = false,
  }) {
    final h = sliderTheme.trackHeight ?? 3;
    final top = offset.dy + (parentBox.size.height - h) / 2;
    return Rect.fromLTWH(offset.dx + 8, top, parentBox.size.width - 16, h);
  }
}

class _GlowThumb extends SliderComponentShape {
  const _GlowThumb();

  @override
  Size getPreferredSize(bool e, bool d) => const Size(14, 14);

  @override
  void paint(
    PaintingContext ctx,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final c = ctx.canvas;
    if (_isDesktopTier) {
      c.drawCircle(
        center,
        9,
        Paint()
          ..color = AppRawColors.cyan.withOpacity(0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
    }
    c.drawCircle(center, 6, Paint()..color = AppRawColors.cyan);
    c.drawCircle(
      center - const Offset(1.5, 1.5),
      2,
      Paint()..color = Colors.white.withOpacity(0.48),
    );
  }
}
