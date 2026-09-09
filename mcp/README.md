# Rive MCP learnings

Notes from connecting Cursor to the Rive editor MCP and debugging the **Early Access 3D Scripts** file.

The scripts themselves live in the Rive cloud file, not in this repo. These docs capture what the MCP can do, what it cannot, and the editor API / shader bugs we hit.

| Doc | What it covers |
| --- | --- |
| [rive-mcp-scope.md](rive-mcp-scope.md) | Connection, tools, shaders, and GLTF/3D import limits |
| [debugging-scripts.md](debugging-scripts.md) | How to list scripts, read linter errors, and check the console |
| [drawcanvas-to-draw.md](drawcanvas-to-draw.md) | `drawCanvas` is gone — move GPU work into `draw` |
| [early-access-3d-fixes.md](early-access-3d-fixes.md) | Concrete fixes applied in Early Access 3D Scripts |
| [node-script-viewmodel.md](node-script-viewmodel.md) | Bind a VMI to an artboard cloned inside a node script |
