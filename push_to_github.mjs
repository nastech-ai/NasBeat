import { readFileSync } from 'fs';

const TOKEN = process.env.GITHUB_PERSONAL_ACCESS_TOKEN;
const OWNER = 'nastech-ai';
const REPO = 'NasBeat';
// Current HEAD on main (as of icon rebrand push)
const BASE_SHA = 'b9528be7e013f1a28ae867fe0eb21cccf5609575';

async function gh(method, path, body) {
  const res = await fetch(`https://api.github.com/repos/${OWNER}/${REPO}${path}`, {
    method,
    headers: {
      Authorization: `token ${TOKEN}`,
      'Content-Type': 'application/json',
      Accept: 'application/vnd.github.v3+json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  try { return JSON.parse(text); } catch { return text; }
}

const FILES = [
  // ── Code changes ────────────────────────────────────────────────────────────
  'lib/core/theme/app_theme.dart',
  'lib/core/constants/setting_keys.dart',
  'lib/blocs/settings_cubit/cubit/settings_state.dart',
  'lib/blocs/settings_cubit/cubit/settings_cubit.dart',
  'lib/main.dart',
  'lib/services/audio_service_initializer.dart',

  // ── Web ─────────────────────────────────────────────────────────────────────
  'web/favicon.png',
  'web/manifest.json',
  'web/index.html',
  'web/icons/Icon-192.png',
  'web/icons/Icon-512.png',
  'web/icons/Icon-maskable-192.png',
  'web/icons/Icon-maskable-512.png',

  // ── Android mipmap launcher ──────────────────────────────────────────────────
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-mdpi/launcher_icon.png',
  'android/app/src/main/res/mipmap-hdpi/launcher_icon.png',
  'android/app/src/main/res/mipmap-xhdpi/launcher_icon.png',
  'android/app/src/main/res/mipmap-xxhdpi/launcher_icon.png',
  'android/app/src/main/res/mipmap-xxxhdpi/launcher_icon.png',

  // ── Android adaptive icon foreground (white tree, transparent bg) ────────────
  'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xhdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xxhdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',

  // ── Android adaptive icon background (solid black) ───────────────────────────
  'android/app/src/main/res/drawable-mdpi/ic_launcher_background.png',
  'android/app/src/main/res/drawable-hdpi/ic_launcher_background.png',
  'android/app/src/main/res/drawable-xhdpi/ic_launcher_background.png',
  'android/app/src/main/res/drawable-xxhdpi/ic_launcher_background.png',
  'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_background.png',

  // ── Android notification icons (white on transparent) ────────────────────────
  'android/app/src/main/res/drawable/ic_stat_nasbeat.png',
  'android/app/src/main/res/drawable-mdpi/ic_stat_nasbeat.png',
  'android/app/src/main/res/drawable-hdpi/ic_stat_nasbeat.png',
  'android/app/src/main/res/drawable-xhdpi/ic_stat_nasbeat.png',
  'android/app/src/main/res/drawable-xxhdpi/ic_stat_nasbeat.png',
  'android/app/src/main/res/drawable-xxxhdpi/ic_stat_nasbeat.png',

  // ── macOS icons ───────────────────────────────────────────────────────────────
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_16.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_64.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_128.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_256.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png',
  'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png',

  // ── iOS icons ─────────────────────────────────────────────────────────────────
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-50x50@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-57x57@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-72x72@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',

  // ── Windows ICO ───────────────────────────────────────────────────────────────
  'windows/runner/resources/app_icon.ico',

  // ── In-app asset icons ────────────────────────────────────────────────────────
  'assets/icons/BloomeeLogo4.png',
  'assets/icons/BloomeeTunes4ZoomedOut.png',
  'assets/icons/BloomeeTunes4ZoomedOut2.png',
  'assets/icons/bloomee_new_logo_gradient_bg.png',
  'assets/icons/bloomee_new_logo_c.png',
  'assets/icons/new_bloomee_logo_mono.png',
  'assets/icons/BloomeeLogoFG.png',
  'assets/icons/bloomee_light_gradient.png',
  'assets/icons/Bloomee_Logo_back_4.png',

  // ── Fastlane ─────────────────────────────────────────────────────────────────
  'fastlane/metadata/android/en-US/images/icon.png',
];

const BINARY = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.ico']);
function isBinary(f) { return BINARY.has('.' + f.split('.').pop().toLowerCase()); }

console.log('Step 1: Creating blobs for', FILES.length, 'files...');
const treeItems = [];

for (const file of FILES) {
  let content, encoding;
  if (isBinary(file)) {
    content = readFileSync(file).toString('base64');
    encoding = 'base64';
  } else {
    content = readFileSync(file, 'utf8');
    encoding = 'utf-8';
  }
  const blob = await gh('POST', '/git/blobs', { content, encoding });
  if (!blob.sha) { console.error('Blob failed for', file, JSON.stringify(blob).slice(0,200)); process.exit(1); }
  console.log('  blob:', file, '->', blob.sha.slice(0,8));
  treeItems.push({ path: file, mode: '100644', type: 'blob', sha: blob.sha });
}

console.log('Step 2: Getting base tree from', BASE_SHA, '...');
const baseCommit = await gh('GET', `/git/commits/${BASE_SHA}`);
const baseTreeSha = baseCommit.tree.sha;
console.log('  base tree:', baseTreeSha);

console.log('Step 3: Creating new tree...');
const newTree = await gh('POST', '/git/trees', { base_tree: baseTreeSha, tree: treeItems });
if (!newTree.sha) { console.error('Tree failed:', JSON.stringify(newTree).slice(0,300)); process.exit(1); }
console.log('  new tree:', newTree.sha);

console.log('Step 4: Creating commit...');
const newCommit = await gh('POST', '/git/commits', {
  message: 'feat: replace all icons with NasBeat branding (launcher, notification, web, iOS, macOS, Windows)\n\n- All Android mipmap launcher icons → NasBeat red tree\n- Android adaptive icon: foreground (white/transparent) + black bg\n- New ic_stat_nasbeat notification icon (white on transparent, all densities)\n- Web PWA icons + favicon → NasBeat red tree\n- macOS 7-size icon set → NasBeat\n- iOS full icon set (21 sizes) → NasBeat\n- Windows ICO → NasBeat\n- In-app asset icons → NasBeat\n- audioNotificationIcon → drawable/ic_stat_nasbeat\n- Notification channel name → NasBeat\n- web/manifest.json theme_color #CC0000, bg #000000\n- Theme system: SettingsCubit appTheme field + setAppTheme()\n- main.dart wires NasBeatTheme to MaterialApp.theme',
  tree: newTree.sha,
  parents: [BASE_SHA],
});
if (!newCommit.sha) { console.error('Commit failed:', JSON.stringify(newCommit).slice(0,300)); process.exit(1); }
console.log('  new commit:', newCommit.sha);

console.log('Step 5: Updating main branch ref...');
const refUpdate = await gh('PATCH', '/git/refs/heads/main', { sha: newCommit.sha, force: false });
if (refUpdate.ref) {
  console.log('✅ Successfully pushed to main!');
  console.log('   Ref:', refUpdate.ref);
  console.log('   SHA:', refUpdate.object.sha);
} else {
  console.error('Ref update failed:', JSON.stringify(refUpdate).slice(0,300));
  process.exit(1);
}
