local ui = require("glyph")

local locale = "en"
local selectedTab = 1
local selectedCommand = "scan"
local messageCount = 3
local filter = ""
local renderCount = 0
local renderTick = 0
local liveBuilds = 0
local memoBuilds = 0
local translationCalls = 0

local localeOptions = {
	{ id = "en", key = "locale.en", script = "Latin", font = "Inconsolata", direction = "LTR", accent = { 0.1, 0.84, 1, 1 } },
	{ id = "pseudo", key = "locale.pseudo", script = "Latin stretch", font = "Inconsolata", direction = "LTR", accent = { 0.72, 0.5, 1, 1 } },
	{ id = "ja", key = "locale.ja", script = "Japanese", font = "DotGothic16", direction = "LTR", accent = { 1, 0.74, 0.24, 1 } },
	{ id = "ar", key = "locale.ar", script = "Arabic", font = "Noto Sans Arabic", direction = "RTL sample", accent = { 0.35, 0.92, 0.72, 1 } },
	{ id = "hy", key = "locale.hy", script = "Armenian", font = "Noto Sans Armenian", direction = "LTR", accent = { 0.95, 0.48, 0.42, 1 } },
	{ id = "ka", key = "locale.ka", script = "Georgian", font = "Noto Sans Georgian", direction = "LTR", accent = { 0.8, 0.9, 1, 1 } },
	{ id = "he", key = "locale.he", script = "Hebrew", font = "Noto Sans Hebrew", direction = "RTL sample", accent = { 0.55, 0.72, 1, 1 } },
	{ id = "mahajani", key = "locale.mahajani", script = "Mahajani", font = "Noto Sans Mahajani", direction = "LTR", accent = { 1, 0.56, 0.84, 1 } },
	{ id = "th", key = "locale.th", script = "Thai", font = "Google Sans", direction = "LTR", accent = { 0.6, 0.95, 0.42, 1 } },
	{ id = "ko", key = "locale.ko", script = "Korean", font = "Noto Serif KR", direction = "LTR", accent = { 0.4, 0.8, 1, 1 } },
	{ id = "am", key = "locale.am", script = "Amharic", font = "Google Sans", direction = "LTR", accent = { 1, 0.86, 0.22, 1 } },
}

local commandMeta = {
	{ id = "scan", code = "SNS", hintKey = "commands.scan_hint", accent = { 0.1, 0.84, 1, 1 } },
	{ id = "launch", code = "LCH", hintKey = "commands.launch_hint", accent = { 1, 0.86, 0.22, 1 } },
	{ id = "guard", code = "GRD", hintKey = "commands.guard_hint", accent = { 0.38, 0.95, 0.5, 1 } },
	{ id = "recall", code = "RCL", hintKey = "commands.recall_hint", accent = { 0.55, 0.72, 1, 1 } },
	{ id = "cancel", code = "ABT", hintKey = "commands.cancel_hint", accent = { 1, 0.36, 0.28, 1 }, danger = true },
}

