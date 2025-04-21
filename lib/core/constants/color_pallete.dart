import 'dart:convert';
import 'package:flutter/material.dart';

/// A simple class that pairs a [Color] with its descriptive [name].
class NamedColor {
  final Color color;
  final String name;
  const NamedColor({required this.color, required this.name});

  /// Factory to build a `NamedColor` from the JSON object
  /// that comes from Remote Config:
  /// ```json
  /// {"name":"Off White","color":"#FAFAFA"}
  /// ```
  factory NamedColor.fromJson(Map<String, dynamic> j) {
    final hex = (j['color'] as String).replaceFirst('#', '');
    // Force‑add the alpha channel (FF = opaque) then parse
    return NamedColor(
      color: Color(int.parse('FF$hex', radix: 16)),
      name: j['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'color': '#${color.value.toRadixString(16).substring(2).toUpperCase()}',
  };
}

/// Handles *both* the baked‑in fallback colors and the
/// list fetched from Firebase Remote Config.
class ColorPalette {
  /// The list that ships in the app (used when Remote Config
  /// hasn’t delivered anything yet, or if parsing fails).
  static const List<NamedColor> _fallback = [
    NamedColor(color: Color(0xFFFAFAFA), name: "Off White"),
    NamedColor(color: Color(0xFFFFC0CB), name: "Pink"),
    NamedColor(color: Color(0xFFADD8E6), name: "Baby Blue"),
    NamedColor(color: Color(0xFFAAF0D1), name: "Mint Green"),
    NamedColor(color: Color(0xFFE6E6FA), name: "Lavender"),
    NamedColor(color: Color(0xFFFFDAB9), name: "Peach"),
    NamedColor(color: Color(0xFFFFFACD), name: "Lemon Chiffon"),
    NamedColor(color: Color(0xFFAFEEEE), name: "Turquoise"),
    NamedColor(color: Color(0xFFF08080), name: "Coral"),
    NamedColor(color: Color(0xFFFFE4E1), name: "Misty Rose"),
    //  …keep or remove as many fallback colours as you like
  ];

  /// Parse the JSON string coming from Remote Config and
  /// return a list of `NamedColor`.
  /// Falls back gracefully to `[_fallback]` if something
  /// goes wrong.
  static List<NamedColor> fromRemote(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded
          .map((e) => NamedColor.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return _fallback;
    }
  }

  /// Convenience getter so old calls still compile.
  static List<NamedColor> fallbackChoices() => _fallback;
}
