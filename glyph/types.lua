-- Type definitions for glyph.lua — indexed by LuaLS as workspace source.
-- No runtime effect; never required at runtime.

-- ---------------------------------------------------------------------------
-- Primitives
-- ---------------------------------------------------------------------------

-- rgb(a) array: {r, g, b, a?}, each component 0–1
---@class GlyphColor
local GlyphColor = {}

-- ---------------------------------------------------------------------------
-- Style
-- ---------------------------------------------------------------------------

---@class GlyphStateStyle
---@field background? GlyphColor
---@field color? GlyphColor
---@field borderColor? GlyphColor
---@field borderWidth? number
---@field radius? number
---@field fontSize? number
---@field opacity? number
local GlyphStateStyle = {}

---@class GlyphStyle
---@field background? GlyphColor
---@field color? GlyphColor
---@field borderColor? GlyphColor
---@field borderWidth? number
---@field radius? number
---@field fontSize? number
---@field font? any
---@field opacity? number
---@field lineWidth? number
---@field shader? any
---@field blendMode? string
---@field draw? fun(node: GlyphNode, x: number, y: number, w: number, h: number, love: table)
---@field hover? GlyphStateStyle
---@field pressed? GlyphStateStyle
---@field focused? GlyphStateStyle
---@field active? GlyphStateStyle
---@field disabled? GlyphStateStyle
local GlyphStyle = {}

-- ---------------------------------------------------------------------------
-- Props
-- ---------------------------------------------------------------------------

---@class GlyphPadding
---@field top? number
---@field right? number
---@field bottom? number
---@field left? number
local GlyphPadding = {}

---@class GlyphProps
---@field style? GlyphStyle
---@field width? number|string
---@field height? number|string
---@field minWidth? number
---@field maxWidth? number
---@field minHeight? number
---@field maxHeight? number
---@field padding? number|GlyphPadding
---@field gap? number
---@field flex? number|boolean
---@field grow? number
---@field shrink? number
---@field basis? number
---@field position? "absolute"
---@field x? number|string
---@field y? number|string
---@field top? number|string
---@field right? number|string
---@field bottom? number|string
---@field left? number|string
---@field inset? number|GlyphPadding
---@field zIndex? number
---@field active? boolean
---@field disabled? boolean
---@field interactive? boolean
---@field variant? string
---@field styleType? string
---@field callbacks? table
local GlyphProps = {}

---@class GlyphTextProps : GlyphProps
local GlyphTextProps = {}

---@class GlyphButtonProps : GlyphProps
---@field label? string
---@field onClick? fun()
---@field focusable? boolean
local GlyphButtonProps = {}

---@class GlyphInputProps : GlyphProps
---@field value? string
---@field placeholder? string
---@field onChange? fun(value: string)
---@field onSubmit? fun(value: string)
---@field focusable? boolean
local GlyphInputProps = {}

---@class GlyphTabsProps : GlyphProps
---@field active? number
---@field defaultActive? number
---@field onChange? fun(index: number, tab: table)
---@field activeColor? GlyphColor
---@field tabHeight? number
---@field tabVariant? string
---@field tabStyle? GlyphStyle
local GlyphTabsProps = {}

---@class GlyphPanelProps : GlyphProps
---@field title? string
---@field titleColor? GlyphColor
local GlyphPanelProps = {}

---@class GlyphTab
---@field label? string
---@field content? GlyphNode
local GlyphTab = {}

-- ---------------------------------------------------------------------------
-- Node
-- ---------------------------------------------------------------------------

---@class GlyphLayout
---@field x number
---@field y number
---@field width number
---@field height number
local GlyphLayout = {}

---@class GlyphDirty
---@field layout boolean
---@field style boolean
---@field text boolean
---@field bounds boolean
local GlyphDirty = {}

---@class GlyphNode
---@field type string
---@field props GlyphProps
---@field children GlyphNode[]
---@field value? string
---@field layout GlyphLayout
---@field resolvedStyle? GlyphStyle
---@field static? boolean
---@field dirty? GlyphDirty
---@field parent? GlyphNode
---@field path? string
local GlyphNode = {}

-- ---------------------------------------------------------------------------
-- Transitions
-- ---------------------------------------------------------------------------

---@class GlyphBounds
---@field x number
---@field y number
---@field width number
---@field height number
local GlyphBounds = {}

-- ---------------------------------------------------------------------------
-- Scene / Layer
-- ---------------------------------------------------------------------------