local translations = {
	en = {
		["app.title"] = "STRIKE CONSOLE",
		["app.subtitle"] = "Localized game UI powered by app-owned translation data.",
		["locale.en"] = "EN",
		["locale.pseudo"] = "PSEUDO",
		["locale.ja"] = "日本語",
		["locale.ar"] = "العربية",
		["locale.hy"] = "Հայ",
		["locale.ka"] = "ქართული",
		["locale.he"] = "עברית",
		["locale.mahajani"] = "𑅐𑅑𑅒",
		["locale.th"] = "ไทย",
		["locale.ko"] = "한국어",
		["locale.am"] = "አማርኛ",
		["input.filter"] = "Filter command log...",
		["status.title"] = "Mission Status",
		["status.ready"] = "Ready for launch",
		["status.zone"] = "Zone %{zone}",
		["status.alert"] = "Threat index %{value}%",
		["stats.power"] = "Reactor %{value}%",
		["stats.shield"] = "Shield %{value}%",
		["stats.sync"] = "Sync %{value}%",
		["commands.title"] = "Command Deck",
		["commands.scan"] = "Scan",
		["commands.scan_hint"] = "Signal sweep",
		["commands.launch"] = "Launch",
		["commands.launch_hint"] = "Launch window",
		["commands.guard"] = "Guard",
		["commands.guard_hint"] = "Shield posture",
		["commands.recall"] = "Recall",
		["commands.recall_hint"] = "Squad return",
		["commands.cancel"] = "Cancel",
		["commands.cancel_hint"] = "Abort queue",
		["command.selected"] = "Queued command: %{command}",
		["tabs.overview"] = "Overview",
		["tabs.messages"] = "Messages",
		["messages.one"] = "1 squad message",
		["messages.other"] = "%{count} squad messages",
		["memo.title"] = "Memoized feed",
		["memo.description"] = "Stable until locale or message count changes.",
		["live.title"] = "Live feed",
		["live.description"] = "Rebuilds on every unrelated render.",
		["compare.title"] = "Translation Cost",
		["compare.rerender"] = "Ping UI",
		["compare.reset"] = "Reset",
		["compare.renders"] = "App renders: %{count}",
		["compare.renders_label"] = "App renders",
		["compare.tick"] = "Ping %{count}",
		["compare.tick_label"] = "Ping",
		["compare.live_builds"] = "Live builds: %{count}",
		["compare.live_builds_label"] = "Live builds",
		["compare.memo_builds"] = "Memo builds: %{count}",
		["compare.memo_builds_label"] = "Memo builds",
		["compare.saved_builds_label"] = "Saved rebuilds",
		["compare.translation_calls"] = "Translator calls: %{count}",
		["compare.translation_calls_label"] = "Translator calls",
	},
	pseudo = {
		["app.title"] = "[loc] STRIKE CONSOLE",
		["app.subtitle"] = "[loc] Localized game UI, app-owned translation data.",
		["locale.en"] = "EN",
		["locale.pseudo"] = "PSEUDO",
		["locale.ja"] = "日本語",
		["locale.ar"] = "العربية",
		["locale.hy"] = "Հայ",
		["locale.ka"] = "ქართული",
		["locale.he"] = "עברית",
		["locale.mahajani"] = "𑅐𑅑𑅒",
		["locale.th"] = "ไทย",
		["locale.ko"] = "한국어",
		["locale.am"] = "አማርኛ",
		["input.filter"] = "[loc] Filter command log...",
		["status.title"] = "[loc] Mission Status",
		["status.ready"] = "[loc] Ready for launch",
		["status.zone"] = "[loc] Zone %{zone}",
		["status.alert"] = "[loc] Threat index %{value}%",
		["stats.power"] = "[loc] Reactor %{value}%",
		["stats.shield"] = "[loc] Shield %{value}%",
		["stats.sync"] = "[loc] Sync %{value}%",
		["commands.title"] = "[loc] Command Deck",
		["commands.scan"] = "[loc] Scan",
		["commands.scan_hint"] = "[loc] Signal sweep",
		["commands.launch"] = "[loc] Launch",
		["commands.launch_hint"] = "[loc] Launch window",
		["commands.guard"] = "[loc] Guard",
		["commands.guard_hint"] = "[loc] Shield posture",
		["commands.recall"] = "[loc] Recall",
		["commands.recall_hint"] = "[loc] Squad return",
		["commands.cancel"] = "[loc] Cancel",
		["commands.cancel_hint"] = "[loc] Abort queue",
		["command.selected"] = "[loc] Queued command: %{command}",
		["tabs.overview"] = "[loc] Overview",
		["tabs.messages"] = "[loc] Messages",
		["messages.one"] = "[loc] 1 squad message",
		["messages.other"] = "[loc] %{count} squad messages",
		["memo.title"] = "[loc] Memoized feed",
		["memo.description"] = "[loc] Stable until locale or message count changes.",
		["live.title"] = "[loc] Live feed",
		["live.description"] = "[loc] Rebuilds on every unrelated render.",
		["compare.title"] = "[loc] Translation Cost",
		["compare.rerender"] = "[loc] Ping UI",
		["compare.reset"] = "[loc] Reset",
		["compare.renders"] = "[loc] App renders: %{count}",
		["compare.renders_label"] = "[loc] App renders",
		["compare.tick"] = "[loc] Ping %{count}",
		["compare.tick_label"] = "[loc] Ping",
		["compare.live_builds"] = "[loc] Live builds: %{count}",
		["compare.live_builds_label"] = "[loc] Live builds",
		["compare.memo_builds"] = "[loc] Memo builds: %{count}",
		["compare.memo_builds_label"] = "[loc] Memo builds",
		["compare.saved_builds_label"] = "[loc] Saved rebuilds",
		["compare.translation_calls"] = "[loc] Translator calls: %{count}",
		["compare.translation_calls_label"] = "[loc] Translator calls",
	},
	ja = {
		["app.title"] = "ストライク端末",
		["app.subtitle"] = "アプリ側の翻訳データで動く多言語ゲームUI。",
		["input.filter"] = "司令ログを絞り込み...",
		["status.title"] = "任務状況",
		["status.ready"] = "発進準備完了",
		["status.zone"] = "区域 %{zone}",
		["status.alert"] = "脅威指数 %{value}%",
		["stats.power"] = "炉心 %{value}%",
		["stats.shield"] = "シールド %{value}%",
		["stats.sync"] = "同期 %{value}%",
		["commands.title"] = "司令デッキ",
		["commands.scan"] = "走査",
		["commands.launch"] = "発進",
		["commands.guard"] = "防御",
		["commands.recall"] = "帰還",
		["commands.cancel"] = "中止",
		["command.selected"] = "待機中の司令: %{command}",
		["tabs.overview"] = "概要",
		["tabs.messages"] = "通信",
		["messages.one"] = "部隊通信 1件",
		["messages.other"] = "部隊通信 %{count}件",
		["memo.title"] = "メモ化フィード",
		["memo.description"] = "ロケールか通信数が変わるまで安定します。",
		["live.title"] = "ライブフィード",
		["live.description"] = "無関係な再描画ごとに再構築します。",
		["compare.title"] = "翻訳コスト",
		["compare.rerender"] = "UI ping",
		["compare.reset"] = "リセット",
		["compare.renders"] = "描画: %{count}",
		["compare.renders_label"] = "描画",
		["compare.tick"] = "Ping %{count}",
		["compare.tick_label"] = "Ping",
		["compare.live_builds"] = "ライブ構築: %{count}",
		["compare.live_builds_label"] = "ライブ構築",
		["compare.memo_builds"] = "メモ構築: %{count}",
		["compare.memo_builds_label"] = "メモ構築",
		["compare.saved_builds_label"] = "節約構築",
		["compare.translation_calls"] = "翻訳呼び出し: %{count}",
		["compare.translation_calls_label"] = "翻訳呼び出し",
	},
	ar = {
		["app.title"] = "وحدة الضربة",
		["app.subtitle"] = "واجهة لعبة مترجمة ببيانات يملكها التطبيق.",
		["input.filter"] = "رشح سجل الأوامر...",
		["status.title"] = "حالة المهمة",
		["status.ready"] = "جاهز للإطلاق",
		["status.zone"] = "المنطقة %{zone}",
		["status.alert"] = "مؤشر الخطر %{value}%",
		["stats.power"] = "المفاعل %{value}%",
		["stats.shield"] = "الدرع %{value}%",
		["stats.sync"] = "التزامن %{value}%",
		["commands.title"] = "لوحة الأوامر",
		["commands.scan"] = "مسح",
		["commands.launch"] = "إطلاق",
		["commands.guard"] = "حراسة",
		["commands.recall"] = "استدعاء",
		["commands.cancel"] = "إلغاء",
		["command.selected"] = "الأمر المنتظر: %{command}",
		["tabs.overview"] = "نظرة عامة",
		["tabs.messages"] = "رسائل",
		["messages.one"] = "رسالة فرقة واحدة",
		["messages.other"] = "%{count} رسائل فرقة",
		["memo.title"] = "موجز محفوظ",
		["memo.description"] = "يبقى ثابتا حتى تتغير اللغة أو الرسائل.",
		["live.title"] = "موجز مباشر",
		["live.description"] = "يعاد بناؤه مع كل رسم غير مرتبط.",
		["compare.title"] = "تكلفة الترجمة",
		["compare.rerender"] = "Ping UI",
		["compare.reset"] = "إعادة",
		["compare.renders"] = "رسوم التطبيق: %{count}",
		["compare.renders_label"] = "رسوم التطبيق",
		["compare.tick"] = "Ping %{count}",
		["compare.tick_label"] = "Ping",
		["compare.live_builds"] = "بناء مباشر: %{count}",
		["compare.live_builds_label"] = "بناء مباشر",
		["compare.memo_builds"] = "بناء محفوظ: %{count}",
		["compare.memo_builds_label"] = "بناء محفوظ",
		["compare.saved_builds_label"] = "بناء موفر",
		["compare.translation_calls"] = "نداءات الترجمة: %{count}",
		["compare.translation_calls_label"] = "نداءات الترجمة",
	},
	hy = {
		["app.title"] = "ՀԱՐՎԱԾԻ ՎԱՀԱՆԱԿ",
		["app.subtitle"] = "Տեղայնացված խաղային UI հավելվածի թարգմանական տվյալներով։",
		["input.filter"] = "Զտել հրամանների մատյանը...",
		["status.title"] = "Առաքելության վիճակ",
		["status.ready"] = "Պատրաստ է մեկնարկի",
		["status.zone"] = "Գոտի %{zone}",
		["status.alert"] = "Սպառնալիք %{value}%",
		["stats.power"] = "Ռեակտոր %{value}%",
		["stats.shield"] = "Վահան %{value}%",
		["stats.sync"] = "Համաժամ %{value}%",
		["commands.title"] = "Հրամաններ",
		["commands.scan"] = "Սկան",
		["commands.launch"] = "Մեկնարկ",
		["commands.guard"] = "Պահակ",
		["commands.recall"] = "Կանչել",
		["commands.cancel"] = "Չեղարկել",
		["command.selected"] = "Հերթագրված հրաման: %{command}",
		["tabs.overview"] = "Ամփոփում",
		["tabs.messages"] = "Հաղորդումներ",
		["messages.one"] = "1 ջոկատի հաղորդում",
		["messages.other"] = "%{count} ջոկատի հաղորդում",
		["memo.title"] = "Memo feed",
		["memo.description"] = "Կայուն է մինչեւ լեզվի կամ քանակի փոփոխություն։",
		["live.title"] = "Live feed",
		["live.description"] = "Վերակառուցվում է ամեն ավելորդ նկարումից։",
		["compare.title"] = "Թարգմանության արժեք",
	},
	ka = {
		["app.title"] = "დარტყმის პულტი",
		["app.subtitle"] = "ლოკალიზებული თამაშის UI აპის თარგმანებით.",
		["input.filter"] = "გაფილტრე ბრძანებების ჟურნალი...",
		["status.title"] = "მისიის სტატუსი",
		["status.ready"] = "გაშვებისთვის მზადაა",
		["status.zone"] = "ზონა %{zone}",
		["status.alert"] = "საფრთხე %{value}%",
		["stats.power"] = "რეაქტორი %{value}%",
		["stats.shield"] = "ფარი %{value}%",
		["stats.sync"] = "სინქი %{value}%",
		["commands.title"] = "ბრძანებები",
		["commands.scan"] = "სკანირება",
		["commands.launch"] = "გაშვება",
		["commands.guard"] = "დაცვა",
		["commands.recall"] = "დაბრუნება",
		["commands.cancel"] = "გაუქმება",
		["command.selected"] = "არჩეული ბრძანება: %{command}",
		["tabs.overview"] = "მიმოხილვა",
		["tabs.messages"] = "შეტყობინებები",
		["messages.one"] = "1 რაზმის შეტყობინება",
		["messages.other"] = "%{count} რაზმის შეტყობინება",
		["memo.title"] = "Memo არხი",
		["memo.description"] = "სტაბილურია ენის ან რაოდენობის ცვლილებამდე.",
		["live.title"] = "Live არხი",
		["live.description"] = "ხელახლა იგება ყოველი ზედმეტი render-ისას.",
		["compare.title"] = "თარგმნის ფასი",
	},
	he = {
		["app.title"] = "מסוף תקיפה",
		["app.subtitle"] = "ממשק משחק מקומי עם נתוני תרגום של האפליקציה.",
		["input.filter"] = "סנן יומן פקודות...",
		["status.title"] = "מצב משימה",
		["status.ready"] = "מוכן לשיגור",
		["status.zone"] = "אזור %{zone}",
		["status.alert"] = "מדד איום %{value}%",
		["stats.power"] = "כור %{value}%",
		["stats.shield"] = "מגן %{value}%",
		["stats.sync"] = "סנכרון %{value}%",
		["commands.title"] = "לוח פקודות",
		["commands.scan"] = "סריקה",
		["commands.launch"] = "שיגור",
		["commands.guard"] = "שמירה",
		["commands.recall"] = "החזרה",
		["commands.cancel"] = "ביטול",
		["command.selected"] = "פקודה בתור: %{command}",
		["tabs.overview"] = "סקירה",
		["tabs.messages"] = "הודעות",
		["messages.one"] = "הודעת צוות אחת",
		["messages.other"] = "%{count} הודעות צוות",
		["memo.title"] = "הזנה שמורה",
		["memo.description"] = "יציבה עד שינוי שפה או כמות.",
		["live.title"] = "הזנה חיה",
		["live.description"] = "נבנית מחדש בכל רינדור לא קשור.",
		["compare.title"] = "עלות תרגום",
	},
	mahajani = {
		["app.title"] = "𑅐𑅑𑅒 𑅓𑅔𑅕",
		["app.subtitle"] = "𑅖𑅗𑅘𑅙 𑅚𑅛𑅜𑅝 𑅞𑅟𑅠𑅡",
		["input.filter"] = "𑅐𑅑𑅒...",
		["status.title"] = "𑅓𑅔 𑅕𑅖",
		["status.ready"] = "𑅗𑅘𑅙",
		["status.zone"] = "𑅚 %{zone}",
		["status.alert"] = "𑅛𑅜 %{value}%",
		["stats.power"] = "𑅐 %{value}%",
		["stats.shield"] = "𑅑 %{value}%",
		["stats.sync"] = "𑅒 %{value}%",
		["commands.title"] = "𑅓𑅔𑅕",
		["commands.scan"] = "𑅐𑅑",
		["commands.launch"] = "𑅒𑅓",
		["commands.guard"] = "𑅔𑅕",
		["commands.recall"] = "𑅖𑅗",
		["commands.cancel"] = "𑅘𑅙",
		["command.selected"] = "𑅚𑅛: %{command}",
		["tabs.overview"] = "𑅜𑅝",
		["tabs.messages"] = "𑅞𑅟",
		["messages.one"] = "𑅐 𑅠𑅡",
		["messages.other"] = "%{count} 𑅠𑅡",
		["memo.title"] = "𑅢𑅣",
		["memo.description"] = "𑅤𑅥𑅦 𑅧𑅨𑅩",
		["live.title"] = "𑅪𑅫",
		["live.description"] = "𑅬𑅭𑅮 𑅯𑅰𑅱",
		["compare.title"] = "𑅲𑅳",
	},
	th = {
		["app.title"] = "คอนโซลโจมตี",
		["app.subtitle"] = "UI เกมหลายภาษาที่ใช้ข้อมูลแปลของแอป.",
		["input.filter"] = "กรองบันทึกคำสั่ง...",
		["status.title"] = "สถานะภารกิจ",
		["status.ready"] = "พร้อมปล่อยตัว",
		["status.zone"] = "โซน %{zone}",
		["status.alert"] = "ดัชนีภัย %{value}%",
		["stats.power"] = "เตาปฏิกรณ์ %{value}%",
		["stats.shield"] = "โล่ %{value}%",
		["stats.sync"] = "ซิงก์ %{value}%",
		["commands.title"] = "ชุดคำสั่ง",
		["commands.scan"] = "สแกน",
		["commands.launch"] = "ปล่อย",
		["commands.guard"] = "คุ้มกัน",
		["commands.recall"] = "เรียกกลับ",
		["commands.cancel"] = "ยกเลิก",
		["command.selected"] = "คำสั่งที่รอ: %{command}",
		["tabs.overview"] = "ภาพรวม",
		["tabs.messages"] = "ข้อความ",
		["messages.one"] = "ข้อความหน่วย 1 รายการ",
		["messages.other"] = "ข้อความหน่วย %{count} รายการ",
		["memo.title"] = "ฟีด memo",
		["memo.description"] = "คงที่จนกว่า locale หรือจำนวนข้อความจะเปลี่ยน.",
		["live.title"] = "ฟีด live",
		["live.description"] = "สร้างใหม่เมื่อมีการ render ที่ไม่เกี่ยวข้อง.",
		["compare.title"] = "ต้นทุนการแปล",
	},
	ko = {
		["app.title"] = "타격 콘솔",
		["app.subtitle"] = "앱 소유 번역 데이터로 구동되는 게임 UI.",
		["input.filter"] = "명령 로그 필터...",
		["status.title"] = "임무 상태",
		["status.ready"] = "발사 준비 완료",
		["status.zone"] = "구역 %{zone}",
		["status.alert"] = "위협 지수 %{value}%",
		["stats.power"] = "원자로 %{value}%",
		["stats.shield"] = "실드 %{value}%",
		["stats.sync"] = "동기화 %{value}%",
		["commands.title"] = "명령 덱",
		["commands.scan"] = "스캔",
		["commands.launch"] = "발사",
		["commands.guard"] = "방어",
		["commands.recall"] = "복귀",
		["commands.cancel"] = "취소",
		["command.selected"] = "대기 명령: %{command}",
		["tabs.overview"] = "개요",
		["tabs.messages"] = "메시지",
		["messages.one"] = "분대 메시지 1개",
		["messages.other"] = "분대 메시지 %{count}개",
		["memo.title"] = "메모 피드",
		["memo.description"] = "locale 또는 메시지 수가 바뀔 때까지 안정적입니다.",
		["live.title"] = "라이브 피드",
		["live.description"] = "관련 없는 렌더마다 다시 빌드됩니다.",
		["compare.title"] = "번역 비용",
	},
	am = {
		["app.title"] = "የጥቃት ኮንሶል",
		["app.subtitle"] = "በመተግበሪያ የተያዙ የትርጉም ውሂቦች የሚሰራ የጨዋታ UI.",
		["input.filter"] = "የትእዛዝ መዝገብ አጣራ...",
		["status.title"] = "የተልዕኮ ሁኔታ",
		["status.ready"] = "ለማስነሳት ዝግጁ",
		["status.zone"] = "ዞን %{zone}",
		["status.alert"] = "የአደጋ መጠን %{value}%",
		["stats.power"] = "ሬአክተር %{value}%",
		["stats.shield"] = "ጋሻ %{value}%",
		["stats.sync"] = "ማመሳሰል %{value}%",
		["commands.title"] = "የትእዛዝ ሰሌዳ",
		["commands.scan"] = "ቃኝ",
		["commands.launch"] = "አስነሳ",
		["commands.guard"] = "ጠብቅ",
		["commands.recall"] = "መልስ",
		["commands.cancel"] = "ሰርዝ",
		["command.selected"] = "የተዘጋጀ ትእዛዝ: %{command}",
		["tabs.overview"] = "አጠቃላይ",
		["tabs.messages"] = "መልዕክቶች",
		["messages.one"] = "1 የቡድን መልዕክት",
		["messages.other"] = "%{count} የቡድን መልዕክቶች",
		["memo.title"] = "Memo ፊድ",
		["memo.description"] = "locale ወይም ቁጥር እስኪቀየር ድረስ ይቆያል.",
		["live.title"] = "Live ፊድ",
		["live.description"] = "ተዛማጅ ያልሆነ render ሲመጣ እንደገና ይሰራል.",
		["compare.title"] = "የትርጉም ዋጋ",
	},
}

