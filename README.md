# NormalHalfIllithidEyes

Toggle normal eyes and illithid veins after partial ceremorphosis (Act 2/3 astral tadpole). Works per character in singleplayer and multiplayer.

## Requirements

- [Baldur's Gate 3 Script Extender](https://github.com/Norbyte/bg3se) (BG3SE)
- All players in a multiplayer session must have this mod and BG3SE installed with matching load order

## Features

- **Toggle Normal Eyes** — spellbook shout to switch between vanilla glowing illithid eyes and your normal eyes
- **Toggle Illithid Veins** — spellbook shout to show or hide illithid vein scars
- **Default after tadpole** — vanilla half-illithid look (glowing eyes + veins) until you cast a toggle
- **Multiplayer-safe** — each player's toggles apply to their own character via `GetMultiplayerCharacter`, not the host
- **Scar menu fix** — character creation / magic mirror retain the full vanilla scar catalog plus illithid vein cosmetics

## Installation

1. Install BG3SE (recommended via BG3 Mod Manager).
2. Pack or symlink this mod into your BG3 `Mods` folder.
3. Enable the mod in BG3 Mod Manager and load after cosmetic frameworks (KAVT, Unique Tav) if you use them.

## Usage

After eating the astral tadpole and gaining `TAD_PARTIAL_CEREMORPH`:

1. Open your spellbook (Common tab).
2. Cast **Toggle Normal Eyes** on yourself to switch eye appearance.
3. Cast **Toggle Illithid Veins** on yourself to show or hide veins.

Spells are granted automatically when the half-illithid transformation is active.

## Testing checklist

### Before testing (Toolkit workflow)

1. **BG3 Script Extender** must be installed (`DWrite.dll` in `bin`).
2. After **Publish Local**, copy the `.pak` to `%LOCALAPPDATA%\\Larian Studios\\Baldur's Gate 3\\Mods\\`.
3. **Enable the mod** in BG3 Mod Manager (or in-game mod settings) and restart the game fully — a `reset` in the SE console is not enough after repacking.
4. In the SE console, type `server` then run the diagnostics below.

### Diagnostics (SE console, server context)

```lua
-- Mod Lua loaded?
_P(Mods and Mods.NormalHalfIllithidEyes)

-- Stats registered?
_P(Ext.Stats.Get("Shout_NHI_ToggleNormalEyes", "SpellData"))
_P(Ext.Stats.Get("NHI_PartialCeremorphWatcher", "PassiveData"))

-- Force-grant spells (if stats exist):
local c = Osi.GetHostCharacter()
Osi.ApplyStatus(c, "TAD_PARTIAL_CEREMORPH", -1, 1, c)
Osi.AddSpell(c, "Shout_NHI_ToggleNormalEyes", 1, 0)
Osi.AddSpell(c, "Shout_NHI_ToggleIllithidVeins", 1, 0)
```

If `Ext.Stats.Get` returns **nil**, the mod stats are not loading — the `.pak` is missing `Public/.../Stats/` files or the mod is not active in load order.

Spells appear in the spellbook under **Common** (scroll down past class spell levels), not in class spell tabs.

### Singleplayer

- [ ] Eat tadpole — default is vanilla glowing eyes + veins
- [ ] Cast Toggle Normal Eyes — eyes become normal, veins unchanged
- [ ] Cast Toggle Illithid Veins — veins hide, eyes unchanged
- [ ] Save/load — toggle state persists
- [ ] Magic mirror — scar tab shows full vanilla list plus mod entries

### Multiplayer (host)

- [ ] Host toggles own character — visuals update correctly
- [ ] Client sees host's updated appearance

### Multiplayer (non-host)

- [ ] Client toggles own character without host intervention
- [ ] Host sees client's updated appearance

## Compatibility

- **Requires BG3SE** — not optional
- Likely incompatible with Valdacil's Half-Illithid Effect Toggle or mods that blank the vanilla half-illithid material override UUID
- Load after mods that override `CharacterCreationAppearanceMaterials.lsx` when possible

## Technical notes

Runtime logic lives in Script Extender Lua (`BootstrapServer.lua` / `BootstrapClient.lua`). Appearance is driven by `AddCustomMaterialOverride` / `RemoveCustomMaterialOverride` with mod-owned `ScriptMaterialOverridePresets` that omit eye parameters for normal-eye modes.
