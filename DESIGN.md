---
name: Glyph
description: A compact service-workbench visual system for readable, game-shaped tools and HUDs.
colors:
  service-amber: "#BD7314"
  service-amber-hover: "#F2AD3D"
  service-amber-pressed: "#B36B12"
  accent-ink: "#120F0B"
  warm-paper: "#EDE8DB"
  muted-stone: "#A8A396"
  chassis-black: "#0B0D0D"
  workfield-black: "#090A0B"
  rail-black: "#111212"
  surface-graphite: "#161819"
  hover-graphite: "#242626"
  pressed-graphite: "#0F1111"
  rule-graphite: "#454747"
typography:
  display:
    fontFamily: "Inconsolata, monospace"
    fontSize: "32px"
    fontWeight: 400
    lineHeight: 1.25
  title:
    fontFamily: "Google Sans, sans-serif"
    fontSize: "22px"
    fontWeight: 400
    lineHeight: 1.55
  headline:
    fontFamily: "Google Sans, sans-serif"
    fontSize: "18px"
    fontWeight: 400
    lineHeight: 1.33
  body:
    fontFamily: "Google Sans, sans-serif"
    fontSize: "14px"
    fontWeight: 400
    lineHeight: 1.43
  label:
    fontFamily: "Google Sans, sans-serif"
    fontSize: "11px"
    fontWeight: 400
    lineHeight: 1.36
  code:
    fontFamily: "Inconsolata, monospace"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.31
rounded:
  square: "0px"
  small: "2px"
spacing:
  hairline: "1px"
  compact: "4px"
  tight: "6px"
  control: "8px"
  group: "12px"
  section: "16px"
  field: "24px"
components:
  button-primary:
    backgroundColor: "{colors.service-amber}"
    textColor: "{colors.accent-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.small}"
    padding: "0 16px"
    height: "36px"
  button-primary-hover:
    backgroundColor: "{colors.service-amber-hover}"
    textColor: "{colors.accent-ink}"
    rounded: "{rounded.small}"
  button-secondary:
    backgroundColor: "{colors.surface-graphite}"
    textColor: "{colors.warm-paper}"
    typography: "{typography.body}"
    rounded: "{rounded.small}"
    padding: "0 16px"
    height: "36px"
  input:
    backgroundColor: "{colors.workfield-black}"
    textColor: "{colors.warm-paper}"
    typography: "{typography.body}"
    rounded: "{rounded.square}"
    padding: "0 10px"
    height: "32px"
  tab-active:
    backgroundColor: "{colors.service-amber}"
    textColor: "{colors.accent-ink}"
    typography: "{typography.body}"
    rounded: "{rounded.square}"
    height: "30px"
---

# Design System: Glyph

## Overview

**Creative North Star: "The Service Workbench"**

Glyph should look like a tool opened inside a running game: compact, direct, and ready to inspect. The visual system borrows the clarity of an arcade operator panel and a diagnostic console without becoming retro cosplay. Information sits in rails, registers, ledgers, and measured workfields instead of floating cards.

The interface is dark, warm, and almost entirely flat. A single amber signal marks the current action or live state; everything else is carried by typography, rules, alignment, and density. The result should feel authored for game development rather than borrowed from a generic SaaS dashboard.

**Key Characteristics:**

- Flat rails and registers with visible structural rules.
- Warm off-white text on blackened neutral surfaces.
- One scarce service amber for action, selection, and live state.
- Workhorse sans-serif UI type with monospace reserved for measurements and counters.
- Square geometry by default, with only a slight softening on general-purpose core controls.

## Colors

The palette is a blackened neutral chassis with warm paper text and one deliberately scarce amber signal.

### Primary

- **Service Amber:** The only strong signal color. Use it for the primary action, active tab, selected state, progress fill, or one live-status marker.
- **Service Amber Hover / Pressed:** Interaction states derived from Service Amber so a customized accent never snaps back to a different hue.

### Neutral

- **Chassis Black:** The outer application field and default full-window ground.
- **Workfield Black:** Recessed inputs, scrolling ledgers, and plotting fields.
- **Rail Black:** Persistent command rails that separate controls from the inspected work.
- **Surface Graphite:** Controls, register headers, and bounded utility surfaces.
- **Hover / Pressed Graphite:** Quiet interaction feedback for neutral controls.
- **Rule Graphite:** One-pixel structure, dividers, and component boundaries.
- **Warm Paper:** Primary text and high-confidence readings.
- **Muted Stone:** Labels, instructions, secondary readings, and inactive states.
- **Accent Ink:** Dark text placed on Service Amber.

**The One Signal Rule.** Service Amber identifies what is actionable, selected, progressing, or live. Do not distribute it across ordinary decoration or multiple competing regions.

**The Derived State Rule.** When an app changes the accent, its hover and pressed colors must be derived from that accent unless the app explicitly supplies them.

## Typography

**Display Font:** Inconsolata (with a monospace fallback)
**Body Font:** Google Sans (with a sans-serif fallback)
**Label/Mono Font:** Inconsolata for values; Google Sans for labels

**Character:** The sans-serif carries instructions and control labels without calling attention to itself. Monospace creates the rhythm of a measured instrument and is reserved for values that benefit from stable widths.