local theme = {
	backgroundColor = { 0.025, 0.035, 0.055, 1 },
	surfaceColor = { 0.055, 0.075, 0.11, 1 },
	surfaceHoverColor = { 0.08, 0.12, 0.16, 1 },
	surfacePressedColor = { 0.02, 0.04, 0.07, 1 },
	textColor = { 0.92, 0.98, 1, 1 },
	mutedTextColor = { 0.52, 0.68, 0.76, 1 },
	borderColor = { 0.12, 0.42, 0.54, 1 },
	accentColor = { 0.1, 0.84, 1, 1 },
	components = {
		button = {
			background = { 0.05, 0.11, 0.16, 1 },
			borderColor = { 0.1, 0.84, 1, 0.36 },
			borderWidth = 1,
			hover = { background = { 0.08, 0.18, 0.24, 1 }, borderColor = { 0.1, 0.84, 1, 0.8 } },
			pressed = { background = { 0.02, 0.07, 0.11, 1 } },
			focused = { borderColor = { 1, 0.86, 0.22, 1 }, borderWidth = 2 },
			active = { background = { 0.1, 0.84, 1, 0.22 }, borderColor = { 0.1, 0.84, 1, 1 } },
			variants = {
				danger = {
					background = { 0.32, 0.06, 0.08, 1 },
					borderColor = { 1, 0.2, 0.28, 0.75 },
					hover = { background = { 0.45, 0.08, 0.12, 1 } },
				},
			},
		},
		panel = {
			background = { 0.045, 0.06, 0.09, 0.92 },
			borderColor = { 0.1, 0.84, 1, 0.3 },
			borderWidth = 1,
		},
		input = {
			background = { 0.02, 0.035, 0.055, 1 },
			borderColor = { 0.1, 0.84, 1, 0.28 },
			focused = { borderColor = { 1, 0.86, 0.22, 1 }, borderWidth = 2 },
		},
	},
}

