// preview_section.dart
import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

/// A single, scroll‑safe row that previews the generated ambigram letters.
class PreviewSection extends StatefulWidget {
  final int imageCount;
  final Color backgroundColor;
  final String firstWord;
  final String secondWord;
  final int selectedChipIndex;
  final bool showImageBackground;

  const PreviewSection({
    Key? key,
    required this.imageCount,
    required this.backgroundColor,
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
    required this.showImageBackground,
  }) : super(key: key);

  @override
  State<PreviewSection> createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<PreviewSection> {
  // ───────────────────────── Remote‑Config defaults ─────────────────────────
  static const _defSvgBase = 'https://d2p3tez4zcgtm0.cloudfront.net/ambigram-';

  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;
  StreamSubscription<RemoteConfigUpdate>? _rcSub;
  String _svgBaseUrl = _defSvgBase;

  // ───────────────────────── connectivity & images ─────────────────────────
  bool _noInternet = false;
  Future<List<Uint8List?>>? _imagesFuture;
  StreamSubscription<List<ConnectivityResult>>? _connSub;

  // rotation
  double _rotationAngle = 0;

  // ───────────────────────── lifecycle ─────────────────────────
  @override
  void initState() {
    super.initState();
    _setupRemoteConfig();
    _maybeLoadImages();

    _connSub = Connectivity().onConnectivityChanged.listen((r) {
      if (r.contains(ConnectivityResult.none)) {
        setState(() {
          _noInternet = true;
          _imagesFuture = null;
        });
      } else {
        setState(() {
          _noInternet = false;
          _maybeLoadImages();
        });
      }
    });
  }

  Future<void> _setupRemoteConfig() async {
    await _rc.setDefaults({'svg_base_url': _defSvgBase});
    try {
      await _rc.setConfigSettings(
        RemoteConfigSettings(
          minimumFetchInterval: const Duration(hours: 1),
          fetchTimeout: const Duration(seconds: 10),
        ),
      );
      await _rc.fetchAndActivate();
    } catch (_) {
      /* ignore */
    }
    _applyRemoteValue(forceImageReload: true);

    _rcSub = _rc.onConfigUpdated.listen((_) async {
      await _rc.activate();
      _applyRemoteValue(forceImageReload: true);
    });
  }

  void _applyRemoteValue({bool forceImageReload = false}) {
    final oldBase = _svgBaseUrl;
    _svgBaseUrl =
        _rc.getString('svg_base_url').trim().isEmpty
            ? _defSvgBase
            : _rc.getString('svg_base_url');

    if (forceImageReload || _svgBaseUrl != oldBase) {
      _imagesFuture = null;
      _maybeLoadImages();
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant PreviewSection old) {
    super.didUpdateWidget(old);
    if (widget.imageCount != old.imageCount ||
        widget.firstWord != old.firstWord ||
        widget.secondWord != old.secondWord ||
        widget.selectedChipIndex != old.selectedChipIndex ||
        widget.showImageBackground != old.showImageBackground) {
      _imagesFuture = null;
      _maybeLoadImages();
    }
  }

  @override
  void dispose() {
    _connSub?.cancel();
    _rcSub?.cancel();
    super.dispose();
  }

  // ───────────────────────── image fetching ─────────────────────────
  Future<void> _maybeLoadImages() async {
    if (widget.imageCount == 0) return;
    final conn = await Connectivity().checkConnectivity();
    if (conn == ConnectivityResult.none) {
      setState(() => _noInternet = true);
      return;
    }
    setState(() {
      _noInternet = false;
      _imagesFuture = Future.wait(List.generate(widget.imageCount, _fetchSvg));
    });
  }

  Future<Uint8List?> _fetchSvg(int i) async {
    try {
      final f = widget.firstWord[i].toLowerCase();
      final s =
          widget.secondWord.isNotEmpty
              ? widget.secondWord[widget.secondWord.length - 1 - i]
                  .toLowerCase()
              : widget.firstWord[widget.firstWord.length - 1 - i].toLowerCase();
      final pair = f.compareTo(s) > 0 ? '$s$f' : '$f$s';
      final url = '$_svgBaseUrl${widget.selectedChipIndex}/$pair.svg';
      final res = await http.get(Uri.parse(url));
      return res.statusCode == 200 ? res.bodyBytes : null;
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── UI helpers ─────────────────────────
  void _rotate() {
    HapticFeedback.lightImpact();
    setState(() => _rotationAngle += pi);
  }

  // ───────────────────────── build ─────────────────────────
  @override
  Widget build(BuildContext context) {
    if (widget.imageCount == 0) {
      return _placeholder(
        widget.backgroundColor,
        'CLICK ON GENERATE TO PREVIEW',
      );
    }
    if (_noInternet) {
      return _placeholder(widget.backgroundColor, 'PLEASE CONNECT TO INTERNET');
    }

    return GestureDetector(
      onTap: _rotate,
      child: AnimatedRotation(
        turns: _rotationAngle / (2 * pi),
        duration: const Duration(milliseconds: 300),
        child: FutureBuilder<List<Uint8List?>>(
          future: _imagesFuture,
          builder: (ctx, snap) {
            if (_imagesFuture == null ||
                snap.connectionState == ConnectionState.waiting ||
                !snap.hasData) {
              return _placeholder(widget.backgroundColor, 'LOADING...');
            }

            final bytesList = snap.data!;
            return Container(
              width: double.infinity,
              height: 220,
              color: widget.backgroundColor,
              padding: const EdgeInsets.all(12),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(widget.imageCount, (i) {
                    final f = widget.firstWord[i].toLowerCase();
                    final s =
                        widget.secondWord.isNotEmpty
                            ? widget
                                .secondWord[widget.secondWord.length - 1 - i]
                                .toLowerCase()
                            : widget.firstWord[widget.firstWord.length - 1 - i]
                                .toLowerCase();
                    final bytes = bytesList[i];

                    if (bytes == null) {
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: Colors.red.shade100,
                        alignment: Alignment.center,
                        child: const Text(
                          'ERR',
                          style: TextStyle(fontSize: 14, color: Colors.red),
                        ),
                      );
                    }

                    final svg = SvgPicture.memory(
                      bytes,
                      height: 300,
                      fit: BoxFit.contain,
                    );
                    final flip = f.compareTo(s) > 0;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      padding: const EdgeInsets.all(4),
                      color:
                          widget.showImageBackground
                              ? Colors.amber.withOpacity(0.2)
                              : Colors.transparent,
                      child:
                          flip ? Transform.rotate(angle: pi, child: svg) : svg,
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _placeholder(Color bg, String txt) => Container(
    width: double.infinity,
    height: 220,
    color: bg,
    alignment: Alignment.center,
    child: Text(
      txt,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.2,
        color: Colors.black54,
      ),
    ),
  );
}
