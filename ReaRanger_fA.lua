-- @description ReaRanger fA - Realtime Region List Editor
-- @author foxAsteria
-- @version 0.7.21
-- @changelog
--   v0.7.21 (2026-06-16) — Title-bar app-name text recolored to the window bg grey
--     (0x787878, Col_WindowBg) per Poofox — was near-white and read poorly here.
--   v0.7.20 (2026-06-16) — Fix stale title-bar version label: the window drew a
--     hardcoded 'v0.7.15' (never bumped past the v0.7.16-0.7.19 batch) so it always
--     displayed the wrong version regardless of the real one. Now reads v0.7.20.
--   v0.7.19 (2026-06-16) — Ship prep: content-move CONFIRMED LIVE, diagnostics
--     stripped. Removed the `[ReaRanger reorder]` console spam and the verbose
--     "X items in spans · Y moved" status text; status now reads cleanly
--     "Reordered N regions (moved M items)". Item counts still go to telemetry
--     (Tel.log 'reorder') for usage analytics — just not in the user's face.
--     Also folds in v0.7.18b/c/d: label plate = button grey; WindowFlags_NoMove
--     (native move was hijacking per-digit number drags); list/table rect excluded
--     from drag-anywhere (inter-row gaps no longer yank the window).
--   v0.7.18 (2026-06-15) — color/readability + rename focus + font crash fix.
--     * FIXED load crash from v0.7.17: under the `require 'imgui' '0.9'` pin the
--       font API is CreateFont(family,SIZE,flags) + 2-arg PushFont(ctx,font) — NOT
--       the newer binary's CreateFont(family,flags)/PushFont(ctx,font,size). The
--       3-arg PushFont threw "expected 2 arguments maximum". Reverted to 0.9 sigs
--       (size baked at create). Mock now ENFORCES the 0.9 contract (asserts no 3rd
--       PushFont arg) so RuneGate catches this class next time.
--     * Rename/edit now focuses + selects-all on open: SetKeyboardFocusHere(ctx,-1)
--       (focuses the PREVIOUS widget) → SetKeyboardFocusHere(ctx) (offset 0 = the
--       InputText next). AutoSelectAll was already set; the wrong offset blocked it.
--       So double-click a name and just type. (All 4 inline editors fixed.)
--     * Overview lane honors CUSTOM colors (was clamped to grey via luminance_grey):
--       region with a color set draws in its true color; uncolored stays grey.
--     * Lane name labels get a translucent black plate → readable over any color.
--     * Region name text (list + lane) is now 93% white (NAME_TEXT_COL 0xEDEDEDFF).
--   v0.7.17 (2026-06-15) — Bold time cells + per-digit drag.
--     * Start/Length times now render in a BOLD font (CreateFont 'sans-serif'
--       Bold, attached once; pushed only around the cells at GetFontSize).
--     * Per-digit drag: in Time mode each number group (minutes / seconds / ms) is
--       its own draggable item — drag just the one you grab, in that place's units
--       (60s / 1s / 10ms per step). Hold Ctrl for fine (10× smaller) steps. Beats
--       mode keeps the whole-cell grid-snap drag. num_drag gained a `place` field;
--       process_num_drag branches place-step vs grid-snap. New DRAG_PX_PER_DIGIT=7.
--     * Mock hardened to ReaImGui 0.9 font API (CreateFont 2-arg, PushFont 3-arg +
--       size assert, GetFontSize, Mod_Ctrl, Key_LeftCtrl) — real-vs-mock parity.
--   v0.7.16 (2026-06-15) — THE CONTENT-MOVE FIX + UI polish.
--     * ROOT CAUSE of "content doesn't move" FOUND via telemetry (not the mover,
--       not ownership): every mutation wrapped PreventUIRefresh(1)..(-1) but NONE
--       called UpdateArrange()/UpdateTimeline(). Items' D_POSITION WAS being
--       rewritten correctly (telemetry: 90/90 items shifted) — REAPER just never
--       repainted the arrange view, so the audio looked frozen while markers moved
--       (SetProjectMarker4 self-refreshes). Added UpdateArrange()+UpdateTimeline()
--       after all four PreventUIRefresh(-1) (move/move_free/gap/reorder). Hardened
--       RuneGate mock with reaper.UpdateArrange (was missing — real-vs-mock gap).
--     * Labels: consistent Capitalized — "len"→"Length", "Gap len"→"Gap Length",
--       "regions:"/"items:"→"Regions:"/"Items:". Regions mode "Overlay"→"Lanes".
--     * +G button → "+Gap"; once a gap exists the button shows its actual length
--       (e.g. "2s") via new gap_after() helper. Single-click adds more, dbl-click types.
--   v0.7.15 (2026-06-15) — HOTFIX: load crash "stack overflow" at tip(). The
--     v0.7.14 sed that routed every SetTooltip through the new tip() gate also
--     rewrote the body of tip() ITSELF (it contained a SetTooltip call) into
--     `tip(s) = tip(s)` → infinite recursion on first hover. Restored the body to
--     call ImGui.SetTooltip directly. RuneGate mock missed it because the mock's
--     IsItemHovered returns false, so tip() was never invoked in 5 frames.
--   v0.7.14 — see below (region content-move plumbing, Insert/Overlay toggle, etc).
--   v0.7.14 (2026-06-15) — THREE live-test bugs, one root cause each:
--     (1) Double-click-to-edit was DEAD everywhere (name, start, length). The
--         v0.7.7 whole-row drag Selectable used SpanAllColumns, which overlapped
--         the plain-Text cells and stole their hover → IsItemHovered never fired
--         → no dbl-click registered. Buttons (color/+G) still worked because they
--         claim hover. FIX: drag handle is now col-0 (the number) only, no span.
--         The LANE is the primary reorder surface now anyway.
--     (2) Content didn't follow a lane move + every move spawned a NEW LANE. Lane
--         drag called apply_move_free, which is MARKER-ONLY the instant pack_lanes
--         bumped the (now-overlapping) region to lane>0. So the audio was left
--         behind and the region jumped to a new row. FIX: new Insert/Overlay mode
--         toggle. INSERT (default) routes a lane move through commit_reorder — the
--         deterministic per-item content-shifter (no 40200/ripple-pref fragility) —
--         so other regions move out of the way and audio follows, single row.
--         OVERLAY keeps the old free-place/stack/marker-only behavior.
--     (3) No indication of insert-vs-overlay: INSERT mode now draws a bright
--         insertion caret at the drop slot; OVERLAY draws the free ghost in-lane.
--   v0.7.13 (2026-06-15) — HOTFIX: title-bar crash on load ("CalcTextSize arg #3
--     number expected, got boolean"). Lua sig is (ctx,text,w,h,hide,wrap) — the
--     hide bool was sitting in the w out-slot. Pass nil,nil first. (Pre-existing
--     real-vs-mock divergence; RuneGate mock now type-checks this signature.)
--   v0.7.12 (2026-06-15) — PUNCH #9: custom colour picker in the palette popup.
--   - Right-click colour cell → grey presets PLUS a full ColorPicker4 (RGB/HSV +
--     alpha). Live-previews in memory; commits to REAPER once on release (no undo
--     spam). Inline swatch left-click still opens ImGui's quick picker too.
--   v0.7.11 (2026-06-15) — FIX: lane double-click rename now accepts typed text.
--   - The full-lane InvisibleButton overlapped the rename InputText and ate its
--     keyboard focus; swap it for a non-interactive Dummy while renaming.
--   v0.7.10 (2026-06-14) — PUNCH #5: beats/time display toggle
--   - Toolbar button toggles Start/Length cells between MM:SS.mmm (time) and
--     measures.beats (musical). Display AND direct-entry follow the mode; drag/
--     snap math stays in seconds (display-only). Uses REAPER format/parse_timestr
--     pos/len, mode 2.
--   v0.7.9 (2026-06-14) — overlap = marker semantics
--   - Overlapping regions are now treated as OVERLAY/marker annotations: the
--     non-overlapping set is the "arrangement" (moving it moves content); a
--     region bumped to a higher row moves its MARKER ONLY, ignoring content — so
--     dropping a region inside another is harmless (nothing reflows), and growing
--     its end just resizes the marker. Classification: greedy pack with longer-
--     first tie-break, so the big section claims the base lane and small nested
--     ones become overlays. Overlay regions get a brighter border + tooltip note.
--   v0.7.8 (2026-06-14) — overlapping regions + stacked lanes + strong snapping
--   - Overview lane now STACKS overlapping/nested regions into rows (greedy
--     interval packing). No overlaps → single row, unchanged. Nested sections
--     (same start, different length) auto-expand so each is visible/grabbable.
--     Lane assignment is ours (display only) — REAPER's ruler-lane data is NOT
--     exposed to ReaScript (EnumProjectMarkers3/SetProjectMarker4 have no lane).
--   - Lane hit-testing is now x+y aware so stacked regions resolve correctly.
--   - Lane block-drag MOVE is now a FREE move (no ripple, no clamp) so regions
--     can overlap/nest. Strong magnetic snapping to other regions' ends (grid as
--     fallback) makes clean end-to-end butting the easy default. Resize edge also
--     snaps to ends. Table-row reorder remains the sequential reflow/swap path.
--   v0.7.7 (2026-06-14) — PUNCH #7: drag the ROW, no handle column
--   - Removed the dedicated "=" drag column. The whole table row is now the
--     drag surface — grab a row by its number (or any empty spot) and drop it on
--     another row to reorder. Reorder behaviour is unchanged: regions re-lay-out
--     sequentially from the first region's start, content follows, never overlap.
--   - Implemented with a row-spanning Selectable + SetNextItemAllowOverlap so the
--     cells (color/name/time/actions) stay clickable on top of it. Hosts without
--     AllowOverlap fall back to a col-0-only grab (no v0.7.3 hover-steal regress).
--   - Table is now 6 columns (#, Color, Name, Start, Length, actions).
--   v0.7.6 (2026-06-14) — title bar returns
--   - Added a custom title BAND at the very top (above the overview lane): app
--     name + the word-wrapped info/stats line + the X close button now live
--     there. Band height adapts to the wrapped text so it can't clip on a narrow
--     window. Toolbar row is now controls-only (stats/X moved up to the band).
--   - Window stays borderless/drag-anywhere (v0.6.0); the band is the visual
--     title bar, app name drawn via draw-list so that strip stays draggable.
--   v0.7.5 (2026-06-13) — PUNCH #8: lane-drag (the headline ask)
--   - Drag a region's BODY on the overview lane = move it; content ripples with
--     it (apply_start → native 40200/40201). Drag the RIGHT EDGE = resize length
--     (apply_length). Bright ghost outline previews the result while dragging;
--     ripple commits ONCE on mouse release (never per-frame).
--   - Plain click (no travel) still navs the edit cursor; double-click still
--     renames. Resize-cursor hint shows when hovering a region's right edge.
--   - v0.7.4 (prior, unbumped header): overview lane moved above the toolbar;
--     "+ Add at cursor" → "+ Region at cursor".
--   v0.7.3 (2026-06-13)
--   - FIXED the "nothing happens" bug at its root. The col-0 drag handle used
--     SelectableFlags_SpanAllColumns, covering the whole row and stealing hover
--     from the time cells + name cell. Time-cell drag and dbl-click name edit
--     never armed. Handle is now contained to col 0. (This is why v0.7.2's
--     ripple "did nothing" — the drag that triggers it never fired.)
--   - Reorder grab: col-0 `=` handle now fills the column (22px strip) instead of
--     a ~7px glyph, so rows are actually grabbable.
--   - Toolbar fix: the long help text overflowed the window and pushed the X
--     close button off-screen. Help text moved to its own wrapped line; X + gap-len
--     field are now visible/reachable.
--   v0.7.2 (2026-06-13)
--   - Single-region move now RIPPLES content (closes the last marker-only gap).
--     Drag a region's start cell (or type a new start): r + every later region
--     and their media reflow by the same delta. True-arranger behavior.
--   - Move-earlier clamped at previous region's end — ripple can't reflow
--     backward into another section's audio (non-destructive).
--   - Start cell is now commit-on-release: drag shows a live preview, the ripple
--     fires once on mouse-up (no per-frame ripple thrash). Grid-snap preserved.
--   v0.7.1 (2026-06-12)
--   - CONTENT MOVES WITH REGIONS. The big one. Gap insert + reorder now move
--     media items, not just markers. (Was the "nothing happens in project" bug.)
--   - Gap insert: wraps Main_OnCommand(40200) under forced ripple-all,
--     restores user ripple mode after.
--   - Reorder: per-item position shift, atomic. No ripple side-effects.
--   - apply_start (single-region drag) remains marker-only — content-move for
--     arbitrary single moves is v0.7.2+ work.
--   - Beta telemetry: anonymous usage JSONL at
--     <REAPER>/Data/ReaRanger/rr_<machine>_<date>.jsonl. Action counts, lengths,
--     region totals. No content. Daily rotated, flushed every 30s.
--   v0.7.0 (2026-06-10)
--   - Renamed: ReaRegions → ReaRanger. Better name (REAPER + Ranger = region
--     patroller/navigator). All filenames, titles, undo blocks updated.
--   v0.6.0 (2026-05-31)
--   - No title bar. Drag the window from any empty space inside it.
--   - Manual close: X button in toolbar (right-aligned), or Esc when nothing else editing.
--   v0.5.0 (2026-05-31)
--   - All-greyscale theme, mid-contrast, no dark backgrounds anywhere.
--   - Window: full grey ImGui style stack (window/frame/button/header/table all mid greys).
--   - Lane: luminance-mapped greyscale rects (mid-light band 0x98–0xC8), light playhead.
--   - Palette: replaced 17 chromatic colors with 8 mid-grey shades (Shadow → Bone).
--   v0.4.0 (2026-05-31)
--   - In-place name editing in BOTH table and lane (dbl-click region block in lane,
--     or dbl-click name in table). No cross-jumping — edit happens where you click.
--   - Table name column: now TextDisabled by default, dbl-click enters edit (was
--     always-on InputText, sloppier).
--   v0.3.0 (2026-05-31)
--   - Region overview lane above table: full project at a glance, colored blocks,
--     click = nav edit cursor, hover = tooltip, magenta playhead.
--   - Snap-drag deadzone bumped 2→5 px (dblclick first-down no longer triggers undo).
--   v0.2.0 (2026-05-31)
--   - Time cells: drag up/down snaps to project grid (was janky mousewheel — removed).
--   - Double-click time = MM:SS.mmm direct edit (ported from ArrangeForge time_cell).
--   - Add Gap After: shifts following regions right by N seconds (one undo block).
--   - Lifted parse_time_full / fmt_time_full from AF.
--   v0.1.0 (2026-05-30)
--   - First cut. Plain region list. Rename / start / length / color / drag-to-reorder.
--   - No timeline viz, no themes, no snapshots. Just the list.
-- @link https://github.com/Poofox/fA_ScriptNexus
-- @about
--   # ReaRanger fA
--
--   The basic version of ArrangeForge for the guy who doesn't need the
--   bells and whistles. Just a live, editable region list:
--
--   - Rename, edit start/length, change color inline (live to project)
--   - Drag rows to reorder the section sequence on the timeline
--   - Polls regions every 0.5s so external changes show up
--
--   Requires ReaImGui v0.9+ (install via ReaPack).
--
--   MIT License | foxAsteria & Planty C

package.path = reaper.ImGui_GetBuiltinPath() .. '/?.lua'
local ImGui = require 'imgui' '0.9'

-- Whole-row drag (v0.7.7) needs SetNextItemAllowOverlap so a row-spanning
-- Selectable can be the drag surface WITHOUT stealing hover from the cells on
-- top of it. ReaImGui's strict __index THROWS on unknown fields, so probe via
-- pcall. If absent, we fall back to a col-0-only drag handle (no row span).
local HAS_ALLOW_OVERLAP = false
do
  local ok, fn = pcall(function() return ImGui.SetNextItemAllowOverlap end)
  HAS_ALLOW_OVERLAP = ok and fn ~= nil
end

local SCRIPT_TITLE = 'ReaRanger fA'
local POLL_INTERVAL = 0.5
local DEFAULT_COLOR_RGBA = 0x888888FF  -- Mid grey (Ash)
local LANE_BG_COL        = 0x808080FF  -- mid grey lane background
local LANE_BORDER_COL    = 0x606060FF  -- subtle lane outline
local LANE_RECT_BORDER   = 0x303030FF  -- defining border on each region rect
local LANE_LABEL_COL     = 0x202020FF  -- dark-on-grey for readable labels
local NAME_TEXT_COL      = 0xEDEDEDFF  -- 93% white — region name text (list + lane), per Poofox
local LANE_LABEL_BG_COL  = 0x6C6C6CFF  -- plate behind lane labels = same grey as button bg (Col_Button), per Poofox
local PLAYHEAD_COL       = 0xD8D8D8FF  -- near-white grey
local EMPTY_TEXT_COL     = 0x404040FF
local GHOST_COL          = 0xF8F8F8FF  -- bright ghost outline for lane drag preview
local TITLE_BG_COL       = 0x383838FF  -- title-bar band background
local TITLE_TEXT_COL     = 0x787878FF  -- title-bar app name = window bg grey (Col_WindowBg), per Poofox
local OVERLAY_BORDER_COL = 0xE0E0E0FF  -- brighter border = overlay/marker region (lane > 0)
local INSERT_CARET_COL   = 0xFFFFFFFF  -- pure-white insertion caret (insert-mode drop slot)
local INSERT_GHOST_COL   = 0xFFFFFF44  -- translucent landing rect at the insert slot
local DEFAULT_GAP_LEN   = 2.0           -- seconds (matches AF DEFAULT_GAP_LEN)
local DRAG_PX_PER_SNAP  = 12            -- pixels of vertical drag to advance one grid step
local DRAG_PX_PER_DIGIT = 7             -- pixels of vertical drag per per-digit place step (v0.7.17)

-- Greyscale-only palette. Mid-contrast — no near-black, no near-white.
local SECTION_PALETTE = {
  {name='(default)', col=0},
  {name='Shadow',    col=0x585858FF},
  {name='Stone',     col=0x686868FF},
  {name='Smoke',     col=0x787878FF},
  {name='Ash',       col=0x888888FF},
  {name='Mist',      col=0x989898FF},
  {name='Pearl',     col=0xA8A8A8FF},
  {name='Bone',      col=0xB8B8B8FF},
}

-- ====================================================================
-- Color helpers — REAPER native int <-> RGBA32 (R high)
-- ====================================================================
local function native_to_rgba(col)
  if col == 0 then return DEFAULT_COLOR_RGBA end
  local r, g, b
  if col & 0x01000000 ~= 0 then
    b = col & 0xFF; g = (col >> 8) & 0xFF; r = (col >> 16) & 0xFF
  else
    r = (col >> 16) & 0xFF; g = (col >> 8) & 0xFF; b = col & 0xFF
  end
  if r == 0 and g == 0 and b == 0 then return DEFAULT_COLOR_RGBA end
  return (r << 24) | (g << 16) | (b << 8) | 0xFF
end

-- Luminance-clamp any RGBA into a mid-tone grey. Used for lane rendering so
-- user-picked colors still produce a *hint* of variation, but everything stays
-- in the mid-greyscale band.
local function luminance_grey(rgba, lo, hi)
  local r = (rgba >> 24) & 0xFF
  local g = (rgba >> 16) & 0xFF
  local b = (rgba >> 8)  & 0xFF
  local lum = math.floor(0.299*r + 0.587*g + 0.114*b)
  if lum < lo then lum = lo end
  if lum > hi then lum = hi end
  return (lum << 24) | (lum << 16) | (lum << 8) | 0xFF
end

local function rgba_to_native(rgba)
  if rgba == 0 then return 0 end  -- 0 = let REAPER use default
  local r = (rgba >> 24) & 0xFF
  local g = (rgba >> 16) & 0xFF
  local b = (rgba >> 8) & 0xFF
  return (r << 16) | (g << 8) | b | 0x01000000
end

-- ====================================================================
-- Telemetry (v0.7.1) — lightweight JSONL usage logger.
-- Beta: always on, transparent in script @about. Daily-rotated file at
-- <REAPER>/Data/ReaRanger/rr_<machine>_<date>.jsonl. Buffers, flushes every 30s.
-- Adapted from FaSuite/reapack/preview/lib/fA_telemetry.lua (2026-04).
-- ====================================================================
local Tel = {}
do
  local DATA_DIR = reaper.GetResourcePath() .. '/Data/ReaRanger/'
  local FLUSH_INTERVAL = 30
  local MAX_BUFFER = 80
  local machine = (os.getenv('COMPUTERNAME') or os.getenv('HOSTNAME') or 'unknown'):gsub('[^%w%-_]', '')
  local session_id = os.time() .. '_' .. machine .. '_' .. math.random(1000, 9999)
  local session_start = reaper.time_precise()
  local buffer = {}
  local last_flush = reaper.time_precise()
  local action_count = 0
  local current_date = os.date('%Y-%m-%d')
  local log_path = nil
  local active = false

  local function get_log_path()
    return DATA_DIR .. string.format('rr_%s_%s.jsonl', machine, os.date('%Y-%m-%d'))
  end

  local function escape(s)
    if not s then return '' end
    return (tostring(s):gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', ''):gsub('\t', '\\t'))
  end

  local function get_project()
    local _, fn = reaper.EnumProjects(-1)
    if fn and fn ~= '' then
      return fn:match('([^\\/]+)%.RPP$') or fn:match('([^\\/]+)$') or fn
    end
    return '(unsaved)'
  end

  local function build_json(entry)
    local s = string.format(
      '{"ts":%d,"sid":"%s","m":"%s","a":"%s","prj":"%s","st":%.1f',
      entry.ts, session_id, machine, escape(entry.action), escape(entry.project), entry.session_time
    )
    if entry.detail then s = s .. ',"d":' .. entry.detail end
    return s .. '}'
  end

  function Tel.log(action, detail)
    if not active then return end
    action_count = action_count + 1
    table.insert(buffer, {
      ts = os.time(),
      action = action,
      project = get_project(),
      session_time = reaper.time_precise() - session_start,
      detail = detail,
    })
    if #buffer >= MAX_BUFFER then Tel.flush() end
  end

  function Tel.log_snapshot(S)
    if not active then return end
    local n = #(S.regions or {})
    local total_len = 0
    for _, r in ipairs(S.regions or {}) do total_len = total_len + (r.len or 0) end
    Tel.log('snapshot', string.format('{"regions":%d,"total_len":%.2f}', n, total_len))
  end

  function Tel.flush()
    if #buffer == 0 then return end
    local today = os.date('%Y-%m-%d')
    if today ~= current_date then
      current_date = today
      log_path = get_log_path()
    end
    local f = io.open(log_path, 'a')
    if not f then return end
    for _, entry in ipairs(buffer) do f:write(build_json(entry) .. '\n') end
    f:close()
    buffer = {}
    last_flush = reaper.time_precise()
  end

  function Tel.tick()
    if not active then return end
    if reaper.time_precise() - last_flush > FLUSH_INTERVAL then Tel.flush() end
  end

  function Tel.init(version)
    reaper.RecursiveCreateDirectory(DATA_DIR, 1)
    log_path = get_log_path()
    active = true
    Tel.log('session_start', string.format('{"version":"%s","os":"%s"}',
      escape(version or '?'), escape(reaper.GetOS() or '?')))
  end

  function Tel.shutdown()
    if not active then return end
    Tel.log('session_end', string.format('{"actions":%d,"duration":%.1f}',
      action_count, reaper.time_precise() - session_start))
    Tel.flush()
    active = false
  end
end

-- ====================================================================
-- State
-- ====================================================================
local S = {
  regions = {},               -- ordered by current timeline pos
  last_marker_count = -1,
  last_poll_t = 0,
  dirty = true,
  edit_name = {},             -- [region_id] = string buffer for in-flight name edit
  drag_src = nil,             -- index in S.regions currently being dragged
  num_drag = nil,             -- {key, start_val, place, on_apply, on_release, preview_val, undo_started} during a time-cell drag. place=seconds/step → per-digit; nil → grid-snap
  edit = nil,                 -- {id=rid, field='start'|'len', buf=str, focused=bool} during direct edit
  rename = nil,               -- {id=rid, buf=str, focused=bool, where='table'|'lane'} during name edit
  lane_drag = nil,            -- {id, mode='move'|'resize', start_x, orig_pos, orig_len, moved, preview} during lane drag
  gap_len = 2.0,              -- user-editable gap insertion length (seconds) — remembers last typed
  gapedit = nil,              -- {id=rid, buf=str, focused=bool} during per-row type-gap (#4)
  time_mode = 'time',         -- 'time' = MM:SS.mmm · 'beats' = measures.beats (#5 toggle)
  lane_mode = 'insert',       -- 'insert' = lane move reorders+ripples content (arranger) · 'overlay' = free place / stack
  overlap_mode = 'overlap',   -- when overlay-placed regions overlap: 'overlap' = hard stack · 'crossfade' = REAPER auto-crossfade
  new_region_len = 4.0,       -- length (s) for "+ Region at cursor"
  tooltips_on = true,         -- master toggle for hover tooltips (? button by the X)
  status_msg = '',
  status_t = 0,
  win_drag = nil,             -- {wx, wy} window pos at drag start (drag-anywhere)
  want_close = false,
}

local function set_status(msg)
  S.status_msg = msg
  S.status_t = reaper.time_precise()
end

-- ====================================================================
-- Region IO
-- ====================================================================
local function load_regions()
  S.regions = {}
  local i = 0
  while true do
    local ok, isrgn, pos, rend, name, idx, color = reaper.EnumProjectMarkers3(0, i)
    if ok == 0 then break end
    if isrgn then
      table.insert(S.regions, {
        enum_i = i,
        id = idx,
        pos = pos,
        rend = rend,
        len = rend - pos,
        name = name ~= '' and name or ('Region ' .. idx),
        color_native = color,
        color_rgba = native_to_rgba(color),
      })
    end
    i = i + 1
  end
  table.sort(S.regions, function(a, b) return a.pos < b.pos end)
  S.last_marker_count = reaper.CountProjectMarkers(0)
  S.dirty = false
end

local function maybe_poll()
  local t = reaper.time_precise()
  if t - S.last_poll_t < POLL_INTERVAL then return end
  S.last_poll_t = t
  if reaper.CountProjectMarkers(0) ~= S.last_marker_count then S.dirty = true end
end

-- ====================================================================
-- REAPER snap helpers — respect Options: Toggle snapping (cmd 1157)
-- ====================================================================
local function snap_enabled()
  if not reaper.GetToggleCommandStateEx then return false end
  return reaper.GetToggleCommandStateEx(0, 1157) == 1
end

local function maybe_snap(t)
  if t < 0 then t = 0 end
  if snap_enabled() and reaper.SnapToGrid then return reaper.SnapToGrid(0, t) end
  return t
end

-- Seconds per project-grid unit (for mousewheel stepping)
local function grid_step_sec()
  local division = 0.25  -- default quarter note
  if reaper.GetSetProjectGrid then
    local _, div = reaper.GetSetProjectGrid(0, false)
    if div and div > 0 then division = div end
  end
  local bpm = reaper.Master_GetTempo and reaper.Master_GetTempo() or 120
  if bpm <= 0 then bpm = 120 end
  return (division * 4 * 60) / bpm
end

-- ====================================================================
-- Native-ripple hybrid (v0.7.1): content moves with regions.
-- We force ripple-all around a content-moving action, then restore the
-- user's original ripple mode. Detection via GetToggleCommandState — robust
-- without SWS extension.
-- ====================================================================
local function get_ripple_mode()
  -- 0=off  1=per-track  2=all
  if reaper.GetToggleCommandState(40311) == 1 then return 2 end
  if reaper.GetToggleCommandState(40310) == 1 then return 1 end
  return 0
end

local function set_ripple_mode(m)
  if m == 0 then reaper.Main_OnCommand(40309, 0)
  elseif m == 1 then reaper.Main_OnCommand(40310, 0)
  elseif m == 2 then reaper.Main_OnCommand(40311, 0) end
end

-- Auto-crossfade option (40912 = "Options: Auto-crossfade media items when
-- editing"). Self-guarding: GetToggleCommandState returns -1 if the id isn't
-- valid on this build → we no-op rather than fire a wrong command. Only toggles
-- when the current state differs from what overlap_mode wants.
local AUTOXFADE_CMD = 40912
local function set_autoxfade(on)
  local st = reaper.GetToggleCommandState(AUTOXFADE_CMD)
  if st == -1 then return end
  if (st == 1) ~= (on == true) then reaper.Main_OnCommand(AUTOXFADE_CMD, 0) end
end

local function with_ripple_all(fn)
  local prev = get_ripple_mode()
  if prev ~= 2 then set_ripple_mode(2) end
  local ok, err = pcall(fn)
  if prev ~= 2 then set_ripple_mode(prev) end
  if not ok then reaper.ShowConsoleMsg('ReaRanger ripple-op error: '..tostring(err)..'\n') end
end

-- ====================================================================
-- Region mutations (each wraps its own undo block; live to project)
-- ====================================================================
local function apply_rename(r, new_name)
  if not r or not new_name or new_name == '' or new_name == r.name then return end
  reaper.Undo_BeginBlock()
  reaper.SetProjectMarker4(0, r.id, true, r.pos, r.rend, new_name, r.color_native, 0)
  reaper.Undo_EndBlock('ReaRanger: rename region', -1)
  r.name = new_name
  S.dirty = true
  Tel.log('rename')
end

-- v0.7.2: single-region move now RIPPLES — moves r's content + every later
-- region (and its content) by the same delta, true-arranger reflow.
-- Non-destructive: a move-earlier is clamped at the previous region's end so
-- ripple can never reflow backward into another section's audio.
-- Mechanism mirrors add_gap_after: native ripple-all shifts items, we shift the
-- markers ourselves (ripple leaves markers untouched on this system).
local function apply_start(r, new_start)
  if not r then return end
  if new_start < 0 then new_start = 0 end

  -- locate r in the (position-sorted) region list
  local idx
  for k, rr in ipairs(S.regions) do if rr.id == r.id then idx = k; break end end
  if not idx then return end

  -- clamp move-earlier at previous region's end (no backward overlap)
  local clamped = false
  if idx > 1 then
    local prev_end = S.regions[idx - 1].rend
    if new_start < prev_end then new_start = prev_end; clamped = true end
  end

  local delta = new_start - r.pos
  if math.abs(delta) < 1e-6 then
    if clamped then set_status('Move clamped at previous region end') end
    return
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Content ripple: shift r's content + ALL later content by delta.
  -- Anchored at r's ORIGINAL start so the empty span added/removed sits just
  -- before r. (delta<0 span is guaranteed empty by the clamp above.)
  with_ripple_all(function()
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    if delta > 0 then
      reaper.GetSet_LoopTimeRange(true, false, r.pos, r.pos + delta, false)
      reaper.Main_OnCommand(40200, 0)   -- insert empty space: r + later shift right
    else
      reaper.GetSet_LoopTimeRange(true, false, r.pos + delta, r.pos, false)
      reaper.Main_OnCommand(40201, 0)   -- remove empty span: r + later pull left
    end
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)

  -- markers untouched by ripple — slide r and every later region by delta
  for j = idx, #S.regions do
    local rr = S.regions[j]
    reaper.SetProjectMarker4(0, rr.id, true, rr.pos + delta, rr.rend + delta,
                             rr.name, rr.color_native, 0)
    rr.pos = rr.pos + delta
    rr.rend = rr.rend + delta
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()   -- force arrange redraw: programmatic D_POSITION moves
  reaper.UpdateTimeline()  -- don't repaint on their own (the "content didn't move" bug)
  reaper.Undo_EndBlock('ReaRanger: move region (content ripple)', -1)
  S.dirty = true
  set_status(('Moved region to %.3fs (content rippled)'):format(new_start))
  Tel.log('move', string.format('{"delta":%.3f,"ripple":true,"clamped":%s}',
    delta, tostring(clamped)))
end

-- Free move (v0.7.8): reposition a region marker + the media items inside its
-- CURRENT span by delta. NO ripple, NO clamp — overlapping/nested regions are
-- allowed (REAPER permits them, esp. with ruler lanes). Lane-drag uses this;
-- strong edge-snapping (in the lane) makes clean end-to-end butting the easy
-- default. The TABLE reorder remains the sequential reflow/swap path.
-- move_content=true → arrangement region: shift its media items too.
-- move_content=false → OVERLAY/marker region: move the marker only, ignore
-- content (overlapping regions are treated as annotations — see v0.7.9).
local function apply_move_free(r, new_start, move_content)
  if not r then return end
  if new_start < 0 then new_start = 0 end
  local delta = new_start - r.pos
  if math.abs(delta) < 1e-6 then return end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  if move_content then
    -- shift media items whose start falls inside this region's current span
    local op, oe = r.pos, r.rend
    local n = reaper.CountMediaItems(0)
    for i = 0, n - 1 do
      local it = reaper.GetMediaItem(0, i)
      local ip = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
      if ip >= op and ip < oe then
        reaper.SetMediaItemInfo_Value(it, 'D_POSITION', ip + delta)
      end
    end
  end

  reaper.SetProjectMarker4(0, r.id, true, new_start, new_start + r.len, r.name, r.color_native, 0)
  r.pos = new_start
  r.rend = new_start + r.len

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()   -- force arrange redraw: programmatic D_POSITION moves
  reaper.UpdateTimeline()  -- don't repaint on their own (the "content didn't move" bug)
  reaper.Undo_EndBlock('ReaRanger: move region (free)', -1)
  S.dirty = true
  set_status(('Moved region to %.3fs%s'):format(new_start, move_content and '' or ' (overlay/marker)'))
  Tel.log('move_free', string.format('{"delta":%.3f,"content":%s}', delta, tostring(move_content)))
end

local function apply_length(r, new_len)
  if not r then return end
  if new_len < 0.01 then new_len = 0.01 end
  if math.abs(new_len - r.len) < 1e-6 then return end
  local old_len = r.len
  reaper.Undo_BeginBlock()
  reaper.SetProjectMarker4(0, r.id, true, r.pos, r.pos + new_len, r.name, r.color_native, 0)
  reaper.Undo_EndBlock('ReaRanger: resize region', -1)
  r.len = new_len
  r.rend = r.pos + new_len
  S.dirty = true
  Tel.log('resize', string.format('{"old":%.3f,"new":%.3f}', old_len, new_len))
end

local function apply_color(r, rgba)
  if not r then return end
  local native = rgba_to_native(rgba)
  reaper.Undo_BeginBlock()
  reaper.SetProjectMarker4(0, r.id, true, r.pos, r.rend, r.name, native, 0)
  reaper.Undo_EndBlock('ReaRanger: color region', -1)
  r.color_native = native
  r.color_rgba = native_to_rgba(native)
  S.dirty = true
  Tel.log('color')
end

local function delete_region(r)
  if not r then return end
  reaper.Undo_BeginBlock()
  reaper.DeleteProjectMarkerByIndex(0, r.enum_i)
  reaper.Undo_EndBlock('ReaRanger: delete region', -1)
  S.dirty = true
  Tel.log('delete')
end

-- Add Gap After row i: opens `len` seconds of silence starting at region i's end.
-- v0.7.1: now moves CONTENT (media items) as well as later region markers.
-- Strategy: ripple-all + Main_OnCommand(40200) shifts items, then we shift
-- the markers ourselves (markers aren't touched by ripple).
local function add_gap_after(i, len)
  if not i or not len or len <= 0 then return end
  if i < 1 or i > #S.regions then return end

  local gap_start = S.regions[i].rend

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  with_ripple_all(function()
    -- save user's current time selection
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    -- set time selection to the gap span
    reaper.GetSet_LoopTimeRange(true, false, gap_start, gap_start + len, false)
    -- insert empty space: items at/after gap_start shift right by len
    reaper.Main_OnCommand(40200, 0)
    -- restore user's time selection
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)

  -- markers were untouched by ripple — slide them ourselves
  for j = #S.regions, i + 1, -1 do
    local r = S.regions[j]
    reaper.SetProjectMarker4(0, r.id, true, r.pos + len, r.rend + len, r.name, r.color_native, 0)
    r.pos = r.pos + len; r.rend = r.rend + len
  end

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()   -- force arrange redraw: programmatic D_POSITION moves
  reaper.UpdateTimeline()  -- don't repaint on their own (the "content didn't move" bug)
  reaper.Undo_EndBlock(('ReaRanger: insert %.3fs gap after row %d (content+markers)'):format(len, i), -1)
  S.dirty = true
  set_status(('Inserted %.2fs gap after row %d (content moved)'):format(len, i))
  Tel.log('gap_insert', string.format('{"row":%d,"len":%.3f}', i, len))
end

-- Timeline gap (seconds) between region r's end and the start of the next
-- region by POSITION. nil if r is the last region (nothing after it). Used to
-- label the gap button with the actual silence after a region once inserted.
local function gap_after(r)
  local best
  for _, o in ipairs(S.regions) do
    if o ~= r and o.pos >= r.rend - 1e-6 then
      if not best or o.pos < best then best = o.pos end
    end
  end
  if best then return best - r.rend end
  return nil
end

local function add_region_at_cursor()
  local pos = reaper.GetCursorPosition()
  local len = math.max(0.1, S.new_region_len or 4.0)   -- length from the toolbar field
  reaper.Undo_BeginBlock()
  reaper.AddProjectMarker2(0, true, pos, pos + len, 'New Region', -1, 0)
  reaper.Undo_EndBlock('ReaRanger: add region', -1)
  S.dirty = true
  Tel.log('add_region', string.format('{"pos":%.3f,"len":%.3f}', pos, len))
end

-- Reorder commit: takes new order of region IDs and re-lays them out
-- starting at the original first region's pos, sequential (no gaps).
-- v0.7.1: ALSO moves media items inside each region to the new position.
-- One undo block for the whole shuffle. Per-item shift (no ripple needed —
-- atomic, avoids any ripple-action ordering races).
local function commit_reorder(new_order_ids)
  if #new_order_ids ~= #S.regions or #S.regions == 0 then return end
  local by_id = {}
  for _, r in ipairs(S.regions) do by_id[r.id] = r end
  local anchor = S.regions[1].pos

  -- Target position per region under the new ordering
  local target_pos = {}
  local cur = anchor
  for _, rid in ipairs(new_order_ids) do
    target_pos[rid] = cur
    cur = cur + by_id[rid].len
  end

  -- Snapshot old spans BEFORE any mutation (items classify by old span)
  local old_pos, old_end = {}, {}
  for rid, r in pairs(by_id) do
    old_pos[rid] = r.pos
    old_end[rid] = r.rend
  end

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- Shift each media item whose start falls inside an old region span
  -- by that region's (target - old) delta. Items outside any region stay put.
  local n_items = reaper.CountMediaItems(0)
  local items_in_region, items_shifted = 0, 0
  for i = 0, n_items - 1 do
    local item = reaper.GetMediaItem(0, i)
    local ipos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    -- v0.7.14: ownership test ported VERBATIM from ArrangeForge commit() PHASE 1
    -- (the proven content-mover): an item belongs to the region whose span contains
    -- its START, with a 0.001s tolerance on both edges. Same math AF has shipped
    -- since day one — the bug was never the mover, it was the drag never reaching it.
    for rid, opos in pairs(old_pos) do
      if ipos >= opos - 0.001 and ipos < old_end[rid] + 0.001 then
        items_in_region = items_in_region + 1
        local delta = target_pos[rid] - opos
        if math.abs(delta) > 1e-9 then
          reaper.SetMediaItemInfo_Value(item, 'D_POSITION', ipos + delta)
          items_shifted = items_shifted + 1
        end
        break
      end
    end
  end
  -- Move region markers to their target positions
  for _, rid in ipairs(new_order_ids) do
    local r = by_id[rid]
    local newp = target_pos[rid]
    reaper.SetProjectMarker4(0, r.id, true, newp, newp + r.len, r.name, r.color_native, 0)
    r.pos = newp
    r.rend = newp + r.len
  end

  -- Re-sort S.regions array to match the new visible order
  local new_arr = {}
  for _, rid in ipairs(new_order_ids) do
    table.insert(new_arr, by_id[rid])
  end
  S.regions = new_arr

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()   -- force arrange redraw: programmatic D_POSITION moves
  reaper.UpdateTimeline()  -- don't repaint on their own (the "content didn't move" bug)
  reaper.Undo_EndBlock('ReaRanger: reorder regions (content+markers)', -1)
  S.dirty = true
  -- Clean user-facing status (diag stripped v0.7.19 — content-move confirmed live).
  -- Item counts still flow to telemetry (Tel.log) for usage analytics, just not the UI.
  set_status(string.format('Reordered %d regions (moved %d items)', #new_order_ids, items_shifted))
  Tel.log('reorder', string.format('{"n":%d,"items_in_region":%d,"items_shifted":%d}',
    #new_order_ids, items_in_region, items_shifted))
  Tel.log_snapshot(S)
end

-- Insert-mode (v0.7.14): given the dragged region id and a drop position in
-- SECONDS, return the new sequential ordering of region ids — the dragged region
-- lands in the slot whose MIDPOINT the drop crosses. Also returns the insertion
-- slot index and the ordered list of the OTHER regions (so the caller can draw a
-- caret at others[idx]'s start). Single-row arranger: no overlap, no new lanes.
local function order_for_insert(drag_id, drop_t)
  local others = {}
  for _, r in ipairs(S.regions) do
    if r.id ~= drag_id then others[#others + 1] = r end
  end
  local idx = #others + 1
  for k, r in ipairs(others) do
    if drop_t < (r.pos + r.rend) / 2 then idx = k; break end
  end
  local order = {}
  for k = 1, idx - 1 do order[#order + 1] = others[k].id end
  order[#order + 1] = drag_id
  for k = idx, #others do order[#order + 1] = others[k].id end
  return order, idx, others
end

-- ====================================================================
-- ImGui context + main loop
-- ====================================================================
local ctx = ImGui.CreateContext(SCRIPT_TITLE)

-- Bold font for the Start/Length time cells (v0.7.17). Under the 0.9 API pin
-- (require 'imgui' '0.9') the signatures are CreateFont(family, size, flags) and
-- 2-arg PushFont(ctx, font) — NOT the newer binary's CreateFont(family,flags) /
-- PushFont(ctx,font,size). Size baked at create. Attached once, pushed around cells.
local FONT_BOLD = ImGui.CreateFont('sans-serif', 14, ImGui.FontFlags_Bold)
ImGui.Attach(ctx, FONT_BOLD)

-- Tooltip gate (v0.7.14): all hover tooltips route through tip() so the ? button
-- by the X can switch them off. ctx is the module-local above.
local function tip(s) if S.tooltips_on then ImGui.SetTooltip(ctx, s) end end

-- ====================================================================
-- Greyscale, mid-contrast, no-dark theme. Pushed at frame begin, popped at end.
-- ====================================================================
local _SC = 0
local function push_grey_theme()
  local safe = {
    {ImGui.Col_WindowBg,            0x787878FF},
    {ImGui.Col_ChildBg,              0x808080FF},
    {ImGui.Col_PopupBg,              0x707070FF},
    {ImGui.Col_Border,               0x505050FF},
    {ImGui.Col_FrameBg,              0x686868FF},
    {ImGui.Col_FrameBgHovered,       0x787878FF},
    {ImGui.Col_FrameBgActive,        0x888888FF},
    {ImGui.Col_TitleBg,              0x606060FF},
    {ImGui.Col_TitleBgActive,        0x707070FF},
    {ImGui.Col_TitleBgCollapsed,     0x505050FF},
    {ImGui.Col_MenuBarBg,            0x707070FF},
    {ImGui.Col_Button,               0x6C6C6CFF},
    {ImGui.Col_ButtonHovered,        0x808080FF},
    {ImGui.Col_ButtonActive,         0x909090FF},
    {ImGui.Col_Header,               0x707070FF},
    {ImGui.Col_HeaderHovered,        0x808080FF},
    {ImGui.Col_HeaderActive,         0x909090FF},
    {ImGui.Col_Separator,            0x505050FF},
    {ImGui.Col_SeparatorHovered,     0x707070FF},
    {ImGui.Col_SeparatorActive,      0x808080FF},
    {ImGui.Col_Text,                 0x202020FF},
    {ImGui.Col_TextDisabled,         0x404040FF},
    {ImGui.Col_TextSelectedBg,       0x404040A0},
    {ImGui.Col_TableHeaderBg,        0x606060FF},
    {ImGui.Col_TableBorderStrong,    0x404040FF},
    {ImGui.Col_TableBorderLight,     0x505050FF},
    {ImGui.Col_TableRowBg,           0x787878FF},
    {ImGui.Col_TableRowBgAlt,        0x707070FF},
    {ImGui.Col_CheckMark,            0x303030FF},
    {ImGui.Col_SliderGrab,           0x484848FF},
    {ImGui.Col_SliderGrabActive,     0x383838FF},
    {ImGui.Col_ResizeGrip,           0x606060FF},
    {ImGui.Col_ResizeGripHovered,    0x808080FF},
    {ImGui.Col_ResizeGripActive,     0x909090FF},
    {ImGui.Col_NavHighlight,         0x404040FF},
  }
  for _, p in ipairs(safe) do
    if p[1] then ImGui.PushStyleColor(ctx, p[1], p[2]); _SC = _SC + 1 end
  end
end
local function pop_grey_theme()
  if _SC > 0 then ImGui.PopStyleColor(ctx, _SC); _SC = 0 end
end

-- Lifted from ArrangeForge_fA.lua (lines 663-672) — keep in lockstep
-- kind: 'pos' (default, a timeline position) or 'len' (a duration). In beats
-- mode they format differently (measures.beats vs a length); in time mode both
-- are plain MM:SS.mmm. Internal values are ALWAYS seconds — this is display only.
local function fmt_time_full(t, kind)
  if S.time_mode == 'beats' then
    if kind == 'len' then
      return reaper.format_timestr_len(t, '', 0, 2)   -- mode 2 = measures.beats
    end
    return reaper.format_timestr_pos(t, '', 2)
  end
  local m  = math.floor(t / 60)
  local s  = math.floor(t - m * 60)
  local ms = math.floor((t - m * 60 - s) * 1000 + 0.5)
  return string.format('%02d:%02d.%03d', m, s, ms)
end

local function parse_time_full(str, kind)
  if not str then return nil end
  if S.time_mode == 'beats' then
    local v = (kind == 'len') and reaper.parse_timestr_len(str, 0, 2)
                               or  reaper.parse_timestr_pos(str, 2)
    if v and v == v then return v end   -- v==v guards NaN
    return nil
  end
  local mm, ss, mss = str:match('^%s*(%-?%d+):(%d+)%.?(%d*)%s*$')
  if mm and ss then
    local m = tonumber(mm); local s = tonumber(ss)
    local ms = (mss ~= '' and tonumber('0.' .. mss)) or 0
    if m and s then return m * 60 + s + ms end
  end
  -- fallback: bare seconds
  local sec = tonumber(str)
  if sec then return sec end
  return nil
end

-- Per-digit drag (v0.7.17): split a TIME-mode value (MM:SS.mmm) into independently
-- draggable place-value segments. Each segment carries `place` = seconds per drag
-- step (Ctrl makes it 10× finer). Separators are non-draggable. Beats mode has no
-- constant seconds-per-place (tempo-dependent) → returns nil, caller falls back to
-- the whole-cell vertical drag.
local function time_segments(val)
  if S.time_mode == 'beats' then return nil end
  local v  = val < 0 and 0 or val
  local m  = math.floor(v / 60)
  local s  = math.floor(v - m * 60)
  local ms = math.floor((v - m * 60 - s) * 1000 + 0.5)
  return {
    {txt = string.format('%02d', m),  place = 60,   sub = 'm'  },
    {sep = ':'},
    {txt = string.format('%02d', s),  place = 1,    sub = 's'  },
    {sep = '.'},
    {txt = string.format('%03d', ms), place = 0.01, sub = 'ms' },
  }
end

-- ====================================================================
-- drag_time_cell — snap-aware vertical drag + double-click direct edit
--   key            unique stable id (e.g. 'reg_42_start')
--   display_val    seconds (what the cell SHOWS, fmt_time_full)
--   drag_anchor    seconds (value snap math operates on; for length-cell pass r.rend)
--   on_apply       function(snapped_val)  — called per-frame during drag
--   on_commit      function(parsed_val)   — called on Enter from direct-edit mode
-- Snap rule: grid_step_sec / DRAG_PX_PER_SNAP seconds per pixel of vertical drag.
--   Drag UP = increase, DOWN = decrease (cursor: ResizeNS).
-- ====================================================================
--   on_release     function(final_val)    — called once on drag release. When
--                  set, the cell is COMMIT-ON-RELEASE: nothing mutates during
--                  the drag (cell shows live preview), the commit runs on mouse-up.
local function drag_time_cell(key, display_val, drag_anchor, on_apply, on_commit, on_release, kind)
  -- DIRECT EDIT MODE
  if S.edit and S.edit.key == key then
    ImGui.SetNextItemWidth(ctx, -1)
    if not S.edit.focused then ImGui.SetKeyboardFocusHere(ctx); S.edit.focused = true end
    local rv, nv = ImGui.InputText(ctx, '##e_' .. key, S.edit.buf, ImGui.InputTextFlags_AutoSelectAll)
    if rv then S.edit.buf = nv end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
      local parsed = parse_time_full(S.edit.buf, kind)
      S.edit = nil
      if parsed and on_commit then on_commit(parsed) end
      return
    end
    if ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then S.edit = nil; return end
    return
  end

  -- DISPLAY + HOVER INTERACTIONS
  -- Commit-on-release cells show the live preview value during a drag; the
  -- project itself isn't touched until release.
  local shown = display_val
  if S.num_drag and S.num_drag.key == key and S.num_drag.on_release and S.num_drag.preview_val then
    shown = S.num_drag.preview_val
  end

  -- Helper: open direct type-edit on this cell (shared by both render paths).
  local function open_edit()
    S.edit = {key=key, buf=fmt_time_full(display_val, kind), focused=false}
    if S.num_drag and S.num_drag.undo_started then
      reaper.Undo_EndBlock('ReaRanger: drag time', -1)
    end
    S.num_drag = nil
  end
  -- Helper: begin a drag on this cell. `place` (seconds/step) set → per-digit
  -- place-value stepping; nil → continuous grid-snap drag (beats / fallback).
  local function begin_drag(place)
    S.num_drag = {
      key = key, start_val = drag_anchor, place = place,
      undo_started = false, on_apply = on_apply,
      on_release = on_release, preview_val = drag_anchor,
    }
    ImGui.ResetMouseDragDelta(ctx, 0)
  end

  local segs = time_segments(shown)
  if segs then
    -- PER-DIGIT path: each numeric group is its own draggable item (bold), so you
    -- can grab the minutes / seconds / ms independently. Ctrl = fine (10× smaller).
    ImGui.PushFont(ctx, FONT_BOLD)
    local first = true
    for _, seg in ipairs(segs) do
      if not first then ImGui.SameLine(ctx, 0, 0) end
      first = false
      if seg.sep then
        ImGui.TextDisabled(ctx, seg.sep)
      else
        ImGui.Text(ctx, seg.txt)
        if ImGui.IsItemHovered(ctx) then
          ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNS)
          if ImGui.IsMouseDoubleClicked(ctx, 0) then
            ImGui.PopFont(ctx); open_edit(); return
          end
          if ImGui.IsMouseClicked(ctx, 0) and not S.num_drag then
            begin_drag(seg.place)
          end
        end
      end
    end
    ImGui.PopFont(ctx)
  else
    -- WHOLE-CELL path (beats mode): bold, single vertical grid-snap drag.
    ImGui.PushFont(ctx, FONT_BOLD)
    ImGui.Text(ctx, fmt_time_full(shown, kind))
    ImGui.PopFont(ctx)
    if ImGui.IsItemHovered(ctx) then
      ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeNS)
      if ImGui.IsMouseDoubleClicked(ctx, 0) then open_edit(); return end
      if ImGui.IsMouseClicked(ctx, 0) and not S.num_drag then begin_drag(nil) end
    end
  end
end

-- Called once per frame AFTER the table draws. Advances active drag, ends it on release.
local function process_num_drag()
  local nd = S.num_drag
  if not nd then return end
  local _, dy = ImGui.GetMouseDragDelta(ctx, 0)
  if math.abs(dy) > 5 then  -- deadzone: prevents click-jitter from opening accidental undo blocks (esp. on dblclick first-down)
    if not nd.undo_started then
      reaper.Undo_BeginBlock()
      nd.undo_started = true
    end
    local final
    if nd.place then
      -- PER-DIGIT: discrete place-value steps. Ctrl = fine (10× smaller place).
      local mods = ImGui.GetKeyMods(ctx)
      local fine = (mods & ImGui.Mod_Ctrl) ~= 0
      local place = nd.place * (fine and 0.1 or 1)
      local steps = math.floor(-dy / DRAG_PX_PER_DIGIT + 0.5)
      local raw = nd.start_val + steps * place
      if raw < 0 then raw = 0 end
      final = raw
    else
      -- WHOLE-CELL: continuous, grid-snapped (beats / fallback).
      local sens = grid_step_sec() / DRAG_PX_PER_SNAP
      local raw  = nd.start_val + (-dy * sens)
      if raw < 0 then raw = 0 end
      final = snap_enabled() and reaper.SnapToGrid(0, raw) or raw
    end
    nd.preview_val = final
    if nd.on_apply then nd.on_apply(final) end   -- live-mutate cells only
  end
  if not ImGui.IsMouseDown(ctx, 0) then
    -- commit-on-release cells run their one ripple commit here, inside the
    -- drag's undo block (nested apply_start block collapses to one undo point).
    if nd.on_release and nd.undo_started then nd.on_release(nd.preview_val) end
    if nd.undo_started then reaper.Undo_EndBlock('ReaRanger: drag time', -1) end
    S.num_drag = nil
  end
end

local function draw_color_button(r, row_idx)
  local cflags = ImGui.ColorEditFlags_NoInputs | ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoTooltip
  local rv, new_col = ImGui.ColorEdit4(ctx, '##col_' .. r.id, r.color_rgba, cflags)
  if rv then
    r.color_rgba = new_col
    apply_color(r, new_col)
  end
  -- Right-click for palette popup
  if ImGui.IsItemClicked(ctx, 1) then
    ImGui.OpenPopup(ctx, 'palette_' .. r.id)
  end
  if ImGui.BeginPopup(ctx, 'palette_' .. r.id) then
    ImGui.Text(ctx, 'Palette')
    ImGui.Separator(ctx)
    for _, p in ipairs(SECTION_PALETTE) do
      local cflags2 = ImGui.ColorEditFlags_NoInputs | ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoTooltip
      if ImGui.ColorButton(ctx, '##pal_' .. r.id .. '_' .. p.name, p.col == 0 and DEFAULT_COLOR_RGBA or p.col, cflags2, 20, 20) then
        r.color_rgba = p.col == 0 and DEFAULT_COLOR_RGBA or p.col
        apply_color(r, p.col)  -- pass raw; 0 = default
        ImGui.CloseCurrentPopup(ctx)
      end
      ImGui.SameLine(ctx); ImGui.Text(ctx, p.name)
    end
    -- Custom picker (#9): full RGB/HSV beyond the grey presets. Live-preview the
    -- colour in memory every drag-frame, but commit to REAPER (one Undo block via
    -- apply_color) only when the picker is released — otherwise dragging would
    -- spam the undo history with a marker write per frame.
    ImGui.Separator(ctx)
    ImGui.Text(ctx, 'Custom')
    local pflags = ImGui.ColorEditFlags_NoLabel | ImGui.ColorEditFlags_NoSidePreview | ImGui.ColorEditFlags_AlphaBar
    local pv, pcol = ImGui.ColorPicker4(ctx, '##custpick_' .. r.id, r.color_rgba, pflags)
    if pv then r.color_rgba = pcol end
    if ImGui.IsItemDeactivatedAfterEdit(ctx) then apply_color(r, r.color_rgba) end
    ImGui.EndPopup(ctx)
  end
end

-- ====================================================================
-- Region overview lane — full project at a glance
-- Each region = colored rect proportional to length, name labeled if wide.
-- Click anywhere on the lane = move REAPER edit cursor to that time.
-- Hover a region = tooltip with name / start / end / length.
-- Playhead = magenta vertical line at REAPER edit cursor.
-- ====================================================================
local LANE_ROW_H = 30   -- height of one stacked lane row
local LANE_PAD   = 3    -- inner vertical padding per region rect
local LANE_EDGE_PX = 6  -- right-edge grab zone for resize
local LANE_DRAG_PX = 4  -- horizontal travel past this = a drag, not a click
local LANE_SNAP_PX = 12 -- magnetic snap radius to region ends (pixels)

-- Greedy interval-packing: assign each region a lane (row) so overlapping
-- regions stack instead of drawing on top of each other. No overlaps → all
-- land in lane 0 → single-row overview (identical to before). Nested/coincident
-- sections (same start, different end) auto-expand into rows. Lane assignment is
-- OURS (display only) — REAPER's own ruler-lane data isn't exposed to scripts.
local function pack_lanes()
  -- pack a sorted copy: pos ascending, ties broken by LONGER first so the big
  -- section claims lane 0 (the "arrangement"); smaller nested ones get bumped to
  -- higher rows and are treated as overlay/marker regions (v0.7.9).
  local order = {}
  for _, r in ipairs(S.regions) do order[#order + 1] = r end
  table.sort(order, function(a, b)
    if math.abs(a.pos - b.pos) > 1e-9 then return a.pos < b.pos end
    return a.len > b.len
  end)
  local lane_of, lane_end, num = {}, {}, 0
  for _, r in ipairs(order) do
    local placed
    for L = 0, num - 1 do
      if r.pos >= lane_end[L] - 1e-9 then placed = L; break end
    end
    if placed == nil then placed = num; num = num + 1 end
    lane_of[r.id] = placed
    lane_end[placed] = r.rend
  end
  return lane_of, math.max(1, num)
end

local function draw_region_lane()
  local avail_w, _ = ImGui.GetContentRegionAvail(ctx)
  if avail_w < 50 then avail_w = 50 end

  local lane_of, num_lanes = pack_lanes()
  local total_h = num_lanes * LANE_ROW_H

  -- While a lane rename is active, submit the lane as a non-interactive Dummy
  -- instead of the InvisibleButton. The full-lane InvisibleButton overlaps the
  -- rename InputText (drawn later at an absolute pos) and was stealing its
  -- hover/active-id/keyboard focus — that's why typed text never registered on
  -- the lane while the table-cell rename (no competing widget) worked fine.
  -- Dummy reserves the same geometry (GetItemRectMin/Max still valid) but
  -- captures no input. All lane interaction below is already gated on
  -- `not S.rename`, so suppressing the button during rename changes nothing else.
  local lane_renaming = S.rename and S.rename.where == 'lane'
  if lane_renaming then
    ImGui.Dummy(ctx, avail_w, total_h)
  else
    ImGui.InvisibleButton(ctx, '##region_lane', avail_w, total_h)
  end
  local hovered = (not lane_renaming) and ImGui.IsItemHovered(ctx)
  local x1g, y1g = ImGui.GetItemRectMin(ctx)
  local x2g, y2g = ImGui.GetItemRectMax(ctx)
  local dl = ImGui.GetWindowDrawList(ctx)

  -- Background (greyscale, mid contrast)
  ImGui.DrawList_AddRectFilled(dl, x1g, y1g, x2g, y2g, LANE_BG_COL)
  ImGui.DrawList_AddRect(dl,       x1g, y1g, x2g, y2g, LANE_BORDER_COL)

  if #S.regions == 0 then
    ImGui.DrawList_AddText(dl, x1g + 6, y1g + (LANE_ROW_H/2) - 7, EMPTY_TEXT_COL, '(no regions)')
    return
  end

  -- Compute timeline span: 0 → max(rend, edit-cursor); never zero
  local span_start, span_end = 0, 0
  for _, r in ipairs(S.regions) do
    if r.rend > span_end then span_end = r.rend end
  end
  local cur = reaper.GetCursorPosition() or 0
  if cur > span_end then span_end = cur end
  if span_end <= span_start then span_end = span_start + 1 end
  local span = span_end - span_start

  local function t_to_x(t) return x1g + ((t - span_start) / span) * (x2g - x1g) end
  local function lane_top(L) return y1g + L * LANE_ROW_H + LANE_PAD end
  local function lane_bot(L) return y1g + (L + 1) * LANE_ROW_H - LANE_PAD end

  -- faint row separators when stacked
  if num_lanes > 1 then
    for L = 1, num_lanes - 1 do
      local ly = y1g + L * LANE_ROW_H
      ImGui.DrawList_AddLine(dl, x1g, ly, x2g, ly, LANE_BORDER_COL, 1.0)
    end
  end

  -- Region rects, each at its packed lane row
  for _, r in ipairs(S.regions) do
    local L = lane_of[r.id]
    local rx1, rx2 = t_to_x(r.pos), t_to_x(r.rend)
    if rx2 - rx1 < 2 then rx2 = rx1 + 2 end
    local yt, yb = lane_top(L), lane_bot(L)
    -- v0.7.18: honor the user's CUSTOM color in the lane (it used to be clamped to
    -- grey via luminance_grey). A region with a custom color set (native ~= 0) draws
    -- in its true color; uncolored regions stay in the mid-grey band.
    local has_custom = r.color_native and r.color_native ~= 0
    local src = r.color_rgba ~= 0 and r.color_rgba or DEFAULT_COLOR_RGBA
    local col = has_custom and src or luminance_grey(src, 0x98, 0xC8)
    ImGui.DrawList_AddRectFilled(dl, rx1, yt, rx2, yb, col)
    -- overlay regions (bumped to a higher row) get a brighter border so they
    -- read as marker-like annotations, not arrangement sections.
    ImGui.DrawList_AddRect(dl, rx1, yt, rx2, yb, L > 0 and OVERLAY_BORDER_COL or LANE_RECT_BORDER)
    if rx2 - rx1 > 30 then
      ImGui.DrawList_PushClipRect(dl, rx1 + 2, yt, rx2 - 2, yb, true)
      -- v0.7.18: translucent plate behind the name so it stays readable over ANY
      -- block color (custom colors can be light or dark), then 93% white text.
      local tw, th = ImGui.CalcTextSize(ctx, r.name)
      local tx, ty = rx1 + 4, yt + 2
      ImGui.DrawList_AddRectFilled(dl, tx - 2, ty - 1, tx + tw + 2, ty + th + 1, LANE_LABEL_BG_COL, 2.0)
      ImGui.DrawList_AddText(dl, tx, ty, NAME_TEXT_COL, r.name)
      ImGui.DrawList_PopClipRect(dl)
    end
  end

  -- Playhead — full height across all rows
  local px = t_to_x(cur)
  if px >= x1g and px <= x2g then
    ImGui.DrawList_AddLine(dl, px, y1g, px, y2g, PLAYHEAD_COL, 1.5)
  end

  -- ------------------------------------------------------------------
  -- Lane interaction (v0.7.8):
  --   drag region body       = FREE move (no ripple, allows overlap/nesting)
  --   drag region right edge = resize length
  --   plain click (no drag)  = nav edit cursor
  --   double-click on region = in-place rename
  -- Strong magnetic snapping to other regions' ends (grid as fallback) makes
  -- clean end-to-end butting the easy default. Commit ONCE on release.
  -- ------------------------------------------------------------------
  local mx, my = ImGui.GetMousePos(ctx)

  -- region whose rect contains (sx,sy) — lane-aware so stacked regions resolve
  local function region_at_xy(sx, sy)
    for _, r in ipairs(S.regions) do
      local L = lane_of[r.id]
      local rx1, rx2 = t_to_x(r.pos), t_to_x(r.rend)
      if rx2 - rx1 < 2 then rx2 = rx1 + 2 end
      if sx >= rx1 and sx <= rx2 and sy >= lane_top(L) and sy <= lane_bot(L) then
        return r, rx1, rx2
      end
    end
    return nil
  end

  -- nearest other-region edge (start or end) to time t, within snap radius
  local function snap_edge(t, exclude_id)
    local best, bestd = nil, LANE_SNAP_PX + 1
    local tx = t_to_x(t)
    for _, r in ipairs(S.regions) do
      if r.id ~= exclude_id then
        local d1 = math.abs(tx - t_to_x(r.pos))
        local d2 = math.abs(tx - t_to_x(r.rend))
        if d1 < bestd then bestd = d1; best = r.pos end
        if d2 < bestd then bestd = d2; best = r.rend end
      end
    end
    return best
  end

  -- Double-click → rename (precedence over drag/click)
  if hovered and ImGui.IsMouseDoubleClicked(ctx, 0) and not S.rename then
    local hr = region_at_xy(mx, my)
    if hr then
      S.lane_drag = nil
      S.rename = {id=hr.id, buf=hr.name, focused=false, where='lane'}
    end
  end

  -- Begin a potential drag on mouse-press over a region
  if hovered and ImGui.IsMouseClicked(ctx, 0) and not S.lane_drag and not S.rename then
    local hr, _, hrx2 = region_at_xy(mx, my)
    if hr then
      local mode = (math.abs(mx - hrx2) <= LANE_EDGE_PX) and 'resize' or 'move'
      S.lane_drag = {id=hr.id, mode=mode, start_x=mx,
                     orig_pos=hr.pos, orig_len=hr.len, lane=lane_of[hr.id], moved=false}
    end
  end

  -- Active drag: track travel, draw ghost preview, commit on release
  if S.lane_drag then
    local ld = S.lane_drag
    local r
    for _, rr in ipairs(S.regions) do if rr.id == ld.id then r = rr; break end end
    if not r then
      S.lane_drag = nil
    else
      local dx = mx - ld.start_x
      if math.abs(dx) > LANE_DRAG_PX then ld.moved = true end
      local delta_t = (dx / (x2g - x1g)) * span
      local yt, yb = lane_top(ld.lane), lane_bot(ld.lane)

      if ld.moved then
        if ld.mode == 'move' and S.lane_mode == 'insert' then
          -- INSERT: don't free-slide. Show a bright caret at the slot the drop
          -- would land in; on release we commit_reorder (content reflows).
          local drop_t = span_start + ((mx - x1g) / (x2g - x1g)) * span
          local _, idx, others = order_for_insert(ld.id, drop_t)
          local caret_x
          if idx <= #others then caret_x = t_to_x(others[idx].pos)
          elseif #others > 0 then caret_x = t_to_x(others[#others].rend)
          else caret_x = x1g end
          ld.preview = drop_t
          -- caret + translucent landing ghost (region width) on row 0
          ImGui.DrawList_AddLine(dl, caret_x, y1g, caret_x, y2g, INSERT_CARET_COL, 3.0)
          local w_px = (ld.orig_len / span) * (x2g - x1g)
          ImGui.DrawList_AddRectFilled(dl, caret_x, lane_top(0), caret_x + w_px, lane_bot(0), INSERT_GHOST_COL)
          local before = (idx <= #others) and others[idx].name or '(end)'
          tip(('INSERT before %s  ·  others reflow, audio follows'):format(before))
        elseif ld.mode == 'move' then
          -- OVERLAY: free slide with strong edge-snapping (can stack / nest).
          local raw = ld.orig_pos + delta_t
          local s_start = snap_edge(raw, ld.id)
          local s_end   = snap_edge(raw + ld.orig_len, ld.id)
          local target
          if s_start and s_end then
            target = (math.abs(t_to_x(s_start) - t_to_x(raw))
                      <= math.abs(t_to_x(s_end) - t_to_x(raw + ld.orig_len)))
                     and s_start or (s_end - ld.orig_len)
          elseif s_start then target = s_start
          elseif s_end   then target = s_end - ld.orig_len
          else target = maybe_snap(raw) end
          if target < 0 then target = 0 end
          ld.preview = target
          local gx1, gx2 = t_to_x(target), t_to_x(target + ld.orig_len)
          ImGui.DrawList_AddRect(dl, gx1, yt, gx2, yb, GHOST_COL, 0, 0, 2.0)
          tip(('OVERLAY → %s  ·  marker only'):format(fmt_time_full(ld.preview)))
        else
          local raw_end = ld.orig_pos + ld.orig_len + delta_t
          local snapped = snap_edge(raw_end, ld.id) or maybe_snap(raw_end)
          local nl = snapped - ld.orig_pos
          if nl < 0.01 then nl = 0.01 end
          ld.preview = nl
          local gx2 = t_to_x(ld.orig_pos + nl)
          ImGui.DrawList_AddLine(dl, gx2, yt, gx2, yb, GHOST_COL, 2.0)
          tip(('len → %s'):format(fmt_time_full(ld.preview)))
        end
      end

      if ImGui.IsMouseReleased(ctx, 0) then
        if ld.moved and ld.preview then
          if ld.mode == 'move' then
            if S.lane_mode == 'insert' then
              -- INSERT: reorder into the dropped slot; commit_reorder shifts the
              -- media items deterministically so content follows + others reflow.
              local order = order_for_insert(ld.id, ld.preview)
              commit_reorder(order)
            else
              -- OVERLAY: free placement that MOVES CONTENT and is allowed to
              -- overlap/nest (v0.7.14 — per Poofox: when regions overlap the audio
              -- should overlap too). overlap_mode picks how the overlap reads:
              -- crossfade = REAPER auto-crossfades the overlapping items; overlap =
              -- hard stack. set_autoxfade self-guards (no-op if the action id is
              -- unavailable on this build).
              set_autoxfade(S.overlap_mode == 'crossfade')
              apply_move_free(r, ld.preview, true)
            end
          else apply_length(r, ld.preview) end
        elseif not ld.moved then
          local rel = (mx - x1g) / (x2g - x1g)
          if rel < 0 then rel = 0 end; if rel > 1 then rel = 1 end
          reaper.SetEditCurPos(span_start + rel * span, true, false)
        end
        S.lane_drag = nil
      end
    end
  end

  -- Hover (no active drag): tooltip + resize-cursor hint
  if hovered and not S.lane_drag then
    local hover_r, _, hrx2 = region_at_xy(mx, my)
    if hover_r then
      if math.abs(mx - hrx2) <= LANE_EDGE_PX and ImGui.SetMouseCursor and ImGui.MouseCursor_ResizeEW then
        ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeEW)
      end
      local kind = S.lane_mode == 'insert'
        and '  [drag = INSERT: reorder, content follows]'
        or  '  [drag = OVERLAY: free place, marker only]'
      tip(('%s%s\n%s  →  %s   (len %s)\n[drag=move · right-edge=resize · dbl-click=rename]'):format(
        hover_r.name, kind, fmt_time_full(hover_r.pos), fmt_time_full(hover_r.rend), fmt_time_full(hover_r.len)))
    else
      local rel = (mx - x1g) / (x2g - x1g)
      if rel < 0 then rel = 0 end; if rel > 1 then rel = 1 end
      tip(fmt_time_full(span_start + rel * span))
    end
  end

  -- In-place rename overlay, positioned at the region's packed lane row
  if S.rename and S.rename.where == 'lane' then
    local rr = nil
    for _, r in ipairs(S.regions) do if r.id == S.rename.id then rr = r; break end end
    if rr then
      local L = lane_of[rr.id] or 0
      local rx1, rx2 = t_to_x(rr.pos), t_to_x(rr.rend)
      local rw = rx2 - rx1
      if rw < 80 then rw = 80 end
      ImGui.SetCursorScreenPos(ctx, rx1, lane_top(L))
      ImGui.SetNextItemWidth(ctx, rw)
      if not S.rename.focused then ImGui.SetKeyboardFocusHere(ctx); S.rename.focused = true end
      local rv, nv = ImGui.InputText(ctx, '##lane_rn_' .. rr.id, S.rename.buf, ImGui.InputTextFlags_AutoSelectAll)
      if rv then S.rename.buf = nv end
      if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
        apply_rename(rr, S.rename.buf); S.rename = nil
      elseif ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
        S.rename = nil
      end
    else
      S.rename = nil
    end
  end
end

local function draw_table()
  local table_flags = ImGui.TableFlags_Borders | ImGui.TableFlags_RowBg
    | ImGui.TableFlags_SizingStretchProp | ImGui.TableFlags_ScrollY
  if not ImGui.BeginTable(ctx, 'regions', 6, table_flags, 0, -28) then return end

  -- v0.7.7: dedicated "=" drag column REMOVED (punch #7). The whole row is the
  -- drag surface now; the "#" column shows the order number AND grabs the row.
  ImGui.TableSetupColumn(ctx, '#',      ImGui.TableColumnFlags_WidthFixed, 28)
  ImGui.TableSetupColumn(ctx, 'Color',  ImGui.TableColumnFlags_WidthFixed, 40)
  ImGui.TableSetupColumn(ctx, 'Name',   ImGui.TableColumnFlags_WidthStretch)
  ImGui.TableSetupColumn(ctx, 'Start',  ImGui.TableColumnFlags_WidthFixed, 100)
  ImGui.TableSetupColumn(ctx, 'Length', ImGui.TableColumnFlags_WidthFixed, 90)
  ImGui.TableSetupColumn(ctx, '',       ImGui.TableColumnFlags_WidthFixed, 64)  -- +Gap and delete
  ImGui.TableHeadersRow(ctx)

  local drop_target_idx = nil

  for i, r in ipairs(S.regions) do
    ImGui.TableNextRow(ctx)
    ImGui.PushID(ctx, r.id)

    -- Col 0: row number + WHOLE-ROW drag handle (v0.7.7, punch #7).
    -- A Selectable spanning all columns is the drag source/target. With
    -- SetNextItemAllowOverlap, the cells drawn afterwards (color/name/time/
    -- actions) sit on top and keep their own hover/click — so you can grab the
    -- row by any empty/number/name spot to reorder, yet still edit the cells.
    -- If the host lacks AllowOverlap, we fall back to a col-0-only grab (no span)
    -- so we never re-introduce the v0.7.3 hover-steal bug.
    -- v0.7.14: drag handle = the NUMBER cell (col 0) ONLY. The old SpanAllColumns
    -- row Selectable overlapped the name/time Text cells and stole their hover, so
    -- IsItemHovered never fired there → double-click-to-edit was dead everywhere.
    -- (The lane is the primary reorder surface now; col-0 grab stays for the table.)
    ImGui.TableSetColumnIndex(ctx, 0)
    ImGui.Selectable(ctx, tostring(i) .. '##rowdrag', false, 0, 0, 0)
    if ImGui.BeginDragDropSource(ctx, ImGui.DragDropFlags_None) then
      ImGui.SetDragDropPayload(ctx, 'REGION_ROW', tostring(i))
      ImGui.Text(ctx, ('Move: %s'):format(r.name))
      S.drag_src = i
      ImGui.EndDragDropSource(ctx)
    end
    if ImGui.BeginDragDropTarget(ctx) then
      local rv, payload = ImGui.AcceptDragDropPayload(ctx, 'REGION_ROW')
      if rv and payload then
        drop_target_idx = i
      end
      ImGui.EndDragDropTarget(ctx)
    end

    -- Col 1: color
    ImGui.TableSetColumnIndex(ctx, 1)
    draw_color_button(r, i)

    -- Col 2: name — dblclick to edit inplace (matches AF in spirit, fixes the
    --                "dblclick in timeline opens list" cross-jump Poofox hated)
    ImGui.TableSetColumnIndex(ctx, 2)
    if S.rename and S.rename.id == r.id and S.rename.where == 'table' then
      ImGui.SetNextItemWidth(ctx, -1)
      if not S.rename.focused then ImGui.SetKeyboardFocusHere(ctx); S.rename.focused = true end
      local rv, nv = ImGui.InputText(ctx, '##rn_' .. r.id, S.rename.buf, ImGui.InputTextFlags_AutoSelectAll)
      if rv then S.rename.buf = nv end
      if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
        apply_rename(r, S.rename.buf); S.rename = nil
      elseif ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
        S.rename = nil
      end
    else
      -- v0.7.14: name is a Selectable, not plain Text. Plain Text was NOT
      -- registering double-clicks (IsItemHovered never true on it on this host) —
      -- that's why names couldn't be edited while the time cells could. Selectable
      -- is fully interactive → reliable hover + dbl-click. It's ALSO a drag source
      -- so you can grab a region BY ITS NAME to reorder (the col-0 number is a tiny
      -- target); the drop routes through commit_reorder so content moves too.
      ImGui.PushStyleColor(ctx, ImGui.Col_Text, NAME_TEXT_COL)  -- 93% white (Poofox)
      ImGui.Selectable(ctx, r.name .. '##nm_' .. r.id, false, ImGui.SelectableFlags_AllowDoubleClick)
      ImGui.PopStyleColor(ctx)
      if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
        S.rename = {id=r.id, buf=r.name, focused=false, where='table'}
      end
      if ImGui.BeginDragDropSource(ctx, ImGui.DragDropFlags_None) then
        ImGui.SetDragDropPayload(ctx, 'REGION_ROW', tostring(i))
        ImGui.Text(ctx, ('Move: %s'):format(r.name))
        S.drag_src = i
        ImGui.EndDragDropSource(ctx)
      end
      if ImGui.BeginDragDropTarget(ctx) then
        local rvn, payn = ImGui.AcceptDragDropPayload(ctx, 'REGION_ROW')
        if rvn and payn then drop_target_idx = i end
        ImGui.EndDragDropTarget(ctx)
      end
    end

    -- Col 3: start — drag up/down snaps to grid; double-click = direct edit MM:SS.mmm
    ImGui.TableSetColumnIndex(ctx, 3)
    drag_time_cell(
      'reg_' .. r.id .. '_start',
      r.pos, r.pos,
      nil,                                            -- no per-frame mutation (ripple is heavy)
      function(parsed)  apply_start(r, parsed)  end,  -- type-to-edit commit
      function(final)   apply_start(r, final)   end,  -- drag release → one ripple commit
      'pos'
    )

    -- Col 4: length — drag manipulates END time (so snap targets musical boundary),
    --                  cell displays LENGTH, direct edit takes a duration.
    ImGui.TableSetColumnIndex(ctx, 4)
    drag_time_cell(
      'reg_' .. r.id .. '_len',
      r.len, r.rend,
      function(snapped_end)
        local new_l = snapped_end - r.pos
        if new_l < 0.01 then new_l = 0.01 end
        apply_length(r, new_l)
      end,
      function(parsed_len) apply_length(r, parsed_len) end,
      nil,    -- no on_release (length is per-frame via on_apply)
      'len'
    )

    -- Col 5: actions (gap-after, delete)
    -- #4: +G single-click inserts the last-used gap; double-click opens an inline
    --     numeric field to TYPE an exact gap length (seconds), committed on Enter.
    --     The editor is the safe path — no stray ripple from a mis-click, because
    --     the default insert only fires on a deliberate single click that is NOT
    --     promoted to a double within the same press.
    ImGui.TableSetColumnIndex(ctx, 5)
    if S.gapedit and S.gapedit.id == r.id then
      ImGui.SetNextItemWidth(ctx, 52)
      if not S.gapedit.focused then ImGui.SetKeyboardFocusHere(ctx); S.gapedit.focused = true end
      local gv, gnv = ImGui.InputText(ctx, '##gap_' .. r.id, S.gapedit.buf,
        ImGui.InputTextFlags_AutoSelectAll | ImGui.InputTextFlags_CharsDecimal)
      if gv then S.gapedit.buf = gnv end
      if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
        local n = tonumber(S.gapedit.buf)
        if n and n > 0 then S.gap_len = n; add_gap_after(i, n) end
        S.gapedit = nil
      elseif ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
        S.gapedit = nil
      end
      if ImGui.IsItemHovered(ctx) then
        tip('Type gap length in seconds · Enter = insert · Esc = cancel')
      end
    else
      -- single-click = insert last-used gap; double-click = type exact.
      -- Label shows the ACTUAL gap after this region once one exists (e.g.
      -- "2s"), else "+Gap". Plenty of column room (64px).
      local g = gap_after(r)
      local glabel = (g and g > 0.001) and (('%.3gs'):format(g)) or '+Gap'
      local clicked = ImGui.SmallButton(ctx, glabel .. '##gap_btn_' .. r.id)
      if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
        S.gapedit = {id=r.id, buf=('%.3f'):format(S.gap_len):gsub('%.?0+$', ''), focused=false}
      elseif clicked then
        add_gap_after(i, S.gap_len)
      end
      if ImGui.IsItemHovered(ctx) then
        if g and g > 0.001 then
          tip(('Gap after this region: %.3gs · click adds %.3gs more · double-click to type exact'):format(g, S.gap_len))
        else
          tip(('Insert %.3gs gap (click) · double-click to type exact length'):format(S.gap_len))
        end
      end
      ImGui.SameLine(ctx, 0, 2)
      if ImGui.SmallButton(ctx, 'X') then delete_region(r) end
      if ImGui.IsItemHovered(ctx) then tip('Delete region') end
    end

    ImGui.PopID(ctx)
  end

  ImGui.EndTable(ctx)
  -- v0.7.18d: remember the table's screen rect so window drag-anywhere can EXCLUDE
  -- it. The gaps between/around rows are non-item space → a click there would start
  -- a window move (yanking the window while you reach for a region to reorder).
  do
    local tx1, ty1 = ImGui.GetItemRectMin(ctx)
    local tx2, ty2 = ImGui.GetItemRectMax(ctx)
    S.table_rect = {tx1, ty1, tx2, ty2}
  end

  -- Advance any in-flight time-cell drag (snap-aware, one undo block per drag)
  process_num_drag()

  -- Handle reorder after table closes (avoid mutating mid-iter)
  if drop_target_idx and S.drag_src and drop_target_idx ~= S.drag_src then
    local new_order = {}
    for _, rr in ipairs(S.regions) do new_order[#new_order + 1] = rr.id end
    local moved = table.remove(new_order, S.drag_src)
    table.insert(new_order, drop_target_idx, moved)
    commit_reorder(new_order)
    S.drag_src = nil
  end
end

local HELP_TEXT =
  'Lane drag depends on the mode toggle:\n' ..
  '  INSERT — drop a region between others; they reflow out of the way and audio follows (a caret shows the slot)\n' ..
  '  LANES — free placement; regions may overlap and their audio overlaps too (Overlap = hard stack · Xfade = auto-crossfade)\n' ..
  'Reorder in the list: drag a region by its NAME (or the number) onto another row — content moves with it\n' ..
  'Time cells (Time mode): drag a SPECIFIC number (minutes / seconds / ms) up/down to change just that place · hold Ctrl for fine steps · double-click = type the value. (Beats mode = whole-cell grid-snap drag.)\n' ..
  'Rename: double-click a region name (list or lane)\n' ..
  'Color: right-click the color cell for grey presets + a custom RGB/HSV picker\n' ..
  'Gap: set "Gap Length" (right), then +Gap on a row to insert that much silence (ripples later regions). Once a gap exists the button shows its length. Double-click to type an exact gap.\n' ..
  'Tooltips: the ? by the X toggles these on/off · Close: the X, or Esc when nothing is being edited\n' ..
  'Usage log (for feedback): a JSONL file at <REAPER resource path>/Data/ReaRanger/ (Options > Show REAPER resource path). Email it to share your sessions.'

-- Custom title bar (v0.7.5b): the window is borderless/no-native-titlebar
-- (drag-anywhere is intentional, v0.6.0). This draws a title BAND at the very
-- top — app name + word-wrapped info/stats + the X close — sitting above the
-- overview lane. Height adapts to the wrapped text so it can never clip.
local function draw_title_bar()
  local x1, y1   = ImGui.GetCursorScreenPos(ctx)
  local avail_w  = ImGui.GetContentRegionAvail(ctx)
  if avail_w < 60 then avail_w = 60 end
  local X_COL_W  = 56                       -- reserved right gutter for the ? and X buttons
  local pad      = 8
  local wrap_w   = avail_w - pad*2 - X_COL_W
  if wrap_w < 40 then wrap_w = 40 end

  local info = ('%d region%s  ·  Snap %s  ·  drag a block = move (ripple) · right-edge = resize · dbl-click = rename'):format(
    #S.regions, #S.regions == 1 and '' or 's', snap_enabled() and 'ON' or 'OFF')
  -- ReaImGui Lua sig: CalcTextSize(ctx, text, w_out, h_out, hide_after_##, wrap_w)
  -- w/h are positional out-slots (pass nil) — hide is #5, wrap_width is #6.
  local _, info_h = ImGui.CalcTextSize(ctx, info, nil, nil, false, wrap_w)
  local bar_h = math.max(38, 20 + info_h + 8)   -- title line + wrapped info + pad

  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddRectFilled(dl, x1, y1, x1 + avail_w, y1 + bar_h, TITLE_BG_COL)
  ImGui.DrawList_AddRect(dl,       x1, y1, x1 + avail_w, y1 + bar_h, LANE_BORDER_COL)
  -- App name (draw-list text = not an item, so this area stays drag-anywhere)
  ImGui.DrawList_AddText(dl, x1 + pad, y1 + 4, TITLE_TEXT_COL, 'ReaRanger  v0.7.21')

  -- ? (help + tooltip-toggle) then X close, top-right inside the band.
  -- The moved-here ? does double duty: hover = full help, click = toggle all
  -- tooltips. Its OWN hover bypasses the tip() gate so it stays discoverable even
  -- when tooltips are off (otherwise you couldn't find the switch to turn them back).
  ImGui.SetCursorScreenPos(ctx, x1 + avail_w - X_COL_W + 4, y1 + 4)
  if ImGui.SmallButton(ctx, (S.tooltips_on and '?' or '?-') .. '##help') then
    S.tooltips_on = not S.tooltips_on
    set_status('Tooltips ' .. (S.tooltips_on and 'ON' or 'OFF'))
  end
  if ImGui.IsItemHovered(ctx) then
    ImGui.SetTooltip(ctx, HELP_TEXT ..
      '\n\n[click this ? to turn tooltips ' .. (S.tooltips_on and 'OFF' or 'ON') .. ']')
  end
  ImGui.SameLine(ctx, 0, 4)
  if ImGui.SmallButton(ctx, 'X##close') then S.want_close = true end
  if ImGui.IsItemHovered(ctx) then tip('Close (Esc also closes when no edit active)') end

  -- Wrapped info/stats line
  ImGui.SetCursorScreenPos(ctx, x1 + pad, y1 + 20)
  ImGui.PushTextWrapPos(ctx, x1 + pad + wrap_w)
  ImGui.TextDisabled(ctx, info)
  ImGui.PopTextWrapPos(ctx)

  -- advance the layout cursor below the band
  ImGui.SetCursorScreenPos(ctx, x1, y1 + bar_h + 2)
  ImGui.Dummy(ctx, avail_w, 0)
end

local function draw_toolbar()
  -- Layout: LEFT = +Region/len · CENTER = mode toggles (regions/items) · RIGHT =
  -- Time/Beats + Gap len.
  local start_x = ImGui.GetCursorPosX(ctx)
  local total_w = start_x + select(1, ImGui.GetContentRegionAvail(ctx))   -- content right edge X

  -- LEFT: + Region with its own length field
  if ImGui.Button(ctx, '+ Region') then add_region_at_cursor() end
  if ImGui.IsItemHovered(ctx) then tip('Add a region at the edit cursor, this many seconds long') end
  ImGui.SameLine(ctx); ImGui.TextDisabled(ctx, 'Length')
  ImGui.SameLine(ctx); ImGui.SetNextItemWidth(ctx, 54)
  local rv_l, nrl = ImGui.InputDouble(ctx, '##newreglen', S.new_region_len, 0, 0, '%.2f')
  if rv_l then S.new_region_len = math.max(0.1, nrl) end

  -- CENTER: the two mode toggles, labelled by what they act on — "regions" (the
  -- Insert/Overlay arrange behaviour) and "items" (how overlapping audio reads).
  local CENTER_W = 250
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, math.max(ImGui.GetCursorPosX(ctx), (total_w - CENTER_W) / 2))
  ImGui.TextDisabled(ctx, 'Regions:'); ImGui.SameLine(ctx)
  if ImGui.Button(ctx, S.lane_mode == 'insert' and 'Insert' or 'Lanes') then
    S.lane_mode = (S.lane_mode == 'insert') and 'overlay' or 'insert'
    set_status('Regions: ' .. (S.lane_mode == 'insert'
      and 'INSERT (reorder, push others out of the way)' or 'LANES (free place, regions can overlap)'))
  end
  if ImGui.IsItemHovered(ctx) then
    tip(S.lane_mode == 'insert'
      and 'Regions: INSERT — lane move reorders, others reflow, audio follows (click → Lanes)'
      or  'Regions: LANES — lane move is free, regions can overlap (click → Insert)')
  end
  ImGui.SameLine(ctx); ImGui.TextDisabled(ctx, 'Items:'); ImGui.SameLine(ctx)
  if ImGui.Button(ctx, S.overlap_mode == 'crossfade' and 'Xfade' or 'Overlap') then
    S.overlap_mode = (S.overlap_mode == 'crossfade') and 'overlap' or 'crossfade'
    set_status('Items: ' .. (S.overlap_mode == 'crossfade'
      and 'CROSSFADE (auto-crossfade overlapping items)' or 'OVERLAP (hard stack)'))
  end
  if ImGui.IsItemHovered(ctx) then
    tip(S.overlap_mode == 'crossfade'
      and 'Items: CROSSFADE — overlapping audio auto-crossfades (click → hard Overlap)'
      or  'Items: OVERLAP — overlapping audio hard-stacks, no fade (click → Crossfade)')
  end

  -- RIGHT: Time/Beats toggle + Gap len, right-aligned (gap field over the Gap col).
  local TIME_W, GAP_LABEL_W, GAP_FIELD_W = 56, 52, 60
  local RIGHT_W = TIME_W + 12 + GAP_LABEL_W + GAP_FIELD_W
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, math.max(ImGui.GetCursorPosX(ctx), total_w - RIGHT_W))
  if ImGui.Button(ctx, S.time_mode == 'beats' and 'Beats' or 'Time') then
    S.time_mode = (S.time_mode == 'beats') and 'time' or 'beats'
  end
  if ImGui.IsItemHovered(ctx) then
    tip('Start/Length display: ' ..
      (S.time_mode == 'beats' and 'measures.beats (click → MM:SS.mmm)' or 'MM:SS.mmm (click → measures.beats)'))
  end
  ImGui.SameLine(ctx); ImGui.TextDisabled(ctx, 'Gap Length')
  ImGui.SameLine(ctx); ImGui.SetNextItemWidth(ctx, GAP_FIELD_W)
  local rv_g, ngl = ImGui.InputDouble(ctx, '##gaplen', S.gap_len, 0, 0, '%.2f')
  if rv_g then S.gap_len = math.max(0.01, ngl) end
end

local function draw_status()
  if S.status_msg ~= '' and (reaper.time_precise() - S.status_t) < 3.0 then
    ImGui.TextDisabled(ctx, S.status_msg)
  else
    ImGui.TextDisabled(ctx, 'Ready.')
  end
end

local function loop()
  maybe_poll()
  Tel.tick()
  if S.dirty then load_regions() end

  push_grey_theme()
  ImGui.SetNextWindowSize(ctx, 760, 460, ImGui.Cond_FirstUseEver)
  -- NoMove (v0.7.18c): disable ImGui's NATIVE drag-to-move. Plain-Text items (the
  -- per-digit time numbers) never become "active", so native move would grab the
  -- drag and slide the WINDOW instead of changing the number. Window moves now go
  -- SOLELY through the manual win_drag handler below, which already excludes
  -- num_drag / rename / edit / lane_drag — so dragging a number no longer moves the
  -- window, yet drag-anywhere (via SetWindowPos, unaffected by NoMove) still works.
  local win_flags = ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoCollapse
                  | ImGui.WindowFlags_NoMove
  local visible, open = ImGui.Begin(ctx, SCRIPT_TITLE, true, win_flags)
  if visible then
    -- v0.7.5b: title band → overview lane → controls (Poofox layout pref).
    draw_title_bar()
    draw_region_lane()
    ImGui.Separator(ctx)
    draw_toolbar()
    ImGui.Separator(ctx)
    draw_table()
    draw_status()

    -- Drag-anywhere: begin drag if mouse pressed in window on empty space —
    -- EXCEPT inside the region list/table, whose inter-row gaps would otherwise
    -- yank the window while you reach to drag a region (v0.7.18d).
    local mxw, myw = ImGui.GetMousePos(ctx)
    local tr = S.table_rect
    local in_table = tr and mxw >= tr[1] and mxw <= tr[3] and myw >= tr[2] and myw <= tr[4]
    if not S.win_drag and not in_table then
      if ImGui.IsWindowHovered(ctx, ImGui.HoveredFlags_RootWindow or 0)
         and not ImGui.IsAnyItemHovered(ctx)
         and not ImGui.IsAnyItemActive(ctx)
         and ImGui.IsMouseClicked(ctx, 0)
         and not S.rename and not S.edit and not S.num_drag and not S.lane_drag then
        local wx, wy = ImGui.GetWindowPos(ctx)
        S.win_drag = {wx=wx, wy=wy}
        ImGui.ResetMouseDragDelta(ctx, 0)
      end
    end
    if S.win_drag then
      if ImGui.IsMouseDown(ctx, 0) then
        local dx, dy = ImGui.GetMouseDragDelta(ctx, 0)
        ImGui.SetWindowPos(ctx, S.win_drag.wx + dx, S.win_drag.wy + dy)
      else
        S.win_drag = nil
      end
    end

    -- Esc closes window when nothing else is being edited (otherwise Esc cancels edit)
    if not S.rename and not S.edit and not S.num_drag and ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
      S.want_close = true
    end

    ImGui.End(ctx)
  end
  pop_grey_theme()

  if S.want_close then open = false end
  if open then reaper.defer(loop) end
end

Tel.init('0.7.13')
reaper.atexit(Tel.shutdown)
reaper.defer(loop)
