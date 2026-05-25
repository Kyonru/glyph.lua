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
---@field shape? GlyphShape|fun(ctx: table): any
---@field fontSize? number
---@field opacity? number
local GlyphStateStyle = {}

---@class GlyphAudioCues
---@field hover? string|false
---@field press? string|false
---@field activate? string|false
---@field focus? string|false
local GlyphAudioCues = {}

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
---@field shape? GlyphShape|fun(ctx: table): any
---@field shader? any
---@field blendMode? string
---@field draw? fun(node: GlyphNode, x: number, y: number, w: number, h: number, love: table)
---@field hover? GlyphStateStyle
---@field pressed? GlyphStateStyle
---@field focused? GlyphStateStyle
---@field active? GlyphStateStyle
---@field disabled? GlyphStateStyle
local GlyphStyle = {}

---@class GlyphBounds
---@field x number
---@field y number
---@field width number
---@field height number
local GlyphBounds = {}

---@class GlyphShape
---@field kind? "rect"|"skew"|"polygon"|"circle"|"ellipse"
---@field radius? number
---@field skew? number
---@field inset? number
---@field points? number[] local point coordinates relative to node bounds
---@field absolute? boolean
local GlyphShape = {}

---@class GlyphStencil
---@field shape? GlyphShape|fun(ctx: table): any
---@field mode? "inside"|"outside"
local GlyphStencil = {}

---@class GlyphAnimationValues
---@field opacity? number
---@field x? number
---@field y? number
---@field scale? number
---@field scaleX? number
---@field scaleY? number
---@field rotation? number
local GlyphAnimationValues = {}

---@class GlyphAnimationSpec
---@field duration? number
---@field delay? number
---@field ease? string
---@field from? GlyphAnimationValues
---@field to? GlyphAnimationValues
---@field onStart? fun(subject: GlyphAnimationValues)
---@field onUpdate? fun(subject: GlyphAnimationValues)
---@field onComplete? fun(subject: GlyphAnimationValues)
local GlyphAnimationSpec = {}

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
---@field draw? fun(node: GlyphNode, x: number, y: number, w: number, h: number, love: table, style: GlyphStyle, ctx: table)
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
---@field focusable? boolean
---@field active? boolean
---@field disabled? boolean
---@field interactive? boolean
---@field variant? string
---@field styleType? string
---@field audio? GlyphAudioCues|false
---@field callbacks? table
---@field key? string|number
---@field enter? GlyphAnimationSpec|false
---@field exit? GlyphAnimationSpec|false
---@field clip? boolean|GlyphShape|fun(ctx: table): any
---@field stencil? GlyphStencil
---@field shape? GlyphShape|fun(ctx: table): any
---@field navGroup? string|number
---@field navScope? boolean
---@field navTrap? boolean
---@field onNavigateExit? fun(direction: GlyphNavDirection, origin: GlyphNode, scope: GlyphNode|GlyphLayer, candidates: GlyphNavCandidate[]): GlyphNode|false|nil
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

---@class GlyphMeterProps : GlyphProps
---@field value? number
---@field min? number
---@field max? number
---@field kind? "linear"|"radial"|"arc"
---@field direction? "right"|"left"|"up"|"down"
---@field shape? GlyphShape|fun(ctx: table): any
---@field trackStyle? GlyphStyle
---@field fillStyle? GlyphStyle
---@field overfillStyle? GlyphStyle
---@field backgroundStyle? GlyphStyle
---@field segments? number
---@field gap? number
---@field thickness? number
---@field startAngle? number
---@field endAngle? number
---@field label? string|fun(value: number, min: number, max: number): string
local GlyphMeterProps = {}

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

---@class GlyphNavigateEvent
---@field direction "up"|"down"|"left"|"right"
---@field candidate GlyphNode|nil
---@field candidates table[]

---@class GlyphAudioEvent
---@field cue string
---@field kind "hover"|"press"|"activate"|"focus"
---@field node GlyphNode
---@field type string
---@field path? string
---@field variant? string
---@field styleType? string
---@field label? string

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
---@field navScope? boolean
---@field navTrap? boolean
---@field onNavigateExit? fun(direction: GlyphNavDirection, origin: GlyphNode, scope: GlyphNode|GlyphLayer, candidates: GlyphNavCandidate[]): GlyphNode|false|nil
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
---@field enter? GlyphAnimationSpec
---@field exit? GlyphAnimationSpec
local GlyphTransition = {}

