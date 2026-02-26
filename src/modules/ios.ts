import type { Module } from '../types';
import { detectFormulas, installFormulas } from './helpers';

const defaults = ['swiftlint', 'swiftformat', 'cocoapods', 'fastlane', 'carthage', 'xcbeautify'];

export const iosModule: Module = {
  name: 'ios',
  label: 'iOS Tooling',
  description: 'swiftlint, swiftformat, cocoapods, fastlane, carthage, xcbeautify',
  dependencies: ['core'],
  async detect() {
    return detectFormulas(defaults);
  },
  async install(opts) {
    const formulas = (opts.profile.config.ios as { formulas?: string[] } | undefined)?.formulas ?? defaults;
    await installFormulas(formulas, opts);
  },
};
