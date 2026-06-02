// File: animation.mdx

---
title: Animation
---

## Fields

### `duration`

The duration of the animation.


## Methods

### `advance`

Advances the animation by the given time in seconds. Returns true if the
animation hasn't reached its end. If the animation is set to loop or ping
pong, it will always return true


### `setTime`

set the animation time in seconds


### `setTimeFrames`

set the animation time in frames


### `setTimePercentage`

set the animation time as a percentage of the duration




---

// File: artboard.mdx

---
title: Artboard
---

Represents a Rive artboard instance, providing drawing, advancing,
interaction handling, and access to named nodes and data.


## Fields

### `frameOrigin`

If true, the artboard’s origin is treated as the frame origin.


### `data`

The typed data associated with the artboard.


### `width`

The width of the artboard.
```lua
self.artboardInstance = self.myArtboard:instance()
if self.artboardInstance then
   self.artboardInstance.width = 20
end
```


### `height`

The height of the artboard.
```lua
self.artboardInstance = self.myArtboard:instance()
if self.artboardInstance then
   self.artboardInstance.height = 20
end
```


## Methods

### `draw`

Draws the artboard using the provided renderer.


### `advance`

Advances the artboard by the given time in seconds. Returns true if the
artboard should continue receiving advance calls.


### `instance`

Creates a new instance of the artboard with independent state.


### `animation`

Creates an animation instance linked to the artboard instance


### `bounds`

Returns the bounding box of the artboard as two [Vector](/scripting/api-reference/vector) values: the
minimum point and the maximum point.
```lua
local minPt, maxPt = self.myArtboard:bounds()
print("Bounds width", maxPt.x - minPt.x)
print("Bounds height", maxPt.y - minPt.y)
```


### `node`

Returns the node with the given name, or nil if no such node exists.


### `pointerDown`

Pointer event down handler. Each returns a hit-test result, where 0
indicates no hit and non-zero values indicate a hit.


### `pointerUp`

Pointer event up handler. Each returns a hit-test result, where 0
indicates no hit and non-zero values indicate a hit.


### `pointerMove`

Pointer event move handler. Each returns a hit-test result, where 0
indicates no hit and non-zero values indicate a hit.


### `pointerExit`

Pointer event exit handler. Each returns a hit-test result, where 0
indicates no hit and non-zero values indicate a hit.


### `addToPath`

Adds the artboard’s geometry to the given path, optionally transformed
by the provided matrix.




---

// File: blend-mode.mdx

---
title: BlendMode
---

Defines how the paint’s color or gradient is composited with the content
behind it.
* `srcOver`
* `screen`
* `overlay`
* `darken`
* `lighten`
* `colorDodge`
* `colorBurn`
* `hardLight`
* `softLight`
* `difference`
* `exclusion`
* `multiply`
* `hue`
* `saturation`
* `color`
* `luminosity`




---

// File: color.mdx

---
title: Color
---

## Constructors

### `lerp`

Linearly interpolates between two colors using the parameter t, where
t = 0 returns 'from' and t = 1 returns 'to'.
```lua
self.color = Color.lerp(color1, color2, t)
```


### `rgb`

Returns a color constructed from red, green, and blue channels. Alpha
defaults to 255 (fully opaque). Channel values are clamped to [0, 255].
```lua
-- Red
self.color = Color.rgb(255, 0, 0)
```


### `rgba`

Returns a color constructed from red, green, blue, and alpha channels.
Channel values are clamped to [0, 255].
```lua
-- Red at 50% opacity
self.color = Color.rgba(255, 0, 0, 128)
```


## Static Functions

### `red`

Returns the red channel of the color. If a value is
provided, returns a new color with that channel updated.
```lua
print("Red:", Color.red(myColor))
```


### `green`

Returns the green channel of the color. If a value is
provided, returns a new color with that channel updated.
```lua
print("Green:", Color.green(myColor))
```


### `blue`

Returns the blue channel of the color. If a value is
provided, returns a new color with that channel updated.
```lua
print("Blue:", Color.blue(myColor))
```


### `alpha`

Returns the alpha channel of the color, or returns a new color with the
alpha channel set to the specified value. Values are clamped to [0, 255].
```lua
print("Alpha:", Color.alpha(myColor))
```


### `opacity`

Returns the opacity of the color as a normalized value in the range
[0.0, 1.0], or returns a new color with its alpha set from the specified
opacity.
```lua
print("Opacity:", Color.opacity(myColor))
```




---

// File: command-type.mdx

---
title: CommandType
---

Describes the type of drawing command stored in a [PathCommand](/scripting/api-reference/path-command).

- `none` – Placeholder command with no effect. You should not normally see this.
- `moveTo`
- `lineTo`
- `cubicTo`
- `quadTo`
- `close`




---

// File: context.mdx

---
title: Context
---

Provides access to update scheduling for scripted objects.


## Methods

### `markNeedsUpdate`

Provides access to update scheduling for scripted objects.
Marks the object as needing an update on the next frame.


### `viewModel`

Returns the context view model




---

// File: contour-measure.mdx

---
title: ContourMeasure
---

## Fields

### `next`

Returns the next [ContourMeasure](/scripting/api-reference/contour-measure) in the path, or nil if this is the last
contour. Use this to iterate through all contours in a path after calling
path:contours().




---

// File: converter.mdx

---
title: Converter
---

A scripted converter used for transforming values between ViewModel data
bindings and Rive properties.

Type parameters:
T: The converter type
I: The input type, must be a DataValue type
(DataValueNumber, DataValueString, DataValueBoolean, DataValueColor, etc)
O: The output type, must be a DataValue type
(DataValueNumber, DataValueString, DataValueBoolean, DataValueColor, etc)

See [Converter Scripts](/scripting/protocols/converter-scripts).


## Methods

### `init`

Called once when the converter is created. Returns true if initialization
succeeds.


### `convert`

Converts the input value (a view model property) to an output value.
The input parameter must be a DataValue type.


### `reverseConvert`

Converts the output value back to an input value (a view model property).
The input parameter must be a DataValue type.


### `advance`

Optional per-frame update. Returns true if the converter should continue
receiving advance calls.




---

// File: converter-scripts.mdx

---
title: "Converter Scripts"
description: "Create custom converters using Rive scripting"
---

import { Demos } from '/snippets/demos.jsx'

Rive includes several built-in converters like **Convert to String** and **Round**.
Scripting lets you create your own custom converters when you need behavior that isn’t covered by the built-ins.