local function interpolate(value, params)
	if type(value) ~= "string" or type(params) ~= "table" then
		return value
	end

	return (value:gsub("%%{([%w_]+)}", function(name)
		local replacement = params[name]
		if replacement == nil then
			return "%{" .. name .. "}"
		end
		return tostring(replacement)
	end))
end

local function translate(key, params, opts)
	translationCalls = translationCalls + 1
	local tableForLocale = translations[locale] or translations.en
	local pluralKey = key
	if params and params.count then
		local candidate = key .. (params.count == 1 and ".one" or ".other")
		if tableForLocale[candidate] ~= nil or translations.en[candidate] ~= nil then
			pluralKey = candidate
		end
	end

	local value = tableForLocale[pluralKey] or translations.en[pluralKey]
	if value == nil and opts and opts.fallback then
		return opts.fallback
	end

	return interpolate(value, params)
end

local function activeLocale()
	for _, option in ipairs(localeOptions) do
		if option.id == locale then
			return option
		end
	end
	return localeOptions[1]
end

local function activeCommandMeta()
	for _, command in ipairs(commandMeta) do
		if command.id == selectedCommand then
			return command
		end
	end
	return commandMeta[1]
end

local function setup()
	ui.setTheme(theme)
	ui.i18n.configure({
		translate = translate,
		setLocale = function(nextLocale)
			locale = nextLocale
		end,
		getLocale = function()
			return locale
		end,
	})
