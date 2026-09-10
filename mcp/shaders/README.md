# Card3D / Sphere3D scripts

Snapshots of the live scripts in the Rive file [shaders](https://editor.rive.app/file/shaders/2565829) (`fileId` `2565829`).

The editor is the source of truth. Edit there via MCP (`text_editor` / `recompile_all_scripts`), then copy back here when you want a git revision.

| File | Role |
| --- | --- |
| [Card3D.luau](Card3D.luau) | Node: rounded box mesh, lighting, foil, face view-model relay |
| [Sphere3D.luau](Sphere3D.luau) | Node: UV sphere; face artboard on the front, cursor look-at |
| [Card3DShader.wgsl](Card3DShader.wgsl) | Shared GPU material (gloss + holographic foil). `params.z` = 0 card / 1 sphere normals |
| [CardShadowShader.wgsl](CardShadowShader.wgsl) | Optional GPU drop-shadow pass (Card3D) |

The 3D card width/height follow the **face** artboard (`face.width` / `face.height`). Sphere radius is `max(width, height) / 2`. The face artboard is mapped onto the **front** of the sphere; the back uses `edgeColor`.
