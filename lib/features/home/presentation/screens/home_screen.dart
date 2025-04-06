import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/constants/app_colors.dart';
import 'package:flutter_application_1/core/constants/color_pallete.dart';
import 'package:flutter_application_1/features/preview/presentation/screens/preview_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/shared/widgets/custom_button.dart';
import 'package:flutter_application_1/shared/widgets/text_input.dart';
import 'package:flutter_application_1/features/notifications/notifications.dart';
import 'dart:math';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize timezone data
  tz.initializeTimeZones();
  // 2. Optional: set local location
  tz.setLocalLocation(tz.getLocation('America/Detroit'));
  // or simply tz.setLocalLocation(tz.local);

  // 3. Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();

  debugPrint('NotificationService initialized');

  // (Optional) Request iOS permissions
  if (Platform.isIOS) {
    await notificationService.requestIOSPermissions();
  }
  // (Optional) Request Android 13+ notifications permission
  // This will prompt the user on Android 13+ only
  await notificationService.requestAndroidPermissions();

  runApp(const MyApp());
}

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
                    onInputChanged: _handleInputChanged, // NEW CALLBACK
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

// -----------------------------------------------------------------------------
// HEADER SECTION
// -----------------------------------------------------------------------------
class HeaderSection extends StatefulWidget {
  final int credits;

  /// Expose these so we can manage them from _HomeScreenState
  final List<String> chipLabels;
  final int selectedChipIndex;
  final ValueChanged<int> onChipSelected;

  const HeaderSection({
    super.key,
    required this.credits,
    required this.chipLabels,
    required this.selectedChipIndex,
    required this.onChipSelected,
  });

  @override
  State<HeaderSection> createState() => _HeaderSectionState();
}

