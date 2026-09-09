---
name: rive-node-viewmodel
description: >-
  Bind a Rive view model so triggers and properties run on an artboard cloned
  inside a node script (ScriptedDrawable, face texture, offscreen instance).
  Use when a node does artboard:instance(), VM triggers like twitch do not
  play on the clone, bindViewModelToComponent has no Path picker, or the user
  mentions viewModelProperty, Input<Data.X>, nested VM, or mounting a VMI
  onto a scripted artboard.
---

# Rive node-script view models

A nested artboard on the host can set **Path** to a nested VM and it plays. A node that `face:instance()`s the same artboard does **not**. Mount the host VM, clone with a **private** VM, then relay fields.

Reference implementation: `mcp/shaders/Card3D.luau` in this repo (`boundSource`, `bindViewModel`, `ensureInstance`). Longer notes: [mcp/node-script-viewmodel.md](../../../mcp/node-script-viewmodel.md).

## Editor wiring

1. Bind the **parent** view model on the **host artboard** (e.g. `Card`).
2. Nested artboard placement (if any): Path = nested property (`propertyOfMercari`).
3. Node inputs — do **not** use a typed VM input as the picker:

| Input | Type | Role |
| --- | --- | --- |
| `face` | `Input<Artboard<nil>>` | Artboard to clone |
| `viewModelProperty` | `Input<string>` | Nested VM name on the host VM |
| `properties` | `Input<string>` | Comma-separated fields to relay |

## What fails

| Approach | Result |
| --- | --- |
| `Input<Data.Mercari>` unbound | `property viewModel does not have a valid data context/value` — aborts init unless `pcall`'d |
| `Input<ViewModel>` | No inspector picker |
| `bindViewModelToComponent` on ScriptedDrawable | Rejected: not a component placement |
| `src:instance(sharedVm)` same VMI as nested SM | Nested SM **consumes** triggers; clone never sees them (`advanceAndApply(seconds, false)` skips VM consume) |
| `self._inst = nil` in every `update()` | Clone resets to default pose |
| `getNumber('twitch')` then `.value` | `attempt to index userdata with 'value'` — bind **triggers first** |

## Pattern

```lua
-- Private VM. Do NOT pass the nested artboard's VMI.
local inst = src:instance()
inst.frameOrigin = true
local clone = inst.data

local function from(card: ViewModel?): ViewModel?
  if not card then return nil end
  if path ~= '' then
    local prop = card:getViewModel(path)
    return prop and prop.value
  end
  return card
end

local source = from(ctx:viewModel())
  or from(ctx:rootViewModel())
-- also walk ctx:dataContext() parents: dc:viewModel() / dc:parent()
```

Relay listed names once (`_didWatch` guard):

1. `getTrigger` on both → `src:addListener(self, function() dst:fire(); ctx:markNeedsUpdate() end)`
2. Else copy `.value` for number / boolean / string / color / enum (`pcall` reads and writes)
3. Nested VMs: recurse `getViewModel(name).value`

Recreate the clone **only** when `face` changes. Re-bind listeners when `viewModelProperty` or `properties` change. Do not compare VM userdata identity (proxies are unstable).

Advance:

- Node `advance`: `inst:advance(seconds)`
- Before draw: `inst:advance(0)` so a trigger between ticks still applies

## Swap faces later

1. New artboard + its VM.
2. Nested property on the parent VM (`propertyOfNewFace`).
3. Host still bound to the parent VM.
4. Node: `face` = new artboard, `viewModelProperty` = that name, `properties` = field list.
5. Nested placement Path = the same nested property.

## MCP

`text_editor` / `recompile_all_scripts` hit the **active tab**. Confirm `session_info` before editing. Play once before trusting `read_console`.