end

local function teardown()
	ui.i18n.configure({})
	locale = "en"
	selectedTab = 1
	selectedCommand = "scan"
	messageCount = 3
	filter = ""
	renderCount = 0
	renderTick = 0
	liveBuilds = 0
	memoBuilds = 0
	translationCalls = 0
end

local function metric(key, value, color)
	return ui.column({ gap = 5, flex = 1 }, {
		ui.row({ gap = 6, align = "center" }, {
			ui.box({
				width = 6,
				height = 6,
				style = { background = color },
			}),
			ui.textKey(key, {
				textParams = { value = value },
				textCacheKey = "metric-label:" .. key .. ":" .. tostring(value),
				style = { color = ui.theme.mutedTextColor },
			}),
		}),
		ui.meter({
			value = value,
			min = 0,
			max = 100,
			height = 10,
			width = "100%",
			shape = { kind = "skew", skew = 8 },
			fillStyle = { background = color },
			trackStyle = { background = { 0, 0, 0, 0.35 } },
			label = "",
		}),
	})
end

local function infoChip(label, value, accent)
	return ui.box({
		display = "column",
		gap = 2,
		padding = { x = 9, y = 7 },
		flex = 1,
		style = {
			background = { 0.015, 0.035, 0.055, 1 },
			borderColor = accent,
			borderWidth = 1,
		},
	}, {
		ui.text(label, { style = { color = ui.theme.mutedTextColor } }),
		ui.text(value, { style = { color = accent } }),
	})
end

local function memoizedRows()
	memoBuilds = memoBuilds + 1
	return ui.column({ gap = 6 }, {
		ui.textKey("memo.description", {
			wrap = true,
			style = { color = ui.theme.mutedTextColor },
		}),
		ui.textKey("messages", {
			textParams = { count = messageCount },
			textCacheKey = "messages:" .. tostring(messageCount),
		}),
		ui.textKey("missing.example", { textFallback = "Fallback text for a missing key" }),
	})
end

local function liveRows()
	liveBuilds = liveBuilds + 1
	return ui.column({ gap = 6 }, {
		ui.textKey("live.description", {
			wrap = true,
			style = { color = ui.theme.mutedTextColor },
		}),
		ui.textKey("messages", {
			textParams = { count = messageCount },
		}),
		ui.textKey("missing.example", { textFallback = "Fallback text for a missing key" }),
	})
