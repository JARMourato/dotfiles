import type { ModuleV2 } from '../types';
import { realHome, runAsUser, runCommand } from '../utils/shell';

type Operation = { cmd: string; args: string[] };

const items = [
  { id: 'dock-cleanup', label: 'Remove default Dock icons' },
  { id: 'dock-folders', label: 'Dock folders' },
  { id: 'photos', label: 'Photos / Image Capture' },
  { id: 'spotlight', label: 'Spotlight' },
  { id: 'bluetooth-audio', label: 'Bluetooth audio tuning' },
  { id: 'printing', label: 'Printing defaults' },
  { id: 'keyboard-shortcuts', label: 'Keyboard shortcuts' },
  { id: 'scroll-behavior', label: 'Scroll behavior' },
  { id: 'login-window', label: 'Login window' },
  { id: 'sourcetree', label: 'SourceTree defaults' },
  { id: 'advanced-trackpad', label: 'Advanced trackpad' },
];

const commandsBySection: Record<string, Operation[]> = {
  'dock-folders': [
    {
      cmd: 'defaults',
      args: [
        'write',
        'com.apple.dock',
        'persistent-others',
        '-array-add',
        '<dict><key>tile-data</key><dict><key>arrangement</key><integer>1</integer><key>displayas</key><integer>0</integer><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/</string><key>_CFURLStringType</key><integer>15</integer></dict><key>preferreditemsize</key><string>-1</string><key>showas</key><integer>0</integer></dict><key>tile-type</key><string>directory-tile</string></dict>',
      ],
    },
  ],
  photos: [{ cmd: 'defaults', args: ['-currentHost', 'write', 'com.apple.ImageCapture', 'disableHotPlug', '-bool', 'true'] }],
  spotlight: [
    { cmd: 'defaults', args: ['write', 'com.apple.Spotlight', 'showedLearnMore', '-bool', 'true'] },
    { cmd: 'defaults', args: ['-currentHost', 'write', 'com.apple.Spotlight', 'MenuItemHidden', '-int', '1'] },
    {
      cmd: 'defaults',
      args: ['write', `${realHome()}/Library/Preferences/com.apple.controlcenter.plist`, 'NSStatusItem Visible Battery', '-bool', 'false'],
    },
  ],
  'bluetooth-audio': [{ cmd: 'defaults', args: ['write', 'com.apple.BluetoothAudioAgent', 'Apple Bitpool Min (editable)', '-int', '40'] }],
  printing: [{ cmd: 'defaults', args: ['write', 'com.apple.print.PrintingPrefs', 'Quit When Finished', '-bool', 'true'] }],
  'keyboard-shortcuts': [
    { cmd: 'defaults', args: ['write', '-g', 'NSUserKeyEquivalents', '-dict-add', 'Strikethrough', '@$x'] },
    { cmd: 'defaults', args: ['write', 'com.apple.dt.Xcode', 'NSUserKeyEquivalents', '-dict-add', 'Sort Selected Lines', '^$i'] },
  ],
  'scroll-behavior': [
    { cmd: 'defaults', args: ['write', '-g', 'AppleScrollerPagingBehavior', '-bool', 'true'] },
    { cmd: 'defaults', args: ['write', '-g', 'AppleActionOnDoubleClick', '-string', 'Maximize'] },
    { cmd: 'defaults', args: ['write', '-g', 'com.apple.sound.beep.feedback', '-int', '1'] },
  ],
  'login-window': [
    { cmd: 'sudo', args: ['defaults', 'write', '/Library/Preferences/com.apple.loginwindow', 'showInputMenu', '-bool', 'false'] },
  ],
  sourcetree: [
    { cmd: 'defaults', args: ['write', 'com.torusknot.SourceTreeNotMAS', 'SidebarWidth_', '-int', '140'] },
    { cmd: 'defaults', args: ['write', 'com.torusknot.SourceTreeNotMAS', 'commitPaneHeight', '-int', '242'] },
    {
      cmd: 'defaults',
      args: ['write', 'com.torusknot.SourceTreeNotMAS', 'diffSkipFilePatterns', '-string', '*.pbxuser, *.xcuserstate, Cartfile.resolved'],
    },
  ],
  'advanced-trackpad': [
    { cmd: 'defaults', args: ['write', 'com.apple.AppleMultitouchTrackpad', 'SecondClickThreshold', '-int', '0'] },
    {
      cmd: 'defaults',
      args: ['write', 'com.apple.driver.AppleBluetoothMultitouch.trackpad', 'SecondClickThreshold', '-int', '0'],
    },
  ],
};

const DOCK_REMOVE_APPS = [
  'Messages',
  'Maps',
  'Photos',
  'FaceTime',
  'Phone',
  'Contacts',
  'Reminders',
  'TV',
  'Music',
  'News',
  'Keynote',
  'Numbers',
  'Pages',
  'Freeform',
];

async function ensureDockutil(dryRun: boolean): Promise<boolean> {
  const has = await runCommand('which', ['dockutil'], { continueOnError: true });
  if (has.ok) return true;
  if (dryRun) return true;
  const install = await runCommand('brew', ['install', 'dockutil'], { continueOnError: true });
  return install.ok;
}

async function removeDockIcons(dryRun: boolean): Promise<void> {
  const hasDockutil = await ensureDockutil(dryRun);
  if (!hasDockutil) return;

  for (const app of DOCK_REMOVE_APPS) {
    if (dryRun) {
      console.log(`[dry-run] dockutil --remove '${app}' --no-restart`);
      continue;
    }
    await runAsUser('dockutil', ['--remove', app, '--no-restart'], { continueOnError: true });
  }

  if (!dryRun) {
    await runCommand('killall', ['Dock'], { continueOnError: true });
  }
}

export const macosComplexModule: ModuleV2 = {
  name: 'macos_complex',
  label: 'macOS Complex Defaults',
  description: 'Advanced and niche defaults grouped by section',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['macos'],
  async detect(_selectedItems) {
    return {
      installed: [],
      missing: _selectedItems,
      partial: false,
    };
  },
  async install(selectedItems, opts) {
    // Handle dock-cleanup separately (needs dockutil)
    if (selectedItems.includes('dock-cleanup')) {
      await removeDockIcons(opts.dryRun);
    }

    for (const section of selectedItems) {
      if (section === 'dock-cleanup') continue; // already handled
      if (section === 'sourcetree') {
        const sourceTree = await runCommand('test', ['-d', '/Applications/SourceTree.app'], { continueOnError: true });
        if (!sourceTree.ok) {
          continue;
        }
      }

      // Skip dock-folders if Applications folder is already in the Dock
      if (section === 'dock-folders') {
        const current = await runAsUser('defaults', ['read', 'com.apple.dock', 'persistent-others'], { continueOnError: true });
        if (current.ok && current.stdout.includes('/Applications/')) {
          continue;
        }
      }

      for (const operation of commandsBySection[section] ?? []) {
        if (operation.cmd === 'defaults') {
          await runAsUser('defaults', operation.args, { dryRun: opts.dryRun });
        } else if (operation.cmd === 'sudo' && operation.args[0] === 'defaults') {
          // System-level defaults (e.g. /Library/...) — run as-is with sudo
          await runCommand('defaults', operation.args.slice(1), { dryRun: opts.dryRun, continueOnError: true });
        } else {
          await runCommand(operation.cmd, operation.args, { dryRun: opts.dryRun, continueOnError: true });
        }
      }
    }
  },
};
