import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';

import 'components/header_section.dart';
import 'components/preview_section.dart';
import 'components/color_selection_section.dart';
import 'components/input_section.dart';

/// Basic example of an app that loads [HomeScreen].
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ambigram Creator',
      themeMode: ThemeMode.system,
      theme: ThemeData(brightness: Brightness.light),
      darkTheme: ThemeData(brightness: Brightness.dark),
      home: const HomeScreen(),
    );
  }
}

/// The main screen that hosts all the sections and orchestrates the logic.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // ---------------------------------------------------------------------------
  // 1) THE CHIP LABELS & SELECTED CHIP INDEX ARE NOW STORED HERE
  // ---------------------------------------------------------------------------
  final List<String> _chipLabels = [
    'ANTIOGLYPH',
    'ESCHERESQUE',
    'AMBORATTIC',
    'SPECULON',
    'AETHERGLYPH',
    'GYROGLYPH',
    'ENANTIGRAM',
  ];
  int _selectedChipIndex = 0;

  /// This will determine how many images get displayed in the PreviewSection.
  int _imageCount = 0;

  /// Track whether the user has already generated an ambigram
  /// (used to switch button label to "DOWNLOAD AMBIGRAM").
  bool _hasGenerated = false;

  /// Store and retrieve credits with SharedPreferences
  int _credits = 25;

  /// Keep track of the user-selected background color for the preview.
  int _selectedColorIndex = 0;
  late List<NamedColor> _colors;

  /// We'll store the words that the user generated so we can build the correct SVG URLs.
  String _generatedFirstWord = '';
  String _generatedSecondWord = '';

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize color choices only once.
    if (!mounted) return;
    _colors = ColorPalette.backgroundChoices(context);
  }

  /// Load credits from SharedPreferences or set to 25 by default.
  Future<void> _loadCredits() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCredits = prefs.getInt('credit_count') ?? 25;
    setState(() {
      _credits = storedCredits;
    });
  }

  /// Save the updated credits to SharedPreferences.
  Future<void> _saveCredits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('credit_count', _credits);
  }

  /// Callback fired from the InputSection's button **after** validations pass.
  void _handleGenerate(String firstWord, String secondWord) async {
    if (_credits > 0) {
      setState(() {
        _generatedFirstWord = firstWord;
        _generatedSecondWord = secondWord;
        _imageCount = firstWord.length;
        _hasGenerated = true;
        _credits -= 1; // Decrement credit
      });
      await _saveCredits();
    } else {
      // Show bottom sheet if user has 0 credits
      _showCreditLimitModal();
    }
  }

  /// When user has 0 credits, display the "CREDIT LIMIT REACHED" bottom sheet.
  void _showCreditLimitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext context) {
        final deviceWidth = MediaQuery.of(context).size.width;

        return SingleChildScrollView(
          child: Container(
            width: deviceWidth,
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Section
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/images/flash_icon.svg',
                        width: 40,
                        height: 40,
                        semanticsLabel: 'Icon',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'CREDIT LIMIT REACHED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Averta Demo PE Cutted Demo',
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text: 'WATCH A SHORT AD TO GET ',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFF959399),
                              ),
                            ),
                            const TextSpan(
                              text: '5',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFFBF9B47),
                              ),
                            ),
                            const TextSpan(
                              text: ' MORE CREDITS INSTANTLY',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Averta Demo PE Cutted Demo',
                                fontWeight: FontWeight.w400,
                                letterSpacing: 1,
                                color: Color(0xFF959399),
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons Section
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      AmbigramButton(
                        text: "WATCH AD (+5)",
                        onPressed: () async {
                          HapticFeedback.mediumImpact();
                          // For demonstration, just add 5 credits instantly
                          setState(() {
                            _credits += 5;
                          });
                          await _saveCredits();
                          Navigator.of(context).pop(); // Close bottom sheet
                        },
                      ),
                      const SizedBox(height: 12),
                      AmbigramButton(
                        text: "BUY UNLIMITED CREDITS",
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          // Implement your in-app purchase flow here
                          setState(() {
                            _credits = 999;
                          });
                          _saveCredits();
                          Navigator.of(context).pop(); // Close bottom sheet
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Color selection callback from the ColorSelectionSection.
  void _onColorSelected(int index) {
    setState(() {
      _selectedColorIndex = index;
    });
  }

  /// Chip selection callback for the HeaderSection.
  void _onChipSelected(int index) async {
    if (_credits > 0) {
      setState(() {
        _credits--;
        _selectedChipIndex = index;
      });
      await _saveCredits();
    } else {
      _showCreditLimitModal();
      // If you don't want to allow chip switching at 0 credits, comment out:
      setState(() {
        _selectedChipIndex = index;
      });
    }
  }

  /// Called once the user wants to "DOWNLOAD AMBIGRAM" (i.e. second press).
  /// Here we do a simple Navigator push. If you’re using go_router or named
  /// routes, replace this accordingly.
  void _handleDownloadTap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PreviewScreen(
              firstWord: _generatedFirstWord,
              secondWord: _generatedSecondWord,
              selectedChipIndex: _selectedChipIndex,
              selectedColorIndex: _selectedColorIndex,
            ),
      ),
    );
  }

  /// When user modifies text after a successful "GENERATE," revert to "GENERATE" button
  void _handleInputChanged() {
    if (_hasGenerated) {
      setState(() {
        _hasGenerated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely handle out-of-range index for the background color
    final backgroundColor =
        (_selectedColorIndex >= 0 && _selectedColorIndex < _colors.length)
            ? _colors[_selectedColorIndex].color
            : AppColors.previewBackground(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: double.infinity),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  HeaderSection(
                    credits: _credits,
                    chipLabels: _chipLabels,
                    selectedChipIndex: _selectedChipIndex,
                    onChipSelected: _onChipSelected,
                  ),
                  const SizedBox(height: 24),
                  PreviewSection(
                    imageCount: _imageCount,
                    backgroundColor: backgroundColor,
                    firstWord: _generatedFirstWord,
                    secondWord: _generatedSecondWord,
                    selectedChipIndex: _selectedChipIndex,
                  ),
                  const SizedBox(height: 16),
                  ColorSelectionSection(
                    selectedColorIndex: _selectedColorIndex,
                    onColorSelected: _onColorSelected,
                  ),
                  const SizedBox(height: 16),
                  InputSection(
                    onGenerate: _handleGenerate,
                    hasGenerated: _hasGenerated,
                    onDownload: _handleDownloadTap,
                    onInputChanged: _handleInputChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
