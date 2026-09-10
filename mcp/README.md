# Rive MCP learnings

Notes from connecting Cursor to the Rive editor MCP.

**Card3D / Sphere3D live copies** are in [shaders/](shaders/). The Rive file [shaders](https://editor.rive.app/file/shaders/2565829) is still the editor source of truth; these files are the git snapshot to read and diff.

| Doc | What it covers |
| --- | --- |
| [shaders/README.md](shaders/README.md) | Card3D / Sphere3D node + WGSL snapshots |
| [rive-mcp-scope.md](rive-mcp-scope.md) | Connection, tools, shaders, and GLTF/3D import limits |
| [debugging-scripts.md](debugging-scripts.md) | How to list scripts, read linter errors, and check the console |
| [drawcanvas-to-draw.md](drawcanvas-to-draw.md) | `drawCanvas` is gone — move GPU work into `draw` |
| [early-access-3d-fixes.md](early-access-3d-fixes.md) | Concrete fixes applied in Early Access 3D Scripts |
| [node-script-viewmodel.md](node-script-viewmodel.md) | Bind a VMI to an artboard cloned inside a node script |
| [../.cursor/skills/rive-node-viewmodel/SKILL.md](../.cursor/skills/rive-node-viewmodel/SKILL.md) | Cursor skill for the same VM-mounting pattern |
