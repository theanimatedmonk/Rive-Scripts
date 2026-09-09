# Card3D scripts

Snapshots of the live scripts in the Rive file [shaders](https://editor.rive.app/file/shaders/2565829) (`fileId` `2565829`).

The editor is the source of truth. Edit there via MCP (`text_editor` / `recompile_all_scripts`), then copy back here when you want a git revision.

| File | Role |
| --- | --- |
| [Card3D.luau](Card3D.luau) | Node: mesh, lighting, foil, face view-model relay |
| [Card3DShader.wgsl](Card3DShader.wgsl) | GPU material (gloss + holographic foil) |
| [CardShadowShader.wgsl](CardShadowShader.wgsl) | Optional GPU drop-shadow pass |

The 3D card width/height follow the **face** artboard assigned in the node dropdown (`face.width` / `face.height`).
