; ─────────────────────────────────────────────────────────────────────────────
; Mac-like keyboard on Windows
; Left Alt  = Cmd  (copy, paste, save, undo...)
; Left Ctrl = Ctrl (stays as-is for terminals, VS Code, etc.)
; Win key   = Option (word-jump, delete-word)
; ─────────────────────────────────────────────────────────────────────────────
#NoEnv
#SingleInstance Force
SendMode Input
SetWorkingDir %A_ScriptDir%

; ── Core shortcuts (Left Alt → Ctrl) ─────────────────────────────────────────
LAlt & c::Send ^c          ; Cmd+C  = Copy
LAlt & v::Send ^v          ; Cmd+V  = Paste
LAlt & a::Send ^a          ; Cmd+A  = Select All
LAlt & s::Send ^s          ; Cmd+S  = Save
LAlt & r::Send ^r          ; Cmd+R  = Refresh / Reload
LAlt & b::Send ^b          ; Cmd+B  = Bold / Toggle sidebar (VS Code)
LAlt & i::Send ^i          ; Cmd+I  = Italic
LAlt & u::Send ^u          ; Cmd+U  = Underline
LAlt & d::Send ^d          ; Cmd+D  = Duplicate / Bookmark
LAlt & y::Send ^y          ; Cmd+Y  = Redo (alternative)
LAlt & o::Send ^o          ; Cmd+O  = Open file
LAlt & j::Send ^j          ; Cmd+J  = Toggle terminal (VS Code)

LAlt & x::
    if GetKeyState("Shift", "P")
        Send ^+x            ; Cmd+Shift+X = Extensions (VS Code)
    else
        Send ^x             ; Cmd+X = Cut
return

LAlt & z::
    if GetKeyState("Shift", "P")
        Send ^y             ; Cmd+Shift+Z = Redo
    else
        Send ^z             ; Cmd+Z = Undo
return

LAlt & w::
    if GetKeyState("Shift", "P")
        Send ^+w            ; Cmd+Shift+W = Close all
    else
        Send ^w             ; Cmd+W = Close tab
return

LAlt & t::
    if GetKeyState("Shift", "P")
        Send ^+t            ; Cmd+Shift+T = Reopen closed tab
    else
        Send ^t             ; Cmd+T = New tab
return

LAlt & n::
    if GetKeyState("Shift", "P")
        Send ^+n            ; Cmd+Shift+N = New window / incognito
    else
        Send ^n             ; Cmd+N = New
return

LAlt & f::
    if GetKeyState("Shift", "P")
        Send ^+f            ; Cmd+Shift+F = Global search (VS Code)
    else
        Send ^f             ; Cmd+F = Find
return

LAlt & p::
    if GetKeyState("Shift", "P")
        Send ^+p            ; Cmd+Shift+P = Command Palette (VS Code)
    else
        Send ^p             ; Cmd+P = Print / Quick Open (VS Code)
return

LAlt & l::
    if GetKeyState("Shift", "P")
        Send ^+l            ; Cmd+Shift+L = Select all occurrences (VS Code)
    else
        Send ^l             ; Cmd+L = Focus address bar
return

LAlt & k::
    if GetKeyState("Shift", "P")
        Send ^+k            ; Cmd+Shift+K = Delete line (VS Code)
    else
        Send ^k             ; Cmd+K = Link
return

LAlt & e::
    if GetKeyState("Shift", "P")
        Send ^+e            ; Cmd+Shift+E = Explorer (VS Code)
    else
        Send ^e             ; Cmd+E = Use selection for find
return

LAlt & g::
    if GetKeyState("Shift", "P")
        Send ^+g            ; Cmd+Shift+G = Source Control (VS Code)
    else
        Send ^g             ; Cmd+G = Go to line / Find next
return

LAlt & /::
    if GetKeyState("Shift", "P")
        Send ^+/            ; Cmd+Shift+/ = Toggle block comment
return

; ── Quit / Minimize ──────────────────────────────────────────────────────────
LAlt & q::Send !{F4}       ; Cmd+Q = Quit/Close app
LAlt & m::WinMinimize, A   ; Cmd+M = Minimize window
LAlt & h::WinMinimize, A   ; Cmd+H = Hide (minimize)

; ── App switching ─────────────────────────────────────────────────────────────
LAlt & Tab::
    if GetKeyState("Shift", "P")
        Send {Alt down}{Shift down}{Tab}{Shift up}{Alt up}
    else
        Send {Alt down}{Tab}{Alt up}
return

LAlt & `::Send !{Tab}      ; Cmd+` = Next window of same app

; ── Text navigation (Cmd+Arrow) ──────────────────────────────────────────────
LAlt & Left::
    if GetKeyState("Shift", "P")
        Send +{Home}        ; Cmd+Shift+Left = Select to line start
    else
        Send {Home}         ; Cmd+Left = Line start
return

LAlt & Right::
    if GetKeyState("Shift", "P")
        Send +{End}         ; Cmd+Shift+Right = Select to line end
    else
        Send {End}          ; Cmd+Right = Line end
return

LAlt & Up::
    if GetKeyState("Shift", "P")
        Send ^+{Home}       ; Cmd+Shift+Up = Select to top
    else
        Send ^{Home}        ; Cmd+Up = Top of document
return

LAlt & Down::
    if GetKeyState("Shift", "P")
        Send ^+{End}        ; Cmd+Shift+Down = Select to bottom
    else
        Send ^{End}         ; Cmd+Down = Bottom of document
return

LAlt & BackSpace::Send +{Home}{BackSpace}  ; Cmd+Backspace = delete to line start

; ── Screenshots ───────────────────────────────────────────────────────────────
LAlt & 3::
    if GetKeyState("Shift", "P")
        Send #{PrintScreen} ; Cmd+Shift+3 = Full screenshot
    else
        Send ^3             ; Cmd+3 = Switch to tab 3
return

LAlt & 4::
    if GetKeyState("Shift", "P")
        Send #+s            ; Cmd+Shift+4 = Snip & Sketch (region)
    else
        Send ^4             ; Cmd+4 = Switch to tab 4
return

; ── Tabs (Cmd+1-9) ────────────────────────────────────────────────────────────
LAlt & 1::Send ^1
LAlt & 2::Send ^2
LAlt & 5::Send ^5
LAlt & 6::Send ^6
LAlt & 7::Send ^7
LAlt & 8::Send ^8
LAlt & 9::Send ^9

; ── Word jump / delete (Win key = Option) ────────────────────────────────────
LWin & Left::
    if GetKeyState("Shift", "P")
        Send ^+{Left}       ; Shift+Option+Left = Select word left
    else
        Send ^{Left}        ; Option+Left = Word left
return

LWin & Right::
    if GetKeyState("Shift", "P")
        Send ^+{Right}      ; Shift+Option+Right = Select word right
    else
        Send ^{Right}       ; Option+Right = Word right
return

LWin & BackSpace::Send ^{BackSpace}  ; Option+Backspace = Delete word left
LWin & Delete::Send ^{Delete}        ; Option+Delete = Delete word right

; ── Spotlight-style launcher ─────────────────────────────────────────────────
LAlt & Space::Send #{s}    ; Cmd+Space = Open Windows Search

; ── Pass through LWin alone (so Win key still opens Start Menu) ──────────────
LWin::
KeyWait, LWin
if (A_TimeSinceThisHotkey < 500 && !A_ThisHotkey ~= "&")
    Send #{s}
return

; ── Pass through LAlt alone (menus, Alt+Tab from other software) ─────────────
LAlt::
return