end

local function localeButton(option)
	local active = locale == option.id
	local accent = option.accent or ui.theme.accentColor
	return ui.button({
		labelKey = option.key,
		width = "100%",
		height = 34,
		active = active,
		style = {
			background = active and ui.mixColor(accent, { 0.02, 0.035, 0.055, 1 }, 0.7) or { 0.025, 0.06, 0.085, 1 },
			borderColor = active and accent or { 0.1, 0.84, 1, 0.26 },
			borderWidth = active and 2 or 1,
			color = active and { 1, 1, 1, 1 } or { 0.78, 0.9, 0.96, 1 },
			hover = {
				background = ui.mixColor(accent, { 0.025, 0.06, 0.085, 1 }, 0.76),
				borderColor = accent,
			},
			focused = {
				borderColor = { 1, 1, 1, 1 },
				borderWidth = 2,
			},
		},
		onClick = function()
			ui.i18n.setLocale(option.id)
		end,
	})
end

local function localePicker(compact)
	local buttons = {}
	for _, option in ipairs(localeOptions) do
		buttons[#buttons + 1] = localeButton(option)
	end

	return ui.panel({ title = "Locale Matrix", gap = 10, width = "100%" }, {
		ui.grid({
			width = "100%",
			minCellWidth = compact and 82 or 94,
			maxColumns = compact and 3 or 6,
			cellHeight = 34,
			gap = 8,
		}, buttons),
	})
end

local function localeReadout(compact)
	local option = activeLocale()
	local accent = option.accent or ui.theme.accentColor
	local chipStyle = {
		background = ui.mixColor(accent, { 0.02, 0.035, 0.055, 1 }, 0.82),
		borderColor = accent,
		borderWidth = 1,
	}
	local meta = {
		ui.box({
			display = "column",
			padding = { x = 8, y = 6 },
			style = chipStyle,
		}, {
			ui.text(option.script, { style = { color = { 1, 1, 1, 1 } } }),
		}),
		ui.box({
			display = "column",
			padding = { x = 8, y = 6 },
			style = chipStyle,
		}, {
			ui.text(option.font, { style = { color = ui.theme.mutedTextColor } }),
		}),
		ui.box({
			display = "column",
			padding = { x = 8, y = 6 },
			style = chipStyle,
		}, {
			ui.text(option.direction, { style = { color = ui.theme.mutedTextColor } }),
		}),
	}

	return ui.panel({ title = "Active Sample", gap = 10, width = "100%" }, {
		ui.row({ gap = 8, align = "center" }, {
			ui.textKey(option.key, { style = { fontSize = compact and 20 or 24, color = accent } }),
			ui.text(locale, { style = { color = ui.theme.mutedTextColor } }),
		}),
		ui.row({ gap = 8 }, meta),
		ui.textKey("app.subtitle", {
			wrap = true,
			style = { color = { 0.88, 0.96, 1, 1 } },
		}),
		ui.textKey("command.selected", {
			textParams = { command = ui.t("commands." .. selectedCommand) },
			textCacheKey = "readout:" .. selectedCommand .. ":" .. tostring(ui.i18n.version()),
			wrap = true,
			style = { color = accent },
		}),
	})
end

local function statChip(label, value, accent)
	return ui.box({
		display = "column",
		padding = { x = 10, y = 8 },
		flex = 1,
		style = {
			background = { 0.015, 0.035, 0.055, 1 },
			borderColor = accent,
			borderWidth = 1,
		},
	}, {
		ui.text(label, { style = { color = ui.theme.mutedTextColor } }),
		ui.text(value, { style = { color = accent } }),
	})
end

local function headerIntro(compact)
	local option = activeLocale()
	local accent = option.accent or ui.theme.accentColor
	local chips = {
		statChip("locale", locale, accent),
		statChip("version", tostring(ui.i18n.version()), { 1, 0.86, 0.22, 1 }),
		statChip("calls", tostring(translationCalls), { 0.38, 0.95, 0.5, 1 }),
	}

	return ui.column({ gap = 10, width = "100%" }, {
		ui.column({ gap = 3, width = "100%" }, {
			ui.textKey("app.title", { style = { fontSize = compact and 20 or 24, color = { 1, 1, 1, 1 } } }),
			ui.textKey("app.subtitle", {
				wrap = true,
				style = { color = ui.theme.mutedTextColor },
			}),
		}),
		ui.row({ gap = 8 }, chips),
	})
end

local function headerPanel(compact)
	local headerTop = compact and ui.column({ gap = 10, width = "100%" }, {
		headerIntro(compact),
		localeReadout(compact),
	}) or ui.row({ gap = 12, align = "stretch", width = "100%" }, {
		ui.box({ display = "column", flex = 1 }, {
			headerIntro(compact),
		}),
		ui.box({ display = "column", width = 300 }, {
			localeReadout(compact),
		}),
	})

	return ui.column({
		width = "100%",
		gap = 12,
		padding = 12,
		style = {
			background = { 0.02, 0.04, 0.065, 0.96 },
			borderColor = { 0.1, 0.84, 1, 0.28 },
			borderWidth = 1,
		},
	}, {
		headerTop,
		localePicker(compact),
	})
end

local function commandButton(command)
	local active = selectedCommand == command.id
	local accent = command.accent
	return ui.customButton({
		labelKey = "commands." .. command.id,
		width = "100%",
		height = 56,
		active = active,
		variant = command.danger and "danger" or nil,
		style = {
			background = active and ui.mixColor(accent, { 0.02, 0.035, 0.055, 1 }, 0.74) or { 0.018, 0.04, 0.06, 1 },
			borderColor = active and accent or { 0.1, 0.84, 1, 0.26 },
			borderWidth = active and 2 or 1,
			hover = {
				background = ui.mixColor(accent, { 0.018, 0.04, 0.06, 1 }, 0.84),
				borderColor = accent,
			},
			pressed = {
				background = ui.mixColor(accent, { 0.01, 0.02, 0.035, 1 }, 0.7),
			},
			focused = {
				borderColor = { 1, 1, 1, 1 },
				borderWidth = 2,
			},
		},
		onClick = function()
			selectedCommand = command.id
		end,
		draw = function(node, x, y, width, height, love, style, ctx)
			local hot = ui.isHovered(node) or ui.isFocused(node) or ui.isPressed(node) or selectedCommand == command.id
			local label = node.props.label or ui.t("commands." .. command.id)
			local hint = ui.t(command.hintKey)
			ctx:color(style.background)
			ctx:rect("fill", x, y, width, height)
			ctx:color(style.borderColor)
			ctx:rect("line", x, y, width, height)
			ctx:color(accent, hot and 1 or 0.52)
			ctx:rect("fill", x, y, 5, height)
			ctx:rect("fill", x + 13, y + height - 9, hot and 34 or 22, 2)
			ctx:color(accent, hot and 1 or 0.72)
			ctx:text(command.code, x + 16, y + 10)
			ctx:color({ 1, 1, 1, hot and 1 or 0.88 })
			ctx:text(label, x + 62, y + 9)
			ctx:color(ui.theme.mutedTextColor, hot and 0.95 or 0.7)
			ctx:text(hint, x + 62, y + 30)
		end,
	})
end

local function commandDeck()
	local buttons = {}
	for _, command in ipairs(commandMeta) do
		buttons[#buttons + 1] = commandButton(command)
	end

	return ui.panel({ titleKey = "commands.title", gap = 10, width = "100%" }, buttons)
end

local function statusPanel(compact)
	local commandLabel = ui.t("commands." .. selectedCommand)
	local command = activeCommandMeta()
	local accent = command.accent
	local chips = {
		infoChip("state", ui.t("status.ready"), { 0.38, 0.95, 0.5, 1 }),
		infoChip("zone", "A-17", { 0.1, 0.84, 1, 1 }),
		infoChip("threat", "34%", { 1, 0.86, 0.22, 1 }),
	}
	local telemetry = {
		metric("stats.power", 76, { 0.1, 0.84, 1, 1 }),
		metric("stats.shield", 58, { 0.38, 0.95, 0.5, 1 }),
		metric("stats.sync", 91, { 1, 0.86, 0.22, 1 }),
	}
	local tabContent = selectedTab == 1
		and ui.column({ gap = 12 }, {
			compact and ui.column({ gap = 8 }, chips) or ui.row({ gap = 8 }, chips),
			ui.box({
				display = "column",
				gap = 8,
				padding = 10,
				style = {
					background = { 0.012, 0.028, 0.046, 1 },
					borderColor = { 0.1, 0.84, 1, 0.24 },
					borderWidth = 1,
				},
			}, compact and ui.column({ gap = 10 }, telemetry) or ui.row({ gap = 12 }, telemetry)),
			ui.box({
				display = "column",
				gap = 4,
				padding = { x = 10, y = 8 },
				style = {
					background = ui.mixColor(accent, { 0.015, 0.03, 0.05, 1 }, 0.84),
					borderColor = accent,
					borderWidth = 1,
				},
			}, {
				ui.text("queued command", { style = { color = ui.theme.mutedTextColor } }),
				ui.textKey("command.selected", {
					textParams = { command = commandLabel },
					textCacheKey = "command:" .. selectedCommand .. ":" .. tostring(ui.i18n.version()),
					wrap = true,
					style = { color = accent },
				}),
			}),
			not compact and ui.textKey("status.alert", {
				textParams = { value = 34 },
				textCacheKey = "alert:34",
				style = { color = ui.theme.mutedTextColor },
			}) or nil,
		})
		or ui.column({ gap = 12 }, {
			compact and ui.column({ gap = 8 }, {
				infoChip("messages", tostring(messageCount), { 0.1, 0.84, 1, 1 }),
				infoChip("cache key", "messages-tab:" .. tostring(messageCount), { 1, 0.86, 0.22, 1 }),
			}) or ui.row({ gap = 8 }, {
				infoChip("messages", tostring(messageCount), { 0.1, 0.84, 1, 1 }),
				infoChip("cache key", "messages-tab:" .. tostring(messageCount), { 1, 0.86, 0.22, 1 }),
			}),
			ui.textKey("messages", {
				textParams = { count = messageCount },
				textCacheKey = "messages-tab:" .. tostring(messageCount),
				style = { color = ui.theme.mutedTextColor },
			}),
			ui.row({ gap = 8 }, {
				ui.button({ label = "-", width = 48, onClick = function() messageCount = math.max(0, messageCount - 1) end }),
				ui.button({ label = "+", width = 48, onClick = function() messageCount = messageCount + 1 end }),
			}),
		})

	return ui.panel({ titleKey = "status.title", gap = 12, width = "100%" }, {
		ui.tabs({ active = selectedTab, onChange = function(index) selectedTab = index end }, {
			{ labelKey = "tabs.overview", content = tabContent },
			{ labelKey = "tabs.messages", content = tabContent },
		}),
	})
end

local function comparisonPanel(compact)
	local comparisonLiveRows = liveRows()
	local comparisonMemoRows = ui.memo(memoizedRows, { ui.i18n.version(), messageCount })
	local savedBuilds = math.max(0, liveBuilds - memoBuilds)
	local maxBuilds = math.max(1, liveBuilds, memoBuilds, savedBuilds)
	local function counterTile(labelKey, value, accent, detail)
		return ui.box({
			display = "column",
			gap = 4,
			padding = { x = 10, y = 8 },
			flex = 1,
			style = {
				background = { 0.015, 0.035, 0.055, 1 },
				borderColor = accent,
				borderWidth = 1,
			},
		}, {
			ui.textKey(labelKey, {
				style = { color = ui.theme.mutedTextColor },
			}),
			ui.text(tostring(value), {
				style = { fontSize = 24, color = accent },
			}),
			detail and ui.text(detail, {
				wrap = true,
				style = { color = ui.theme.mutedTextColor },
			}) or nil,
		})
	end

	local function ledgerRow(titleKey, value, accent, cached)
		return ui.column({ gap = 5, width = "100%" }, {
			ui.row({ gap = 8, align = "center" }, {
				ui.textKey(titleKey, { style = { color = accent } }),
				ui.text(cached and "cached" or "fresh", { style = { color = ui.theme.mutedTextColor } }),
				ui.text(tostring(value), { style = { color = { 1, 1, 1, 1 } } }),
			}),
			ui.meter({
				value = value,
				max = maxBuilds,
				height = 8,
				width = "100%",
				shape = { kind = "skew", skew = 8 },
				fillStyle = { background = accent },
				trackStyle = { background = { 0, 0, 0, 0.35 } },
				label = "",
			}),
		})
	end

	local function feedLane(titleKey, countKey, count, rows, accent, note)
		return ui.box({
			display = "column",
			gap = 8,
			padding = 10,
			flex = 1,
			style = {
				background = { 0.012, 0.028, 0.046, 1 },
				borderColor = accent,
				borderWidth = 1,
			},
		}, {
			ui.row({ gap = 8, align = "center" }, {
				ui.textKey(titleKey, { style = { color = accent } }),
				ui.text(note, { style = { color = ui.theme.mutedTextColor } }),
			}),
			ui.textKey(countKey, {
				textParams = { count = count },
				textCacheKey = countKey .. ":" .. tostring(count),
			}),
			rows,
		})
	end

	local counters = {
		counterTile("compare.translation_calls_label", translationCalls, { 0.38, 0.95, 0.5, 1 }, "translator pressure"),
		counterTile("compare.renders_label", renderCount, { 0.1, 0.84, 1, 1 }, "full app passes"),
		counterTile("compare.saved_builds_label", savedBuilds, { 1, 0.86, 0.22, 1 }, "work avoided"),
	}

	return ui.panel({ titleKey = "compare.title", gap = 10, width = "100%" }, {
		ui.row({ gap = 8, align = "center" }, {
			ui.button({
				labelKey = "compare.rerender",
				width = compact and 132 or 150,
				onClick = function()
					renderTick = renderTick + 1
				end,
			}),
			ui.button({
				labelKey = "compare.reset",
				width = compact and 82 or 92,
				onClick = function()
					renderCount = 0
					renderTick = 0
					liveBuilds = 0
					memoBuilds = 0
					translationCalls = 0
				end,
			}),
		}),
		compact and ui.column({ gap = 8 }, counters) or ui.row({ gap = 8, align = "stretch" }, counters),
		ui.box({
			display = "column",
			gap = 8,
			padding = 10,
			style = {
				background = { 0.015, 0.035, 0.055, 1 },
				borderColor = { 0.1, 0.84, 1, 0.24 },
				borderWidth = 1,
			},
		}, {
			ledgerRow("live.title", liveBuilds, { 1, 0.36, 0.28, 1 }, false),
			ledgerRow("memo.title", memoBuilds, { 0.38, 0.95, 0.5, 1 }, true),
			ledgerRow("compare.saved_builds_label", savedBuilds, { 1, 0.86, 0.22, 1 }, true),
		}),
		(compact or ui.below("lg")) and ui.column({ gap = 10 }, {
			feedLane("live.title", "compare.live_builds", liveBuilds, comparisonLiveRows, { 1, 0.36, 0.28, 1 }, "fresh"),
			feedLane("memo.title", "compare.memo_builds", memoBuilds, comparisonMemoRows, { 0.38, 0.95, 0.5, 1 }, "cached"),
		}) or ui.row({ gap = 12, align = "stretch" }, {
			feedLane("live.title", "compare.live_builds", liveBuilds, comparisonLiveRows, { 1, 0.36, 0.28, 1 }, "fresh"),
			feedLane("memo.title", "compare.memo_builds", memoBuilds, comparisonMemoRows, { 0.38, 0.95, 0.5, 1 }, "cached"),
		}),
	})
end

local function App()
	renderCount = renderCount + 1
	local viewport = ui.viewport()
	local compact = ui.below("md")
	local padding = compact and 12 or 18
	local contentWidth = math.max(320, viewport.width - padding * 2 - 48)
	local commandWidth = compact and contentWidth or 230
	local mainWidth = compact and contentWidth or math.max(360, contentWidth - commandWidth - 16)

	local header = headerPanel(compact)

	local controls = ui.row({ gap = 10, align = "center" }, {
		ui.input({
			value = filter,
			onChange = function(nextValue)
				filter = nextValue
			end,
			placeholderKey = "input.filter",
			flex = 1,
		}),
	})

	local mainPanels = ui.column({ gap = 12, width = mainWidth }, {
		statusPanel(compact),
		comparisonPanel(compact),
	})

	local body = compact and ui.column({ gap = 12, width = "100%" }, {
		commandDeck(),
		mainPanels,
	}) or ui.row({ gap = 16, align = "start" }, {
		ui.column({ gap = 12, width = commandWidth }, {
			commandDeck(),
		}),
		mainPanels,
	})

	return ui.scrollView({ width = "100%", height = "100%" }, {
		ui.column({
			width = contentWidth,
			minHeight = viewport.height,
			padding = padding,
			gap = 12,
			style = { background = ui.theme.backgroundColor },
		}, {
			header,
			controls,
			body,
		}),
	})
end

return {
	id = "i18n",
	label = "I18n",
	description = "Switch Latin, CJK, RTL, Indic, Thai, Korean, and Ethiopic locale samples.",
	setup = setup,
	teardown = teardown,
	window = {
		width = 880,
		height = 600,
		minWidth = 420,
		minHeight = 440,
		title = "I18n - glyph.lua",
		resizable = true,
		breakpoints = { md = 720, lg = 980 },
	},
	component = function()
		return App()
	end,
}
