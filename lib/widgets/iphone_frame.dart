import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Mouse and trackpad drag-scroll like a finger, with iOS bounce
/// and no desktop scrollbar.
class PhoneScrollBehavior extends MaterialScrollBehavior {
  const PhoneScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics();

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}

/// Draws an iPhone 17 (402 x 874) around the app.
/// Click the home bar to leave the app, click the Todos icon to open it again.
class IPhoneFrame extends StatefulWidget {
  final Widget child;
  const IPhoneFrame({super.key, required this.child});

  static const double screenW = 402;
  static const double screenH = 874;
  static const double statusBarH = 54;
  static const double homeBarH = 34;

  @override
  State<IPhoneFrame> createState() => _IPhoneFrameState();
}

class _IPhoneFrameState extends State<IPhoneFrame> {
  bool _appOpen = true;

  void _goHome() {
    if (_appOpen) setState(() => _appOpen = false);
  }

  void _openApp() => setState(() => _appOpen = true);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final barColor = _appOpen ? Colors.black : Colors.white;

    return Material(
      color: const Color(0xFF111111),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _PhoneBody(
                    child: Stack(
                      children: [
                        // Home screen (always there, under the app)
                        Positioned.fill(
                          child: _HomeScreen(onOpenTodos: _openApp),
                        ),
                        // The real app: zooms in and out, keeps its state
                        Positioned.fill(
                          child: IgnorePointer(
                            ignoring: !_appOpen,
                            child: AnimatedScale(
                              scale: _appOpen ? 1 : 0.8,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              child: AnimatedOpacity(
                                opacity: _appOpen ? 1 : 0,
                                duration: const Duration(milliseconds: 250),
                                child: MediaQuery(
                                  data: mq.copyWith(
                                    size: const Size(
                                      IPhoneFrame.screenW,
                                      IPhoneFrame.screenH,
                                    ),
                                    padding: const EdgeInsets.only(
                                      top: IPhoneFrame.statusBarH,
                                      bottom: IPhoneFrame.homeBarH,
                                    ),
                                  ),
                                  child: widget.child,
                                ),
                              ),
                            ),
                          ),
                        ),
                        _StatusBar(color: barColor),
                        const _DynamicIsland(),
                        _HomeIndicator(color: barColor, onHome: _goHome),
                      ],
                    ),
                  ),
                ),
                // Side buttons
                const _SideButton(left: true, top: 150, height: 34),
                const _SideButton(left: true, top: 215, height: 62),
                const _SideButton(left: true, top: 290, height: 62),
                const _SideButton(left: false, top: 240, height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Titanium edge, black bezel and the screen with rounded corners.
class _PhoneBody extends StatelessWidget {
  final Widget child;
  const _PhoneBody({required this.child});

  static const double _screenRadius = 57;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(69),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9A9AA0), Color(0xFF3A3A3C), Color(0xFF9A9AA0)],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(66),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_screenRadius),
          child: SizedBox(
            width: IPhoneFrame.screenW,
            height: IPhoneFrame.screenH,
            child: Stack(
              children: [
                Positioned.fill(child: child),
                // Black corner mask on top: guarantees round screen corners
                const Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _CornerMaskPainter(_screenRadius),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints black everywhere outside a rounded rectangle.
class _CornerMaskPainter extends CustomPainter {
  final double radius;
  const _CornerMaskPainter(this.radius);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = Path()..addRect(rect);
    final inner = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, outer, inner),
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant _CornerMaskPainter oldDelegate) =>
      oldDelegate.radius != radius;
}

// ---------------------------------------------------------------- home screen

/// Two swipeable home screen pages with a fixed search pill and dock.
class _HomeScreen extends StatefulWidget {
  final VoidCallback onOpenTodos;
  const _HomeScreen({required this.onOpenTodos});

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen>
    with TickerProviderStateMixin {
  static const int _songSeconds = 222;

  final _controller = PageController();
  late final AnimationController _song;
  late final AnimationController _eq;
  int _page = 0;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    // Simulated playback: progress and equalizer keep running while the
    // home screen is shown, even on the other page.
    _song = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _songSeconds),
    )..repeat();
    _eq = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _song.dispose();
    _eq.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    if (_playing) {
      _song.repeat();
      _eq.repeat();
    } else {
      _song.stop();
      _eq.stop();
    }
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  /// Current scroll position as a number (0.0 to 1.0), used for parallax.
  double get _offset => _controller.hasClients
      ? (_controller.page ?? _page.toDouble())
      : _page.toDouble();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    final dayName = days[now.weekday - 1];
    final shortName = dayName.substring(0, 3);

    final page1Apps = <Widget>[
      _AppIcon(
        label: 'Todos',
        onTap: widget.onOpenTodos,
        face: const _IconFace(
          top: Color(0xFFA78BFA),
          bottom: Color(0xFF6D3FD6),
          child: Icon(Icons.checklist_rounded, color: Colors.white, size: 34),
        ),
      ),
      const _AppIcon(
        label: 'Photos',
        face: _IconFace(
          top: Colors.white,
          bottom: Color(0xFFF2F2F7),
          child: Icon(Icons.filter_vintage, color: Color(0xFFFF9500), size: 36),
        ),
      ),
      const _AppIcon(
        label: 'Camera',
        face: _IconFace(
          top: Color(0xFF9A9AA0),
          bottom: Color(0xFF55555A),
          child: Icon(Icons.photo_camera, color: Colors.white, size: 32),
        ),
      ),
      const _AppIcon(
        label: 'Maps',
        face: _IconFace(
          top: Color(0xFF6FD66F),
          bottom: Color(0xFF2FA84F),
          child: Icon(Icons.map, color: Colors.white, size: 32),
        ),
      ),
      const _AppIcon(
        label: 'Clock',
        face: _IconFace(
          top: Color(0xFF3A3A3C),
          bottom: Colors.black,
          child: Icon(Icons.access_time_filled, color: Colors.white, size: 34),
        ),
      ),
      const _AppIcon(
        label: 'Notes',
        face: _IconFace(
          top: Color(0xFFFFE066),
          bottom: Color(0xFFFFB800),
          child: Icon(Icons.sticky_note_2, color: Colors.white, size: 32),
        ),
      ),
      const _AppIcon(
        label: 'Wallet',
        face: _IconFace(
          top: Color(0xFF3A3A3C),
          bottom: Colors.black,
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
      const _AppIcon(
        label: 'App Store',
        face: _IconFace(
          top: Color(0xFF4FC3FF),
          bottom: Color(0xFF0A6CFF),
          child: Icon(Icons.apps, color: Colors.white, size: 34),
        ),
      ),
      const _AppIcon(
        label: 'Health',
        face: _IconFace(
          top: Colors.white,
          bottom: Color(0xFFF2F2F7),
          child: Icon(Icons.favorite, color: Color(0xFFFF2D55), size: 34),
        ),
      ),
      const _AppIcon(
        label: 'Settings',
        face: _IconFace(
          top: Color(0xFFAEAEB2),
          bottom: Color(0xFF636366),
          child: Icon(Icons.settings, color: Colors.white, size: 34),
        ),
      ),
      const _AppIcon(
        label: 'Mail',
        face: _IconFace(
          top: Color(0xFF4FC3FF),
          bottom: Color(0xFF0A6CFF),
          child: Icon(Icons.mail, color: Colors.white, size: 32),
        ),
      ),
      _AppIcon(
        label: 'Calendar',
        face: _IconFace(
          top: Colors.white,
          bottom: const Color(0xFFF2F2F7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                shortName,
                style: const TextStyle(
                  color: Color(0xFFFF3B30),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  decoration: TextDecoration.none,
                ),
              ),
              Text(
                '${now.day}',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 30,
                  fontWeight: FontWeight.w300,
                  height: 1.0,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    ];

    const page2Apps = <Widget>[
      _AppIcon(
        label: 'Music',
        face: _IconFace(
          top: Color(0xFFFF6B81),
          bottom: Color(0xFFFF2D55),
          child: Icon(Icons.music_note, color: Colors.white, size: 34),
        ),
      ),
      _AppIcon(
        label: 'Podcasts',
        face: _IconFace(
          top: Color(0xFFC77DFF),
          bottom: Color(0xFF7B2FF7),
          child: Icon(Icons.podcasts, color: Colors.white, size: 34),
        ),
      ),
      _AppIcon(
        label: 'Books',
        face: _IconFace(
          top: Color(0xFFFFB347),
          bottom: Color(0xFFFF8C00),
          child: Icon(Icons.menu_book, color: Colors.white, size: 32),
        ),
      ),
      _AppIcon(
        label: 'Files',
        face: _IconFace(
          top: Color(0xFF4FC3FF),
          bottom: Color(0xFF0A6CFF),
          child: Icon(Icons.folder, color: Colors.white, size: 34),
        ),
      ),
      _AppIcon(
        label: 'Stocks',
        face: _IconFace(
          top: Color(0xFF3A3A3C),
          bottom: Colors.black,
          child: Icon(Icons.show_chart, color: Color(0xFF30D158), size: 36),
        ),
      ),
      _AppIcon(
        label: 'Reminders',
        face: _IconFace(
          top: Colors.white,
          bottom: Color(0xFFF2F2F7),
          child: Icon(
            Icons.format_list_bulleted,
            color: Color(0xFFFF9500),
            size: 34,
          ),
        ),
      ),
      _AppIcon(
        label: 'Calculator',
        face: _IconFace(
          top: Color(0xFFFFB347),
          bottom: Color(0xFFFF8C00),
          child: Icon(Icons.calculate, color: Colors.white, size: 34),
        ),
      ),
      _AppIcon(
        label: 'Voice Memos',
        face: _IconFace(
          top: Color(0xFF3A3A3C),
          bottom: Colors.black,
          child: Icon(Icons.mic, color: Color(0xFFFF3B30), size: 34),
        ),
      ),
    ];

    return Stack(
      children: [
        // Wallpaper
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF3A1C71),
                  Color(0xFFD76D77),
                  Color(0xFFFFAF7B),
                ],
                stops: [0, 0.45, 0.8, 1],
              ),
            ),
          ),
        ),
        // Glows move a little while you swipe (parallax)
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final o = _offset;
              return Stack(
                children: [
                  Positioned(
                    top: -90,
                    left: -70 - o * 70,
                    child: const _Glow(
                      inner: Color(0x663A7BD5),
                      outer: Color(0x003A7BD5),
                      size: 340,
                    ),
                  ),
                  Positioned(
                    bottom: 100,
                    right: -100 + o * 90,
                    child: const _Glow(
                      inner: Color(0x55FF6A88),
                      outer: Color(0x00FF6A88),
                      size: 320,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 66, bottom: 26),
          child: Column(
            children: [
              // The swipeable pages
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (p) => setState(() => _page = p),
                  children: [
                    // Page 1: calendar + weather widgets and 12 apps
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 158,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _CalendarWidget(
                                    dayName: dayName,
                                    day: now.day,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Expanded(child: _WeatherWidget()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 26),
                          _appGrid(page1Apps),
                        ],
                      ),
                    ),
                    // Page 2: now playing widget and 8 apps
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          _NowPlayingWidget(
                            song: _song,
                            eq: _eq,
                            playing: _playing,
                            totalSeconds: _songSeconds,
                            onToggle: _togglePlay,
                          ),
                          const SizedBox(height: 26),
                          _appGrid(page2Apps),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Page dots (click one to jump to that page)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Dot(active: _page == 0, onTap: () => _goTo(0)),
                  _Dot(active: _page == 1, onTap: () => _goTo(1)),
                ],
              ),
              const SizedBox(height: 9),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Search pill
                    Container(
                      width: 150,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0x40FFFFFF),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, color: Colors.white70, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Search',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Frosted dock
                    ClipRRect(
                      borderRadius: BorderRadius.circular(38),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: const Color(0x40FFFFFF),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _IconFace(
                                top: Color(0xFF6FD66F),
                                bottom: Color(0xFF2FA84F),
                                child: Icon(
                                  Icons.call,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              _IconFace(
                                top: Colors.white,
                                bottom: Color(0xFFF2F2F7),
                                child: Icon(
                                  Icons.explore,
                                  color: Color(0xFF0A84FF),
                                  size: 38,
                                ),
                              ),
                              _IconFace(
                                top: Color(0xFF6FD66F),
                                bottom: Color(0xFF2FA84F),
                                child: Icon(
                                  Icons.chat_bubble,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              _IconFace(
                                top: Color(0xFFFF6B81),
                                bottom: Color(0xFFFF2D55),
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.white,
                                  size: 34,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rows of four icons.
Widget _appGrid(List<Widget> apps) {
  return Column(
    children: [
      for (var r = 0; r < apps.length; r += 4) ...[
        if (r > 0) const SizedBox(height: 22),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: apps.sublist(r, r + 4 > apps.length ? apps.length : r + 4),
        ),
      ],
    ],
  );
}

class _Glow extends StatelessWidget {
  final Color inner;
  final Color outer;
  final double size;
  const _Glow({required this.inner, required this.outer, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [inner, outer]),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _Dot({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarWidget extends StatelessWidget {
  final String dayName;
  final int day;
  const _CalendarWidget({required this.dayName, required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xF2FFFFFF),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(52),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            '$day',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 54,
              fontWeight: FontWeight.w300,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          const Text(
            'No events today',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherWidget extends StatelessWidget {
  const _WeatherWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5AA9F0), Color(0xFF2B5BA8)],
        ),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(52),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weather',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              Icon(Icons.wb_sunny, color: Color(0xFFFFD60A), size: 24),
            ],
          ),
          SizedBox(height: 6),
          Text(
            '10°',
            style: TextStyle(
              color: Colors.white,
              fontSize: 50,
              fontWeight: FontWeight.w300,
              height: 1.0,
              decoration: TextDecoration.none,
            ),
          ),
          Spacer(),
          Text(
            'Partly Cloudy',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            'H:12°  L:5°',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

/// Wide "now playing" widget on page 2. Playback is simulated: the progress
/// bar, timer and equalizer move, but no audio plays.
class _NowPlayingWidget extends StatelessWidget {
  final Animation<double> song;
  final Animation<double> eq;
  final bool playing;
  final int totalSeconds;
  final VoidCallback onToggle;

  const _NowPlayingWidget({
    required this.song,
    required this.eq,
    required this.playing,
    required this.totalSeconds,
    required this.onToggle,
  });

  String _fmt(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      color: Colors.white70,
      fontSize: 11,
      decoration: TextDecoration.none,
    );

    return Container(
      width: double.infinity,
      height: 170,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B1055), Color(0xFFD53369)],
        ),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(52),
        ),
      ),
      child: Row(
        children: [
          // Album art
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFAF7B), Color(0xFFD76D77)],
              ),
              shape: ContinuousRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
            ),
            child: const Text(
              'ح',
              style: TextStyle(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w300,
                height: 1.0,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Text(
                      playing ? 'NOW PLAYING' : 'PAUSED',
                      style: label.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 8),
                    _Equalizer(animation: eq, playing: playing),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'حرام عليك',
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: song,
                  builder: (context, _) {
                    final elapsed = (song.value * totalSeconds).floor();
                    return Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: song.value,
                            minHeight: 4,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(elapsed), style: label),
                            Text(
                              '-${_fmt(totalSeconds - elapsed)}',
                              style: label,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(Icons.skip_previous,
                        color: Colors.white, size: 28),
                    GestureDetector(
                      onTap: onToggle,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_fill,
                          color: Colors.white,
                          size: 38,
                        ),
                      ),
                    ),
                    const Icon(Icons.skip_next, color: Colors.white, size: 28),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Four small bars that bounce while the song plays.
class _Equalizer extends StatelessWidget {
  final Animation<double> animation;
  final bool playing;
  const _Equalizer({required this.animation, required this.playing});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 4; i++)
                Container(
                  width: 3,
                  height: playing
                      ? 4 +
                      10 *
                          (0.5 +
                              0.5 *
                                  math.sin(2 *
                                      math.pi *
                                      animation.value *
                                      (i + 1) +
                                      i * 1.7))
                      : 4,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// iOS-style rounded icon tile with a soft gradient.
class _IconFace extends StatelessWidget {
  final Color top;
  final Color bottom;
  final Widget child;
  final double size;

  const _IconFace({
    required this.top,
    required this.bottom,
    required this.child,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [top, bottom],
        ),
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.42),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Icon + label. Shrinks a little while pressed, like iOS.
class _AppIcon extends StatefulWidget {
  final String label;
  final Widget face;
  final VoidCallback? onTap;

  const _AppIcon({required this.label, required this.face, this.onTap});

  @override
  State<_AppIcon> createState() => _AppIconState();
}

class _AppIconState extends State<_AppIcon> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor:
      widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.9 : 1,
          duration: const Duration(milliseconds: 100),
          child: SizedBox(
            width: 70,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                widget.face,
                const SizedBox(height: 5),
                Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.5,
                    decoration: TextDecoration.none,
                    shadows: [Shadow(color: Color(0x66000000), blurRadius: 3)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ phone hardware

class _StatusBar extends StatelessWidget {
  final Color color;
  const _StatusBar({required this.color});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: IPhoneFrame.statusBarH,
      child: IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 8, 30, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '9:41',
                style: TextStyle(
                  color: color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.signal_cellular_alt, size: 18, color: color),
                  const SizedBox(width: 5),
                  Icon(Icons.wifi, size: 18, color: color),
                  const SizedBox(width: 5),
                  // Charging battery (green with a bolt)
                  const Icon(
                    Icons.battery_charging_full,
                    size: 24,
                    color: Color(0xFF30D158),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DynamicIsland extends StatelessWidget {
  const _DynamicIsland();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 11,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Center(
          child: Container(
            width: 124,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0B1A2E), // camera lens
                    border: Border.all(
                      color: const Color(0xFF1C2F4A),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bar at the bottom: click it, or drag it up, to leave the app.
class _HomeIndicator extends StatelessWidget {
  final Color color;
  final VoidCallback onHome;
  const _HomeIndicator({required this.color, required this.onHome});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: IPhoneFrame.homeBarH,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onHome,
          onVerticalDragEnd: (d) {
            if ((d.primaryVelocity ?? 0) < -150) onHome();
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                width: 140,
                height: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final bool left;
  final double top;
  final double height;
  const _SideButton({
    required this.left,
    required this.top,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left ? 0 : null,
      right: left ? null : 0,
      top: top,
      child: Container(
        width: 4,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF4A4A4C),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}