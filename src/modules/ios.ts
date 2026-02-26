import type { ModuleV2 } from '../types';
import { detectFormulas, installFormulas } from './helpers';

const items = [
  { id: 'swiftlint', label: 'swiftlint' },
  { id: 'swiftformat', label: 'swiftformat' },
  { id: 'cocoapods', label: 'cocoapods' },
  { id: 'fastlane', label: 'fastlane' },
  { id: 'carthage', label: 'carthage' },
  { id: 'xcbeautify', label: 'xcbeautify' },
];

export const iosModule: ModuleV2 = {
  name: 'ios',
  label: 'iOS Dev',
  description: 'swiftlint, swiftformat, cocoapods, fastlane, carthage, xcbeautify',
  items,
  defaultItems: items.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    return detectFormulas(selectedItems);
  },
  async install(selectedItems, opts) {
    await installFormulas(selectedItems, opts);
  },
};
