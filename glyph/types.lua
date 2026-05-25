-- Type definitions for glyph.lua — indexed by LuaLS as workspace source.
-- No runtime effect; never required at runtime.

-- ---------------------------------------------------------------------------
-- Primitives
-- ---------------------------------------------------------------------------

-- rgb(a) array: {r, g, b, a?}, each component 0–1
---@class GlyphColor
local GlyphColor = {}

---@class GlyphFontSpec
---@field path? string
---@field size? number
---@field hinting? string
local GlyphFontSpec = {}

---@alias GlyphFontRef any|string|GlyphFontSpec

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
---@field lineHeight? number
---@field font? GlyphFontRef
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
---@field lineHeight? number
---@field font? GlyphFontRef
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
---@field kind? "rect"|"skew"|"polygon"|"circle"|"ellipse"|"blob"
---@field radius? number
---@field skew? number
---@field inset? number
---@field points? number[] local point coordinates relative to node bounds
---@field absolute? boolean
---@field variance? number
---@field seed? string|number
---@field phase? number
---@field segments? number
local GlyphShape = {}

---@class GlyphStencil
---@field shape? GlyphShape|fun(ctx: table): any
---@field mode? "inside"|"outside"
local GlyphStencil = {}

---@class GlyphDrawContext
---@field node GlyphNode
---@field props GlyphProps
---@field x number
---@field y number
---@field width number
---@field height number
---@field love table
---@field graphics table|nil
---@field style GlyphStyle
---@field animation? GlyphAnimationValues
---@field runtime table
---@field hovered boolean
---@field pressed boolean
---@field focused boolean
---@field active boolean
---@field hot boolean
---@field time number
---@field pulse fun(self: GlyphDrawContext, speed?: number, phase?: number): number
---@field color fun(self: GlyphDrawContext, value: GlyphColor, alpha?: number)
---@field rect fun(self: GlyphDrawContext, mode: "fill"|"line"|string, x: number, y: number, width: number, height: number, radius?: number)
---@field line fun(self: GlyphDrawContext, ...: any)
---@field polygon fun(self: GlyphDrawContext, mode: "fill"|"line"|string, points: number[])
---@field shape fun(self: GlyphDrawContext, mode: "fill"|"line"|string, shape?: GlyphShape|fun(ctx: GlyphDrawContext): any, bounds?: GlyphBounds)
---@field clip fun(self: GlyphDrawContext, shape: boolean|GlyphShape|fun(ctx: GlyphDrawContext): any, fn: fun())
---@field stencil fun(self: GlyphDrawContext, shapeOrFn: GlyphShape|fun(ctx: GlyphDrawContext): any, fn: fun(), opts?: GlyphStencil)
---@field meter fun(self: GlyphDrawContext, bounds?: GlyphBounds, opts?: GlyphMeterProps)
---@field text fun(self: GlyphDrawContext, value: any, x: number, y: number)
---@field printf fun(self: GlyphDrawContext, value: any, x: number, y: number, limit: number, align?: string)
---@field skewBox fun(self: GlyphDrawContext, opts?: table): number[]
---@field blob fun(self: GlyphDrawContext, bounds?: GlyphBounds, opts?: table): number[]
local GlyphDrawContext = {}

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

---@class GlyphAnimationTweenOpts
---@field ease? string
---@field delay? number
---@field onStart? fun(subject: table)
---@field onUpdate? fun(subject: table)
---@field onComplete? fun(subject: table)
local GlyphAnimationTweenOpts = {}

---@class GlyphFeedbackStep
---@field kind? "animate"|"audio"|"emit"|"callback"|string
---@field target? "node"|string
---@field from? GlyphAnimationValues
---@field to? GlyphAnimationValues
---@field duration? number
---@field delay? number
---@field ease? string
---@field cue? string
---@field audioKind? string
---@field event? string
---@field name? string
---@field payload? table
---@field callback? fun(ctx: GlyphFeedbackContext)
---@field fn? fun(ctx: GlyphFeedbackContext)
---@field onStart? fun(subject: GlyphAnimationValues)
---@field onUpdate? fun(subject: GlyphAnimationValues, ctx: GlyphFeedbackContext)
---@field onComplete? fun(subject: GlyphAnimationValues, ctx: GlyphFeedbackContext)
local GlyphFeedbackStep = {}

---@alias GlyphFeedbackSequence GlyphFeedbackStep[]

---@class GlyphFeedbackProps
---@field hover? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
---@field focus? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
---@field press? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
---@field release? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
---@field activate? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
---@field error? string|GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)|false
local GlyphFeedbackProps = {}

