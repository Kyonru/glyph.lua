---
icon: lucide/sparkles
---

# Feedback

Glyph feedback sequences are small triggerable stacks for game-feel polish. They can animate a node, emit audio cue metadata, dispatch app-owned FX events, or run a callback.

The API is named `ui.feedback`; “juice” is example language, not a widget namespace.

## Define A Sequence

```lua
ui.feedback.define("button.pop", {
  { kind = "animate", to = { scaleX = 1.08, scaleY = 0.92 }, duration = 0.06 },
  { kind = "audio", cue = "ui-pop" },
  { kind = "emit", event = "particles", name = "spark" },
  { kind = "animate", to = { scale = 1 }, duration = 0.16, ease = "backout" },
})
```

Then attach it to any node:

```lua
ui.button({
  label = "Launch",
  feedback = {
    hover = "button.hover",
    press = "button.squash",
    release = "button.release",
    activate = "button.pop",
  },
})
```

Feedback triggers are `hover`, `focus`, `press`, `release`, `activate`, and `error`. The `error` trigger is manual:

```lua
ui.feedback.play("button.warn", node, { trigger = "error" })
```

Set `feedback = false` on a node to disable feedback.

## Step Types

`animate` uses Glyph's visual-only Flux animation values:

```lua
{ kind = "animate", from = { opacity = 0.6 }, to = { opacity = 1, y = -2 }, duration = 0.12 }
```

Supported values are `opacity`, `x`, `y`, `scale`, `scaleX`, `scaleY`, and `rotation`. These do not affect layout, hit testing, focus, navigation, or accessibility snapshots.

`audio` emits the same app-owned audio callback shape as interaction cues:

```lua
{ kind = "audio", cue = "ui-confirm" }
```

`emit` dispatches a `feedback` runtime event for particles, camera shake, haptics, splats, or other app-owned systems:

```lua
ui.on("feedback", function(event)
  if event.kind == "shake" then
    cameraShake(event.payload.amount)
  end
end)
```

`callback` runs a function with the feedback context:

```lua
{
  kind = "callback",
  callback = function(ctx)
    print(ctx.trigger, ctx.node and ctx.node.path)
  end,
}
```

## Manual Playback

```lua
ui.feedback.play({
  { kind = "animate", to = { scale = 1.1 }, duration = 0.08 },
  { kind = "animate", to = { scale = 1 }, duration = 0.14 },
}, node)
```

Use `ui.feedback.clear()` in tests or app teardown when registered sequences should be reset.

## Core Boundary

Glyph runs the sequence and emits metadata. It does not own particles, camera shake, haptics, sound loading, or game-specific widgets.

Use examples or app code for:

- blob buttons
- ink/splat visuals
- screen shake
- particles and confetti
- sound packs
- game-specific shaders