### Hierarchy

- **Display:** Large counters and singular readings only; never a marketing headline.
- **Title:** Workfield names and the main task heading.
- **Headline:** Register titles and meaningful subsections.
- **Body:** Controls, descriptions, and readable wrapped copy.
- **Label:** Compact section labels and column headings, usually written in uppercase by the component.
- **Code:** Sequences, timestamps, percentages, dimensions, status codes, and runtime measurements.

**The Measured Mono Rule.** Use monospace because alignment or measurement benefits from it, not as a blanket shortcut for a technical mood.

## Layout

Operate-mode examples favor an asymmetric split: a narrow command rail and a flexible workfield. The rail contains actions and compact context; the workfield contains the live artifact, register, or inspection result. A one-pixel rule joins the regions so the screen reads as one instrument, not a collection of cards.

Spacing follows the compact through field scale in the frontmatter. Dense ledgers may use the compact and tight steps; controls and local groups use control and group; rail padding and major workfield insets use section and field. Rows are usually 24–36 pixels high, keeping enough density for debugging without making interaction targets ambiguous.

At narrow widths, preserve reading order and access to every control. Stack the rail above the workfield or place the whole composition in a vertical scroll view. Do not squeeze a desktop register until labels collide.

**The Purposeful Void Rule.** Empty space separates tasks or preserves a stable work area. Do not fill it with decorative cards, badges, or explanatory filler.

## Elevation & Depth

The system is flat by default and uses no shadows. Depth comes from adjacent neutral tones, one-pixel rules, recessed workfields, and strict layer order. Hover and pressed states change tone inside the same footprint; they do not lift, glow, or cast a shadow.

**The Chassis Rule.** If a region needs separation, change its neutral level or draw a rule. Never solve structure with a floating card shadow.

## Shapes

The form language is rectilinear. Example workbenches use square corners for rails, ledgers, meters, tabs, inputs, and instrument cells. Core controls retain a very small radius so the default library remains adaptable, but no surface should read as a soft pill or rounded bento tile.

Borders are structural and normally one pixel. Focus may strengthen the existing boundary to two pixels without changing geometry. Status markers are small squares, not ornamental dots with glow.

## Components

### Buttons

- **Shape:** Compact rectangles; general defaults use the small radius while diagnostic examples may use square corners.
- **Primary:** Service Amber with Accent Ink, reserved for the main available action.
- **Command rails:** An amber outline may mark an available command while
  reserving solid amber for selection and live instrumentation.
- **Secondary:** Surface Graphite with Warm Paper and a Rule Graphite boundary.
- **Hover / Focus:** Hover changes the fill within the same footprint. Focus uses a precise two-pixel border in Warm Paper or Accent Ink; no glow.
- **Disabled:** Lower-contrast graphite with Muted Stone, while preserving the control's size.

### Cards / Containers

- **Corner Style:** Square in workbench surfaces; slightly softened only for neutral core panels.
- **Background:** Use a rail, surface, or workfield neutral according to function.
- **Shadow Strategy:** None; see Elevation & Depth.
- **Border:** One-pixel rules define registers and containment.
- **Internal Padding:** Use the control, group, section, and field spacing steps rather than one padded tile pattern everywhere.

### Inputs / Fields

- **Style:** Recessed Workfield Black, a one-pixel Rule Graphite boundary, and compact horizontal padding.
- **Focus:** Replace the rule with a precise two-pixel high-contrast boundary.
- **Disabled:** Keep the field legible but visibly quieter with disabled graphite and Muted Stone.

### Navigation

Tabs are attached to their content region rather than floating above it.
Operator shells may instead use a vertical semantic mode rail beside one fixed
workfield. Inactive modes use neutral surfaces; the active mode uses Service
Amber. Keyboard and gamepad focus must remain distinguishable from selection,
including when both states are present.

### Registers and Ledgers

Registers are the signature pattern. A shallow neutral header establishes columns, repeating rows share fixed widths, and one-pixel rules maintain scan lines. Use monospace for aligned sequences and measurements, sans-serif for the event text, and scroll only the repeated body when practical.

### Meters and Instrument Cells

Meters are thin, square-ended tracks with one amber fill. Instrument cells form a shared matrix with rules between cells; they are not individual metric cards. Labels stay quiet and values carry the visual weight.

## Do's and Don'ts

### Do:

- **Do** organize complex screens as a command rail plus a measured workfield.
- **Do** let rules, column alignment, and type hierarchy create structure.
- **Do** reserve amber for a small number of consequential states.
- **Do** keep focus visible for mouse, keyboard, and gamepad workflows.
- **Do** use real runtime values, honest sample labels, and explicit synthetic-data notices.
- **Do** keep the smallest introductory example genuinely small.

### Don't:

- **Don't** compose screens as interchangeable rounded cards in a bento grid.
- **Don't** add glows, gradients, soft shadows, or fake glass to create hierarchy.
- **Don't** use monospace for every label or turn the interface into novelty terminal styling.
- **Don't** promote a page title into an oversized marketing hero.
- **Don't** invent timestamps, telemetry, or claims that look real when they are only decorative.
- **Don't** let active styling erase the separate focus indicator.