---@class GlyphFeedbackPlayOpts
---@field trigger? "hover"|"focus"|"press"|"release"|"activate"|"error"|string
---@field [string] any
local GlyphFeedbackPlayOpts = {}

---@class GlyphFeedbackContext
---@field runtime table
---@field node? GlyphNode
---@field trigger string
---@field source any
---@field opts GlyphFeedbackPlayOpts
local GlyphFeedbackContext = {}

---@class GlyphFeedbackState
---@field id string
---@field subject GlyphAnimationValues
---@field active number
---@field node? GlyphNode
---@field tweens? table[]
local GlyphFeedbackState = {}

---@class GlyphFeedbackEvent
---@field kind string
---@field name? string
---@field trigger? string
---@field node? GlyphNode
---@field path? string
---@field payload? table
---@field step? GlyphFeedbackStep
local GlyphFeedbackEvent = {}

---@class GlyphFeedbackApi
---@field define fun(name: string, sequence: GlyphFeedbackSequence|GlyphFeedbackStep|fun(ctx: GlyphFeedbackContext)): GlyphFeedbackSequence|nil
---@field play fun(nameOrSequence: any, node?: GlyphNode, opts?: GlyphFeedbackPlayOpts): GlyphFeedbackContext|nil
---@field clear fun()
local GlyphFeedbackApi = {}

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
---@field draw? fun(node: GlyphNode, x: number, y: number, w: number, h: number, love: table, style: GlyphStyle, ctx: GlyphDrawContext)
---@field width? number|string
---@field height? number|string
---@field minWidth? number
---@field maxWidth? number
---@field minHeight? number
---@field maxHeight? number
---@field padding? number|GlyphPadding
---@field gap? number
---@field align? "start"|"center"|"end"|"stretch"
---@field justify? "start"|"center"|"end"
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
---@field feedback? GlyphFeedbackProps|false
---@field font? GlyphFontRef
---@field fontSize? number
---@field lineHeight? number
---@field textStyle? string
---@field textVerticalAlign? "top"|"center"|"middle"|"bottom"|"start"|"end"
---@field format? "plain"|"sysl"
---@field rich? boolean
---@field role? "button"|"text"|"input"|"panel"|"tab"|"meter"|"dialog"|"group"|"none"|string
---@field accessibilityLabel? string
---@field accessibilityLabelKey? string
---@field accessibilityLabelParams? table
---@field accessibilityLabelFallback? string
---@field accessibilityLabelCacheKey? string|number
---@field accessibilityDescription? string
---@field accessibilityDescriptionKey? string
---@field accessibilityDescriptionParams? table
---@field accessibilityDescriptionFallback? string
---@field accessibilityDescriptionCacheKey? string|number
---@field accessibilityValue? string|number
---@field accessibilityValueText? string
---@field accessibilityValueTextKey? string
---@field accessibilityValueTextParams? table
---@field accessibilityValueTextFallback? string
---@field accessibilityValueTextCacheKey? string|number
---@field accessibilityHidden? boolean
---@field accessibilityLive? "off"|"polite"|"assertive"
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
---@field textKey? string
---@field textParams? table
---@field textFallback? string
---@field textCacheKey? string|number
---@field textStyle? "text"|"h1"|"h2"|"paragraph"|"caption"|"code"|string
---@field textVerticalAlign? "top"|"center"|"middle"|"bottom"|"start"|"end"
---@field format? "plain"|"sysl"
---@field rich? boolean
local GlyphTextProps = {}

---@class GlyphImageProps : GlyphProps
---@field source? any Love2D Image/Canvas-like drawable with getWidth/getHeight
---@field quad? any Love2D Quad-like object with getViewport
---@field fit? "contain"|"cover"|"stretch"|"none"
---@field align? "start"|"center"|"end"
---@field valign? "start"|"center"|"end"
---@field tint? GlyphColor
---@field opacity? number
local GlyphImageProps = {}

---@class GlyphButtonProps : GlyphProps
---@field label? string
---@field labelKey? string
---@field labelParams? table
---@field labelFallback? string
---@field labelCacheKey? string|number
---@field onClick? fun()
---@field focusable? boolean
local GlyphButtonProps = {}

---@class GlyphInputProps : GlyphProps
---@field value? string
---@field placeholder? string
---@field placeholderKey? string
---@field placeholderParams? table
---@field placeholderFallback? string
---@field placeholderCacheKey? string|number
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
---@field labelKey? string
---@field labelParams? table
---@field labelFallback? string
---@field labelCacheKey? string|number
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
---@field titleKey? string
---@field titleParams? table
---@field titleFallback? string
---@field titleCacheKey? string|number
---@field titleColor? GlyphColor
---@field titleTextStyle? string
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

