# `drawCanvas` → `draw`

The runtime logs:

```
drawCanvas is no longer called; move its body into draw
```

Exporting `drawCanvas` on a Node or Layout does nothing. GPU / off-screen work that used to run in that hook must run from `draw`.

## Old two-phase frame

1. Every node `drawCanvas()` — render to GPU canvases, bind groups, post-FX
2. Every node `draw(renderer)` — blit those images into the 2D renderer

## New single phase

One `draw(self, renderer)` per node. Do GPU work first, then blit, in the same function.

## Pattern

Keep a local helper if the body is large; **do not put it on the returned node table**.

```lua
local function drawCanvas(self: MyNode)
	-- GPU scene, bind groups, post-FX, artboard-to-texture, …
end

local function draw(self: MyNode, renderer: Renderer)
	drawCanvas(self)
	-- then blit / drawPath / drawImage
end

return function(): Node<MyNode>
	return {
		init = init,
		update = update,
		advance = advance,
		draw = draw, -- not drawCanvas
	}
end
```

## Call order between nodes

Previously all `drawCanvas` hooks ran before any `draw`. Now each node does prep + blit when *it* is drawn.

If node A’s GPU pass consumes a texture that node B renders in its old `drawCanvas` (e.g. `GlbMaterialController` artboard → `GltfViewport3D` PBR slot), B must draw **before** A, or you get a one-frame lag / empty texture. Internal helpers on the same node are safe: call them at the top of that node’s `draw`.

## Not the same as a module method

`Card3D`’s `deck:drawCanvas(ctx)` is a **Deck method**, not a node hook. Keep it. Call it from the node’s `draw` before `deck:draw(renderer, …)`.