---@class GlyphTransitionApi
---@field none fun(opts?: table): GlyphTransition
---@field fade fun(opts?: table): GlyphTransition
---@field slide fun(opts?: table): GlyphTransition
---@field scale fun(opts?: table): GlyphTransition
---@field custom fun(spec: GlyphTransition|fun(ctx: GlyphTransitionCtx)): GlyphTransition
---@field animate fun(opts: { enter?: GlyphAnimationSpec, exit?: GlyphAnimationSpec, duration?: number, exitDuration?: number }): GlyphTransition
local GlyphTransitionApi = {}

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
---@field navScope? boolean
---@field navTrap? boolean
---@field onNavigateExit? fun(direction: GlyphNavDirection, origin: GlyphNode, scope: GlyphNode|GlyphLayer, candidates: GlyphNavCandidate[]): GlyphNode|false|nil
local GlyphLayerOpts = {}

---@class GlyphAnimationApi
---@field to fun(subject: table, duration: number, target: table, opts?: table): table
---@field update fun(dt: number): boolean
---@field clear fun()
---@field active fun(): number
local GlyphAnimationApi = {}

---@class GlyphViewportBackendApi
---@field isEnabled fun(): boolean
---@field backend fun(): "push"|"shove"|nil
---@field screenToViewport fun(x: number, y: number): boolean, number|false, number|false
---@field viewportToScreen fun(x: number, y: number): number, number
---@field beginDraw fun(): boolean
---@field endDraw fun(): boolean
---@field raw fun(): table|nil
local GlyphViewportBackendApi = {}

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
---@field breakpoint? string
---@field backend? "push"|"shove"
---@field virtual? boolean
---@field screen? GlyphBounds
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
---@field minWidth? number
---@field minHeight? number
---@field minwidth? number
---@field minheight? number
---@field breakpoints? table<string, number>
---@field viewport? GlyphViewportBackendOpts
local GlyphWindowOpts = {}

---@class GlyphViewportBackendOpts
---@field backend? "push"|"shove"
---@field instance? table
---@field width? number
---@field height? number
---@field fit? "aspect"|"pixel"|"stretch"|"none"
---@field fitMethod? "aspect"|"pixel"|"stretch"|"none"
---@field filter? "nearest"|"linear"
---@field scalingFilter? "nearest"|"linear"
---@field canvas? boolean
---@field managed? boolean
---@field renderMode? "direct"|"layer"
local GlyphViewportBackendOpts = {}

---@class GlyphGamepadMapperOpts
---@field navigation? table<string, "up"|"down"|"left"|"right"|false>
---@field buttons? table<string, string|false>
local GlyphGamepadMapperOpts = {}

---@class GlyphInstallOpts
---@field app? fun(): GlyphNode
---@field callbacks? table
---@field order? "before"|"after"
---@field gamepad? boolean|GlyphGamepadMapperOpts
---@field gamepadpressed? boolean
---@field gamepadreleased? boolean
local GlyphInstallOpts = {}

---@class GlyphLoadOpts
---@field love? table
---@field theme? GlyphTheme
---@field window? GlyphWindowOpts
---@field app? fun(): GlyphNode
---@field install? GlyphInstallOpts
---@field callbacks? table
---@field order? "before"|"after"
---@field gamepad? boolean|GlyphGamepadMapperOpts
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
---@field transitions GlyphTransitionApi
local GlyphModalApi = {}

-- ---------------------------------------------------------------------------
-- Navigation
-- ---------------------------------------------------------------------------

---@alias GlyphNavDirection "up"|"down"|"left"|"right"

---@class GlyphNavCandidate
---@field node GlyphNode
---@field x number
---@field y number
---@field w number
---@field h number
---@field width number
---@field height number
---@field cx number center x
---@field cy number center y
---@field group any navGroup value inherited from the nearest ancestor with navGroup set
---@field scope GlyphNode|GlyphLayer|nil nearest ancestor or layer with navScope = true
---@field scopeNode GlyphNode|GlyphLayer|nil alias for scope
local GlyphNavCandidate = {}

return {}
