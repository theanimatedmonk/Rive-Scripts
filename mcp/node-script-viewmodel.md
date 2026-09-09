# Binding a view model to an artboard used in a node script

Skill: [rive-node-viewmodel](../.cursor/skills/rive-node-viewmodel/SKILL.md) (also at `~/.cursor/skills/rive-node-viewmodel/SKILL.md` locally).

File: [shaders](https://editor.rive.app/file/shaders/2565829) — `Card3D` clones **Mercari** as the 3D face. Working code: [shaders/Card3D.luau](shaders/Card3D.luau) (`boundSource`, `bindViewModel`, `ensureInstance`).

A nested artboard on the host can set Path to `Card.propertyOfMercari` and `idle` / `lookDown` / `twitch` play. A scripted drawable that `face:instance()`s the same artboard will **not** pick that up. Mount the host VM, clone with a **private** VM, then relay fields.

## Editor wiring

1. Bind the **parent** view model on the **host artboard** (e.g. `Card`).
2. Nested artboard placement (if any): Path = nested property (`propertyOfMercari`).
3. Node inputs — do **not** use a typed VM input as the picker:

| Input | Type | Role |
| --- | --- | --- |
| `face` | `Input<Artboard<nil>>` | Artboard to clone |
| `viewModelProperty` | `Input<string>` | Nested VM name on the host VM |
| `properties` | `Input<string>` | Comma-separated fields to relay (`idle,lookDown,twitch`) |

Read the source from the host, not from a node VM input:

```lua
local card = ctx:rootViewModel() -- also try ctx:viewModel() and dataContext parents
local prop = card:getViewModel(self.viewModelProperty)
local source = prop and prop.value
```

## What actually works in the inspector

| Placement | Data context |
| --- | --- |
| Host artboard (`Card3D`) | Bind **Card** (the parent VM) |
| Nested artboard (`Mercari`) | Path = `propertyOfMercari` (`bindViewModelToComponent`) |
| Scripted drawable | **No Path picker.** `bindViewModelToComponent` rejects it (`not a component placement`) |

Rive only creates a view-model **dropdown** on a node for a *typed* input: `viewModel: Input<Data.Mercari>`. That becomes `ScriptInputViewModelProperty` and only accepts that VM type.

`Input<ViewModel>` (untyped) does **not** show a picker. Unbound typed VM inputs throw at runtime:

- `property viewModel does not have a valid data context.`
- `property viewModel does not have a valid value set.`

Accessing that input without a bind aborts `ensureInstance` unless it is `pcall`’d — the face then instantiates with a private VM and never sees `twitch`.

## Do not share one VMI with two state machines

`Artboard:instance(vm)` creates an instance with **independent** visual state. The default state machine is bound to `vm`. `inst:advance(seconds)` runs that machine.

The runtime skips view-model consume on script-driven advance (`advanceAndApply(seconds, false)`). The host frame consumes the VMI for the nested artboard’s `NestedStateMachine` first.

So if the clone is created with the **same** `propertyOfMercari` instance the nested artboard uses:

1. You fire `twitch` on Card → propertyOfMercari.
2. The nested SM consumes it and shows the purple square.
3. The script clone never sees the trigger and stays on the default face.

**Fix:** give the clone its own VM, then relay.

```lua
local inst = src:instance()           -- private VM (not the nested artboard's)
local clone = inst.data
source.twitch:addListener(self, function()
  clone:getTrigger('twitch'):fire()
  ctx:markNeedsUpdate()
end)
```

Relay every listed field the same way: triggers `fire()`, numbers/bools/strings/colors/enums copy `.value`. Bind **triggers first**. Calling `getNumber('twitch')` then `.value` throws `attempt to index userdata with 'value'`.

Advance the clone in the node’s `advance`, and `inst:advance(0)` before `inst:draw` so a trigger that lands between ticks still applies.

## Do not recreate the clone every `update`

`update()` runs when any node input changes. This wipes in-flight state (including twitch):

```lua
function update(self)
  self._inst = nil  -- bad: new clone, default pose
  ensureInstance(self)
end
```

Only recreate when `face` changes. Re-attach listeners when `viewModelProperty` / `properties` change. Do not compare VM userdata identity every frame — proxies are not stable.

## Swap in another artboard

1. Create the new artboard and its view model (triggers/numbers as needed).
2. Add a nested VM property on **Card** (e.g. `propertyOfNewFace`).
3. Keep **Card** bound on the host artboard.
4. On the node: `face` = new artboard, `viewModelProperty` = `propertyOfNewFace`, `properties` = that VM’s field names.
5. Nested placement of the new artboard (if any) gets Path = the same nested property.

The node clones `face` with a private VM and relays those fields from Card’s nested instance. The nested placement and the 3D face can both react.

## MCP

`text_editor` / `script_diagnostics` / `recompile_all_scripts` target the **active** tab. If `session_info` shows Early Access 3D Scripts while you meant shaders, you are editing the wrong `Card3D`. After bytecode changes, `recompile_all_scripts` then Play once before trusting `read_console`.
