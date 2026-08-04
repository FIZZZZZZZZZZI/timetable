import '../models/app_theme.dart';
import '../utils/theme_color_utils.dart';

/// The built-in themes, always re-seeded (put) into the themes box on every
/// app start so code changes to preset colors take effect immediately —
/// unlike custom themes, presets aren't user data, so there's nothing to
/// preserve by leaving them alone.
List<AppTheme> buildPresetThemes() => [
      AppTheme(
        id: 'default',
        name: 'Default',
        isCustom: false,
        background: 0xFFF7F7FC,
        card: 0xFFFFFFFF,
        primary: 0xFF3F51B5,
        accent: 0xFF5C6BC0,
        textPrimary: kDarkTextPrimary,
        textSecondary: kDarkTextSecondary,
        streakColor: 0xFFFF5722,
        borderRadius: 16.0,
      ),
      AppTheme(
        id: 'sunset',
        name: 'Sunset',
        isCustom: false,
        background: 0xFF1F1220,
        card: 0xFF2E1B2E,
        primary: 0xFFFF6B4A,
        accent: 0xFFFFB74D,
        textPrimary: 0xFFFDEEE7,
        textSecondary: 0xFFCBA9A0,
        streakColor: 0xFFFF3D00,
        borderRadius: 14.0,
      ),
      AppTheme(
        id: 'ninja',
        name: 'Ninja',
        isCustom: false,
        background: 0xFF0A0E1A,
        card: 0xFF141B2E,
        primary: 0xFF2E63D8,
        accent: 0xFF5FA8FF,
        textPrimary: kLightTextPrimary,
        textSecondary: kLightTextSecondary,
        streakColor: 0xFFD8452E,
        borderRadius: 5.0,
      ),
    ];

/// Level required to select each preset. Anything not listed (i.e. every
/// custom theme) has no preset-specific gate — creating one at all is
/// already gated behind [kCustomThemeUnlockLevel].
const Map<String, int> kPresetUnlockLevels = {
  'default': 1,
  'sunset': 4,
  'ninja': 8,
};

const int kCustomThemeUnlockLevel = 12;

const String kDefaultThemeId = 'default';