class _HeaderSectionState extends State<HeaderSection> {
  final List<GlobalKey> _chipKeys = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // create a key for each label
    _chipKeys.addAll(widget.chipLabels.map((_) => GlobalKey()).toList());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onChipTap(int index) {
    // Scroll the tapped chip into view
    final ctx = _chipKeys[index].currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.5,
      );
    }

    // Notify parent
    widget.onChipSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final credits = widget.credits;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // space between two children
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title area
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CREATE YOUR OWN ',
                  style: TextStyle(
                    color: AppColors.textSecondary(context),
                    fontSize: 12,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AMBIGRAM',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 20,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
            // Credits area
            Row(
              children: [
                SvgPicture.asset(
                  'assets/images/flash_icon.svg',
                  width: 14,
                  height: 14,
                  semanticsLabel: 'Icon',
                ),
                const SizedBox(width: 4),
                Text(
                  '$credits',
                  style: TextStyle(
                    color: AppColors.textPrimary(context),
                    fontSize: 12,
                    fontFamily: 'Averta Demo PE Cutted Demo',
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // <-- Make horizontal overflow visible
          child: Row(
            children: List.generate(widget.chipLabels.length, (index) {
              final label = widget.chipLabels[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AnimatedSelectableChip(
                  key: _chipKeys[index],
                  label: label,
                  delay: Duration(milliseconds: 100 * index),
                  isSelected: widget.selectedChipIndex == index,
                  onTap: () => _onChipTap(index),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// ANIMATED SELECTABLE CHIP
// -----------------------------------------------------------------------------
class AnimatedSelectableChip extends StatefulWidget {
  final String label;
  final Duration delay;
  final bool isSelected;
  final VoidCallback onTap;

  const AnimatedSelectableChip({
    super.key,
    required this.label,
    required this.delay,
    required this.isSelected,
    required this.onTap,
  });

  @override
  _AnimatedSelectableChipState createState() => _AnimatedSelectableChipState();
}

class _AnimatedSelectableChipState extends State<AnimatedSelectableChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeInController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  late final Animation<double> _fadeInAnimation = CurvedAnimation(
    parent: _fadeInController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _fadeInController.forward();
    });
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bgColor =
        widget.isSelected
            ? AppColors.chipSelectedBg(context)
            : AppColors.chipUnselectedBg(context);
    final border =
        widget.isSelected
            ? null
            : Border.all(color: AppColors.borderColor(context), width: 0.5);
    final textColor = AppColors.chipText(context, widget.isSelected);

    return FadeTransition(
      opacity: _fadeInAnimation,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            border: border,
            boxShadow:
                widget.isSelected
                    ? const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 16,
                        offset: Offset(0, 10),
                      ),
                    ]
                    : null,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontFamily: 'Averta Demo PE Cutted Demo',
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// PREVIEW SECTION
// -----------------------------------------------------------------------------
class PreviewSection extends StatefulWidget {
  /// Number of images to show horizontally.
  final int imageCount;

  /// The color that should be used for the preview background.
  final Color backgroundColor;

  /// The words used to build the final SVG URLs.
  final String firstWord;
  final String secondWord;

  /// The index of the currently selected chip (used in the URL).
  final int selectedChipIndex;

  const PreviewSection({
    super.key,
    required this.imageCount,
    required this.backgroundColor,
    required this.firstWord,
    required this.secondWord,
    required this.selectedChipIndex,
  });

  @override
  _PreviewSectionState createState() => _PreviewSectionState();
}

class _PreviewSectionState extends State<PreviewSection> {
  bool _toastShown = false; // Tracks if the toast has been shown
  bool _isLoading = false; // Tracks if we are in the "LOADING..." phase
  double _rotationAngle = 0.0; // Tracks the current rotation angle in radians

  @override
  void didUpdateWidget(covariant PreviewSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If previously there were zero images, and now there's some positive number,
    // trigger the loading phase for 2 seconds.
    if (oldWidget.imageCount == 0 && widget.imageCount > 0) {
      setState(() {
        _isLoading = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }

    // 2) If the user changes the selectedChipIndex, also show loading for 2 seconds.
    if (oldWidget.selectedChipIndex != widget.selectedChipIndex) {
      setState(() {
        _isLoading = true;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  // Called when the preview section is tapped.
  void _rotatePreview() {
    // create a haptic feedback
    HapticFeedback.lightImpact();
    setState(() {
      _rotationAngle += pi; // Increase rotation by 180 degrees (pi radians)
    });
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the whole container in a GestureDetector
    return GestureDetector(
      onTap: _rotatePreview,
      child: AnimatedRotation(
        turns: _rotationAngle / (2 * pi), // Convert radians to "turns"
        duration: const Duration(milliseconds: 300),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    // If still zero images, just show "CLICK ON GENERATE TO PREVIEW"
    if (widget.imageCount == 0) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "CLICK ON GENERATE TO PREVIEW",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      );
    }

    // If in loading phase, show "LOADING..."
    if (_isLoading) {
      return Container(
        width: double.infinity,
        height: 220,
        color: widget.backgroundColor,
        alignment: Alignment.center,
        child: const Text(
          "LOADING...",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        ),
      );
    }

    // Otherwise, show the generated images with scrolling + toast logic
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(color: widget.backgroundColor),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 60,
            child: NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (!_toastShown && scrollInfo is ScrollStartNotification) {
                  Fluttertoast.showToast(
                    msg: "YOU CAN SCROLL THROUGH THE IMAGES",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                  );
                  _toastShown = true;
                }
                return false;
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none, // <-- Make horizontal overflow visible
                child: Row(
                  children: List.generate(widget.imageCount, (index) {
                    // Compute letters
                    final firstLetter = widget.firstWord[index].toLowerCase();
                    final secondLetter =
                        widget.secondWord.isNotEmpty
                            ? widget
                                .secondWord[widget.secondWord.length -
                                    1 -
                                    index]
                                .toLowerCase()
                            : widget
                                .firstWord[widget.firstWord.length - 1 - index]
                                .toLowerCase();

                    // Determine if the letters should be flipped
                    final isFlipped = firstLetter.compareTo(secondLetter) > 0;

                    // Build the letter pair
                    final letterPair =
                        isFlipped
                            ? "$secondLetter$firstLetter"
                            : "$firstLetter$secondLetter";

                    // Build the final URL
                    final svgUrl =
                        "https://d2p3tez4zcgtm0.cloudfront.net/ambigram-${widget.selectedChipIndex}/$letterPair.svg";

                    // Create the SVG widget
                    final svgWidget = SvgPicture.network(
                      svgUrl,
                      height: 60,
                      fit: BoxFit.fitHeight,
                    );

                    // Wrap with Transform.rotate if flipped
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child:
                          isFlipped
                              ? Transform.rotate(angle: pi, child: svgWidget)
                              : svgWidget,
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// COLOR SELECTION SECTION
// -----------------------------------------------------------------------------
class ColorSelectionSection extends StatefulWidget {
  /// The currently selected color index (passed down from parent).
  final int selectedColorIndex;

  /// Callback to inform the parent which color index was selected.
  final ValueChanged<int> onColorSelected;

  const ColorSelectionSection({
    Key? key,
    required this.selectedColorIndex,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  _ColorSelectionSectionState createState() => _ColorSelectionSectionState();
}

class _ColorSelectionSectionState extends State<ColorSelectionSection> {
  @override
  Widget build(BuildContext context) {
    // We retrieve all possible background choices from ColorPalette
    final List<NamedColor> colors = ColorPalette.backgroundChoices(context);
    final int selectedIndex = widget.selectedColorIndex;

    // Safely get the currently selected color's name (for display).
    final String selectedColorName =
        (selectedIndex >= 0 && selectedIndex < colors.length)
            ? colors[selectedIndex].name.toUpperCase()
            : 'UNKNOWN';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and label.
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/images/color_icon.svg',
                        width: 100.0,
                        height: 100.0,
                        semanticsLabel: 'App Logo',
                        placeholderBuilder:
                            (BuildContext context) => Container(
                              padding: const EdgeInsets.all(30.0),
                              child: const CircularProgressIndicator(),
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'BACKGROUND COLOR',
                    style: TextStyle(
                      color: AppColors.labelText(context),
                      fontSize: 12,
                      fontFamily: 'Averta Demo PE Cutted Demo',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              Text(
                selectedColorName,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.labelText(context),
                  fontSize: 12,
                  fontFamily: 'Averta Demo PE Cutted Demo',
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Row of color options.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none, // <-- Make horizontal overflow visible
          child: Row(
            children: List.generate(colors.length, (index) {
              final namedColor = colors[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    widget.onColorSelected(index);
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: ShapeDecoration(
                          color: namedColor.color,
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              width: 0.50,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                        ),
                      ),
                      if (selectedIndex == index)
                        SvgPicture.asset(
                          'assets/images/tick_icon.svg',
                          width: 10,
                          height: 10,
                          semanticsLabel: 'Tick Icon',
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// INPUT SECTION
// -----------------------------------------------------------------------------
class InputSection extends StatefulWidget {
  final void Function(String firstWord, String secondWord) onGenerate;
  final bool hasGenerated;

  /// Expose a callback for "DOWNLOAD AMBIGRAM"
  final VoidCallback onDownload;

  /// New callback to inform parent when the user changes text
  final VoidCallback onInputChanged;

  const InputSection({
    super.key,
    required this.onGenerate,
    required this.hasGenerated,
    required this.onDownload,
    required this.onInputChanged,
  });

  @override
  State<InputSection> createState() => _InputSectionState();
}

class _InputSectionState extends State<InputSection> {
  final _firstController = TextEditingController();
  final _secondController = TextEditingController();

  String? _firstError;
  String? _secondError;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    // Remove field errors once user starts typing
    _firstController.addListener(() {
      if (_firstError != null) {
        setState(() => _firstError = null);
      }
      // If user had already generated, revert the button back to "GENERATE"
      if (widget.hasGenerated) {
        widget.onInputChanged();
      }
    });
    _secondController.addListener(() {
      if (_secondError != null) {
        setState(() => _secondError = null);
      }
      // If user had already generated, revert the button back to "GENERATE"
      if (widget.hasGenerated) {
        widget.onInputChanged();
      }
    });
  }

  @override
  void dispose() {
    _firstController.dispose();
    _secondController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    final firstWord = _firstController.text.trim();
    final secondWord = _secondController.text.trim();

    _firstError = null;
    _secondError = null;

    // 1) Non-empty check for first word
    if (firstWord.isEmpty) {
      _firstError =
          "YOU HAVEN'T ENTERED YOUR FIRST WORD YET. PLEASE TYPE SOMETHING!";
    } else {
      // 2) Check length constraints, only letters, etc.
      if (firstWord.length < 2) {
        _firstError = "YOUR FIRST WORD MUST HAVE AT LEAST 2 LETTERS.";
      } else if (firstWord.length > 12) {
        _firstError = "YOUR FIRST WORD CAN’T BE LONGER THAN 12 LETTERS.";
      } else if (!RegExp(r'^[A-Za-z]+$').hasMatch(firstWord)) {
        _firstError =
            "PLEASE USE LETTERS (A–Z) ONLY, NO NUMBERS OR SPECIAL CHARACTERS.";
      }
    }

    // 3) If the second word is not empty, check constraints
    if (secondWord.isNotEmpty) {
      if (secondWord.length < 2) {
        _secondError = "YOUR SECOND WORD MUST HAVE AT LEAST 2 LETTERS.";
      } else if (secondWord.length > 12) {
        _secondError = "YOUR SECOND WORD CAN’T BE LONGER THAN 12 LETTERS.";
      } else if (!RegExp(r'^[A-Za-z]+$').hasMatch(secondWord)) {
        _secondError =
            "PLEASE USE LETTERS (A–Z) ONLY, NO NUMBERS OR SPECIAL CHARACTERS.";
      } else {
        // 4) If second word is present, it must match the first word's length
        if (_firstError == null && firstWord.length != secondWord.length) {
          _secondError =
              "SECOND WORD MUST MATCH THE FIRST WORD'S LENGTH IF USED.";
        }
      }
    }

    return _firstError == null && _secondError == null;
  }

  @override
  Widget build(BuildContext context) {
    final firstErrorToShow = _showErrors ? _firstError : null;
    final secondErrorToShow = _showErrors ? _secondError : null;

    final buttonLabel = widget.hasGenerated ? "DOWNLOAD AMBIGRAM" : "GENERATE";

    return Column(
      children: [
        AmbigramTextInput(
          controller: _firstController,
          hintText: "ENTER FIRST WORD",
          error: firstErrorToShow,
        ),
        const SizedBox(height: 16),
        AmbigramTextInput(
          controller: _secondController,
          hintText: "ENTER SECOND WORD (OPTIONAL)",
          error: secondErrorToShow,
        ),
        const SizedBox(height: 20),
        AmbigramButton(
          text: buttonLabel,
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (widget.hasGenerated) {
              // If button label is "DOWNLOAD AMBIGRAM", open preview
              widget.onDownload();
            } else {
              // Otherwise, do "GENERATE" logic
              setState(() => _showErrors = true);
              if (_validateInputs()) {
                widget.onGenerate(
                  _firstController.text.trim(),
                  _secondController.text.trim(),
                );
              }
            }
          },
        ),
      ],
    );
  }
}
