---
icon: lucide/layers
---

# Scenes And Modals

<!-- glyph:feature-gif scenes-modals -->
![Animated GIF showing Glyph scene layers, overlays, modal blocking, and backdrop behavior.](assets/feature-gifs/scenes-modals.gif)
<!-- /glyph:feature-gif scenes-modals -->

Glyph provides a native scene/layer stack. Scenes, overlays, and modals use one stack model, one transition pipeline, one input router, and isolated hook scopes.

## Scene API

```lua
ui.scene.set(id, component, opts)
ui.scene.push(id, component, opts)
ui.scene.pop(idOrNil)
ui.scene.close(id)
ui.scene.clear(predicateOrNil)
ui.scene.current()
ui.scene.isOpen(id)
ui.scene.layers()
```

## Layer Options

Common options:

- `kind = "scene" | "modal" | "overlay"`
- `blocking`
- `input`
- `backdrop`
- `backdropColor`
- `dismissOnBackdrop`
- `escapeToClose`
- `width`, `height`
- `align`
- `zIndex`
- `props`
- `transition`
- `duration`
- `exitDuration`
- `onEnter`
- `onExit`
- `onClose`
- `onUpdate`
- `onEvent`

## Main Scene

```lua
ui.scene.set("home", HomeScene, {
  transition = "none",
})
```

## Overlay

```lua
ui.scene.push("debug", DebugOverlay, {
  kind = "overlay",
  blocking = false,
  input = false,
  transition = "fade",
})
```

Non-blocking overlays allow lower layers to keep receiving input.

## Modal

```lua
ui.scene.push("pause", PauseMenu, {
  kind = "modal",
  width = 420,
  height = 260,
  dismissOnBackdrop = true,
  transition = ui.transitions.scale({ duration = 0.18 }),
})
```

## Modal Convenience API

```lua
ui.modal.open("settings", SettingsModal, opts)
ui.modal.close("settings")
ui.modal.closeAll()
ui.modal.isOpen("settings")
```

`ui.modal.open` is a wrapper over `ui.scene.push` with `kind = "modal"`.

## Input Rules

- Layers route input top-down.
- Blocking layers stop input from reaching lower layers.
- Non-blocking overlays can pass input through.
- Backdrop clicks close a layer only when `dismissOnBackdrop = true`.
- Escape closes the top eligible layer unless `escapeToClose = false`.

## Hook Isolation

Each scene layer has its own hook scope. `useState` inside a modal does not mutate state in the main scene or another modal.
