# Early Access 3D Scripts — fixes

File: [Early Access 3D Scripts](https://editor.rive.app/file/early-access-3d-scripts/2563106)

Applied 2026-09-08. After these, `script_diagnostics` only warned on empty `Shader 1` (no entry points).

## 1. `DOFComposite` vs `postfx/CompositePass`

The WGSL struct had been half-upgraded to a 48-byte depth-aware layout (`focusParams` / `tiltParams` / `texelSize`, `depthTex` at binding 3, sampler at 4). The fragment still read `u.params`, and Lua still wrote a **32-byte** UBO:

| Offset | CPU (`CompositePass.writeUBO`) |
| --- | --- |
| 0 | `apertureCoC`, `tiltStrength`, `tiltCentre`, `tiltSharpness` |
| 16 | `1/w`, `1/h`, unused |

Bindings from Lua: UBO 0, sharp 1, blur 2, sampler 3. No depth texture.

**Fix:** make the shader match the CPU, not the aspirational comments.

```wgsl
struct UBO {
  params:  vec4<f32>,  // x=apertureCoC y=tiltStrength z=tiltCentre w=tiltSharpness
  texSize: vec4<f32>,
}
@group(0) @binding(0) var<uniform> u: UBO;
@group(0) @binding(1) var sharpTex: texture_2d<f32>;
@group(0) @binding(2) var blurTex:  texture_2d<f32>;
@group(0) @binding(3) var samp:     sampler;
```

Keep using `u.params` in the fragment. Do not declare `depthTex` until Lua binds it.

**Learning:** shader UBO size and bind-group slots must match the Lua packer. A “future” layout in comments will fail pipeline creation if the CPU is still on the old contract. `clamp` / `mix` overload errors were cascade from the missing `params` field.

True depth-aware CoC (`|sceneDepth - focusDistance| / focusRange`) is still a future change: `GPURenderer` depth view + extra binding + 48-byte UBO on both sides.

## 2. `PBRShader` `D_GGX`

Naga failed to parse the packed helper:

```wgsl
fn D_GGX(NdH: f32, a: f32) -> f32 {
  let a2 = a*a; let d = NdH*NdH*(a2-1.0)+1.0;
```

**Fix:** rename `a` → `alpha`, one statement per line, spaces around `-`:

```wgsl
fn D_GGX(NdH: f32, alpha: f32) -> f32 {
  let a2 = alpha * alpha;
  let d = NdH * NdH * (a2 - 1.0) + 1.0;
  return a2 / (3.14159265 * d * d + 0.00001);
}
```

**Learning:** avoid two `let`s on one line and tight `ident-1.0` in this WGSL pipeline.

## 3. `MeshLoader` `PropEntry`

```lua
type PropEntry = { t: string, nums: { number }? }
```

`table.insert` of `{ t = "f", nums = nums }` (nums required) into `{PropEntry}` (nums optional) hits Luau’s invariant table check.

**Fix:** cast the two array-valued inserts:

```lua
table.insert(props, { t = "f", nums = nums } :: PropEntry)
table.insert(props, { t = "d", nums = nums } :: PropEntry)
```

## 4. `drawCanvas` on three hosts

See [drawcanvas-to-draw.md](drawcanvas-to-draw.md).

| Script | What moved into `draw` |
| --- | --- |
| `GltfViewport3D` | GPU `renderScene`, env / artboard bind groups, DOF `run()`; then existing blit + dots |
| `CardController` | `deck:drawCanvas(ctx)` before `deck:draw` |
| `GlbMaterialController` | Artboard → Rive canvas → `GlbMat.setArtboardTexView` (this script had no `draw` before) |

Removed `drawCanvas` from the returned node/layout tables. Local helper in `GltfViewport3D` kept the old name.

## Left as-is

- **`Shader 1`** — empty WGSL placeholder; HLSL bake warning only
- **`[GltfViewport3D] No 3D model loaded — using fallback cube`** — runtime print when the GLB blob is missing, not a compile error
