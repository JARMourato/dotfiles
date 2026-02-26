import type { Module } from '../types';
import { runCommand } from '../utils/shell';

const commands: Array<{ cmd: string; args: string[] }> = [
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
  { cmd: 'defaults', args: ['-currentHost', 'write', 'com.apple.ImageCapture', 'disableHotPlug', '-bool', 'true'] },
  { cmd: 'defaults', args: ['write', 'com.apple.Spotlight', 'showedLearnMore', '-bool', 'true'] },
  { cmd: 'defaults', args: ['-currentHost', 'write', 'com.apple.Spotlight', 'MenuItemHidden', '-int', '1'] },
  {
    cmd: 'defaults',
    args: ['write', `${process.env.HOME}/Library/Preferences/com.apple.controlcenter.plist`, 'NSStatusItem Visible Battery', '-bool', 'false'],
  },
  { cmd: 'defaults', args: ['write', 'com.apple.BluetoothAudioAgent', 'Apple Bitpool Min (editable)', '-int', '40'] },
  { cmd: 'defaults', args: ['write', 'com.apple.print.PrintingPrefs', 'Quit When Finished', '-bool', 'true'] },
  { cmd: 'defaults', args: ['write', '-g', 'NSUserKeyEquivalents', '-dict-add', 'Strikethrough', '@$x'] },
  { cmd: 'defaults', args: ['write', 'com.apple.dt.Xcode', 'NSUserKeyEquivalents', '-dict-add', 'Sort Selected Lines', '^$i'] },
  { cmd: 'defaults', args: ['write', '-g', 'AppleScrollerPagingBehavior', '-bool', 'true'] },
  { cmd: 'defaults', args: ['write', '-g', 'AppleActionOnDoubleClick', '-string', 'Maximize'] },
  { cmd: 'defaults', args: ['write', '-g', 'com.apple.sound.beep.feedback', '-int', '1'] },
  { cmd: 'sudo', args: ['defaults', 'write', '/Library/Preferences/com.apple.loginwindow', 'showInputMenu', '-bool', 'false'] },
  { cmd: 'defaults', args: ['write', 'com.apple.AppleMultitouchTrackpad', 'SecondClickThreshold', '-int', '0'] },
  {
    cmd: 'defaults',
    args: ['write', 'com.apple.driver.AppleBluetoothMultitouch.trackpad', 'SecondClickThreshold', '-int', '0'],
  },
];

export const macosComplexModule: Module = {
  name: 'macos-complex',
  label: 'Complex macOS Defaults',
  description: 'Dock folders, Spotlight, SourceTree and advanced defaults',
  dependencies: ['macos'],
  async detect() {
    return {
      installed: [],
      missing: ['complex-defaults'],
      partial: false,
    };
  },
  async install(opts) {
    for (const operation of commands) {
      await runCommand(operation.cmd, operation.args, { dryRun: opts.dryRun, continueOnError: true });
    }

    const sourceTree = await runCommand('test', ['-d', '/Applications/SourceTree.app'], { continueOnError: true });
    if (sourceTree.ok) {
      const sourceTreeCommands: Array<{ cmd: string; args: string[] }> = [
        { cmd: 'defaults', args: ['write', 'com.torusknot.SourceTreeNotMAS', 'SidebarWidth_', '-int', '140'] },
        { cmd: 'defaults', args: ['write', 'com.torusknot.SourceTreeNotMAS', 'commitPaneHeight', '-int', '242'] },
        {
          cmd: 'defaults',
          args: ['write', 'com.torusknot.SourceTreeNotMAS', 'diffSkipFilePatterns', '-string', '*.pbxuser, *.xcuserstate, Cartfile.resolved'],
        },
      ];
      for (const operation of sourceTreeCommands) {
        await runCommand(operation.cmd, operation.args, { dryRun: opts.dryRun, continueOnError: true });
      }
    }
  },
};
