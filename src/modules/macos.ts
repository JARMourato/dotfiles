import os from 'node:os';
import path from 'node:path';
import type { Module } from '../types';
import { runCommand } from '../utils/shell';

type MacosConfig = Record<string, any>;

function asBool(value: unknown): boolean {
  return value === true || value === 'true';
}

function asString(value: unknown): string {
  return String(value);
}

function toDefaultsType(value: unknown): 'bool' | 'int' | 'float' | 'string' {
  if (typeof value === 'boolean') return 'bool';
  if (typeof value === 'number') return Number.isInteger(value) ? 'int' : 'float';
  return 'string';
}

async function defaultsWrite(
  domain: string,
  key: string,
  value: unknown,
  dryRun: boolean,
): Promise<void> {
  const type = toDefaultsType(value);
  const flag = `-${type}`;
  const normalized = typeof value === 'boolean' ? String(value) : asString(value);
  await runCommand('defaults', ['write', domain, key, flag, normalized], { dryRun, continueOnError: true });
}

export const macosModule: Module = {
  name: 'macos',
  label: 'macOS Defaults',
  description: 'Dock, Finder, keyboard, trackpad, power, screenshots, clock and more',
  async detect(opts) {
    const hasConfig = Boolean(opts.profile.config.macos);
    return {
      installed: hasConfig ? ['profile-defaults'] : [],
      missing: hasConfig ? [] : ['profile-defaults'],
      partial: false,
    };
  },
  async install(opts) {
    const cfg = (opts.profile.config.macos ?? {}) as MacosConfig;

    await runCommand('osascript', ['-e', 'tell application "System Preferences" to quit'], {
      dryRun: opts.dryRun,
      continueOnError: true,
    });

    const activity = cfg.activity_monitor ?? {};
    if ('open_main_window' in activity) {
      await defaultsWrite('com.apple.ActivityMonitor', 'OpenMainWindow', asBool(activity.open_main_window), opts.dryRun);
    }
    if (asBool(activity.show_all_processes)) {
      await defaultsWrite('com.apple.ActivityMonitor', 'ShowCategory', 0, opts.dryRun);
    }
    if (asBool(activity.sort_by_cpu)) {
      await defaultsWrite('com.apple.ActivityMonitor', 'SortColumn', 'CPUUsage', opts.dryRun);
      await defaultsWrite('com.apple.ActivityMonitor', 'SortDirection', 0, opts.dryRun);
    }

    const appStore = cfg.app_store ?? {};
    if (asBool(appStore.check_updates_daily)) {
      await defaultsWrite('com.apple.SoftwareUpdate', 'ScheduleFrequency', 1, opts.dryRun);
    }

    const dock = cfg.dock ?? {};
    const dockMap: Array<[string, string]> = [
      ['autohide', 'autohide'],
      ['tile_size', 'tilesize'],
      ['large_size', 'largesize'],
      ['magnification', 'magnification'],
      ['minimize_to_application', 'minimize-to-application'],
      ['show_process_indicators', 'show-process-indicators'],
      ['orientation', 'orientation'],
    ];
    for (const [source, key] of dockMap) {
      if (dock[source] !== undefined) {
        await defaultsWrite('com.apple.dock', key, dock[source], opts.dryRun);
      }
    }
    if (asBool(dock.disable_rearrange_spaces)) {
      await defaultsWrite('com.apple.dock', 'mru-spaces', false, opts.dryRun);
    }
    if (asBool(dock.disable_recent_apps)) {
      await defaultsWrite('com.apple.dock', 'show-recents', false, opts.dryRun);
    }

    const finder = cfg.finder ?? {};
    if (finder.new_window_target === 'home') {
      await defaultsWrite('com.apple.finder', 'NewWindowTarget', 'PfLo', opts.dryRun);
      await defaultsWrite('com.apple.finder', 'NewWindowTargetPath', `file://${os.homedir()}`, opts.dryRun);
    }
    if (finder.new_window_target === 'desktop') {
      await defaultsWrite('com.apple.finder', 'NewWindowTarget', 'PfDe', opts.dryRun);
      await defaultsWrite('com.apple.finder', 'NewWindowTargetPath', `file://${path.join(os.homedir(), 'Desktop')}/`, opts.dryRun);
    }
    const finderMap: Array<[string, string]> = [
      ['show_external_drives', 'ShowExternalHardDrivesOnDesktop'],
      ['show_hard_drives', 'ShowHardDrivesOnDesktop'],
      ['show_servers', 'ShowMountedServersOnDesktop'],
      ['show_removable_media', 'ShowRemovableMediaOnDesktop'],
      ['show_hidden_files', 'AppleShowAllFiles'],
      ['show_status_bar', 'ShowStatusBar'],
      ['show_path_bar', 'ShowPathbar'],
      ['show_posix_path_title', '_FXShowPosixPathInTitle'],
      ['sort_folders_first', '_FXSortFoldersFirst'],
      ['empty_trash_securely', 'EmptyTrashSecurely'],
    ];
    for (const [source, key] of finderMap) {
      if (finder[source] !== undefined) {
        await defaultsWrite('com.apple.finder', key, finder[source], opts.dryRun);
      }
    }
    if (asBool(finder.search_current_folder)) {
      await defaultsWrite('com.apple.finder', 'FXDefaultSearchScope', 'SCcf', opts.dryRun);
    }
    if (finder.preferred_view) {
      const map: Record<string, string> = { icon: 'icnv', list: 'Nlsv', column: 'clmv', gallery: 'glyv' };
      await defaultsWrite('com.apple.finder', 'FXPreferredViewStyle', map[finder.preferred_view] ?? 'clmv', opts.dryRun);
    }
    if (asBool(finder.snap_to_grid)) {
      const finderPrefs = path.join(os.homedir(), 'Library/Preferences/com.apple.finder.plist');
      await runCommand('/usr/libexec/PlistBuddy', ['-c', 'Set :DesktopViewSettings:IconViewSettings:arrangeBy grid', finderPrefs], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('/usr/libexec/PlistBuddy', ['-c', 'Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid', finderPrefs], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('/usr/libexec/PlistBuddy', ['-c', 'Set :StandardViewSettings:IconViewSettings:arrangeBy grid', finderPrefs], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
    if (asBool(finder.expand_info_panes)) {
      await runCommand('defaults', ['write', 'com.apple.finder', 'FXInfoPanesExpanded', '-dict', 'General', '-bool', 'true', 'OpenWith', '-bool', 'true', 'Privileges', '-bool', 'true'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }

    const keyboard = cfg.keyboard ?? {};
    const keyboardBooleanKeys: Array<[string, string, boolean]> = [
      ['disable_auto_capitalization', 'NSAutomaticCapitalizationEnabled', false],
      ['disable_smart_dashes', 'NSAutomaticDashSubstitutionEnabled', false],
      ['disable_period_substitution', 'NSAutomaticPeriodSubstitutionEnabled', false],
      ['disable_smart_quotes', 'NSAutomaticQuoteSubstitutionEnabled', false],
      ['disable_auto_correct', 'NSAutomaticSpellingCorrectionEnabled', false],
      ['disable_text_completion', 'NSAutomaticTextCompletionEnabled', false],
      ['disable_press_and_hold', 'ApplePressAndHoldEnabled', false],
    ];
    for (const [source, key, target] of keyboardBooleanKeys) {
      if (asBool(keyboard[source])) {
        await defaultsWrite('-g', key, target, opts.dryRun);
      }
    }
    if (keyboard.key_repeat_rate !== undefined) await defaultsWrite('-g', 'KeyRepeat', keyboard.key_repeat_rate, opts.dryRun);
    if (keyboard.initial_key_repeat !== undefined) await defaultsWrite('-g', 'InitialKeyRepeat', keyboard.initial_key_repeat, opts.dryRun);
    if (asBool(keyboard.enable_tab_navigation)) {
      await runCommand('defaults', ['write', '-g', 'NSUserKeyEquivalents', '-dict-add', 'Show Next Tab', '@~\\U2192'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
      await runCommand('defaults', ['write', '-g', 'NSUserKeyEquivalents', '-dict-add', 'Show Previous Tab', '@~\\U2190'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }

    const lang = cfg.language_region ?? {};
    if (Array.isArray(lang.languages) && lang.languages.length > 0) {
      await runCommand('defaults', ['write', '-g', 'AppleLanguages', '-array', ...lang.languages.map(String)], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
    if (lang.locale) await defaultsWrite('-g', 'AppleLocale', lang.locale, opts.dryRun);
    if (lang.measurement_units) await defaultsWrite('-g', 'AppleMeasurementUnits', lang.measurement_units, opts.dryRun);
    if (lang.metric_units !== undefined) await defaultsWrite('-g', 'AppleMetricUnits', asBool(lang.metric_units), opts.dryRun);
    if (lang.temperature_unit) await defaultsWrite('-g', 'AppleTemperatureUnit', lang.temperature_unit, opts.dryRun);
    if (asBool(lang.force_24_hour)) await defaultsWrite('-g', 'AppleICUForce24HourTime', true, opts.dryRun);
    if (asBool(lang.hide_language_menu)) await defaultsWrite('com.apple.TextInputMenu', 'visible', false, opts.dryRun);

    const mouse = cfg.mouse ?? {};
    if (mouse.tracking_speed !== undefined) await defaultsWrite('-g', 'com.apple.mouse.scaling', mouse.tracking_speed, opts.dryRun);
    if (mouse.double_click_threshold !== undefined) await defaultsWrite('-g', 'com.apple.mouse.doubleClickThreshold', mouse.double_click_threshold, opts.dryRun);
    if (mouse.scroll_speed !== undefined) await defaultsWrite('-g', 'com.apple.scrollwheel.scaling', mouse.scroll_speed, opts.dryRun);

    const trackpad = cfg.trackpad ?? {};
    if (asBool(trackpad.tap_to_click)) {
      await defaultsWrite('com.apple.driver.AppleBluetoothMultitouch.trackpad', 'Clicking', true, opts.dryRun);
      await defaultsWrite('com.apple.AppleMultitouchTrackpad', 'Clicking', true, opts.dryRun);
      await defaultsWrite('-g', 'com.apple.mouse.tapBehavior', 1, opts.dryRun);
    }
    if (asBool(trackpad.silent_clicking)) {
      await defaultsWrite('com.apple.AppleMultitouchTrackpad', 'ActuationStrength', 0, opts.dryRun);
      await defaultsWrite('com.apple.driver.AppleBluetoothMultitouch.trackpad', 'ActuationStrength', 0, opts.dryRun);
    }
    if (trackpad.haptic_feedback !== undefined) {
      await defaultsWrite('com.apple.AppleMultitouchTrackpad', 'FirstClickThreshold', trackpad.haptic_feedback, opts.dryRun);
      await defaultsWrite('com.apple.driver.AppleBluetoothMultitouch.trackpad', 'FirstClickThreshold', trackpad.haptic_feedback, opts.dryRun);
    }
    if (trackpad.tracking_speed !== undefined) await defaultsWrite('-g', 'com.apple.trackpad.scaling', trackpad.tracking_speed, opts.dryRun);
    if (asBool(trackpad.disable_swipe_navigation)) {
      await defaultsWrite('com.apple.AppleMultitouchTrackpad', 'TrackpadThreeFingerHorizSwipeGesture', 0, opts.dryRun);
      await defaultsWrite('com.apple.driver.AppleBluetoothMultitouch.trackpad', 'TrackpadThreeFingerHorizSwipeGesture', 0, opts.dryRun);
    }

    const power = cfg.power ?? {};
    if (power.sleep_on_power !== undefined) {
      await runCommand('sudo', ['pmset', '-c', 'sleep', asString(power.sleep_on_power)], { dryRun: opts.dryRun, continueOnError: true });
    }
    if (power.sleep_on_battery !== undefined) {
      await runCommand('sudo', ['pmset', '-b', 'sleep', asString(power.sleep_on_battery)], { dryRun: opts.dryRun, continueOnError: true });
    }
    if (asBool(power.disable_proximity_wake)) {
      await runCommand('sudo', ['pmset', '-a', 'proximitywake', '0'], { dryRun: opts.dryRun, continueOnError: true });
    }
    if (asBool(power.disable_power_nap)) {
      await runCommand('sudo', ['pmset', '-c', 'powernap', '0'], { dryRun: opts.dryRun, continueOnError: true });
      await runCommand('sudo', ['pmset', '-b', 'powernap', '0'], { dryRun: opts.dryRun, continueOnError: true });
    }
    if (asBool(power.require_password_immediately)) {
      await defaultsWrite('com.apple.screensaver', 'askForPassword', 1, opts.dryRun);
      await defaultsWrite('com.apple.screensaver', 'askForPasswordDelay', 0, opts.dryRun);
    }

    const screen = cfg.screen ?? {};
    if (screen.font_smoothing !== undefined) {
      await defaultsWrite('-g', 'CGFontRenderingFontSmoothingDisabled', false, opts.dryRun);
      await defaultsWrite('-g', 'AppleFontSmoothing', screen.font_smoothing, opts.dryRun);
    }
    if (asBool(screen.enable_hidpi) || asBool(screen.enable_more_space)) {
      await runCommand('sudo', ['defaults', 'write', '/Library/Preferences/com.apple.windowserver', 'DisplayResolutionEnabled', '-bool', 'true'], {
        dryRun: opts.dryRun,
        continueOnError: true,
      });
    }
    if (screen.screenshot_location) {
      const location = asString(screen.screenshot_location).replace(/^~\//, `${os.homedir()}/`);
      await runCommand('mkdir', ['-p', location], { dryRun: opts.dryRun, continueOnError: true });
      await defaultsWrite('com.apple.screencapture', 'location', location, opts.dryRun);
    }
    if (screen.screenshot_format) await defaultsWrite('com.apple.screencapture', 'type', screen.screenshot_format, opts.dryRun);
    if (screen.disable_screenshot_shadows !== undefined) {
      await defaultsWrite('com.apple.screencapture', 'disable-shadow', asBool(screen.disable_screenshot_shadows), opts.dryRun);
    }

    const menu = cfg.menu_bar ?? {};
    if (asBool(menu.show_full_date_time)) {
      await defaultsWrite('com.apple.menuextra.clock', 'DateFormat', menu.date_format ?? 'EEE MMM d  h:mm:ss a', opts.dryRun);
      await defaultsWrite('com.apple.menuextra.clock', 'Show24Hour', false, opts.dryRun);
      await defaultsWrite('com.apple.menuextra.clock', 'ShowDayOfWeek', true, opts.dryRun);
      await defaultsWrite('com.apple.menuextra.clock', 'ShowDate', 1, opts.dryRun);
      await defaultsWrite('com.apple.menuextra.clock', 'ShowSeconds', true, opts.dryRun);
      if (menu.flash_date_separators !== undefined) {
        await defaultsWrite('com.apple.menuextra.clock', 'FlashDateSeparators', asBool(menu.flash_date_separators), opts.dryRun);
      }
    }

    const terminal = cfg.terminal ?? {};
    if (asBool(terminal.secure_keyboard_entry)) {
      await defaultsWrite('com.apple.terminal', 'SecureKeyboardEntry', true, opts.dryRun);
    }

    const timeMachine = cfg.time_machine ?? {};
    if (asBool(timeMachine.disable_new_disk_prompt)) {
      await defaultsWrite('com.apple.TimeMachine', 'DoNotOfferNewDisksForBackup', true, opts.dryRun);
    }

    const hotCorners = cfg.hot_corners ?? {};
    const corners: Array<[string, string, string]> = [
      ['top_left', 'wvous-tl-corner', 'wvous-tl-modifier'],
      ['top_right', 'wvous-tr-corner', 'wvous-tr-modifier'],
      ['bottom_left', 'wvous-bl-corner', 'wvous-bl-modifier'],
      ['bottom_right', 'wvous-br-corner', 'wvous-br-modifier'],
    ];
    for (const [source, cornerKey, modifierKey] of corners) {
      if (hotCorners[source] !== undefined) {
        await defaultsWrite('com.apple.dock', cornerKey, hotCorners[source], opts.dryRun);
        await defaultsWrite('com.apple.dock', modifierKey, 0, opts.dryRun);
      }
    }

    const xcode = cfg.xcode ?? {};
    const xcodeMap: Array<[string, string, unknown]> = [
      ['trim_whitespace', 'DVTTextEditorTrimTrailingWhitespace', true],
      ['trim_whitespace_only_lines', 'DVTTextEditorTrimWhitespaceOnlyLines', true],
      ['disable_case_indent', 'DVTTextIndentCase', false],
      ['indent_on_paste', 'DVTTextIndentOnPaste', true],
      ['hide_authors_panel', 'DVTTextShowAuthors', false],
      ['hide_minimap', 'DVTTextShowMinimap', false],
      ['show_build_steps', 'DVTBuildLogShowSteps', true],
      ['show_analyzer_results', 'DVTAnalyzerResultsViewerShowResultsInline', true],
      ['show_errors', 'DVTIssueNavigatorShowErrors', true],
      ['show_warnings', 'DVTIssueNavigatorShowWarnings', true],
      ['command_click_jumps', 'DVTTextEditorCommandClickJumpsToDefinition', true],
      ['show_indexing_progress', 'IDEIndexShowIndexingProgress', true],
      ['show_build_duration', 'ShowBuildOperationDuration', true],
    ];
    for (const [source, key, value] of xcodeMap) {
      if (asBool(xcode[source])) {
        await defaultsWrite('com.apple.dt.Xcode', key, value, opts.dryRun);
      }
    }
    if (xcode.overscroll_amount !== undefined) {
      await defaultsWrite('com.apple.dt.Xcode', 'DVTTextOverscrollAmount', xcode.overscroll_amount, opts.dryRun);
    }

    await runCommand('killall', ['Dock'], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('killall', ['Finder'], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('killall', ['SystemUIServer'], { dryRun: opts.dryRun, continueOnError: true });
    await runCommand('killall', ['ControlStrip'], { dryRun: opts.dryRun, continueOnError: true });
  },
};
