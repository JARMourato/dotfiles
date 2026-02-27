import type { MasAppSelection, ModuleV2 } from '../types';
import { detectMasApps, installMasApp, installMasApps } from './helpers';

const masItems: Array<{ id: string; label: string; app: MasAppSelection }> = [
  { id: 'lanscan', label: 'LanScan', app: { id: 472226235, name: 'LanScan' } },
  { id: 'things-3', label: 'Things 3', app: { id: 904280696, name: 'Things 3' } },
  { id: 'magnet', label: 'Magnet', app: { id: 441258766, name: 'Magnet' } },
];

const byItem = new Map(masItems.map((item) => [item.id, item]));

function idsForItems(items: string[]): number[] {
  return items
    .map((item) => byItem.get(item)?.app.id)
    .filter((value): value is number => typeof value === 'number');
}

export function masAppsForItems(items: string[]): MasAppSelection[] {
  return items
    .map((item) => byItem.get(item)?.app)
    .filter((value): value is MasAppSelection => Boolean(value));
}

export function masItemsFromApps(apps: MasAppSelection[]): string[] {
  const byId = new Map(masItems.map((item) => [item.app.id, item.id]));
  return apps
    .map((app) => byId.get(app.id))
    .filter((value): value is string => Boolean(value));
}

export const masModule: ModuleV2 = {
  name: 'mas',
  label: 'Mac App Store',
  description: 'Install selected App Store applications',
  items: masItems.map(({ id, label }) => ({ id, label })),
  defaultItems: masItems.map((item) => item.id),
  dependencies: ['core'],
  async detect(selectedItems) {
    const ids = idsForItems(selectedItems);
    const detect = await detectMasApps(ids);

    const idToItem = new Map(masItems.map((item) => [String(item.app.id), item.id]));
    return {
      installed: detect.installed.map((id) => idToItem.get(id) ?? id),
      missing: detect.missing.map((id) => idToItem.get(id) ?? id),
      partial: detect.partial,
    };
  },
  async install(selectedItems, opts) {
    const ids = idsForItems(selectedItems);
    await installMasApps(ids, opts);
  },
  async installItem(item, opts) {
    const entry = byItem.get(item);
    if (entry) await installMasApp(entry.app.id, opts);
  },
};