---@class GlyphLayer
---@field id string|number
---@field kind string
---@field component fun(): GlyphNode
---@field state "entering"|"open"|"exiting"
---@field progress number
---@field blocking boolean
---@field input boolean
---@field backdrop boolean
---@field escapeToClose boolean
---@field zIndex number
---@field width? number
---@field height? number
---@field align string
---@field root? GlyphNode
---@field offsetX number
---@field offsetY number
---@field bounds GlyphBounds
local GlyphLayer = {}

---@class GlyphTransitionCtx
---@field progress number
---@field phase "enter"|"exit"
---@field layer GlyphLayer
---@field bounds GlyphBounds
---@field love table
---@field transition table
---@field drawLayer fun()
local GlyphTransitionCtx = {}

---@class GlyphTransition
---@field name string
---@field duration number
---@field exitDuration number
---@field draw fun(ctx: GlyphTransitionCtx)
---@field direction? "top"|"bottom"|"left"|"right"
local GlyphTransition = {}

---@class GlyphLayerOpts
---@field kind? "scene"|"modal"|"overlay"
---@field width? number
---@field height? number
---@field align? "center"|"top"|"bottom"|"left"|"right"|"stretch"
---@field blocking? boolean
---@field input? boolean
---@field backdrop? boolean
---@field backdropColor? GlyphColor
---@field dismissOnBackdrop? boolean
---@field escapeToClose? boolean
---@field transition? string|GlyphTransition|fun(ctx: GlyphTransitionCtx)
---@field transitionName? string
---@field duration? number
---@field exitDuration? number
---@field zIndex? number
---@field onEnter? fun(layer: GlyphLayer)
---@field onExit? fun(layer: GlyphLayer)
---@field onClose? fun(layer: GlyphLayer)
---@field onUpdate? fun(layer: GlyphLayer, dt: number)
---@field onEvent? fun(layer: GlyphLayer, name: string, ...)
local GlyphLayerOpts = {}

-- ---------------------------------------------------------------------------
-- Theme
-- ---------------------------------------------------------------------------

---@class GlyphTheme
---@field textColor? GlyphColor
---@field mutedTextColor? GlyphColor
---@field backgroundColor? GlyphColor
---@field surfaceColor? GlyphColor
---@field borderColor? GlyphColor
---@field accentColor? GlyphColor
---@field accentTextColor? GlyphColor
---@field fontSize? number
---@field lineHeight? number
---@field radius? number
---@field borderWidth? number
---@field font? any
---@field base? GlyphStyle
---@field components? table
local GlyphTheme = {}

-- ---------------------------------------------------------------------------
-- Install / Load
-- ---------------------------------------------------------------------------

---@class GlyphViewport
---@field width number
---@field height number
local GlyphViewport = {}

---@class GlyphVariant
---@field name string
---@field style GlyphStyle
local GlyphVariant = {}

---@class GlyphWindowOpts
---@field width? number
---@field height? number
---@field title? string
---@field resizable? boolean
---@field minwidth? number
---@field minheight? number
local GlyphWindowOpts = {}

---@class GlyphLoadOpts
---@field love? table
---@field theme? GlyphTheme
---@field window? GlyphWindowOpts
---@field app? fun(): GlyphNode
---@field install? table
---@field callbacks? table
---@field order? "before"|"after"
local GlyphLoadOpts = {}

-- ---------------------------------------------------------------------------
-- Scene / Modal API
-- ---------------------------------------------------------------------------

---@class GlyphSceneApi
---@field set fun(id: string|number, component: fun(), opts: GlyphLayerOpts|nil): GlyphLayer
---@field push fun(id: string|number, component: fun(), opts: GlyphLayerOpts|nil): GlyphLayer
---@field pop fun(id: string|number|nil): GlyphLayer|nil
---@field close fun(id: string|number): GlyphLayer|nil
---@field clear fun(predicate: fun(layer: GlyphLayer)|nil)
---@field current fun(): GlyphLayer|nil
---@field isOpen fun(id: string|number): boolean
---@field layers GlyphLayer[]
local GlyphSceneApi = {}

---@class GlyphModalApi
---@field open fun(id: string|number, component: fun(), opts: GlyphLayerOpts|nil): GlyphLayer
---@field close fun(id: string|number|nil)
---@field closeAll fun()
---@field isOpen fun(id: string|number): boolean
---@field transitions table
local GlyphModalApi = {}

return {}
