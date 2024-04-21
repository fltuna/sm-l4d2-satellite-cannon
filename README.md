[英語] [[日本語](/README_JA.md)]

# Satellite Cannon

## Difference between my fork and original

### Code refactor

- Rewrite with new syntax
- Code is more readable (Maybe)

### Bug fixes

- Ring closing effect is not consistent with burst delay settings

### Translations support

- Menu
- Hint text
- Instructor hint

### New abilities

- Todo

### More customizable

These settings are able to set individually or globally.

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

### Global settings

- `sm_satellite_enable` - 0:OFF 1:ON
- `sm_satellite_laser_visual_height` - Height of launching point visual laser.
- `sm_satellite_burst_delay` - Launching delay of Satellite cannon. This value is only be used when sm_satellite_burst_delay_global is 1
- `sm_satellite_burst_delay_global` - Toggle global burst delay. When set to 0 it uses individual burst delay based on satellite ammo settings.
- `sm_satellite_push_force` - Push force of Satellite cannon. This value is only be used when sm_satellite_push_force_global is 1
- `sm_satellite_push_force_global` - Toggle global push force. When set to 0 it uses individual push force based on satellite ammo settings.
- `sm_satellite_friendly_fire` - Toggle friendly fire. This value is only be used when sm_satellite_friendly_fire_global is 1
- `sm_satellite_friendly_fire_global` - Toggle global friendly fire. When set to 0 it uses individual push force based on satellite ammo settings.
- `sm_satellite_usage_reset_timing` - When ammo will reset. | 1: Round start, 2: Map start, 4: Death | If you want to use multiple timings you can set the combined number. For example Round start and death is 5.

### Individual settings

All of individual settings is are only used when `sm_satellite_****_global` is 0 except ammo specific ,cooldown and damage.

Please see configuration file to what settings available.

- `sm_satellite_ammo_****_enable` - Toggles ammo type
- `sm_satellite_ammo_****_damage` - Damage of cannon
- `sm_satellite_ammo_****_radius` - Radius of cannon
- `sm_satellite_ammo_****_limit` - limit of uses
- `sm_satellite_ammo_****_cooldown` - Cooldown per shot
- `sm_satellite_ammo_****_usage_reset_timing` - Reset timing of limit of uses
- `sm_satellite_ammo_****_burst_delay` - Launching delay of cannon
- `sm_satellite_ammo_****_push_force` - Push force of this cannon.
- `sm_satellite_ammo_****_friendly_fire` - 0:OFF 1:ON.

## Commands

- None

## Original

### Author
- ztar

### Plugin link

https://forums.alliedmods.net/showthread.php?p=1229450


### Author's website

http://ztar.blog7.fc2.com