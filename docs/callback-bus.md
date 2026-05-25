---
icon: lucide/radio
---

# Callback Bus

Glyph includes a callback bus modeled after Feather-style callback semantics.

## Runtime API

```lua
local off = ui.on("beforeUpdate", function(dt)
  -- work
end, {
  priority = 10,
})

off()
```

Dispatch manually:

```lua
ui.dispatch("event", "custom", payload)
```

## Semantics

- Only supported callback names can be registered.
- Unsupported names error.
- Higher-priority callbacks run first.
- Registration order breaks priority ties.
- The unregister closure is idempotent.
- Dispatch uses a snapshot, so callbacks may register/unregister during dispatch safely.
- Entries have active flags internally.

## Runtime Callback Names

- `beforeUpdate`
- `afterUpdate`
- `beforeRender`
- `afterRender`
- `layout`
- `audio`
- `accessibility`
- `focusChanged`
- `hoverChanged`
- `event`

## Component-Local Buses

Components can own local callback buses through node props when advanced widgets need local event systems. Prefer simple props for common widgets; use local buses only for complex reusable controls.