For background on converters and data binding, see [Data Converters](/editor/data-binding/overview#converter).

## Examples

<Demos
  examples={[
    "scriptingTippingConverter",
  ]}
/>

## Creating a Converter

[Create a new script](/scripting/creating-scripts) and select **Converter** as the type.

## Anatomy of a Converter Script

```lua
type MyConverter = {}

-- Called once when the script initializes.
function init(self: MyConverter): boolean
  return true
end

-- Converts the property value.
function convert(self: MyConverter, input: DataInputs): DataOutput
  local dv: DataValueNumber = DataValue.number()

  if input:isNumber() then
    dv.value = (input :: DataValueNumber).value + 1
  else
    dv.value = 0 -- 0 if input is not a number
  end

  return dv
end

-- For 2-way data binding, converts the target value back to the source
function reverseConvert(self: MyConverter, input: DataOutput): DataInputs
  local dv: DataValueNumber = DataValue.number()

  if input:isNumber() then
    -- Example: Subtract 1 from the target number
    dv.value = (input :: DataValueNumber).value - 1
  else
    dv.value = 0 -- 0 if target is not a number
  end

  return dv
end

-- Return a factory function that builds the converter instance.
-- Rive calls this when the script is created, passing back a table
-- containing its lifecycle functions and any default values.
return function(): Converter<MyConverter, DataValueNumber, DataValueNumber>
  return {
    init = init,
    convert = convert,
    reverseConvert = reverseConvert,
  }
end
```


## Creating a Converter using your Script

Create a new converter using your new converter script:

1. In the Data panel, click the `+` button.
2. Choose **Converters → Script → MyConverter**.


![Create converter with a script](/images/scripting/create-converter-with-script.png)


## Adding Inputs

See [Script Inputs](/scripting/script-inputs).

---

// File: creating-scripts.mdx

---
title: "Creating Scripts"
description: ""
---

There are two ways to create a new script, from the Assets Panel and with the Scripting tool.

### Creating a Script from the Assets Panel

1. In the Assets Panel, click the `+` button.
2. Choose **Script** and select the [type of script](/scripting/protocols) you'd like to create.

![Create Script from Assets Panel](/images/scripting/assets-panel-create-script.png)

### Creating a Script with the Scripts Tool

1. Select the dropdown icon next to the Script button in the Toolbar
2. Select the [type of script](/scripting/protocols) you'd like to create.

![Create Script from Assets Panel](/images/scripting/script-tool-create-script.png)

New scripts are saved as Assets and can be found in the Assets Panel.

<Tip>
Use **PascalCase** for script names and update the script’s type name accordingly.

Example: If the script is named `MyConverter`, the main type should also be named `MyConverter`.
</Tip>

## Adding Scripts to Your Scene

To run [Node](/scripting/protocols/node-scripts) and [Layout](/scripting/protocols/layout-scripts) scripts, they need to be added to the scene.

1. Right-click the artboard you'd like to add your script to and select your script from the menu
2. Position the script object, keeping in mind that the script's position will determine where it's rendered
3. Select the group to set inputs (See [Script Inputs](/scripting/script-inputs))

![Create Script from Assets Panel](/images/scripting/add-script-to-artboard.gif)

<Tip>
**Troubleshooting: If you don't see your script in the list:**

1. Make sure your script is in the Assets Panel.
2. Check the [Problems Panel](/scripting/debugging/debug-panel#problems) for issues.
3. Make sure your script returns a function that returns a table with at least an `init` and `draw` function.
</Tip>


---

// File: data-binding.mdx

---
title: "Data Binding"
description: ""
---

Scripting allows you to read, modify, and subscribe to changes in View Model properties,
as well as create new View Model instances at runtime.

<Info>
For a conceptual overview of View Models and how they drive your graphic,
see [View Models & Data Binding](/editor/data-binding/overview).
</Info>

There are three main ways a script can interact with View Model properties:

### Accessing the Main View Model

All lifecycle functions (`init`, `advance`, `convert`, etc.) include a `context` parameter that gives you access
to the View Model that is attached to the main artboard. This allows you to read values (strings, enums, lists, etc.), set values,
fire triggers, listen for triggers, and subscribe to value changes.

<Note>
  In this context the "main" artboard refers to the topmost artboard being played.
</Note>

This is the most common approach, and is ideal when your script is intended to operate on the primary data model of the file.

```lua {8-16,19,20}
type AlarmClock = {}

function handleHoursChanged()
  print('hours changed!')
end

function init(self: AlarmClock, context: Context): boolean
  -- Make a reference to the main view model
  local vm = context:viewModel()

  -- Get properties from the main view model
  local hours = vm:getNumber('hours')

  -- Access properties on a nested view model
  local dateVM = vm:getViewModel('dateViewModel')
  local date = dateVM:getString('formattedDate')

  if hours then
    print(hours.value)
    -- handleHoursChanged is called whenever the hours value changes
    hours:addListener(handleHoursChanged)
  end

  return true
end

return function(): Node<AlarmClock>
  return {
    init = init,
  }
end
```

## View Models as Inputs

See [View Model Inputs](/scripting/script-inputs#view-model-inputs)

## Binding Inputs

See [Data Binding Inputs](/scripting/script-inputs#data-binding-inputs)


## Creating a View Model Instance

Coming soon

---

// File: data-value.mdx

---
title: DataValue
---

Base type for values that can be stored in inputs. Provides
functions for checking the underlying value type.


## Static Functions

### `number`

Constructors for [DataValue](/scripting/api-reference/data-value) types. Each function returns a mutable
DataValue container of the corresponding underlying type.
Creates a [DataValueNumber](/scripting/api-reference/data-value-number) that stores a number.


### `string`

Creates a [DataValueString](/scripting/api-reference/data-value-string) that stores a string.


### `boolean`

Creates a [DataValueBoolean](/scripting/api-reference/data-value-boolean) that stores a boolean.


### `color`

Creates a [DataValueColor](/scripting/api-reference/data-value-color) that stores a [Color](/scripting/api-reference/color).


## Methods

### `isNumber`

Base type for values that can be stored in inputs. Provides
functions for checking the underlying value type.
Returns true if the value is a number.
```lua
local dv: DataValueNumber = DataValue.number()
print(dv.isNumber) -- true
```


### `isString`

Returns true if the value is a string.
```lua
local dv: DataValueNumber = DataValue.number()
print(dv.isString) -- false
```


### `isBoolean`

Returns true if the value is a boolean.
```lua
local dv: DataValueNumber = DataValue.number()
print(dv.isBoolean) -- false
```


### `isColor`

Returns true if the value is a color.
```lua
local dv: DataValueNumber = DataValue.number()
print(dv.isColor) -- false
```




---

// File: data-value-boolean.mdx

---
title: DataValueBoolean
---

[DataValue](/scripting/api-reference/data-value) that stores a boolean value.
```lua
local dv: DataValueBoolean = DataValue.boolean()
dv.value = false
```


## Fields

### `value`

[DataValue](/scripting/api-reference/data-value) that stores a boolean value.
```lua
local dv: DataValueBoolean = DataValue.boolean()
dv.value = false
```




---

// File: data-value-color.mdx

---
title: DataValueColor
---

[DataValue](/scripting/api-reference/data-value) that stores a color value encoded as a number, with
red, green, blue, and alpha components.
```lua
local dv: DataValueColor = DataValue.color()
dv.value = Color.rgba(255, 0, 0, 155)
```


## Fields

### `value`

[DataValue](/scripting/api-reference/data-value) that stores a color value encoded as a number, with
red, green, blue, and alpha components.
```lua
local dv: DataValueColor = DataValue.color()
dv.value = Color.rgba(255, 0, 0, 155)
```
The full color value encoded as a number.


### `red`

Color components in the range [0, 255].


### `green`

Color components in the range [0, 255].


### `blue`

Color components in the range [0, 255].


### `alpha`

Alpha component in the range [0, 255].




---

// File: data-value-number.mdx

---
title: DataValueNumber
---

[DataValue](/scripting/api-reference/data-value) that stores a number value.
```lua
local dv: DataValueNumber = DataValue.number()
dv.value = 200
```


## Fields

### `value`

[DataValue](/scripting/api-reference/data-value) that stores a number value.
```lua
local dv: DataValueNumber = DataValue.number()
dv.value = 200
```




---

// File: data-value-string.mdx

---
title: DataValueString
---

[DataValue](/scripting/api-reference/data-value) that stores a string value.
```lua
local dv: DataValueString = DataValue.string()
dv.value = "I heart Rive."
```


## Fields

### `value`

[DataValue](/scripting/api-reference/data-value) that stores a string value.
```lua
local dv: DataValueString = DataValue.string()
dv.value = "I heart Rive."
```




---

// File: debug-panel.mdx

---
title: "Debug Panel"
description: ""
---

The Debug Panel lets you inspect script output and detect issues
in your code.

## Toolbar

Switch between [Console](#console) and [Problems](#problems) using the tabs to the left of the panel. Use the icons at the right end of the panel to open and close the panel and toggle fullscreen mode. Additional options to copy and clear the console show up when the Console tab is active.

![Debug panel toolbar](/images/scripting/debugging/debug-panel-toolbar.png)


## Console

The Console shows all log output from your scripts during playback. You can use the standard [Luau print()](https://create.roblox.com/docs/reference/engine/globals/LuaGlobals#print) function to log information, variable values, and messages.

```lua
print("Rive is so cool!")
print("Elapsed time:", seconds)
```

![Debug panel toolbar](/images/scripting/debugging/console-print.png)

## Problems

The Problems tab lists problems detected _before_ the script runs such as type mismatches, syntax errors, or missing data bindings.

The tab badge shows the number of issues found across your scripts.

Clicking a problem will jump directly to the affected line of code.
You can also hover any underlined code in the editor to see an explanation or suggested fix.

![Problems panel](/images/scripting/debugging/problems-panel.png)

---

// File: demos.mdx

---
title: "Scripting Demos"
sidebarTitle: "Demos"
description: ""
mode: 'wide'
---

import { Demos } from '/snippets/demos.jsx'

<Demos
  examples={[
    "scriptingPlinko",
    "scriptingSlotMachine",
    "scriptingSnakeGame",
    "scriptingBoilPathEffect",
    "scriptingTextPathEffect",
    "scriptingDrawingShapes",
    "scriptingTippingConverter",
    "scriptingMasonry",
    "scriptingUnitTesting",
    "scriptingMultiTouch",
    "scriptingNestedPointers",
  ]}
  columns={3}
/>


---

// File: enum-values.mdx

---
title: EnumValues
---

## Methods

### `__len`



---

// File: getting-started.mdx

---
title: "Getting Started"
description: "Code, animation, and interaction all in one Editor."
---

import { Demos } from '/snippets/demos.jsx'
import { YouTube } from '/snippets/youtube.mdx'

Scripting lets you iterate on code, design, and animation in one collaborative editor.

## Quick Start

This video introduces the basics of writing and using scripts in Rive. You’ll learn how to create different types of scripts and how they connect to data bindings and artboards, and how you can create scripts with the [AI Agent](/editor/ai-agent).

<YouTube id="M6kGkR-7JTE" />

## Fundamentals

- [Why Luau](https://rive.app/blog/why-scripting-runs-on-luau) - Why Scripting runs on Luau
- [Creating Scripts](/scripting/creating-scripts) - Creating a new script
- [Protocols](/scripting/protocols) - The type of scripts you can create
- [Inputs](/scripting/script-inputs) - Connecting scripts to inputs and data
- [Debugging](/scripting/debugging/debug-panel) - Debugging your scripts
- [AI Agent](/editor/ai-agent) - Using AI to create and modify scripts


---

// File: gradient.mdx

---
title: Gradient
---

Represents a gradient used for filling or stroking a shape. A gradient is
defined by a set of color stops ([GradientStop](/scripting/api-reference/gradient-stop)) and either a linear or radial configuration.


## Constructors

### `linear`

Creates a linear gradient that transitions between the specified color
stops along the line from 'from' to 'to'.

```lua
local g = Gradient.linear(Vector.xy(0, 0), Vector.xy(100, 0), {
  { position = 0, color = Color.rgb(255, 0, 0) },
  { position = 1, color = Color.rgb(0, 0, 255) },
})
```


### `radial`

Creates a radial gradient centered at 'from', extending outward to the
given radius, using the specified color stops.

```lua
local g = Gradient.radial(Vector.xy(50, 50), 40, {
  { position = 0, color = Color.white },
  { position = 1, color = Color.black },
})
```




---

// File: gradient-stop.mdx

---
title: GradientStop
---

A color stop in a [Gradient](/scripting/api-reference/gradient), defined by its position in the range [0, 1] and
the color at that position.


## Fields

### `position`

A color stop in a [Gradient](/scripting/api-reference/gradient), defined by its position in the range [0, 1] and
the color at that position.
Position of the stop along the gradient, where 0 is the start and 1 is
the end.


### `color`

[Color](/scripting/api-reference/color) at the specified position.




---

// File: image.mdx

---
title: Image
---

Represents an image asset that can be drawn by the [Renderer](/scripting/api-reference/renderer).


## Fields

### `width`

Represents an image asset that can be drawn by the [Renderer](/scripting/api-reference/renderer).
Width of the image.


### `height`

Height of the image.




---

// File: image-filter.mdx

---
title: ImageFilter
---

Defines how image sampling is performed when scaling or transforming the
image.
* `trilinear`
* `nearest`




---

// File: image-sampler.mdx

---
title: ImageSampler
---

Represents sampling parameters applied when drawing an image, including
wrapping and filtering behaviour.




---

// File: image-wrap.mdx

---
title: ImageWrap
---

Defines how texture coordinates outside the [0, 1] range are handled.
* `clamp`
* `repeat`
* `mirror`




---

// File: input.mdx

---
title: Input
---

Represents a typed input value.




---

// File: keyboard-shortcuts.mdx

---
title: "Keyboard Shortcuts"
description: "A comprehensive reference for all keyboard shortcuts in the Rive script editor."
---

## Basic Editing

| Command                 | macOS                                           | Windows/Linux                        |
| ----------------------- | ----------------------------------------------- | ------------------------------------ |
| **Undo**                | <kbd>⌘</kbd> + <kbd>Z</kbd>                     | <kbd>Ctrl</kbd> + <kbd>Z</kbd>       |
| **Redo**                | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>Z</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Z</kbd> |
| **Copy**                | <kbd>⌘</kbd> + <kbd>C</kbd>                     | <kbd>Ctrl</kbd> + <kbd>C</kbd>       |
| **Cut**                 | <kbd>⌘</kbd> + <kbd>X</kbd>                     | <kbd>Ctrl</kbd> + <kbd>X</kbd>       |
| **Paste**               | <kbd>⌘</kbd> + <kbd>V</kbd>                     | <kbd>Ctrl</kbd> + <kbd>V</kbd>       |
| **Save**                | <kbd>⌘</kbd> + <kbd>S</kbd>                     | <kbd>Ctrl</kbd> + <kbd>S</kbd>       |
| **Select All**          | <kbd>⌘</kbd> + <kbd>A</kbd>                     | <kbd>Ctrl</kbd> + <kbd>A</kbd>       |
| **Indent**              | <kbd>Tab</kbd>                                  | <kbd>Tab</kbd>                       |
| **Outdent**             | <kbd>⇧</kbd> + <kbd>Tab</kbd>                   | <kbd>Shift</kbd> + <kbd>Tab</kbd>    |
| **Format File**         | <kbd>F4</kbd>                                   | <kbd>F4</kbd>                        |

## Cursor Movement

| Command                     | macOS                                              | Windows/Linux                              |
| --------------------------- | -------------------------------------------------- | ------------------------------------------ |
| **Move by Character**       | <kbd>←</kbd>/<kbd>→</kbd>                          | <kbd>←</kbd>/<kbd>→</kbd>                  |
| **Move by Line**            | <kbd>↑</kbd>/<kbd>↓</kbd>                          | <kbd>↑</kbd>/<kbd>↓</kbd>                  |
| **Move by Word**            | <kbd>⌥</kbd> + <kbd>←</kbd>/<kbd>→</kbd>           | <kbd>Alt</kbd> + <kbd>←</kbd>/<kbd>→</kbd> |
| **Move by Subword**         | <kbd>⌃</kbd> + <kbd>⌥</kbd> + <kbd>←</kbd>/<kbd>→</kbd> | —                                     |
| **Move to Line Start/End**  | <kbd>⌘</kbd> + <kbd>←</kbd>/<kbd>→</kbd>           | <kbd>Ctrl</kbd> + <kbd>←</kbd>/<kbd>→</kbd> |
| **Move to Document Start/End** | <kbd>⌘</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd>        | <kbd>Ctrl</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd> |

## Selection

All cursor movement commands can be combined with <kbd>⇧</kbd> (Shift) to extend the selection:

| Command                          | macOS                                                   | Windows/Linux                                       |
| -------------------------------- | ------------------------------------------------------- | --------------------------------------------------- |
| **Select by Character**          | <kbd>⇧</kbd> + <kbd>←</kbd>/<kbd>→</kbd>                | <kbd>Shift</kbd> + <kbd>←</kbd>/<kbd>→</kbd>        |
| **Select by Line**               | <kbd>⇧</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd>                | <kbd>Shift</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd>        |
| **Select by Word**               | <kbd>⇧</kbd> + <kbd>⌥</kbd> + <kbd>←</kbd>/<kbd>→</kbd> | <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>←</kbd>/<kbd>→</kbd> |
| **Select to Line Start/End**     | <kbd>⇧</kbd> + <kbd>⌘</kbd> + <kbd>←</kbd>/<kbd>→</kbd> | <kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>←</kbd>/<kbd>→</kbd> |
| **Select to Document Start/End** | <kbd>⇧</kbd> + <kbd>⌘</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd> | <kbd>Shift</kbd> + <kbd>Ctrl</kbd> + <kbd>↑</kbd>/<kbd>↓</kbd> |

## Line Operations

| Command                 | macOS                                           | Windows/Linux                                    |
| ----------------------- | ----------------------------------------------- | ------------------------------------------------ |
| **Toggle Comment**      | <kbd>⌘</kbd> + <kbd>/</kbd>                     | <kbd>Ctrl</kbd> + <kbd>/</kbd>                   |
| **Insert Line Below**   | <kbd>⌘</kbd> + <kbd>↩</kbd>                     | <kbd>Ctrl</kbd> + <kbd>Enter</kbd>               |
| **Insert Line Above**   | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>↩</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Enter</kbd> |
| **Move Line(s) Up**     | <kbd>⌥</kbd> + <kbd>↑</kbd>                     | <kbd>Alt</kbd> + <kbd>↑</kbd>                    |
| **Move Line(s) Down**   | <kbd>⌥</kbd> + <kbd>↓</kbd>                     | <kbd>Alt</kbd> + <kbd>↓</kbd>                    |
| **Duplicate Line Up**   | <kbd>⇧</kbd> + <kbd>⌥</kbd> + <kbd>↑</kbd>      | <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>↑</kbd> |
| **Duplicate Line Down** | <kbd>⇧</kbd> + <kbd>⌥</kbd> + <kbd>↓</kbd>      | <kbd>Shift</kbd> + <kbd>Alt</kbd> + <kbd>↓</kbd> |

## Multi-Cursor Editing

| Command                      | macOS                                    | Windows/Linux                         |
| ---------------------------- | ---------------------------------------- | ------------------------------------- |
| **Add Cursor**               | <kbd>⌥</kbd> + Click                     | <kbd>Alt</kbd> + Click                |
| **Select Next Occurrence**   | <kbd>⌘</kbd> + <kbd>D</kbd>              | <kbd>Ctrl</kbd> + <kbd>D</kbd>        |
| **Collapse to Single Cursor**| <kbd>Esc</kbd>                           | <kbd>Esc</kbd>                        |

## Search and Replace

| Command                 | macOS                                           | Windows/Linux                                    |
| ----------------------- | ----------------------------------------------- | ------------------------------------------------ |
| **Find**                | <kbd>⌘</kbd> + <kbd>F</kbd>                     | <kbd>Ctrl</kbd> + <kbd>F</kbd>                   |
| **Find in Files**       | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>F</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>F</kbd> |
| **Find Next**           | <kbd>⌘</kbd> + <kbd>G</kbd> or <kbd>↩</kbd>     | <kbd>Ctrl</kbd> + <kbd>G</kbd> or <kbd>Enter</kbd> |
| **Find Previous**       | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>G</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>G</kbd> |
| **Close Search**        | <kbd>Esc</kbd>                                  | <kbd>Esc</kbd>                                   |

The search panel includes toggle buttons for:
- **Match Case**: Toggle case-sensitive search
- **Whole Word**: Toggle whole word matching
- **Regex**: Toggle regular expression mode

## Code Navigation

| Command                 | macOS                                           | Windows/Linux                        |
| ----------------------- | ----------------------------------------------- | ------------------------------------ |
| **Go to Definition**    | <kbd>⌘</kbd> + Click                            | <kbd>Ctrl</kbd> + Click              |
| **File Palette**        | <kbd>⌘</kbd> + <kbd>P</kbd>                     | <kbd>Ctrl</kbd> + <kbd>P</kbd>       |
| **Command Palette**     | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>P</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>P</kbd> |
| **Global Search**       | <kbd>⌘</kbd> + <kbd>K</kbd>                     | <kbd>Ctrl</kbd> + <kbd>K</kbd>       |

## File and Tab Management

| Command                     | macOS                                           | Windows/Linux                                    |
| --------------------------- | ----------------------------------------------- | ------------------------------------------------ |
| **Close Tab**               | <kbd>⌘</kbd> + <kbd>W</kbd>                     | <kbd>Ctrl</kbd> + <kbd>W</kbd>                   |
| **Previous Tab**            | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>[</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>[</kbd> |
| **Next Tab**                | <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>]</kbd>      | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>]</kbd> |
| **Tab Palette Forward**     | <kbd>⌃</kbd> + <kbd>Tab</kbd>                   | <kbd>Ctrl</kbd> + <kbd>Tab</kbd>                 |
| **Tab Palette Backward**    | <kbd>⌃</kbd> + <kbd>⇧</kbd> + <kbd>Tab</kbd>    | <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>Tab</kbd> |

## Autocomplete

| Command                 | macOS                                           | Windows/Linux                        |
| ----------------------- | ----------------------------------------------- | ------------------------------------ |
| **Previous Suggestion** | <kbd>↑</kbd>                                    | <kbd>↑</kbd>                         |
| **Next Suggestion**     | <kbd>↓</kbd>                                    | <kbd>↓</kbd>                         |
| **Accept Suggestion**   | <kbd>↩</kbd> or <kbd>Tab</kbd>                  | <kbd>Enter</kbd> or <kbd>Tab</kbd>   |
| **Dismiss**             | <kbd>Esc</kbd>                                  | <kbd>Esc</kbd>                       |

## Mouse Actions

| Action                      | Description                                          |
| --------------------------- | ---------------------------------------------------- |
| Click                       | Place cursor at click position                       |
| Double-click                | Select the word at click position                    |
| Click in gutter             | Select entire line                                   |
| <kbd>⇧</kbd> + Click        | Extend selection to click position                   |
| <kbd>⌥</kbd> + Click        | Add additional cursor at click position              |
| <kbd>⌘</kbd> + Hover        | Show definition preview for symbol under cursor      |
| <kbd>⌘</kbd> + Click        | Go to definition of symbol under cursor              |
| Click and drag              | Select text by dragging                              |
| Click and drag in gutter    | Select multiple lines                                |

## Auto-Closing Pairs

The editor automatically inserts closing characters for:

| Opening | Closing | Notes                                |
| ------- | ------- | ------------------------------------ |
| `{`     | `}`     | Curly braces                         |
| `[`     | `]`     | Square brackets                      |
| `(`     | `)`     | Parentheses                          |
| `"`     | `"`     | Double quotes (not inside strings)   |
| `'`     | `'`     | Single quotes (not inside strings)   |
| `` ` `` | `` ` `` | Backticks (not inside strings)       |

## Surrounding Selection

When text is selected, typing an opening character wraps the selection:

| Type    | Selection becomes  |
| ------- | ------------------ |
| `{`     | `{selection}`      |
| `[`     | `[selection]`      |
| `(`     | `(selection)`      |
| `"`     | `"selection"`      |
| `'`     | `'selection'`      |
| `` ` `` | `` `selection` ``  |
| `<`     | `<selection>`      |

## Auto-Completion for Luau Blocks

When pressing <kbd>↩</kbd> (Enter) after certain keywords, the editor auto-completes the block structure:

| After typing... | Auto-inserts          |
| --------------- | --------------------- |
| `function`      | `end` on new line     |
| `do`            | `end` on new line     |
| `then`          | `end` on new line     |
| `else`          | `end` on new line     |
| `repeat`        | `until false` on new line |

## Smart Indentation

- Pressing <kbd>↩</kbd> (Enter) automatically maintains the current indentation level
- After opening keywords (`function`, `do`, `then`, `else`, `repeat`, `{`), the next line is indented
- <kbd>⌫</kbd> (Backspace) in the indent region removes a full tab (2 spaces) at a time
- <kbd>⌘</kbd> + <kbd>←</kbd> (Home) toggles between column 0 and the first non-whitespace character
- Indentation uses 2 spaces (soft tabs)
- Line comments use `--` (Luau style)

## Diff Mode

When viewing AI-generated changes:

| Action              | Description                               |
| ------------------- | ----------------------------------------- |
| Hover over chunk    | Shows accept/reject buttons               |
| Accept button       | Accept the changes in this chunk          |
| Reject button       | Reject the changes and restore original   |
| Accept All          | Accept all pending changes                |
| Reject All          | Reject all pending changes                |


---

// File: layout.mdx

---
title: Layout
---

A scripted Layout which can function just like a [Node](/scripting/api-reference/node) but
also has the ability to fit into a layout box provided via
resize. It can also be intrinsically sized allowing hosting
layouts to attempt to fit to its size by using the measure
function to report desired dimensions.

See [Layout Scripts](/scripting/protocols/layout-scripts).


## Methods

### `measure`

When provided this Layout can be intrinsically sized/request
to be a specific size. This is not guaranteed as the layout
may have min/max dimensions. Resize will be called with the
granted size after being measured.


### `resize`

Guaranteed to be called to set initial size and also called
whenever the size changes.




---

// File: layout-scripts.mdx

---
title: "Layout Scripts"
description: ""
---

import { Demos } from '/snippets/demos.jsx'

Layout Scripts extend the behavior of [Node Scripts](/scripting/protocols/node-scripts), giving you programmatic control over Layout components. They let you measure, size, and react to changes in your Layout’s geometry. They are ideal for building custom layout behaviors such as masonry grids, carousels, spacing logic, and more.



## Examples

<Demos
  examples={[
    "scriptingMasonry",
    "scriptingPlinko"
  ]}
/>

## Adding a Layout Script to a Layout

1. Add a new [Layout](/editor/layouts/layouts-overview) to the scene.
2. [Create a new script](/scripting/creating-scripts) and select **Layout** as the type.
3. Add your script as a child of the Layout.

## Lifecycle

Layout Scripts add two additional lifecycle functions:

- `measure(self): Vec2D` — optional
- `resize(self, size: Vec2D)` — required

### Measure

Measure lets your script propose an ideal size for the layout.
Rive will use this value unless a Fit rule overrides it.

Measure only has an effect on layouts with a Fit type of Hug.

```lua
function measure(self: MyLayout): Vec2D
  -- Always declare that this layout would like to be 100×100
  return Vec2D.xy(100, 100)
end
```

### Resize

Resize runs whenever the Layout receives a new size from its parent or from your measure function.
This is where you position or update child nodes, recalculate flow, or react to container changes.

```lua
-- Called whenever the Layout is resized.
function resize(self: MyLayout, size: Vec2D)
  print("New size:")
  print("x:", size.x)
  print("y:", size.y)
end
```







---

// File: listener.mdx

---
title: Listener
---

Represents a listener callback that can observe changes on an object.




---

// File: listener-action.mdx

---
title: ListenerAction
---

An action performed when a listener is triggered


## Methods

### `init`

Called once when the listener is created or attached.


### `perform`

Called any time a listener is triggered.




---

// File: mat2d.mdx

---
title: Mat2D
---

Represents a 2D transformation matrix with components for scaling,
rotation, shear, and translation.


## Fields

### `xx`

Represents a 2D transformation matrix with components for scaling,
rotation, shear, and translation.
The xx component of the matrix.


### `xy`

The xy component of the matrix.


### `yx`

The yx component of the matrix.


### `yy`

The yy component of the matrix.


### `tx`

Translation along the x-axis.


### `ty`

Translation along the y-axis.


### `withTranslation`

Creates a translation matrix from the given x and y values or from a
[Vector](/scripting/api-reference/vector) position.


### `withScale`

Creates a scale matrix from the given x and y values or from a [Vector](/scripting/api-reference/vector).


### `withScaleAndTranslation`

Creates a scale-and-translation matrix from numeric values or vectors.


## Constructors

### `values`

Creates a matrix using the specified components.


### `identity`

Returns the identity matrix.


### `withRotation`

Creates a rotation matrix from the given angle in radians.


## Methods

### `invert`

Provides indexed access to the matrix components.
Returns the inverse of the matrix, or nil if the matrix is not invertible.


### `isIdentity`

Returns true if the matrix is the identity transform.


### `__eq`

Returns true if all components of the two matrices are equal.


### `__mul`

Transforms the given vector by the matrix and returns the result.


### `__mul`

Returns the matrix product of this matrix and the given matrix




---

// File: node.mdx

---
title: Node
---

A scripted node that can be attached to any Node. The node is rendered
in the local transform space of the hosting Node.

See [Node Scripts](/scripting/protocols/node-scripts).


## Methods

### `init`

Called once when the node is created. Returns true if initialization
succeeds.


### `advance`

Optional per-frame update. Returns true if the node should continue
receiving advance calls.


### `update`

Called when an input value changes.


### `draw`

Called to render the node using the provided renderer.


### `pointerDown`

Pointer event down handler.

```lua
function handlePointerDown(self: MyGame, event: PointerEvent)
  print('Pointer Position: ', event.position.x, event.position.y)

  event:hit()
end

return function(): Node<MyGame>
    return {
        init = init,
        advance = advance,
        draw = draw,
        pointerDown = handlePointerDown,
    }
end
```


### `pointerMove`

Pointer event move handler.

```lua
function handlePointerMove(self: MyGame, event: PointerEvent)
  print('Pointer Position: ', event.position.x, event.position.y)

  event:hit()
end

return function(): Node<MyGame>
    return {
        init = init,
        advance = advance,
        draw = draw,
        pointerMove = handlePointerMove,
    }
end
```


### `pointerUp`

Pointer event up handler.
```lua
function handlePointerUp(self: MyGame, event: PointerEvent)
  print('Pointer Position: ', event.position.x, event.position.y)

  event:hit()
end

return function(): Node<MyGame>
    return {
        init = init,
        advance = advance,
        draw = draw,
        pointerUp = handlePointerUp,
    }
end
```


### `pointerExit`

Pointer event exit handler.
```lua
function handlePointerExit(self: MyGame, event: PointerEvent)
  print('Pointer Position: ', event.position.x, event.position.y)

  event:hit()
end

return function(): Node<MyGame>
    return {
        init = init,
        advance = advance,
        draw = draw,
        pointerExit = handlePointerExit,
    }
end
```




---

// File: node-data.mdx

---
title: NodeData
---

Represents a node in the hierarchy, providing transform properties and
access to parent and child nodes.


## Fields

### `children`

The node’s children.


### `parent`

The parent of the node, or nil if it has none.


## Methods

### `decompose`

Represents a node in the hierarchy, providing transform properties and
access to parent and child nodes.
Updates the node’s position, rotation, and scale from the given world
transform.




---

// File: node-read-data.mdx

---
title: NodeReadData
---

Represents a node in the hierarchy, providing transform properties and
access to parent and child nodes.


## Fields

### `position`

Represents a node in the hierarchy, providing transform properties and
access to parent and child nodes.
The local position of the node.


### `rotation`

The local rotation of the node in radians.


### `scale`

The local scale of the node.


### `worldTransform`

The world transform of the node.


### `x`

The x-coordinate of the local position.


### `y`

The y-coordinate of the local position.


### `scaleX`

The x component of the local scale.


### `scaleY`

The y component of the local scale.


### `paint`

If node is a Path, paint trait is available with paint data




---

// File: node-scripts.mdx

---
title: "Node Scripts"
description: ""
---

import { Demos } from '/snippets/demos.jsx'

Node scripts can be used to render shapes, images, text, artboards, and more.

## Creating a Node Script

1. [Create a new script](/scripting/creating-scripts) and select **Node** as the type.
2. [Add it to the scene](/scripting/creating-scripts#adding-scripts-to-your-scene).

## Anatomy of a Node Script

```lua
-- Define the script's data and inputs.
type MyNode = {}

-- Called once when the script initializes.
function init(self: MyNode): boolean
  return true
end

-- Called every frame to advance the simulation.
-- 'seconds' is the elapsed time since the previous frame.
function advance(self: MyNode, seconds: number): boolean
  return false
end

-- Called when any input value changes.
function update(self: MyNode) end

-- Called every frame (after advance) to render the content.
function draw(self: MyNode, renderer: Renderer) end


-- Return a factory function that Rive uses to build the Node instance.
return function(): Node<MyNode>
  return {
    init = init,
    advance = advance,
    update = update,
    draw = draw,
  }
end
```


## Node

Node scripts allow you to draw shapes and render them in your scene.

<Demos
  examples={[
    "scriptingDrawingShapes"
  ]}
/>

```lua
function rectangle(self: Rectangle)
  -- Update the path with current width and height
  self.path:reset()

  local halfWidth = self.width / 2
  local halfHeight = self.height / 2

  -- Draw rectangle centered at origin
  self.path:moveTo(Vec2D.xy(-halfWidth, -halfHeight))
  self.path:lineTo(Vec2D.xy(halfWidth, -halfHeight))
  self.path:lineTo(Vec2D.xy(halfWidth, halfHeight))
  self.path:lineTo(Vec2D.xy(-halfWidth, halfHeight))
  self.path:close()

  -- Update paint color
  self.paint.color = self.color
end

function draw(self: Rectangle, renderer: Renderer)
  renderer:drawPath(self.path, self.paint)
end
```

See the [API Reference](/scripting/api-reference/path) for a complete list of drawing utilities.

## Common Patterns

### Instantiating Components

To be able to instantiate components at runtime, you will need to have a basic understanding of
[Data Binding](/editor/data-binding/overview), [Components](/editor/fundamentals/components), and [Script Inputs](/scripting/script-inputs).

See the following example showing how to set up your components, view models, and scripts:

<Demos
  examples={[
    "scriptingSnakeGame"
  ]}
/>


```lua
type Enemy = {
  artboard: Artboard<Data.Enemy>,
  position: Vec2D,
}

export type MyGame = {
  -- This is the component that we will dynamically add to our scene
  -- See: https://rive.app/docs/scripting/script-inputs
  enemy: Input<Artboard<Data.Enemy>>,
  enemies: { Enemy },
}

function createEnemy(self: MyGame)
  -- Create an instance of the artboard
  local enemy = self.enemy:instance()

  -- Keep track of all enemies in self.enemies
  local entry: Enemy = {
    artboard = enemy,
    position = Vec2D.xy(0, 0),
  }
  table.insert(self.enemies, entry)
end

function init(self: MyGame)
  createEnemy(self)

  return true
end

function advance(self: MyGame, seconds: number)
  -- Advance the artboard of each enemy
  for _, enemy in self.enemies do
    enemy.artboard:advance(seconds)
  end

  return true
end

function draw(self: MyGame, renderer: Renderer)
  -- draw each enemy
  for _, enemy in self.enemies do
    renderer:save()
    enemy.artboard:draw(renderer)
    renderer:restore()
  end
end

return function(): Node<MyGame>
  return {
    init = init,
    advance = advance,
    draw = draw,
    enemy = late(),
    enemies = {},
  }
end
```

### Fixed-Step Advance

Frame rates can vary between devices and scenes. If your script moves or animates objects based directly on the frame time, faster devices will move them farther each second, while slower ones will appear to lag behind.

To keep movement and timing consistent, you can advance your simulation in fixed time steps instead of relying on the variable frame rate. This technique is called a fixed-step update or fixed timestep.

<Demos
  examples={[
    "scriptingSnakeGame"
  ]}
/>

```lua
--- Fixed Timestep Advance
--- Keeps movement consistent across different frame rates
--- by advancing the simulation in fixed time steps.
export type CarGame = {
  speed: Input<number>,
  accumulator: number,
  fixedStep: Input<number>,
  direction: number,
  currentX: number,
  currentY: number,
}

-- Prevent the script from running too many catch-up steps
-- after a long pause or frame drop.
local MAX_STEPS = 5

function advance(self: CarGame, seconds: number): boolean
  -- Add the time since the last frame to the accumulator.
  self.accumulator += seconds

  local dt = self.fixedStep
  local steps = 0

  -- Run the simulation in small, fixed steps.
  -- If the frame took longer than one step, multiple steps may run this frame.
  while self.accumulator >= dt and steps < MAX_STEPS do
    -- Move forward by speed * time.
    -- Using a fixed dt keeps movement stable even if the frame rate changes.
    self.currentX += self.speed * math.cos(self.direction) * dt
    self.currentY += self.speed * math.sin(self.direction) * dt

    -- Subtract one fixed step from the accumulator
    -- and repeat until we've caught up to real time.
    self.accumulator -= dt
    steps += 1
  end

  return true
end

-- Create a new instance of the CarGame script with default values.
-- The simulation runs 60 fixed steps per second.
return function(): Node<CarGame>
  return {
    speed = 100,
    accumulator = 0,
    direction = 0,
    fixedStep = 1 / 60,
    currentX = 0,
    currentY = 0,
  }
end

```



---

// File: output.mdx

---
title: Output
---

Represents a typed output value.




---

// File: overview.mdx

---
title: "Protocols"
sidebarTitle: "Overview"
description: ""
---

Protocols are the structured categories of scripts that tell the Editor what you’re trying to make.

Rive currently ships with five, with more to come:

- [Node](/scripting/protocols/node-scripts)
- [Layout](/scripting/protocols/layout-scripts)
- [Converter](/scripting/protocols/converter-scripts)
- [Path Effect](/scripting/protocols/path-effect-scripts)
- [Test](/scripting/protocols/test-scripts)

Each protocol represents a different kind of script the Editor can generate: a converter that shapes data, a custom drawing function, a layout helper, a testing harness, a path effect you can attach to strokes, and so on.

Selecting a protocol generates a typed scaffold that defines the surface area you’re allowed to operate on. From there, you work with Rive-native concepts — paths, shapes, view models, artboards, state machines, timelines — but always through the lens of the protocol you picked. It keeps scripts specific and prevents “do anything anywhere” chaos.


---

// File: paint.mdx

---
title: Paint
---

Describes how shapes are drawn, including fill or stroke style, thickness,
color, gradient, and blending behaviour.


## Fields

### `style`

Describes how shapes are drawn, including fill or stroke style, thickness,
color, gradient, and blending behaviour.
Painting style of type [PaintStyle](/scripting/api-reference/paint-style).


### `join`

Stroke join behaviour for corners. See [StrokeJoin](/scripting/api-reference/stroke-join).


### `cap`

Stroke cap used for line endings. See [StrokeCap](/scripting/api-reference/stroke-cap).


### `thickness`

Thickness of the stroked path.


### `blendMode`

Blending mode used when compositing. See [BlendMode](/scripting/api-reference/blend-mode).


### `feather`

Feathering amount.


### `gradient`

[Gradient](/scripting/api-reference/gradient) applied to fill (if present).


### `color`

Color. See [Color](/scripting/api-reference/color).


## Constructors

### `new`

Creates a new [Paint](/scripting/api-reference/paint) object with default settings.

Example:
```lua
local paint = Paint.new()
paint.style = 'fill'
paint.color = Color.rgb(255, 200, 80)
```


### `with`

Creates a new Paint initialized from the provided [PaintDefinition](/scripting/api-reference/paint-definition).

Example:
```lua
local strokePaint = Paint.with({
  style = 'stroke',
  thickness = 3,
  color = Color.hex('#FF0066'),
  join = 'round',
  cap = 'round',
})
```


## Methods

### `copy`

Returns a new Paint that copies this one, optionally overriding selected
properties with values from the provided [PaintDefinition](/scripting/api-reference/paint-definition).

Example:
```lua
local base = Paint.with({
  style = 'fill',
  color = Color.rgb(255, 0, 0),
})

local outline = base:copy({
  style = 'stroke',
  thickness = 4,
})
```

@param values Optional overrides.
@return A new [Paint](/scripting/api-reference/paint) instance with merged values.




---

// File: paint-definition.mdx

---
title: PaintDefinition
---

A partial set of paint properties used to initialize or update a Paint
instance. All fields are optional.


## Fields

### `style`

A partial set of paint properties used to initialize or update a Paint
instance. All fields are optional.
The painting style (stroke or fill).


### `join`

Stroke join behaviour for corners.


### `cap`

Stroke cap used for line endings.


### `thickness`

Thickness of the stroked path.


### `blendMode`

Blending mode used when compositing.


### `feather`

Feathering amount.


### `gradient`

Gradient fill applied to the paint.
If explicitly set to `false`, removes any existing gradient.


### `color`

Color




---

// File: paint-style.mdx

---
title: PaintStyle
---

Specifies how the shape should be painted.
* `stroke`
* `fill`




---

// File: path.mdx

---
title: Path
---

## Constructors

### `new`

## Methods

### `moveTo`

Moves the current point to the specified location, starting a new
contour.
```lua
path:moveTo(Vector.xy(0, 0))
```


### `lineTo`

Adds a straight line segment from the current point to the specified
point.
```lua
path:lineTo(Vector.xy(10, 0))
```


### `quadTo`

Adds a quadratic Bézier curve from the current point to the specified
point, using the control point to define the curve shape.
```lua
path:quadTo(
  Vector.xy(-50, -50), -- control point
  Vector.xy(0, 0)      -- end point
)
```


### `cubicTo`

Adds a cubic Bézier curve from the current point to the specified point,
using controlOut for the start tangent and controlIn for the end tangent.
```lua
path:cubicTo(
  Vector.xy(25, -40),  -- control point out
  Vector.xy(75, 40),   -- control point in
  Vector.xy(100, 0)    -- end point
)
```


### `close`

Closes the current contour by adding a line segment from the current
point back to the first point of the contour (the last moveTo).
```lua
-- Draw a rectangle
path:moveTo(Vector.xy(-10, -10))
path:lineTo(Vector.xy(10, -10))
path:lineTo(Vector.xy(10, 10))
path:lineTo(Vector.xy(-10, 10))
-- Close the path
path:close()
```


### `__len`

Each entry is a [PathCommand](/scripting/api-reference/path-command) describing one segment or action in the path.
Returns the number of commands in the path.


### `reset`

Paths should not be reset, or mutated at all, while they are in flight for
rendering. Only call reset on subsequent frames if you've called
Renderer.drawPath with it.
```lua
path:reset()
```


### `add`

Add one path to another path with the given transform, when specified.


### `contours`

Returns a [ContourMeasure](/scripting/api-reference/contour-measure) for the first contour in the path. A contour is
a sequence of path segments between moveTo operations. Use the 'next'
property on the returned ContourMeasure to iterate through subsequent
contours. Returns nil if the path has no contours.


### `measure`

Returns a [PathMeasure](/scripting/api-reference/path-measure) that measures the entire path across all contours.
This provides the total length and allows operations on the path as a whole.
```lua
local pathLength = path:measure()
```




---

// File: path-command.mdx

---
title: PathCommand
---

A PathCommand represents a single drawing instruction inside a Path.
Each command has a type, and a variable number of points depending on that type.


## Fields

### `type`

A PathCommand represents a single drawing instruction inside a Path.
Each command has a type, and a variable number of points depending on that type.
See [CommandType](/scripting/api-reference/command-type).


## Methods

### `__len`

points size varies depending on command. moveTo and lineTo have only two points
cubicTo has 6 and close has none
Returns the number of points stored on this command.
This is equivalent to the size listed in the table above.




---

// File: path-data.mdx

---
title: PathData
---

PathData is an indexed collection of [PathCommand](/scripting/api-reference/path-command) objects.
Both Path and PathData behave like arrays of commands and support iteration via ipairs.


## Methods

### `__len`

PathData is an indexed collection of [PathCommand](/scripting/api-reference/path-command) objects.
Both Path and PathData behave like arrays of commands and support iteration via ipairs.
Each entry is a [PathCommand](/scripting/api-reference/path-command) describing one segment or action in the path.
Returns the number of commands in the path.


### `contours`

Returns a [ContourMeasure](/scripting/api-reference/contour-measure) for the first contour in the path. A contour is
a sequence of path segments between moveTo operations. Use the 'next'
property on the returned ContourMeasure to iterate through subsequent
contours. Returns nil if the path has no contours.


### `measure`

Returns a [PathMeasure](/scripting/api-reference/path-measure) that measures the entire path across all contours.
This provides the total length and allows operations on the path as a whole.




---

// File: path-effect.mdx

---
title: PathEffect
---

A scripted effect applied to a path


## Methods

### `init`

Called once when the effect is created or attached.
Return `true` to keep the effect active, or `false` to disable it.


### `update`

Called any time an input changes.
You receive the original [PathData](/scripting/api-reference/path-data) and must return the path
that should be used for rendering.


### `advance`

Called every frame to advance the effect over time.
`seconds` is the time delta since the last frame.
Return `true` to keep the effect active, or `false` to disable it.




---

// File: path-effect-scripts.mdx

---
title: "Path Effect Scripts"
description: "Create custom path effects using Rive scripting"
---

import { Demos } from '/snippets/demos.jsx'

Path Effects are Rive scripts that modify and transform path geometry in real-time. They give you programmatic control over the shape and structure of paths in your animations, enabling effects like warping, distortion, animation, and procedural modifications.


## Creating a Path Effect

[Create a new script](/scripting/creating-scripts) and select **Path Effect** as the type.

## Examples

<Demos
  examples={[
    "scriptingBoilPathEffect",
    "scriptingTextPathEffect",
  ]}
/>

## Anatomy of a Path Effect Script

### Methods

- *init (optional)*
Called once when the path effect is created. Use this to set up initial state. Returns true if initialization succeeds.
- *update (required)*
The core method where path transformation happens. Receives the original `PathData` and returns a modified version. This is where you manipulate the path's geometry.
- *advance (optional)*
Called every frame with elapsed time in seconds. Returns true to continue receiving advance calls. Useful for animated effects that change over time.

## Working with `PathData`
`PathData` provides access to a path's drawing commands (`moveTo`, `lineTo`, `cubicTo`, `quadTo`, `close`). You can:

- Read existing commands using indexing
- Get the command count with `#pathData`
- Create new paths and add commands
- Use measurement tools like `contours()` and `measure()` for advanced operations

```lua
type MyPathEffect = {
  context: Context,
}

function init(self: MyPathEffect, context: Context): boolean
  self.context = context
  return true
end

function update(self: MyPathEffect, inPath: PathData): PathData
  local path = Path.new()
  return path
end

function advance(self: MyPathEffect, seconds: number): boolean
  return true
end

-- Return a factory function that Rive uses to build the Path Effect instance.
return function(): PathEffect<MyPathEffect>
  return {
    init = init,
    update = update,
    advance = advance,
    context = late(),
  }
end
```


## Add the Scripted Path Effect to a Stroke

Select or add a stroke to a shape:

1. Open the Options menu.
2. Select the Effects Tab and click the '+' to add an effect.
3. Find your effects under the Script Effects menu option.
4. Any inputs you have defined will apepar and can be edited here.

![Add Path Effect to a Stroke](/images/scripting/add-path-effect-to-stroke.png)

## Adding Inputs

See [Script Inputs](/scripting/script-inputs).

---

// File: path-measure.mdx

---
title: PathMeasure
---

## Fields

### `length`

The total length of the path across all contours.
```lua
local measure = path:measure()
local pathLength = measure.length
```


### `isClosed`

Returns true only if the path has exactly one contour and that contour is
closed. Paths with multiple contours always return false, even if all
contours are closed.


## Methods

### `positionAndTangent`

Returns the position and tangent vector at the given distance along the
path. The distance is clamped to the valid range [0, length]. Returns two
[Vector](/scripting/api-reference/vector) values: the position and the normalized tangent vector.


### `warp`

Warps a point onto the path. The x-coordinate of the source point is
interpreted as a distance along the path, and the y-coordinate is used as
an offset along the tangent direction. Returns the warped position as a
[Vector](/scripting/api-reference/vector).


### `extract`

Extracts a sub-section of the path from startDistance to endDistance and
appends it to the destination path. Distances are clamped to the valid
range [0, length]. If startWithMove is true (the default), the extracted
segment begins with a moveTo operation. If false, it continues from the
previous point in the destination path.




---

// File: pointer-event.mdx

---
title: PointerEvent
---

Represents a pointer interaction event containing position and pointer id.


## Fields

### `position`

Represents a pointer interaction event containing position and pointer id.
The position of the pointer in local coordinates.


### `id`

The unique identifier for the pointer.


## Constructors

### `new`

Creates a new [PointerEvent](/scripting/api-reference/pointer-event) with the given id and position.


## Methods

### `hit`

Marks the event as handled. If isTranslucent is true, the event may
continue to propagate through translucent hit targets.




---

// File: pointer-events.mdx

---
title: "Pointer Events"
description: ""
---

import { Demos } from '/snippets/demos.jsx'

You can listen for pointer events inside any script that implements `pointerDown`, `pointerMove`, `pointerUp`, or `pointerExit`. These functions can be defined in [Node Scripts](/scripting/protocols/node-scripts) and [Layout Scripts](/scripting/protocols/layout-scripts).

```lua
-- Pointer event callbacks have parameters of `self` and a `PointerEvent`.
function handlePointerDown(self: MyNode, event: PointerEvent)
  -- Pointer location in local coordinates relative to the script.
  print(event.position.x, event.position.y)

  -- the pointer identifier (useful for multi-touch)
  print(event.id)

  -- Marks the event as handled and prevents propagation.
  event:hit()
  -- event:hit(true) -- handled, but allowed to pass through translucent elements
end

-- Register your pointer handlers by assigning functions to pointerDown,
-- pointerUp, pointerMove, or pointerExit in the script’s returned table.
return function(): Node<MyScript>
  return {
    init = init,
    draw = draw,
    advance = advance,
    pointerDown = myPointerDownFunction,
  }
end

```

## Multi-touch

Using `event.id`, you can track multiple active pointers.

<Demos
  examples={[
    "scriptingMultiTouch"
  ]}
/>

```lua
type ActiveId = {
  position: Vec2D,
}

export type TrackPointers = {
  -- Keep track of the position for each of the pointers
  activePointers: { ActiveId },
}

function onPointerDown(self: TrackPointers, event: PointerEvent)
  -- Save an item in the table for each pointer down
  self.activePointers[event.id] = {
    position = event.position,
  }

  print('New pointer down: ' .. event.id)
  print('Position: ' .. event.position.x .. event.position.y)

  event:hit()
end

function onPointerMove(self: TrackPointers, event: PointerEvent)
  if self.activePointers[event.id] then
    self.activePointers[event.id].position = event.position

    -- Print all currently active pointer IDs
    print('Active pointer IDs:')
    for id, pointer in self.activePointers do
      print('  id: ', id)
      print('    x:', pointer.position.x)
      print('    y:', pointer.position.y)
    end
  end

  event:hit()
end

function onPointerUp(self: TrackPointers, event: PointerEvent)
  self.activePointers[event.id] = nil

  print('Pointer up: ' .. event.id)
  print('Position: ' .. event.position.x .. event.position.y)

  event:hit()
end

return function(): Node<TrackPointers>
  return {
    init = init,
    advance = advance,
    draw = draw,
    pointerDown = onPointerDown,
    pointerMove = onPointerMove,
    pointerUp = onPointerUp,
    activePointers = {},
  }
end

```

## Nested Pointer Events

Rive only listens for Pointer Events on the main artboard.
If you need to listen for Pointer Events in your [instantiated artboards](/scripting/protocols/node-scripts#instanting-components),
you must forward them manually.

<Demos
  examples={[
    "scriptingNestedPointers"
  ]}
/>


```lua
-- Handle pointer events in the main script
function handlePointerDown(self: MyScript, event: PointerEvent)
  -- self.enemy.pointerDown(self.enemy, event)
  for _, enemy in self.enemies do
    -- Convert the incoming pointer position into the enemy's local space.
    -- This example assumes enemy.position is in the same coordinate system.
    local localEvent = PointerEvent.new(
      event.id,
      Vec2D.xy(
        -- Normalize the pointer position based on the artboard's position
        event.position.x - enemy.position.x,
        event.position.y - enemy.position.y
      )
    )

    -- Forward the event into the instantiated artboard
    self.enemy:pointerDown(localEvent)
  end
end
```

---

// File: property.mdx

---
title: Property
---

Represents a mutable property with a stored value and listener support.


## Fields

### `value`

### `addListener`

### `removeListener`



---

// File: property-enum.mdx

---
title: PropertyEnum
---

## Methods

### `values`



---

// File: property-list.mdx

---
title: PropertyList
---

## Fields

### `length`

## Methods

### `push`

### `insert`

### `swap`

### `pop`

### `shift`



---

// File: property-trigger.mdx

---
title: PropertyTrigger
---

Represents a trigger property that can fire events and notify listeners.


## Fields

### `addListener`

Represents a trigger property that can fire events and notify listeners.


### `removeListener`

## Methods

### `fire`



---

// File: property-view-model.mdx

---
title: PropertyViewModel
---

## Fields

### `value`



---

// File: renderer.mdx

---
title: Renderer
---

Provides functions for drawing paths and images, managing clipping, and
applying transforms during rendering.


## Methods

### `drawPath`

Provides functions for drawing paths and images, managing clipping, and
applying transforms during rendering.
Draws the given path using the specified paint.


### `drawImage`

Draws an image using the specified sampler, blend mode, and opacity.


### `drawImageMesh`

Draws an image using mesh data defined by vertices, texture
coordinates, and triangle indices.


### `clipPath`

Restricts subsequent drawing to the area defined by the given path.
Clipping remains in effect until the next restore call.


### `save`

Saves the current rendering state, including transforms and clipping.


### `restore`

Restores the most recently saved rendering state.


### `transform`

Applies a transform to the current rendering state. Transforms are
applied cumulatively until restored.




---

// File: script-inputs.mdx

---
title: "Script Inputs"
sidebarTitle: "Script Inputs"
description: ""
---

import { Demos } from '/snippets/demos.jsx'

Scripted Inputs are the bridge between your scripts and the Rive editor, allowing you to customize and control script behavior through custom input fields.

By defining inputs in your scripts, you expose configurable properties — like numbers, colors, booleans, and artboard components — that appear directly in the Rive interface. This means you can write the logic once in a script, and then experiment freely with values, animate properties over time, bind data from external sources, and reuse the same script across multiple instances with different configurations. Inputs transform static scripts into flexible, designer-friendly tools that enable true collaboration and rapid iteration.

## Defining Inputs

To make new script inputs, add them to the type and set the defaults in the script's return function.

```lua
-- Define the script's data and inputs.
-- These properties will be available in `self`
type MyNode = {
  myNumber: Input<number>,
  myColor: Input<Color>,
  -- This input expects a View Model named Points
  myViewModel: Input<Data.Points>,
  -- This input expects an Artboard with a View Model named Points
  myArtboard: Input<Artboard<Data.Points>>,
  -- This will be accessible via self, but not in the inputs panel
  myString: string,
}

function init(self: SnakeGame): boolean
  print("myString", self.myString)
  print("myNumber", self.myNumber)
  print("myColor", self.myColor)
  print("myViewModel value", self.myViewModel.someString.value)
  print("myViewModel value", self.myArtboard.data.someEnum.value)

  return true
end

return function(): Node<MyNode>
  return {
    init = init,
    draw = draw,
    myString = "Rive for president!"
    -- Sets default value when creating a new instance of the script
    -- This will be overridden by a value set in the script's inputs
    myNumber = 0,
    myColor = Color.rgba(255, 255, 0, 255), -- 0xFFFFFF00

    -- Use late() to mark this input as assigned at runtime
    myViewModel = late(),
    myArtboard = late()
  }
end

```

<Tip>
  Using inputs, instances of Artboards can be added to your scene at runtime. See [Instantiating Components](/scripting/protocols/node-scripts#instanting-components).
</Tip>

## Setting Input Values

To access the input properties in the right sidebar of the editor, select your [Node](/scripting/protocols/node-scripts) or [Layout script](/scripting/protocols/layout-scripts) in the Hierarchy Panel or the [Converter](/scripting/protocols/converter-scripts) in the Data Panel.

![Node script input](/images/scripting/script-input.png)

<Demos
  examples={[
    "scriptingDrawingShapes"
  ]}
/>

## Data Binding Inputs

You can use [Data Binding](/editor/data-binding/overview) to control input values at runtime.

<Note>
  Inputs can control scripts, but scripts can't change the value of inputs.

  If you need to control a view model property from your script, access the [Main View model through context](/scripting/data-binding#accessing-the-main-view-model) or [View Model Inputs](#view-model-inputs)
</Note>

To data bind an input, right-click the input field in right sidebar, choose Data Bind, and select a
property.

![Data bind a converter input](/images/scripting/converter-script-input-data-binding.png)

## Listening for Changes to Inputs

The `update` function fires every time any input changes.

```lua
function update(self: MyNode)
  print('An update changed')
end
```

You can also listen for changes to specific properties:

```lua
function handleMyStringChanged()
  print('myString changed!')
end

function handleMyNumberChanged(myNumber: number)
  print('myNumber changed!', myNumber)
end

function init(self: MyApp): boolean
  -- handleMyStringChanged fires when self.myString changes
  local myString = self.myString
  myString:addListener(handleMyStringChanged)

  -- Pass a parameter to the handleMyStringChanged callback
  local myNumber = self.myNumber
  myNumber:addListener(myNumber.value, handleMyNumberChanged)

  return true
end
```


## View Model Inputs

View Model Inputs let your script read from and write to View Model properties. These properties can control any element in your Rive scene via (See [Data Binding](/editor/data-binding/overview)).

<Note>
  You can access the [Main View model through context](/scripting/data-binding#accessing-the-main-view-model).
</Note>

### Setting Up Your View Model

**In this example:**

- The `Main` view model has a property named `character`.
- The `character` property is itself a `Character` view model.
- The `Character` view model contains two number properties (x and y) that you want to control from your script.

![Nested](/images/scripting/nested-view-model.png)

### Defining a View Model Input

Inside your script, declare a new input whose type matches the nested view model you want to reference (`Data.` + the name of your nested view model).

In this case, the Character view model type becomes `Data.Character`.

```lua
type MyNode = {
  -- This input expects a view model instance of type Character
  character: Input<Data.Character>
}

return function(): Node<MyNode>
  return {
    init = init,
    advance = advance,
    draw = draw,
    -- Initialize with `late()` so the value
    -- can be provided by the editor at runtime.
    character = late(),
  }
end
```

### Connecting the Input in the Editor

1. Select your script in the Scene panel (or the converter if you're using a [Converter](/scripting/protocols/converter-scripts) script)
2. In the right sidebar, look for the Property Group section
3. You’ll see a dropdown for your character input
4. Select your nested `character` property from the Main view model

![Nested](/images/scripting/select-vm-input.png)

### Reading and Writing View Model Properties

Once connected, you can access the nested view model directly from your script:

```lua
function moveCharacter(self: MyNode)
  print('Current x: ', self.character.x.value)
  self.character.x.value = 10
end
```

Because character is a view model instance, you can access all of its public properties:

```lua
self.character.<propertyName>.value
```




---

// File: stroke-cap.mdx

---
title: StrokeCap
---

Defines the shape used at the ends of open stroke segments.
* `butt` – squared, no extension.
* `round` – semicircular cap.
* `square` – squared, extends past the end point.




---

// File: stroke-join.mdx

---
title: StrokeJoin
---

Defines how two stroke segments are joined at a corner.
* `miter` – sharp corner.
* `round` – rounded corner.
* `bevel` – flattened corner.




---

// File: test-scripts.mdx

---
title: "Test Scripts"
description: "Write tests for your scripts to ensure they are working correctly."
---

See [Unit Testing](/scripting/debugging/unit-testing).

---

// File: trigger.mdx

---
title: Trigger
---

A function that triggers an action when invoked.




---

// File: unit-testing.mdx

---
title: "Unit Testing"
description: "Write and run unit tests for your Util Scripts using Test scripts."
---
import { Demos } from '/snippets/demos.jsx'

Test scripts let you write unit tests for your [Util Scripts](/scripting/protocols/util-scripts) and run them directly in the Rive editor.
Use them to verify math helpers, string utilities, or any other pure logic your scripts depend on.

Beyond validating your code, tests also serve as precise instructions for the [AI Agent](/editor/ai-agent), helping it produce code that behaves exactly as you intend.

<Demos
  examples={[
    "scriptingUnitTesting"
  ]}
/>

## Creating a Test Script

[Create a new script](/scripting/creating-scripts) and select **Test** as the type.

### Anatomy of a Test Script

A Test script exposes a single `setup(test: Tester)` function. The `Tester` object gives you helpers to define and group tests:

- `test.case(name, fn)` – define a single test case.
- `test.group(name, fn)` – group related tests. Groups can be nested.
- `expect(value)` – create an expectation object to assert on a value.

Inside a case, the `expect` function is passed as an argument to your test callback.

### Example

```lua
-- Load the Util that you want to create tests for
local MyUtil = require('MyUtil')

function setup(test: Tester)
  local case = test.case
  local group = test.group

  -- Create a single case with multiple tests
  case('Addition', function(expect)
    local result = MyUtil.add(2, 3)
    expect(result).is(5)
    expect(result).greaterThanOrEqual(5)
  end)

  -- Organize your tests with groups
  group('Math', function()
    case('Subtraction', function(expect)
      local result = MyUtil.subtract(2, 3)
      expect(result).is(-1)
    end)

    case('Multiplication', function(expect)
      local result = MyUtil.multiply(2, 3)
      expect(result).greaterThanOrEqual(6)
    end)

    group('Trigonometry', function()

      case('Degrees to Radians', function(expect)
        local result = MyUtil.deg2rad(180)
        expect(result).is(math.pi)
      end)
    end)
  end)
end

```
<Tip>
  Tip: Use descriptive names for your groups and cases. They show up in the test results panel and make it easier to see what failed.
</Tip>

### Matchers (expectations)

The `expect` helper returns an object with matcher methods you can use in your tests, for example:

```lua
expect(value).is(expected)
expect(value).greaterThan(number)
expect(value).greaterThanOrEqual(number)
expect(value).lessThan(number)
expect(value).lessThanOrEqual(number)
```

For a complete list of matchers and test utilities, see Test API Reference (TODO: link).

### Inverting matchers with never

You can invert any matcher by chaining .never before it.
This means: the test passes only if the matcher would normally fail.

```lua
case('never examples', function(expect)
  -- This passes because 2 + 2 is NOT 3
  expect(2 + 2).never.is(3)

  -- This passes because 4 is NOT >= 6
  expect(4).never.greaterThanOrEqual(6)
end)
```

## Running Tests

1. In the Assets panel, right-click your Test script.
2. Select Run Tests.

Test results are shown:

- Passing and failing cases are listed under the script in the Assets Panel
- Passing and failing cases are highlighted in the script editor

![Problems panel](/images/scripting/debugging/test-results.png)


---

// File: util-scripts.mdx

---
title: "Util Scripts"
description: "Create helper modules to organize shared logic across your scripts."
---

Util scripts let you organize your code into small, focused modules that can be reused across multiple scripts.
They’re ideal for math helpers, geometry utilities, color functions, or any logic that should be broken out into its own script.

## Creating a Util Script

[Create a new script](/scripting/creating-scripts) and select **Util** as the type.

```lua
--- Example helper function.
local function add(a: number, b: number): MyUtil
  return a + b,
end

-- Return the functions you'd like to use in another script
return {
  add = add,
}

```

**Usage:**

```lua
local MyUtil = require("MyUtil")

local result = MyUtil.add(2, 3)
print(result) -- 5

```

## Utils with Custom Types

Custom types defined in your Util scripts will automatically be accessible
in the parent script.

```lua
--- Defines the return type for this util.
--- The type is automatically available when you require the script.
export type AdditionResult = {
  exampleValue: number,
  someString: string
}

--- Example helper function.
local function add(a: number, b: number): AdditionResult
  return {
    exampleValue = a + b,
    someString = "4 out of 5 dentists recommend Rive"
  }
end

return {
  add = add,
}

```

**Usage:**

```lua
-- With type annotation
local result: AdditionResult = MyUtil.add(2, 3)
```


---

// File: vector.mdx

---
title: Vector
---

Represents a vector with x and y components.


## Fields

### `x`

Represents a vector with x and y components.
The x component, note that this is read-only.
```lua
local v = Vector.xy(10, -5)
local xValue = v.x  -- 10
```


### `y`

The y component, note that this is read-only.
```lua
local v = Vector.xy(10, -5)
local yValue = v.y  -- -5
```


## Constructors

### `xy`

Creates a vector with the specified x and y components.
```lua
local v = Vector.xy(5, -2)  -- (5, -2)
```


### `origin`

Returns the zero vector (0, 0).
```lua
local origin = Vector.origin()  -- (0,0)
```


## Methods

### `length`

Provides indexed access to the vector components.
```lua
local v = Vector.xy(3, 4)
print(v[1], v[2]) -- 3  4
```
Returns the length of the vector.
```lua
local v = Vector.xy(3, 4)
local len = v:length()  -- 5
```


### `lengthSquared`

Returns the squared length of the vector.
```lua
local v = Vector.xy(3, 4)
local len2 = v:lengthSquared()  -- 25
```


### `normalized`

Returns a normalized copy of the vector. If the length is zero,
the result is the zero vector.
```lua
local v = Vector.xy(10, 0)
local n = v:normalized()  -- (1,0)
```


### `__eq`

Returns true if the two vectors have equal components.
```lua
local a = Vector.xy(1, 2)
local b = Vector.xy(1, 2)
local c = Vector.xy(2, 1)
print(a == b)  -- true
print(a == c)  -- false
```


### `__unm`

Returns the negated vector.
```lua
local v = Vector.xy(2, -3)
local neg = -v   -- (-2, 3)
```


### `__add`

Returns the sum of two vectors.
```lua
local a = Vector.xy(2, 3)
local b = Vector.xy(-1, 5)
local c = a + b  -- (1, 8)
```


### `__sub`

Returns the difference between two vectors.
```lua
local a = Vector.xy(2, 3)
local b = Vector.xy(-1, 5)
local c = a - b  -- (3, -2)
```
Returns the difference between two vectors.


### `__mul`

Returns the vector scaled by the given number.
```lua
local v = Vector.xy(3, -2)
local doubled = v * 2    -- (6, -4)
```


### `__div`

Returns the vector divided by the given number
```lua
local v = Vector.xy(6, -4)
local half = v / 2    -- (3, -2)
```


### `distance`

Returns the distance to the other vector.
```lua
local a = Vector.xy(0, 0)
local b = Vector.xy(3, 4)
print(a:distance(b))  -- 5
```


### `distanceSquared`

Returns the squared distance to the other vector.
```lua
local a = Vector.xy(0, 0)
local b = Vector.xy(3, 4)
print(a:distanceSquared(b))  -- 25
```


### `dot`

Returns the dot product of the vector and the other vector.
```lua
local a = Vector.xy(1, 2)
local b = Vector.xy(3, 4)
print(a:dot(b))  -- 11  (1*3 + 2*4)
```


### `lerp`

Returns the linear interpolation between the vector and the other
vector, using t where 0 returns the vector and 1 returns the other.




---

// File: view-model.mdx

---
title: ViewModel
---

## Fields

### `name`

## Methods

### `getNumber`

### `getTrigger`

### `getString`

### `getBoolean`

### `getColor`

### `getList`

### `getViewModel`

### `getEnum`

### `instance`