---@class GlyphAccessibilityDescription
---@field node GlyphNode
---@field path? string
---@field type string
---@field role? string
---@field label? string
---@field description? string
---@field value? string|number
---@field valueText? string
---@field live? "off"|"polite"|"assertive"|string
---@field disabled? boolean
---@field focusable? boolean

---@class GlyphAccessibilityAnnounceOpts
---@field kind? "focus"|"activate"|"live"|"announce"|string
---@field message? string
---@field node? GlyphNode
---@field path? string
---@field role? string
---@field label? string
---@field description? string
---@field valueText? string
---@field live? "off"|"polite"|"assertive"|string

---@class GlyphAccessibilityEvent
---@field kind "focus"|"activate"|"live"|"announce"|string
---@field message? string
---@field node? GlyphNode
---@field path? string
---@field role? string
---@field label? string
---@field description? string
---@field valueText? string
---@field live? "off"|"polite"|"assertive"|string

---@class GlyphAccessibilityConfig
---@field enabled? boolean
---@field announceOnFocus? boolean
---@field announceOnActivate? boolean

---@class GlyphAccessibilityApi
---@field configure fun(opts?: GlyphAccessibilityConfig)
---@field describe fun(node?: GlyphNode): GlyphAccessibilityDescription|nil
---@field snapshot fun(root?: GlyphNode): GlyphAccessibilityDescription[]
---@field focused fun(): GlyphAccessibilityDescription|nil
---@field announce fun(message: string, opts?: GlyphAccessibilityAnnounceOpts): GlyphAccessibilityEvent|nil

---@class GlyphTab
---@field label? string
---@field labelKey? string
---@field labelParams? table
---@field labelFallback? string
---@field labelCacheKey? string|number
---@field role? "tab"|"button"|"none"|string
---@field accessibilityLabel? string
---@field accessibilityLabelKey? string
---@field accessibilityLabelParams? table
---@field accessibilityLabelFallback? string
---@field accessibilityLabelCacheKey? string|number
---@field accessibilityDescription? string
---@field accessibilityDescriptionKey? string
---@field accessibilityDescriptionParams? table
---@field accessibilityDescriptionFallback? string
---@field accessibilityDescriptionCacheKey? string|number
---@field accessibilityHidden? boolean
---@field content? GlyphNode
local GlyphTab = {}

---@class GlyphI18nTranslateOpts
---@field fallback? string
---@field default? string
---@field cacheKey? string|number
local GlyphI18nTranslateOpts = {}

---@class GlyphI18nConfig
---@field translate? fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string|nil
---@field missing? fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string|nil
---@field setLocale? fun(locale: any)
---@field getLocale? fun(): any
---@field locale? any
local GlyphI18nConfig = {}

---@class GlyphI18nApi
---@field configure fun(opts?: GlyphI18nConfig|fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string|nil)
---@field t fun(key: string, params?: table, opts?: GlyphI18nTranslateOpts): string
---@field setLocale fun(locale: any)
---@field locale fun(): any
---@field invalidate fun()
---@field version fun(): number
local GlyphI18nApi = {}

---@class GlyphTypographyStyle
---@field font? GlyphFontRef
---@field fontSize? number
---@field lineHeight? number
---@field color? GlyphColor
local GlyphTypographyStyle = {}

---@class GlyphRichTextLayout
---@field textbox? table
---@field fallback? boolean
---@field width number
---@field height number
---@field lines number|table
local GlyphRichTextLayout = {}

---@class GlyphRichTextBackendConfig
---@field sysl? table
---@field defaults? table
---@field configure? fun(sysl: table)
local GlyphRichTextBackendConfig = {}

---@class GlyphRichTextBackendApi
---@field configure fun(opts?: GlyphRichTextBackendConfig)
---@field clear fun()
local GlyphRichTextBackendApi = {}

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
---@field _glyphFeedback? GlyphAnimationValues
---@field _glyphFeedbackId? string
---@field richText? GlyphRichTextLayout
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

---@class GlyphViewportBackend
---@field enabled boolean
---@field name? "push"|"shove"
---@field instance? table
---@field managed boolean
---@field width? number
---@field height? number
---@field lastScreenWidth? number
---@field lastScreenHeight? number
---@field loveModule? table
---@field pushedGraphicsState boolean
local GlyphViewportBackend = {}

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
---@field textScale? number
---@field radius? number
---@field borderWidth? number
---@field font? GlyphFontRef
---@field fonts? table<string, GlyphFontRef>
---@field typography? table<string, GlyphTypographyStyle>
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
