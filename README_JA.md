[[English](/README.md)] [日本語]

# Satellite Cannon

## 元のプラグインとの違い

### リファクタリング

- 新しいSourceModの記法で書き直した
- コードが見やすくなった(多分)

### バグ修正

- リングが閉まっていくエフェクトがBurst delayの設定値と一貫性が無い問題


### 翻訳サポート

- Menu
- Hint text
- Instructor hint

### 新アビリティ

- 多分作る

### より沢山のカスタマイズ項目

以下の設定は個別/全体で設定できます。

- Push force
- Radius
- Cooldown
- Damage
- Max uses
- Burst delay
- Friendly fire
- Ability specific 1 (Like freeze)
- Ability specific 2 (Like freeze)

## CVars

### 全般

- `sm_satellite_enable` - 0:OFF 1:ON
- `sm_satellite_laser_visual_height` - Height of launching point visual laser.
- `sm_satellite_burst_delay` - Launching delay of Satellite cannon. This value is only be used when sm_satellite_burst_delay_global is 1
- `sm_satellite_burst_delay_global` - Toggle global burst delay. When set to 0 it uses individual burst delay based on satellite ammo settings.
- `sm_satellite_push_force` - Push force of Satellite cannon. This value is only be used when sm_satellite_push_force_global is 1
- `sm_satellite_push_force_global` - Toggle global push force. When set to 0 it uses individual push force based on satellite ammo settings.
- `sm_satellite_friendly_fire` - Toggle friendly fire. This value is only be used when sm_satellite_friendly_fire_global is 1
- `sm_satellite_friendly_fire_global` - Toggle global friendly fire. When set to 0 it uses individual push force based on satellite ammo settings.
- `sm_satellite_usage_reset_timing` - When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.

### 個別

全ての個別の設定は `sm_satellite_****_global` が0である場合にのみ使用されます。ただし例外として、アビリティ固有, クールダウン, ダメージは個別に設定する必要があります。

詳細な内容はコンフィグを確認してください。

- `sm_satellite_ammo_****_enable` - Toggles ammo type
- `sm_satellite_ammo_****_damage` - Damage of cannon
- `sm_satellite_ammo_****_radius` - Radius of cannon
- `sm_satellite_ammo_****_limit` - limit of uses
- `sm_satellite_ammo_****_cooldown` - Cooldown per shot
- `sm_satellite_ammo_****_usage_reset_timing` - Reset timing of limit of uses
- `sm_satellite_ammo_****_burst_delay` - Launching delay of cannon
- `sm_satellite_ammo_****_push_force` - Push force of this cannon.
- `sm_satellite_ammo_****_friendly_fire` - 0:OFF 1:ON.

## コマンド

- 無し

## オリジナル

### 作者
- ztar

### Pluginのリンク

https://forums.alliedmods.net/showthread.php?p=1229450


### 作者のウェブサイト

http://ztar.blog7.fc2.com