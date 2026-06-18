-- @description ReaRanger fA - Realtime Region List Editor
-- @author foxAsteria
-- @version 0.7.39
-- @changelog
--   v0.7.39 (2026-06-18) — per-digit drag refinement + gap-cell drag.
--     * Per-digit time drag now changes ONLY the hovered place (minutes / seconds /
--       ms) and CLAMPS within it — no carry into the neighbouring place. Dragging
--       seconds rolls 0–59 and stays in the same minute; ms stays 0–999.
--     * Ctrl-fine DROPPED (Poofox: "just makes it slower") — restrict-to-place is the
--       precision model now.
--     * GAP cell is now a draggable per-digit time value once a gap exists (same feel
--       as start/length): drag a digit to resize (ripple on release), double-click to
--       type exact, drag/type to 0 closes it. "+Gap" button stays for creating one.
--       New helpers close_gap_after (partial ripple-close) + set_gap_after (absolute).
--   v0.7.38 (2026-06-18) — multi-select + split-snap toggle + 3-way removal.
--     * SPLIT-SNAP MAGNET toggle (toolbar center): ON = SHIFT-drag split snaps to
--       the project grid (clean bar landing); OFF = drop the new region anywhere
--       (free split, no snap). Default ON.
--     * LIST MULTI-SELECT: click = select · Ctrl+click = add/toggle · Shift+click =
--       range from the anchor. Whole selection highlights in list + lane.
--     * REMOVAL is now 3 options (right-click region, list or lane): "Remove region"
--       (marker only — timeline untouched), "Remove region + content (leave gap)",
--       "Remove region + content + gap" (ripple-close). Applies to the whole
--       multi-selection at once when the clicked region is part of it. One undo each.
--     * ALT-click erase = marker only, nothing else changes (now id-based delete).
--   v0.7.37 (2026-06-18) — selection highlight made clearly visible on BOTH surfaces:
--     the list row tint was brightened (muted olive → warm amber), and the lane block
--     now gets a translucent warm fill on top of its bright border (the thin border
--     alone was easy to miss). Select a region anywhere → it pops in list + lane.
--     Also: +Region now auto-selects the region it just created (highlight + time-sel).
--     Also: new-region LENGTH field in beats mode now accepts a bare beat count
--     (tempo-aware fallback) — REAPER's measures.beats parser was rejecting edits
--     and pinning the length at the 4.0s default.
--     Also: SHIFT-drag split-create now snaps to the project GRID (grid lines only,
--     not region edges/markers — computed via QN). The lane spans the whole project,
--     so raw drags produced wild huge spans that never sat inside one region (→ no
--     split). Grid snap makes dragged regions land cleanly on bars at any zoom so
--     mid-region splits actually fire. ALT erase-click stays raw.
--   v0.7.36 (2026-06-18) — added SHOW-IN-LANES toggle in the toolbar center (next
--     to crossfade): bound to REAPER option 40507 "Show overlapping media items in
--     lanes (when room)". Icon reflects REAPER's state, click flips it; self-guards
--     if the option is unavailable on the build.
--   v0.7.35 (2026-06-18) — split moved to SHIFT-drag (Shift = REAPER's no-snap
--     modifier, so it reads naturally as "place exactly here"). ALT stays as the
--     erase-click. Split still uses raw cursor time (no snap).
--   v0.7.34 (2026-06-18) — alt-split bypasses snapping (it was forcing the split
--     span to region edges, so a mid-region split was impossible). Alt drag now
--     uses raw cursor time, no maybe_snap.
--   v0.7.33 (2026-06-18) — gap removal + gap highlighting.
--     * Gaps between regions are now faintly highlighted on the lane (warm tint +
--       thin border) so they read as targets.
--     * Right-click a gap → "Remove gap (X)" — ripple-deletes that empty span so
--       later content + region markers pull left by the gap length (inverse of the
--       +Gap insert). Undo-wrapped.
--   v0.7.32 (2026-06-18) — gesture-driven lanes, alt split/erase, removal.
--     * Overlap/insert TOGGLE REMOVED. The drag gesture decides: sideways (same
--       lane) = ripple-reorder; drag a region into a DIFFERENT lane row = stack it
--       there (overlap), and the DRAGGED region keeps that lane (S.lane_pref →
--       pack_lanes honors it, instead of bumping the in-the-way region).
--     * +Region now always INSERTS (ripples space open — no accidental lanes).
--     * ALT-drag on the lane = create a new region over the dragged span; if it
--       lands strictly inside a region, that region splits into <name>-a / New
--       Region / <name>-b. ALT-click a region = erase marker only (content stays).
--     * Removal: right-click a region (lane OR list name) → "Remove region (keep
--       content)" / "Remove region + content (leave gap)". The latter deletes the
--       media items fully inside the span and the marker, leaving silence.
--     * Help text + tooltips rewritten for the gesture model; crossfade toggle kept.
--   v0.7.31 (2026-06-18) — selection, add-region mode, glyph + undo fixes.
--     * SELECT a region: click a list row OR a lane block → highlights it in
--       ReaRanger (row tint + bright lane border) AND selects it in the project
--       (sets the time selection to the region span). Reverse-synced: when
--       REAPER's time selection matches a region, that row lights up — so you can
--       pick a region in the timeline, see which it is, then +Gap on that row.
--     * Lane CLICK: empty space now moves the edit cursor; clicking a region
--       SELECTS it (was: always moved the cursor).
--     * +Region honours the overlap toggle: NOT-OVERLAP = INSERT (opens space at
--       the cursor, ripples later content/markers right — no more accidental
--       lanes); OVERLAP = drop as-is. (Fixes "add region adds lanes".)
--     * +Region glyph no longer faded (it's an action, one state) + drawn as a
--       closed region block (top edge added) so it reads as a region, not an "H".
--     * Beats glyph = two beamed eighth notes instead of the snare (read as a TV).
--     * Ctrl+Z / Ctrl+Shift+Z / Ctrl+Y now dispatch REAPER undo/redo explicitly
--       (40029/40030) — the WantCaptureKeyboard release alone didn't pass through.
--   v0.7.30 (2026-06-17) — icon toolbar + 2-way overlap toggle + resync.
--     * ICON TOOLBAR: +Region, Time/Beats and the overlap toggle are now
--       hand-drawn DrawList glyphs (no text). +Region = "+" plus a region span
--       (bar w/ end caps); Time/Beats = clock (time) / snare drum (beats);
--       overlap toggle = two corner-offset shaded rects; not-overlap = two rects
--       with a gap. Light, low-contrast styling with a few greys — more contrast
--       when ON than OFF. Icons are frame-height so the row lines up.
--     * OVERLAP TOGGLE: 2-way EXCLUSIVE — OVERLAP / NOT OVERLAP (replaces the old
--       Insert/Lanes + Xfade/Overlap buttons; free-position dropped). S.region_mode
--       is source of truth; also sets the drag mode (lane_mode).
--     * CROSSFADE: standalone on/off icon toggle (bezier-X glyph, shaded lens),
--       set apart from the overlap pair. Bound to REAPER's own auto-crossfade
--       option (40912) — the icon reflects the REAPER state and clicking flips it
--       (self-guards if unavailable). User-driven; not forced on drags.
--     * RESYNC: the poll now detects regions MOVED / RESIZED / RENAMED / RECOLORED
--       directly in REAPER (was count-only → only saw add/remove). Cheap
--       GetProjectStateChangeCount gate, then a region content signature; guarded
--       against reloading mid drag/rename. No manual refresh button needed.
--     * TOOLTIPS: fixed stale "OVERLAY … marker only" hints — free-mode drags
--       MOVE CONTENT (since v0.7.14); renamed to FREE/CROSSFADE/LANES to match the
--       new toggle. HELP_TEXT updated.
--   v0.7.29 (2026-06-17) — Docking + keyboard passthrough.
--     * Keyboard passthrough: when you're not typing in a field, ReaRanger now
--       releases ImGui's keyboard capture so REAPER's own shortcuts work while the
--       window is focused — Ctrl+Z undo, space = play, etc. (was swallowed before).
--     * Docking: right-click the title band → Dock / Undock. A docked window is
--       managed by REAPER (no custom drag-move / NoMove while docked); undock→redock
--       returns to the same docker. Drag a floating window onto a REAPER docker to
--       dock natively. Title-band right-click menu also has Close.
--   v0.7.28 (2026-06-16) — Length/duration entry honours the Time/Beats toggle
--     everywhere (was seconds-only in three spots): the +Region length field,
--     the gap field (button label + type-exact entry + tooltips), and the lane
--     hover "len" readout. The per-row Length COLUMN already respected it; these
--     now match. Values stay seconds internally; display/parse route through
--     fmt_time_full/parse_time_full with kind='len' (measures.beats vs MM:SS.mmm).
--   v0.7.27 (2026-06-16) — CONTENT-COMPLETE moves (punch #2). New unified
--     carry_content() primitive moves a span's media items + track automation
--     (envelope points) + normal markers + tempo/timesig markers by a delta —
--     100% manual set-absolute, no native ripple, pref/timebase-independent.
--     Reorder (commit_reorder) and free lane-move (apply_move_free) now carry
--     ALL of that, not just media items. Proven by ~/Downloads/rr_carry_probe.lua
--     (all 4 element types swap cleanly). Beats-timebase note: moving tempo
--     markers re-warps beat-anchored content (REAPER's anchoring, documented).
--     apply_start/add_gap/duplicate still use native ripple (follow-up).
--   v0.7.26 (2026-06-16) — Ctrl+drag-DUPLICATE on the lane: hold Ctrl and drag a
--     region to clone it (marker + the media items in its span) to the drop point.
--     Respects the Insert/Lanes toggle like a move — Lanes = free overlay copy;
--     Insert = ripple-open r.len of space then place. Items cloned exactly via state
--     chunk with regenerated GUIDs (no collisions); snapshot taken before any ripple.
--     Undo-wrapped. NOTE: list-drag duplicate is the follow-up (lane-first).
--   v0.7.25 (2026-06-16) — Settled: ALL title-band text (app-name + info/stats line)
--     uses the original near-white 0xE6E6E6, driven from one constant. The info line
--     was the only broken one (dark TextDisabled on the dark band → invisible); it now
--     follows TITLE_TEXT_COL. The earlier muting detour is fully reverted.
--   v0.7.24 (2026-06-16) — Title-bar text readability: band is DARK (0x383838), so both
--     the app-name AND the info/stats line draw from one TITLE_TEXT_COL constant.
--   v0.7.23 (2026-06-16) — Title-bar app-name = 0x404040, matching the info/stats
--     line (Col_TextDisabled): muted-dark, reads on the light surface. (Light greys
--     went the wrong way — text sits on a light bg, so it needed to go darker.)
--   v0.7.22 (2026-06-16) — Title-bar app-name to muted light grey (0xA8A8A8, Pearl):
--     0x787878 matched the body bg and vanished; this reads while staying muted.
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
local TITLE_TEXT_COL     = 0xE6E6E6FF  -- title-bar text (app name + info line) = original near-white, readable on dark band, per Poofox
local OVERLAY_BORDER_COL = 0xE0E0E0FF  -- brighter border = overlay/marker region (lane > 0)
local INSERT_CARET_COL   = 0xFFFFFFFF  -- pure-white insertion caret (insert-mode drop slot)
local INSERT_GHOST_COL   = 0xFFFFFF44  -- translucent landing rect at the insert slot
local SEL_BORDER_COL     = 0xFFE066FF  -- selected region: warm bright border (lane)
local SEL_FILL_COL       = 0xFFE0664D  -- selected region: translucent warm fill over the lane block (v0.7.37)
local SEL_ROW_COL        = 0x8A7630FF  -- selected region: list-row background tint (v0.7.37: brightened warm amber — old olive was too subtle to see)
local GAP_FILL_COL       = 0xFFC04018  -- gap between regions: faint warm fill (lane row 0)
local GAP_BORDER_COL     = 0xFFC04055  -- gap: thin warm border so it reads as clickable
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
  last_state_count = -1,        -- reaper.GetProjectStateChangeCount snapshot (cheap pre-check)
  last_region_sig = nil,        -- signature of region set — detects external move/rename/resize/recolor (v0.7.30)
  region_mode = 'overlap',      -- 2-way toggle: 'overlap' | 'nonoverlap'. v0.7.30
  sel_id = nil,                 -- ANCHOR selected region id (v0.7.31): click a region (list/lane) → select in project (time-sel) + highlight; reverse-synced from REAPER time selection. Drives time-sel + shift-range anchor.
  sel_set = {},                 -- [region_id]=true, the full multi-selection (v0.7.38). List: plain click=replace, Ctrl=toggle, Shift=range from anchor. Highlight + bulk removal use this set; sel_id is the anchor within it.
  split_snap = true,            -- v0.7.38: magnet toggle. ON = SHIFT-drag split-create snaps to the project grid (clean bar landing). OFF = drop anywhere raw (free split).
  lane_pref = {},               -- [region_id] = lane row the user dragged it to (v0.7.32). Honored by pack_lanes; nil = auto-pack.
  alt_drag = nil,               -- {start_x, start_t, over_id, moved} during an ALT split-create / erase gesture (v0.7.32)
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
  new_region_len = 4.0,       -- length (s) for "+ Region at cursor"
  tooltips_on = true,         -- master toggle for hover tooltips (? button by the X)
  status_msg = '',
  status_t = 0,
  win_drag = nil,             -- {wx, wy} window pos at drag start (drag-anywhere)
  want_close = false,
  -- Docking (v0.7.29). is_docked is read each frame from ImGui.IsWindowDocked.
  -- dock_apply/dock_target = one-shot request to SetNextWindowDockID next frame
  -- (right-click toggle). last_dock_id remembers the docker so undock→redock
  -- returns to the same place; -1 = "a REAPER docker" for the first-ever dock.
  is_docked = false,
  dock_apply = false,
  dock_target = 0,
  last_dock_id = -1,
}

local function set_status(msg)
  S.status_msg = msg
  S.status_t = reaper.time_precise()
end

-- ====================================================================
-- Region IO
-- ====================================================================
-- Cheap content signature of the project's region set (each region's
-- id / pos / end / color / name). The bare marker COUNT only catches add/remove;
-- this also catches a region MOVED, RESIZED, RENAMED, or RECOLORED directly in
-- REAPER — so the list/lane stays in sync with the arrange view. v0.7.30.
local function region_signature()
  local parts, i = {}, 0
  while true do
    local ok, isrgn, pos, rend, name, idx, color = reaper.EnumProjectMarkers3(0, i)
    if ok == 0 then break end
    if isrgn then
      parts[#parts + 1] = string.format('%d:%.4f:%.4f:%d:%s', idx, pos, rend, color, name)
    end
    i = i + 1
  end
  return table.concat(parts, '|')
end

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
  -- re-baseline the change detectors so a reload (ours or external) doesn't
  -- immediately re-trigger itself
  S.last_region_sig  = region_signature()
  S.last_state_count = reaper.GetProjectStateChangeCount(0)
  S.dirty = false
end

local function maybe_poll()
  -- Never resync mid-interaction — reloading would clobber an in-flight
  -- drag / list-reorder / rename.
  if S.lane_drag or S.drag_src or S.rename then return end
  local t = reaper.time_precise()
  if t - S.last_poll_t < POLL_INTERVAL then return end
  S.last_poll_t = t
  -- Compare a fresh region signature every tick. (The old
  -- GetProjectStateChangeCount pre-gate was dropped 2026-06-18: some marker edits
  -- don't bump that counter, so changes silently slipped through and the list
  -- never refreshed. The signature itself is the reliable detector; enumerating
  -- markers twice a second is cheap.)
  local sig = region_signature()
  if sig ~= S.last_region_sig then
    S.last_region_sig = sig
    S.dirty = true
  end
  -- v0.7.31: reverse-sync selection — if REAPER's time selection exactly spans a
  -- region (e.g. user double-clicked it in the ruler), light that row up in the
  -- list. Cheap: one GetSet read + a linear scan twice a second.
  local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
  if ts_b > ts_a then
    for _, r in ipairs(S.regions) do
      if math.abs(r.pos - ts_a) < 1e-4 and math.abs(r.rend - ts_b) < 1e-4 then
        -- v0.7.38: don't clobber a multi-selection — only make it the sole
        -- selection if it wasn't already part of the set (i.e. user picked it in
        -- REAPER's ruler). Otherwise just move the anchor.
        if not S.sel_set[r.id] then S.sel_set = { [r.id] = true } end
        S.sel_id = r.id; break
      end
    end
  end
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

-- Snap a time to the nearest project GRID line only (bar/beat division). Unlike
-- reaper.SnapToGrid this does NOT snap to region edges / markers — that marker
-- snapping is exactly why v0.7.34 had to drop snapping to allow mid-region splits.
-- v0.7.37: the shift-drag split-create snaps to grid so dragged regions land
-- cleanly on bars at any zoom (the lane spans the whole project → raw drags were
-- wild huge spans). Computed via QN so it's tempo/time-sig aware.
local function snap_to_grid_only(t)
  if t < 0 then t = 0 end
  if not (reaper.TimeMap2_timeToQN and reaper.TimeMap2_QNToTime) then return t end
  local division = 0.25
  if reaper.GetSetProjectGrid then
    local _, div = reaper.GetSetProjectGrid(0, false)
    if div and div > 0 then division = div end
  end
  local step_qn = division * 4          -- division is in whole-notes; ×4 → quarter-notes
  if step_qn <= 0 then return t end
  local qn = reaper.TimeMap2_timeToQN(0, t)
  local snapped = math.floor(qn / step_qn + 0.5) * step_qn
  return reaper.TimeMap2_QNToTime(0, snapped)
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


local function with_ripple_all(fn)
  local prev = get_ripple_mode()
  if prev ~= 2 then set_ripple_mode(2) end
  local ok, err = pcall(fn)
  if prev ~= 2 then set_ripple_mode(prev) end
  if not ok then reaper.ShowConsoleMsg('ReaRanger ripple-op error: '..tostring(err)..'\n') end
end

-- ====================================================================
-- carry_content (v0.7.27) — the unified content-mover. Proven by
-- ~/Downloads/rr_carry_probe.lua (all 4 element types carry a per-span delta in
-- a non-contiguous swap). spans = list of {lo, hi, delta}: every media item,
-- track-envelope point, normal (non-region) marker, and tempo/timesig marker
-- whose ORIGINAL position falls in some span is moved by that span's delta.
-- 100% manual set-absolute — NO native ripple, NO time selection, NO command
-- IDs → deterministic and independent of the user's ripple/insert-time prefs.
-- Snapshot-then-apply throughout so an overlapping source/dest never double-
-- applies. opts.items / opts.env = false skips those classes.
-- Region markers are intentionally NOT touched here — callers reposition those
-- explicitly (they own the region layout). Automation ITEMS (AI objects) are a
-- known gap (edge case for a lite arranger); track envelope POINTS are carried.
-- NOTE: in a beats-timebase project with tempo changes, moving tempo markers
-- re-warps beat-anchored content — that is REAPER's anchoring, not a bug here.
-- ====================================================================
local CARRY_TOL = 0.001
local function delta_for(pos, spans)
  for _, s in ipairs(spans) do
    if pos >= s.lo - CARRY_TOL and pos < s.hi + CARRY_TOL then return s.delta end
  end
  return nil
end

local function carry_content(spans, opts)
  opts = opts or {}
  local do_items = opts.items ~= false
  local do_env   = opts.env   ~= false
  local stats = {items = 0, env = 0, markers = 0, tempo = 0}

  -- 1) MEDIA ITEMS — stable handle, snapshot then apply
  if do_items then
    local moves = {}
    for i = 0, reaper.CountMediaItems(0) - 1 do
      local it = reaper.GetMediaItem(0, i)
      local p = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
      local d = delta_for(p, spans)
      if d and math.abs(d) > 1e-9 then moves[#moves+1] = {it = it, np = p + d} end
    end
    for _, m in ipairs(moves) do
      reaper.SetMediaItemInfo_Value(m.it, 'D_POSITION', m.np)
    end
    stats.items = #moves
  end

  -- 2) TRACK ENVELOPE POINTS — set with noSort=true (idx stays valid), sort once
  if do_env then
    local touched = {}
    for ti = 0, reaper.CountTracks(0) - 1 do
      local tr = reaper.GetTrack(0, ti)
      for ei = 0, reaper.CountTrackEnvelopes(tr) - 1 do
        local env = reaper.GetTrackEnvelope(tr, ei)
        local moves = {}
        for pi = 0, reaper.CountEnvelopePoints(env) - 1 do
          local ok, t = reaper.GetEnvelopePoint(env, pi)
          if ok then
            local d = delta_for(t, spans)
            if d and math.abs(d) > 1e-9 then moves[#moves+1] = {idx = pi, nt = t + d} end
          end
        end
        if #moves > 0 then
          for _, mv in ipairs(moves) do
            reaper.SetEnvelopePoint(env, mv.idx, mv.nt, nil, nil, nil, nil, true)
          end
          touched[#touched+1] = env
          stats.env = stats.env + #moves
        end
      end
    end
    for _, env in ipairs(touched) do reaper.Envelope_SortPoints(env) end
  end

  -- 3) NORMAL MARKERS — addressed by STABLE IDnumber, written to an ABSOLUTE
  --    target (same pattern the shipped region-marker code uses).
  local mk, i = {}, 0
  while true do
    local retval, isrgn, pos, _, name, idnum, color = reaper.EnumProjectMarkers3(0, i)
    if retval == 0 then break end
    if not isrgn then
      local d = delta_for(pos, spans)
      if d and math.abs(d) > 1e-9 then
        mk[#mk+1] = {idnum = idnum, np = pos + d, name = name, color = color}
      end
    end
    i = i + 1
  end
  for _, m in ipairs(mk) do
    reaper.SetProjectMarker4(0, m.idnum, false, m.np, 0, m.name, m.color, 0)
  end
  stats.markers = #mk

  -- 4) TEMPO/TIMESIG MARKERS — no stable id & ptidx churns on move, so snapshot,
  --    delete DESCENDING (keeps lower idx valid), then re-add at target time.
  --    Guard t>1e-6 so the project-initial tempo marker is never relocated.
  local tm = {}
  for ti = 0, reaper.CountTempoTimeSigMarkers(0) - 1 do
    local ok, tpos, _, _, bpm, num, den, lin = reaper.GetTempoTimeSigMarker(0, ti)
    if ok and tpos > 1e-6 then
      local d = delta_for(tpos, spans)
      if d and math.abs(d) > 1e-9 then
        tm[#tm+1] = {idx = ti, ntpos = tpos + d, bpm = bpm, num = num, den = den, lin = lin}
      end
    end
  end
  table.sort(tm, function(a, b) return a.idx > b.idx end)
  for _, t in ipairs(tm) do reaper.DeleteTempoTimeSigMarker(0, t.idx) end
  for _, t in ipairs(tm) do
    reaper.AddTempoTimeSigMarker(0, t.ntpos, t.bpm, t.num, t.den, t.lin)
  end
  stats.tempo = #tm
  return stats
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
    -- v0.7.27: carry the whole content of this region's CURRENT span (items +
    -- track automation + normal markers + tempo/timesig) by delta — not just
    -- media items. Region marker itself is moved separately below.
    carry_content({{lo = r.pos, hi = r.rend, delta = delta}})
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

-- ====================================================================
-- Duplicate (v0.7.26): Ctrl+drag a region on the lane → clone it (marker +
-- the media items in its span) to the drop position. Respects the Insert/Lanes
-- toggle, same as move: 'lanes' = free overlay placement (no ripple); 'insert'
-- = open r.len of space at the drop and ripple later content right, then place.
-- Items are cloned EXACTLY via state chunk (take/source/fades preserved) with
-- regenerated GUIDs so there are no duplicate-GUID collisions. Snapshot is taken
-- BEFORE any ripple so moving the originals can't disturb the clone source.
-- ====================================================================
local function snapshot_span_items(src_pos, src_end)
  local snap, n = {}, reaper.CountMediaItems(0)
  for i = 0, n - 1 do
    local it = reaper.GetMediaItem(0, i)
    local ip = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
    if ip >= src_pos - 0.001 and ip < src_end + 0.001 then
      local _, chunk = reaper.GetItemStateChunk(it, '', false)
      snap[#snap + 1] = {track = reaper.GetMediaItem_Track(it), chunk = chunk, pos = ip}
    end
  end
  return snap
end

-- GUID-shaped token: {8-4-4-4-12 hex}. Regenerate every one so clones are unique.
local GUID_PAT = '{%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x}'
local function clone_snapshot(snap, delta)
  for _, s in ipairs(snap) do
    local newit = reaper.AddMediaItemToTrack(s.track)
    local chunk = s.chunk:gsub(GUID_PAT, function() return reaper.genGuid('') end)
    reaper.SetItemStateChunk(newit, chunk, false)
    reaper.SetMediaItemInfo_Value(newit, 'D_POSITION', s.pos + delta)
  end
  return #snap
end

local function duplicate_region(r, new_start, mode)
  if not r then return end
  if new_start < 0 then new_start = 0 end
  local delta = new_start - r.pos

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)

  -- snapshot source items FIRST (original positions; survives a later ripple)
  local snap = snapshot_span_items(r.pos, r.rend)

  if mode == 'insert' then
    -- open r.len of empty space at the drop; later items shift right via ripple
    with_ripple_all(function()
      local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
      reaper.GetSet_LoopTimeRange(true, false, new_start, new_start + r.len, false)
      reaper.Main_OnCommand(40200, 0)   -- insert empty space
      reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
    end)
    -- markers aren't touched by ripple — slide every region at/after the drop
    for _, rr in ipairs(S.regions) do
      if rr.pos >= new_start - 1e-6 then
        reaper.SetProjectMarker4(0, rr.id, true, rr.pos + r.len, rr.rend + r.len,
                                 rr.name, rr.color_native, 0)
        rr.pos = rr.pos + r.len; rr.rend = rr.rend + r.len
      end
    end
  end
  -- v0.7.30: no longer force REAPER's auto-crossfade pref on a free/overlap clone.

  local n_items = clone_snapshot(snap, delta)
  reaper.AddProjectMarker2(0, true, new_start, new_start + r.len, r.name,
                           r.color_native or -1, 0)

  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.UpdateTimeline()
  reaper.Undo_EndBlock(('ReaRanger: duplicate region (%s, %d items)'):format(mode, n_items), -1)
  S.dirty = true
  set_status(('Duplicated "%s" → %.3fs (%s, %d items)'):format(r.name, new_start, mode, n_items))
  Tel.log('duplicate', string.format('{"mode":"%s","delta":%.3f,"items":%d}', mode, delta, n_items))
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

-- ALT-click / "Remove region": marker ONLY. Nothing else in the timeline changes —
-- content stays exactly put, no ripple, no gap close (Poofox, v0.7.38). id-based
-- (DeleteProjectMarker) not enum_i, so a stale enumeration index can't nuke the
-- wrong marker.
local function delete_region(r)
  if not r then return end
  reaper.Undo_BeginBlock()
  reaper.DeleteProjectMarker(0, r.id, true)
  reaper.Undo_EndBlock('ReaRanger: remove region (marker only)', -1)
  S.lane_pref[r.id] = nil
  S.sel_set[r.id] = nil
  if S.sel_id == r.id then S.sel_id = nil end
  S.dirty = true
  Tel.log('delete')
end

-- v0.7.32: remove the region marker AND the media items inside its span, leaving
-- a gap (per Poofox). Only items FULLY within [pos,rend] are deleted; items that
-- straddle a boundary are left alone. Undo-wrapped.
local function remove_region_with_content(r)
  if not r then return end
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local n = 0
  for ti = reaper.CountTracks(0) - 1, 0, -1 do
    local tr = reaper.GetTrack(0, ti)
    for ii = reaper.CountTrackMediaItems(tr) - 1, 0, -1 do
      local it   = reaper.GetTrackMediaItem(tr, ii)
      local ipos = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
      local iend = ipos + reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
      if ipos >= r.pos - 1e-6 and iend <= r.rend + 1e-6 then
        reaper.DeleteTrackMediaItem(tr, it); n = n + 1
      end
    end
  end
  reaper.DeleteProjectMarker(0, r.id, true)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock('ReaRanger: remove region + content', -1)
  S.lane_pref[r.id] = nil
  S.dirty = true
  set_status(('Removed region + %d item%s (gap left): %s'):format(n, n == 1 and '' or 's', r.name))
  Tel.log('remove_with_content', string.format('{"id":%d,"items":%d}', r.id, n))
end

-- ── Bulk-capable removal (v0.7.38) ───────────────────────────────────────────
-- Three kinds, applied to one region or a whole multi-selection:
--   'marker'      — delete the region marker only; timeline untouched.
--   'content'     — delete the region + the media items fully inside its span,
--                   leaving the gap (later content stays put).
--   'content_gap' — as 'content', then ripple-close the gap so later content +
--                   markers pull left by the region length.
local function sel_count()
  local n = 0; for _ in pairs(S.sel_set) do n = n + 1 end; return n
end

-- Delete media items fully within [pos,rend] across all tracks. Returns the count.
local function delete_items_in_span(pos, rend)
  local n = 0
  for ti = reaper.CountTracks(0) - 1, 0, -1 do
    local tr = reaper.GetTrack(0, ti)
    for ii = reaper.CountTrackMediaItems(tr) - 1, 0, -1 do
      local it   = reaper.GetTrackMediaItem(tr, ii)
      local ipos = reaper.GetMediaItemInfo_Value(it, 'D_POSITION')
      local iend = ipos + reaper.GetMediaItemInfo_Value(it, 'D_LENGTH')
      if ipos >= pos - 1e-6 and iend <= rend + 1e-6 then
        reaper.DeleteTrackMediaItem(tr, it); n = n + 1
      end
    end
  end
  return n
end

-- Ripple-close the span [pos,rend]: remove that (now empty) time range so later
-- content pulls left, then slide every marker/region at/after `rend` left by the
-- span length. Markers are enumerated FRESH (not from stale S.regions) so this is
-- safe to call repeatedly within a bulk loop.
local function ripple_close_span(pos, rend)
  local len = rend - pos
  if len <= 1e-9 then return end
  with_ripple_all(function()
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, pos, rend, false)
    reaper.Main_OnCommand(40201, 0)   -- remove time selection (ripple): later content pulls left
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)
  local i = 0
  while true do
    local ok, isrgn, mpos, mend, name, idx, color = reaper.EnumProjectMarkers3(0, i)
    if ok == 0 then break end
    if mpos >= rend - 1e-6 then
      reaper.SetProjectMarker4(0, idx, isrgn, mpos - len, isrgn and (mend - len) or 0, name, color, 0)
    end
    i = i + 1
  end
end

local function apply_removal(targets, kind)
  if not targets or #targets == 0 then return end
  -- Process right-to-left so a ripple-close never shifts the position of a
  -- not-yet-removed region to its left.
  table.sort(targets, function(a, b) return a.pos > b.pos end)
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  local nitems = 0
  for _, r in ipairs(targets) do
    if kind == 'content' or kind == 'content_gap' then
      nitems = nitems + delete_items_in_span(r.pos, r.rend)
    end
    reaper.DeleteProjectMarker(0, r.id, true)
    if kind == 'content_gap' then ripple_close_span(r.pos, r.rend) end
    S.lane_pref[r.id] = nil
    S.sel_set[r.id] = nil
    if S.sel_id == r.id then S.sel_id = nil end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange(); reaper.UpdateTimeline()
  local label = (kind == 'marker') and 'remove region (marker only)'
             or (kind == 'content') and 'remove region + content (leave gap)'
             or 'remove region + content + gap'
  reaper.Undo_EndBlock(('ReaRanger: %s%s'):format(label, #targets > 1 and (' ×' .. #targets) or ''), -1)
  S.dirty = true
  set_status(('%s — %d region%s%s'):format(label, #targets, #targets == 1 and '' or 's',
    nitems > 0 and (', ' .. nitems .. ' item' .. (nitems == 1 and '' or 's')) or ''))
  Tel.log('removal', string.format('{"kind":"%s","n":%d,"items":%d}', kind, #targets, nitems))
end

-- Targets for a right-click removal: the whole multi-selection if the clicked
-- region is part of it (and >1 selected), else just the clicked region.
local function removal_targets(clicked)
  if clicked and S.sel_set[clicked.id] and sel_count() > 1 then
    local t = {}
    for _, rr in ipairs(S.regions) do if S.sel_set[rr.id] then t[#t + 1] = rr end end
    return t
  end
  return { clicked }
end
-- (removal_menu needs `ctx`, so it's defined just after ctx is created — below.)

-- v0.7.32: ALT-drag created a new region spanning [t1,t2]. If that span sits
-- STRICTLY inside an existing region, split the host into <name>-a (left) and
-- <name>-b (right) around the new region; the new region itself is 'New Region'.
-- Outside any region (or overlapping a boundary) it's just added (may overlap).
local function alt_create_split(t1, t2)
  if t2 < t1 then t1, t2 = t2, t1 end
  if (t2 - t1) < 1e-4 then return end
  reaper.Undo_BeginBlock()
  local host
  for _, rr in ipairs(S.regions) do
    if t1 > rr.pos + 1e-4 and t2 < rr.rend - 1e-4 then host = rr; break end
  end
  if host then
    -- host shrinks to its left half (Foo-a); add the right half (Foo-b)
    reaper.SetProjectMarker4(0, host.id, true, host.pos, t1, host.name .. '-a', host.color_native, 0)
    reaper.AddProjectMarker2(0, true, t2, host.rend, host.name .. '-b', -1, host.color_native)
  end
  reaper.AddProjectMarker2(0, true, t1, t2, 'New Region', -1, 0)
  reaper.UpdateArrange()
  reaper.Undo_EndBlock('ReaRanger: alt-drag split region', -1)
  S.dirty = true
  set_status(host and ('Split %s → %s-a / New Region / %s-b'):format(host.name, host.name, host.name)
                   or 'Added region (alt-drag)')
  Tel.log('alt_split', string.format('{"t1":%.3f,"t2":%.3f,"host":%s}',
    t1, t2, host and ('"' .. host.name .. '"') or 'null'))
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

-- v0.7.33: remove the gap AFTER region i — ripple-delete the empty span so later
-- content + region markers pull left by the gap length (inverse of add_gap_after).
local function remove_gap_after(i)
  if not i or i < 1 or i > #S.regions then return end
  local r = S.regions[i]
  local gap = gap_after(r)
  if not gap or gap <= 1e-6 then return end
  local gap_start = r.rend

  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  with_ripple_all(function()
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, gap_start, gap_start + gap, false)
    reaper.Main_OnCommand(40201, 0)   -- remove empty span: later items pull left
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)
  -- markers untouched by ripple — slide the ones at/after the gap left by `gap`
  for _, o in ipairs(S.regions) do
    if o.pos >= gap_start + gap - 1e-6 then
      reaper.SetProjectMarker4(0, o.id, true, o.pos - gap, o.rend - gap, o.name, o.color_native, 0)
      o.pos = o.pos - gap; o.rend = o.rend - gap
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange(); reaper.UpdateTimeline()
  reaper.Undo_EndBlock(('ReaRanger: remove %.3fs gap after row %d (content+markers)'):format(gap, i), -1)
  S.dirty = true
  set_status(('Removed %.2fs gap after row %d (content pulled left)'):format(gap, i))
  Tel.log('remove_gap', string.format('{"row":%d,"len":%.3f}', i, gap))
end

-- v0.7.39: close `amount` seconds of the gap after row i (partial inverse of
-- add_gap_after). Generalises remove_gap_after so the gap cell can be DRAG-resized
-- smaller without nuking the whole gap. Clamps amount to the existing gap.
local function close_gap_after(i, amount)
  if not i or i < 1 or i > #S.regions then return end
  local r = S.regions[i]
  local gap = gap_after(r)
  if not gap or gap <= 1e-6 then return end
  if amount > gap then amount = gap end
  if amount <= 1e-6 then return end
  local gap_start = r.rend
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  with_ripple_all(function()
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, gap_start, gap_start + amount, false)
    reaper.Main_OnCommand(40201, 0)   -- remove empty span: later items pull left
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)
  for _, o in ipairs(S.regions) do
    if o.pos >= gap_start + amount - 1e-6 then
      reaper.SetProjectMarker4(0, o.id, true, o.pos - amount, o.rend - amount, o.name, o.color_native, 0)
      o.pos = o.pos - amount; o.rend = o.rend - amount
    end
  end
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange(); reaper.UpdateTimeline()
  reaper.Undo_EndBlock(('ReaRanger: close %.3fs of gap after row %d'):format(amount, i), -1)
  S.dirty = true
  Tel.log('remove_gap', string.format('{"row":%d,"len":%.3f}', i, amount))
end

-- v0.7.39: set the gap after row i to an absolute `target` (drag/type on the gap
-- cell). Grows via add_gap_after, shrinks via close_gap_after. target<=0 ⇒ close all.
local function set_gap_after(i, target)
  local r = S.regions[i]; if not r then return end
  if target < 0 then target = 0 end
  local cur = gap_after(r) or 0
  local delta = target - cur
  if math.abs(delta) < 0.0005 then return end
  if delta > 0 then add_gap_after(i, delta) else close_gap_after(i, -delta) end
end

local function add_region_at_cursor()
  local pos = reaper.GetCursorPosition()
  local len = math.max(0.1, S.new_region_len or 4.0)   -- length from the toolbar field
  -- v0.7.32: +Region always INSERTS (the overlap/insert toggle is gone — overlap
  -- is now opt-in via a lane-drag or alt-drag). Open `len` of space at the cursor
  -- so existing content + later region markers shift right; the new region drops
  -- into the cleared span (no accidental lanes). Mirrors add_gap_after.
  reaper.Undo_BeginBlock()
  reaper.PreventUIRefresh(1)
  with_ripple_all(function()
    local ts_a, ts_b = reaper.GetSet_LoopTimeRange(false, false, 0, 0, false)
    reaper.GetSet_LoopTimeRange(true, false, pos, pos + len, false)
    reaper.Main_OnCommand(40200, 0)   -- insert empty space (ripple-all)
    reaper.GetSet_LoopTimeRange(true, false, ts_a, ts_b, false)
  end)
  -- ripple doesn't touch region markers — slide the ones at/after the cursor
  for _, r in ipairs(S.regions) do
    if r.pos >= pos - 1e-6 then
      reaper.SetProjectMarker4(0, r.id, true, r.pos + len, r.rend + len, r.name, r.color_native, 0)
      r.pos = r.pos + len; r.rend = r.rend + len
    end
  end
  local new_idx = reaper.AddProjectMarker2(0, true, pos, pos + len, 'New Region', -1, 0)
  reaper.PreventUIRefresh(-1)
  reaper.UpdateArrange(); reaper.UpdateTimeline()
  reaper.Undo_EndBlock('ReaRanger: add region', -1)
  -- v0.7.37: select the freshly-added region immediately (highlight in list + lane,
  -- + project time-sel) so it's the active region without a manual click. id == the
  -- marker index AddProjectMarker2 returns, which is what load_regions stores as r.id.
  S.sel_id = new_idx
  S.sel_set = { [new_idx] = true }   -- v0.7.38: sole selection
  reaper.GetSet_LoopTimeRange(true, false, pos, pos + len, false)
  S.dirty = true
  Tel.log('add_region', string.format('{"pos":%.3f,"len":%.3f}', pos, len))
end

-- v0.7.31 — Selection. Clicking a region (list row or lane block) selects it:
-- highlight in ReaRanger AND select it in the project by setting the time
-- selection to the region span (the natural "selected region" in REAPER — what
-- double-clicking a region in the ruler does). Does NOT move the edit cursor
-- (empty-space clicks do that). Reverse-synced in maybe_poll: when REAPER's time
-- selection matches a region, that row lights up in the list.
-- v0.7.38: multi-select. mods (ImGui key-mods bitmask, optional) decides:
--   none  → replace selection with just r (r becomes anchor)
--   Ctrl  → toggle r in the selection (r becomes anchor)
--   Shift → range from the current anchor to r in list order, ADDED to the set
-- The project time-selection follows the clicked region. Callers with no mods
-- (lane click, +Region auto-select) get plain single-select.
local function select_region(r, mods)
  if not r then return end
  mods = mods or 0
  local shift = (mods & ImGui.Mod_Shift) ~= 0
  local ctrl  = (mods & ImGui.Mod_Ctrl) ~= 0
  if shift and S.sel_id then
    local ai, ci
    for idx, rr in ipairs(S.regions) do
      if rr.id == S.sel_id then ai = idx end
      if rr.id == r.id then ci = idx end
    end
    if ai and ci then
      for idx = math.min(ai, ci), math.max(ai, ci) do S.sel_set[S.regions[idx].id] = true end
    else
      S.sel_set[r.id] = true
    end
    -- anchor unchanged so the range can be re-dragged
  elseif ctrl then
    if S.sel_set[r.id] then S.sel_set[r.id] = nil else S.sel_set[r.id] = true end
    S.sel_id = r.id
  else
    S.sel_set = { [r.id] = true }
    S.sel_id = r.id
  end
  reaper.GetSet_LoopTimeRange(true, false, r.pos, r.rend, false)
  reaper.UpdateTimeline()
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

  -- v0.7.27: carry ALL content (media items + track automation + normal markers
  -- + tempo/timesig) inside each region's OLD span by that region's delta, via
  -- the proven carry_content primitive. Spans are built from the pre-mutation
  -- snapshot (old_pos/old_end) so an item relocating into another region's NEW
  -- position can never be matched twice — carry_content is snapshot-then-apply.
  -- Replaces the old items-only per-item shuffler (the gap punch #2 closed).
  local spans = {}
  for rid, opos in pairs(old_pos) do
    spans[#spans+1] = {lo = opos, hi = old_end[rid], delta = target_pos[rid] - opos}
  end
  local cstats = carry_content(spans)
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
  set_status(string.format('Reordered %d regions (moved %d items)', #new_order_ids, cstats.items))
  Tel.log('reorder', string.format(
    '{"n":%d,"items":%d,"env":%d,"markers":%d,"tempo":%d}',
    #new_order_ids, cstats.items, cstats.env, cstats.markers, cstats.tempo))
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

-- Render the 3-option removal menu (shared by the lane + list context menus).
-- Defined here (not next to removal_targets) because it needs the module-local ctx.
local function removal_menu(clicked)
  local t = removal_targets(clicked)
  local suffix = (#t > 1) and (' (' .. #t .. ' regions)') or ''
  if ImGui.Selectable(ctx, 'Remove region' .. suffix) then apply_removal(t, 'marker') end
  if ImGui.Selectable(ctx, 'Remove region + content (leave gap)' .. suffix) then apply_removal(t, 'content') end
  if ImGui.Selectable(ctx, 'Remove region + content + gap' .. suffix) then apply_removal(t, 'content_gap') end
end

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
    if v and v == v and v > 0 then return v end   -- v==v guards NaN; >0 since 0 = parse error
    -- v0.7.37: fallback — REAPER's measures.beats parser returns 0 on inputs it
    -- doesn't like (e.g. a bare number, or our 3-part display string), which used
    -- to silently reject the edit and pin the length at the 4.0s default. Accept a
    -- bare number as a quarter-note (beat) count and convert via the project tempo.
    local n = tonumber((str:gsub('%s', '')))
    if n and n > 0 then
      local secs = reaper.TimeMap2_QNToTime(0, n)   -- n QN from project start = n-beats length
      if secs and secs == secs and secs > 0 then return secs end
    end
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
      -- PER-DIGIT (v0.7.39): drag changes ONLY the hovered place — minutes, seconds,
      -- or ms — and CLAMPS within that place (no carry into the neighbour). Decompose
      -- the anchor, bump the one component, recompose. (Ctrl-fine dropped — Poofox: it
      -- "just makes it slower"; restrict-to-place is the precision now.)
      local steps = math.floor(-dy / DRAG_PX_PER_DIGIT + 0.5)
      local base = nd.start_val < 0 and 0 or nd.start_val
      local m  = math.floor(base / 60)
      local s  = math.floor(base - m * 60)
      local ms = math.floor((base - m * 60 - s) * 1000 + 0.5)
      if nd.place == 60 then            -- minutes (unbounded up, floor 0)
        m = m + steps; if m < 0 then m = 0 end
      elseif nd.place == 1 then         -- seconds (0–59, no roll into minutes)
        s = s + steps; if s < 0 then s = 0 elseif s > 59 then s = 59 end
      else                              -- ms segment (place 0.01 → 10ms/step, 0–999)
        ms = ms + steps * 10; if ms < 0 then ms = 0 elseif ms > 999 then ms = 999 end
      end
      final = m * 60 + s + ms / 1000
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
  -- v0.7.32: honor S.lane_pref (a lane the user explicitly dragged a region to)
  -- FIRST, so the DRAGGED region keeps its chosen row instead of the auto-packer
  -- bumping the in-the-way one. Pref'd regions are placed first and claim their
  -- row; everything else greedy-packs into the remaining gaps (longer-first so the
  -- big section claims lane 0 = the "arrangement").
  local order = {}
  for _, r in ipairs(S.regions) do order[#order + 1] = r end
  table.sort(order, function(a, b)
    local pa, pb = S.lane_pref[a.id], S.lane_pref[b.id]
    if (pa ~= nil) ~= (pb ~= nil) then return pa ~= nil end   -- pref'd regions first
    if math.abs(a.pos - b.pos) > 1e-9 then return a.pos < b.pos end
    return a.len > b.len
  end)
  -- lane_spans[L] = list of {pos,rend} already placed in row L
  local lane_of, lane_spans, num = {}, {}, 0
  local function fits(L, r)
    for _, sp in ipairs(lane_spans[L] or {}) do
      if not (r.pos >= sp.rend - 1e-9 or r.rend <= sp.pos + 1e-9) then return false end
    end
    return true
  end
  for _, r in ipairs(order) do
    local L
    local pref = S.lane_pref[r.id]
    if pref ~= nil and fits(pref, r) then
      L = pref
    else
      L = 0
      while not fits(L, r) do L = L + 1 end
    end
    lane_of[r.id] = L
    lane_spans[L] = lane_spans[L] or {}
    table.insert(lane_spans[L], {pos = r.pos, rend = r.rend})
    if L + 1 > num then num = L + 1 end
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
    -- v0.7.31: selected region gets a bright thick border (matches the list row hl).
    -- v0.7.37: + a translucent warm fill over the block so the selection reads on the
    -- lane as obviously as the row tint does (a thin border was easy to miss).
    if S.sel_set[r.id] then   -- v0.7.38: whole multi-selection highlights, not just the anchor
      ImGui.DrawList_AddRectFilled(dl, rx1, yt, rx2, yb, SEL_FILL_COL)
      ImGui.DrawList_AddRect(dl, rx1 - 1, yt - 1, rx2 + 1, yb + 1, SEL_BORDER_COL, 0, 0, 2.0)
    end
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

  -- v0.7.33: gaps between consecutive regions (by position) — faintly highlighted
  -- on the main row so they read as clickable; right-click one to remove it.
  -- S.regions is kept sorted by position (load_regions), so neighbours are gaps.
  local gaps = {}
  for k = 1, #S.regions - 1 do
    local a, b = S.regions[k], S.regions[k + 1]
    if b.pos > a.rend + 1e-6 then
      gaps[#gaps + 1] = {start = a.rend, fin = b.pos, after_id = a.id, after_i = k, len = b.pos - a.rend}
    end
  end
  for _, g in ipairs(gaps) do
    local gx1, gx2 = t_to_x(g.start), t_to_x(g.fin)
    if gx2 - gx1 >= 2 then
      ImGui.DrawList_AddRectFilled(dl, gx1, lane_top(0), gx2, lane_bot(0), GAP_FILL_COL)
      ImGui.DrawList_AddRect(dl, gx1, lane_top(0), gx2, lane_bot(0), GAP_BORDER_COL, 0, 0, 1.0)
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

  -- Begin a potential drag on mouse-press
  if hovered and ImGui.IsMouseClicked(ctx, 0) and not S.lane_drag and not S.alt_drag and not S.rename then
    local mods  = ImGui.GetKeyMods(ctx)
    local shift = (mods & ImGui.Mod_Shift) ~= 0
    local alt   = (mods & ImGui.Mod_Alt) ~= 0
    local hr, _, hrx2 = region_at_xy(mx, my)
    if shift or alt then
      -- v0.7.35/37: SHIFT-drag = split-create, snapped to the project GRID (v0.7.37
      -- — raw drags spanned the whole-project lane into huge regions that never
      -- split). ALT-click = erase the region marker (content stays). On release.
      local t0 = span_start + ((mx - x1g) / (x2g - x1g)) * span
      if shift and S.split_snap then t0 = snap_to_grid_only(t0) end   -- v0.7.37/38: split snaps to grid when the magnet is on; erase stays raw
      S.alt_drag = {start_x=mx, start_t=t0, over_id=hr and hr.id or nil,
                    moved=false, do_split=shift, do_erase=alt}
    elseif hr then
      local mode = (math.abs(mx - hrx2) <= LANE_EDGE_PX) and 'resize' or 'move'
      -- Ctrl held at grab = DUPLICATE (move-mode only); captured at grab like REAPER
      local dup = (mode == 'move') and ((mods & ImGui.Mod_Ctrl) ~= 0)
      S.lane_drag = {id=hr.id, mode=mode, start_x=mx, start_y=my, dup=dup,
                     orig_pos=hr.pos, orig_len=hr.len, lane=lane_of[hr.id], moved=false}
    else
      -- v0.7.31: clicked EMPTY lane space → move the edit cursor here (clicking a
      -- region selects it instead — handled on release in the drag block below).
      local rel = (mx - x1g) / (x2g - x1g)
      if rel < 0 then rel = 0 end; if rel > 1 then rel = 1 end
      reaper.SetEditCurPos(span_start + rel * span, true, false)
      S.sel_id = nil; S.sel_set = {}   -- v0.7.38: empty-space click clears the whole selection
    end
  end

  -- v0.7.35: SHIFT-drag = split-create (no snap) · ALT-click = erase (see above).
  if S.alt_drag then
    local ad = S.alt_drag
    local cur_t = span_start + ((mx - x1g) / (x2g - x1g)) * span
    if ad.do_split and S.split_snap then cur_t = snap_to_grid_only(cur_t) end   -- v0.7.37/38: split snaps to grid when the magnet is on; erase stays raw
    if math.abs(mx - ad.start_x) > LANE_DRAG_PX then ad.moved = true end
    if ad.do_split and ad.moved then
      local gx1, gx2 = t_to_x(math.min(ad.start_t, cur_t)), t_to_x(math.max(ad.start_t, cur_t))
      ImGui.DrawList_AddRectFilled(dl, gx1, lane_top(0), gx2, lane_bot(0), INSERT_GHOST_COL)
      ImGui.DrawList_AddRect(dl, gx1, lane_top(0), gx2, lane_bot(0), INSERT_CARET_COL, 0, 0, 2.0)
      tip(('SHIFT: new region %s → %s (splits host into -a / -b)'):format(
        fmt_time_full(math.min(ad.start_t, cur_t)), fmt_time_full(math.max(ad.start_t, cur_t))))
    elseif ad.do_erase and ad.over_id and not ad.moved then
      tip('ALT-click: erase this region (marker only — content stays)')
    end
    if ImGui.IsMouseReleased(ctx, 0) then
      if ad.do_split and ad.moved then
        alt_create_split(ad.start_t, cur_t)
      elseif ad.do_erase and not ad.moved and ad.over_id then
        local er
        for _, rr in ipairs(S.regions) do if rr.id == ad.over_id then er = rr; break end end
        if er then delete_region(er) end
      end
      S.alt_drag = nil
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
      local dy = my - (ld.start_y or my)
      if math.abs(dx) > LANE_DRAG_PX or math.abs(dy) > LANE_DRAG_PX then ld.moved = true end
      local delta_t = (dx / (x2g - x1g)) * span
      -- v0.7.32: drag DIRECTION decides the action (the overlap/insert toggle is
      -- gone). Dragging into a DIFFERENT lane row = LANE-MOVE: the dragged region
      -- goes to that lane at the drop time (free overlay, content follows). Staying
      -- in the same lane row = RIPPLE-REORDER into the nearest slot (others reflow).
      local target_lane = math.floor((my - y1g) / LANE_ROW_H)
      if target_lane < 0 then target_lane = 0 end
      ld.lane_move = (ld.mode == 'move') and (target_lane ~= ld.lane)
      ld.target_lane = target_lane
      local yt, yb = lane_top(ld.lane_move and target_lane or ld.lane),
                     lane_bot(ld.lane_move and target_lane or ld.lane)

      if ld.moved then
        if ld.mode == 'move' and ld.lane_move then
          -- LANE-MOVE: free placement onto the target lane row, strong edge-snap.
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
          if ld.dup then
            tip(('DUPLICATE → lane %d @ %s (content follows)'):format(target_lane + 1, fmt_time_full(target)))
          else
            tip(('LANE MOVE → lane %d @ %s (content follows, may overlap)'):format(target_lane + 1, fmt_time_full(target)))
          end
        elseif ld.mode == 'move' then
          -- RIPPLE-REORDER: caret at the slot the drop lands in; commit_reorder
          -- on release shifts the media items so content follows + others reflow.
          local drop_t = span_start + ((mx - x1g) / (x2g - x1g)) * span
          local _, idx, others = order_for_insert(ld.id, drop_t)
          local caret_x
          if idx <= #others then caret_x = t_to_x(others[idx].pos)
          elseif #others > 0 then caret_x = t_to_x(others[#others].rend)
          else caret_x = x1g end
          ld.preview = drop_t
          ImGui.DrawList_AddLine(dl, caret_x, y1g, caret_x, y2g, INSERT_CARET_COL, 3.0)
          local w_px = (ld.orig_len / span) * (x2g - x1g)
          ImGui.DrawList_AddRectFilled(dl, caret_x, lane_top(0), caret_x + w_px, lane_bot(0), INSERT_GHOST_COL)
          local before = (idx <= #others) and others[idx].name or '(end)'
          if ld.dup then
            tip(('DUPLICATE → REORDER before %s  ·  copy added, later content reflows'):format(before))
          else
            tip(('REORDER before %s  ·  others reflow, audio follows · drag to a lane row to stack'):format(before))
          end
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
            if ld.lane_move then
              -- LANE-MOVE: place the DRAGGED region on the target lane (free,
              -- content follows). lane_pref makes the packer keep IT in that lane
              -- (vs bumping the in-the-way region, which the old auto-pack did).
              if ld.dup then duplicate_region(r, ld.preview, 'overlay')
              else apply_move_free(r, ld.preview, true) end
              if ld.target_lane and ld.target_lane > 0 then
                S.lane_pref[ld.id] = ld.target_lane
              else
                S.lane_pref[ld.id] = nil
              end
            else
              -- RIPPLE-REORDER (same-lane horizontal drag).
              S.lane_pref[ld.id] = nil   -- reorder lays it back into lane 0
              if ld.dup then
                duplicate_region(r, ld.preview, 'insert')
              else
                local order = order_for_insert(ld.id, ld.preview)
                commit_reorder(order)
              end
            end
          else apply_length(r, ld.preview) end
        elseif not ld.moved then
          -- v0.7.31: plain click on a region = SELECT it (project time-sel +
          -- list highlight), NOT move the edit cursor. (Empty-space clicks move
          -- the cursor — handled at mouse-press above.)
          select_region(r)
        end
        S.lane_drag = nil
      end
    end
  end

  -- Hover (no active drag): tooltip + resize-cursor hint
  if hovered and not S.lane_drag and not S.alt_drag then
    local hover_r, _, hrx2 = region_at_xy(mx, my)
    if hover_r then
      if math.abs(mx - hrx2) <= LANE_EDGE_PX and ImGui.SetMouseCursor and ImGui.MouseCursor_ResizeEW then
        ImGui.SetMouseCursor(ctx, ImGui.MouseCursor_ResizeEW)
      end
      tip(('%s\n%s  →  %s   (len %s)\n[drag sideways=reorder · drag to a lane=stack · right-edge=resize\n dbl-click=rename · alt-click=erase · shift-drag=split · right-click=menu]'):format(
        hover_r.name, fmt_time_full(hover_r.pos), fmt_time_full(hover_r.rend), fmt_time_full(hover_r.len, 'len')))
    else
      local rel = (mx - x1g) / (x2g - x1g)
      if rel < 0 then rel = 0 end; if rel > 1 then rel = 1 end
      tip(fmt_time_full(span_start + rel * span))
    end
  end

  -- v0.7.32/33: right-click a lane region → remove menu; right-click a GAP → remove-gap menu.
  if hovered and ImGui.IsMouseClicked(ctx, 1) and not S.lane_drag and not S.alt_drag then
    local cr = region_at_xy(mx, my)
    if cr then
      S.lane_ctx_id = cr.id; ImGui.OpenPopup(ctx, '##lane_ctx')
    elseif my >= lane_top(0) and my <= lane_bot(0) then
      for _, g in ipairs(gaps) do
        if mx >= t_to_x(g.start) and mx <= t_to_x(g.fin) then
          S.gap_ctx = {after_id = g.after_id, len = g.len}
          ImGui.OpenPopup(ctx, '##gap_ctx'); break
        end
      end
    end
  end
  if ImGui.BeginPopup(ctx, '##gap_ctx') then
    if S.gap_ctx then
      ImGui.Text(ctx, ('Gap: %s'):format(fmt_time_full(S.gap_ctx.len, 'len'))); ImGui.Separator(ctx)
      if ImGui.Selectable(ctx, ('Remove gap (%s) — pull later content left'):format(fmt_time_full(S.gap_ctx.len, 'len'))) then
        for idx, rr in ipairs(S.regions) do
          if rr.id == S.gap_ctx.after_id then remove_gap_after(idx); break end
        end
      end
    else
      ImGui.Text(ctx, '(gap gone)')
    end
    ImGui.EndPopup(ctx)
  end
  if ImGui.BeginPopup(ctx, '##lane_ctx') then
    local cr
    for _, rr in ipairs(S.regions) do if rr.id == S.lane_ctx_id then cr = rr; break end end
    if cr then
      local n = (S.sel_set[cr.id] and sel_count() > 1) and sel_count() or 1
      ImGui.Text(ctx, n > 1 and (n .. ' regions selected') or cr.name); ImGui.Separator(ctx)
      removal_menu(cr)   -- v0.7.38: 3 options, applies to the whole selection if cr is in it
    else
      ImGui.Text(ctx, '(region gone)')
    end
    ImGui.EndPopup(ctx)
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

    -- v0.7.31/38: tint every selected row (matches the lane highlight).
    if S.sel_set[r.id] then
      ImGui.TableSetBgColor(ctx, ImGui.TableBgTarget_RowBg0, SEL_ROW_COL)
    end

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
    if ImGui.Selectable(ctx, tostring(i) .. '##rowdrag', S.sel_set[r.id] and true or false, 0, 0, 0) then
      select_region(r, ImGui.GetKeyMods(ctx))   -- v0.7.31/38: click row number → select (Shift=range, Ctrl=toggle)
    end
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
      if ImGui.Selectable(ctx, r.name .. '##nm_' .. r.id, S.sel_set[r.id] and true or false, ImGui.SelectableFlags_AllowDoubleClick) then
        select_region(r, ImGui.GetKeyMods(ctx))   -- v0.7.31/38: click name → select (Shift=range, Ctrl=toggle; dbl-click still renames)
      end
      ImGui.PopStyleColor(ctx)
      if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
        S.rename = {id=r.id, buf=r.name, focused=false, where='table'}
      end
      -- v0.7.32: right-click the name → remove context menu (mirrors the lane).
      if ImGui.BeginPopupContextItem(ctx, 'rowctx_' .. r.id) then
        local n = (S.sel_set[r.id] and sel_count() > 1) and sel_count() or 1
        ImGui.Text(ctx, n > 1 and (n .. ' regions selected') or r.name); ImGui.Separator(ctx)
        removal_menu(r)   -- v0.7.38: 3 options, applies to the whole selection if r is in it
        ImGui.EndPopup(ctx)
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
      ImGui.SetNextItemWidth(ctx, 60)
      if not S.gapedit.focused then ImGui.SetKeyboardFocusHere(ctx); S.gapedit.focused = true end
      -- v0.7.28: gap length honours Time/Beats — CharsDecimal dropped (it blocked
      -- the ':' in MM:SS.mmm and beats' multi-dot form); parse via parse_time_full.
      local gv, gnv = ImGui.InputText(ctx, '##gap_' .. r.id, S.gapedit.buf,
        ImGui.InputTextFlags_AutoSelectAll)
      if gv then S.gapedit.buf = gnv end
      if ImGui.IsKeyPressed(ctx, ImGui.Key_Enter) or ImGui.IsKeyPressed(ctx, ImGui.Key_KeypadEnter) then
        local n = parse_time_full(S.gapedit.buf, 'len')
        if n and n > 0 then S.gap_len = n; add_gap_after(i, n) end
        S.gapedit = nil
      elseif ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
        S.gapedit = nil
      end
      if ImGui.IsItemHovered(ctx) then
        tip('Type gap length (honours Time/Beats) · Enter = insert · Esc = cancel')
      end
    else
      local g = gap_after(r)
      if g and g > 0.001 then
        -- v0.7.39: an existing gap is now a DRAGGABLE per-digit cell (same feel as
        -- start/length). Drag = resize via ripple on release; double-click = type
        -- exact; drag/type to 0 closes it. Honours Time/Beats via kind='len'.
        drag_time_cell(
          'reg_' .. r.id .. '_gap',
          g, g,
          nil,                                            -- ripple is heavy: no per-frame
          function(parsed) set_gap_after(i, parsed) end,  -- type-to-edit commit
          function(final)  set_gap_after(i, final)  end,  -- drag release → one ripple
          'len'
        )
        if ImGui.IsItemHovered(ctx) then
          tip(('Gap: %s · drag a digit to resize · double-click to type · 0 closes it')
              :format(fmt_time_full(g, 'len')))
        end
      else
        -- no gap yet → "+Gap" button: click inserts last-used length, dbl-click types.
        local clicked = ImGui.SmallButton(ctx, '+Gap##gap_btn_' .. r.id)
        if ImGui.IsItemHovered(ctx) and ImGui.IsMouseDoubleClicked(ctx, 0) then
          S.gapedit = {id=r.id, buf=fmt_time_full(S.gap_len, 'len'), focused=false}
        elseif clicked then
          add_gap_after(i, S.gap_len)
        end
        if ImGui.IsItemHovered(ctx) then
          tip(('Insert %s gap (click) · double-click to type · drag to resize once it exists')
              :format(fmt_time_full(S.gap_len, 'len')))
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
  'Lane gestures (no mode toggle — the gesture decides):\n' ..
  '  Drag a region SIDEWAYS (same row) = ripple-reorder into the slot; others reflow, content follows (a caret shows the slot)\n' ..
  '  Drag a region INTO ANOTHER LANE ROW = stack it there (overlap); the dragged region takes that lane, content follows\n' ..
  '  Right-edge drag = resize · Ctrl+drag = duplicate\n' ..
  '  SHIFT-drag on the lane = new region over that span (no snap); if it lands inside a region, that region splits into name-a / name-b\n' ..
  '  ALT-click a region = erase it (marker only — nothing else in the timeline changes)\n' ..
  '  Right-click a region = remove menu: Remove region · + content (leave gap) · + content + gap (ripple-close)\n' ..
  '  Click a region = select · Ctrl+click = add/toggle · Shift+click = range (list). Right-click any selected → removes all of them.\n' ..
  '  CROSSFADE toggle (toolbar center) — REAPER auto-crossfade on/off for overlapping items\n' ..
  '  SHOW-IN-LANES toggle — REAPER "show overlapping media items in lanes" on/off · MAGNET — SHIFT-drag split snaps to grid (on) / free (off)\n' ..
  'Reorder in the list: drag a region by its NAME (or the number) onto another row — content moves with it\n' ..
  'Time cells (Time mode): drag a SPECIFIC number (minutes / seconds / ms) up/down to change just that place · hold Ctrl for fine steps · double-click = type the value. (Beats mode = whole-cell grid-snap drag.)\n' ..
  'Rename: double-click a region name (list or lane)\n' ..
  'Color: right-click the color cell for grey presets + a custom RGB/HSV picker\n' ..
  'Gap: set "Gap Length" (right), then +Gap on a row to insert that much silence (ripples later regions). Once a gap exists the button shows its length. Double-click to type an exact gap.\n' ..
  'Remove a gap: gaps between regions are faintly highlighted on the lane — right-click one → "Remove gap" pulls later content left by that amount.\n' ..
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
  ImGui.DrawList_AddText(dl, x1 + pad, y1 + 4, TITLE_TEXT_COL, 'ReaRanger  v0.7.38')

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
  ImGui.PushStyleColor(ctx, ImGui.Col_Text, TITLE_TEXT_COL)  -- info line shares title text grey (readable on dark band)
  ImGui.Text(ctx, info)
  ImGui.PopStyleColor(ctx)
  ImGui.PopTextWrapPos(ctx)

  -- Right-click the title band → dock context menu (v0.7.29). Hit-tested manually
  -- (the band is draw-list text, not an item, to preserve drag-anywhere) over the
  -- band minus the ?/X gutter. Drag a floating window onto a REAPER docker to dock
  -- natively; this menu is the explicit toggle Poofox asked for.
  do
    local mx, my = ImGui.GetMousePos(ctx)
    local in_band = mx >= x1 and mx <= (x1 + avail_w - X_COL_W)
                and my >= y1 and my <= (y1 + bar_h)
    if in_band and ImGui.IsMouseClicked(ctx, 1) then
      ImGui.OpenPopup(ctx, '##rr_titlemenu')
    end
    if ImGui.BeginPopup(ctx, '##rr_titlemenu') then
      if S.is_docked then
        if ImGui.MenuItem(ctx, 'Undock') then
          S.dock_target = 0; S.dock_apply = true
        end
        ImGui.TextDisabled(ctx, ('docker id %d'):format(S.last_dock_id or 0))
      else
        if ImGui.MenuItem(ctx, 'Dock') then
          S.dock_target = S.last_dock_id or -1; S.dock_apply = true
        end
      end
      ImGui.Separator(ctx)
      if ImGui.MenuItem(ctx, 'Close') then S.want_close = true end
      ImGui.EndPopup(ctx)
    end
  end

  -- advance the layout cursor below the band
  ImGui.SetCursorScreenPos(ctx, x1, y1 + bar_h + 2)
  ImGui.Dummy(ctx, avail_w, 0)
end

-- ── Icon toolbar (v0.7.30) ──────────────────────────────────────────────────
-- Light, low-contrast styling with a few grey tones: OFF = muted grey glyph on a
-- light backing; ON = high-contrast dark glyph on a brighter backing (per Poofox
-- "more contrast when on than off"). Every glyph is hand-drawn via DrawList
-- (sigs reasig-verified, version-stable vs the 0.9 pin) inside its button box.
local ICON_BG_OFF    = 0xBCBCBCFF   -- light grey backing (off)
local ICON_BG_ON     = 0xECECECFF   -- brighter backing (on)
local ICON_GLYPH_OFF = 0x868686FF   -- muted grey glyph (low contrast)
local ICON_GLYPH_ON  = 0x1C1C1CFF   -- near-black glyph (high contrast)
local ICON_BD_OFF    = 0x9A9A9AFF
local ICON_BD_ON     = 0x404040FF
local ICON_SHADE     = 0x00000026   -- translucent overlap shading


-- Generic icon button: light backing + a glyph drawn by glyph_fn, hit-tested
-- with an InvisibleButton. glyph_fn(dl, x1, y1, w, h, col, active) paints inside
-- the [x1,y1 .. x1+w,y1+h] box. Returns true on click.
-- glyph_col (optional): force the glyph colour regardless of active state. Used
-- by ACTION buttons (e.g. +Region) that have only one state and shouldn't render
-- faded like an OFF toggle (Poofox, v0.7.31).
local function icon_button(id, w, h, active, tip_txt, glyph_fn, glyph_col)
  local sx, sy  = ImGui.GetCursorScreenPos(ctx)
  local clicked = ImGui.InvisibleButton(ctx, id, w, h)
  local hovered = ImGui.IsItemHovered(ctx)
  if hovered then tip(tip_txt) end
  local dl = ImGui.GetWindowDrawList(ctx)
  ImGui.DrawList_AddRectFilled(dl, sx, sy, sx + w, sy + h, active and ICON_BG_ON or ICON_BG_OFF, 3.0)
  ImGui.DrawList_AddRect(dl, sx, sy, sx + w, sy + h, active and ICON_BD_ON or ICON_BD_OFF, 3.0, 0, active and 2.0 or 1.0)
  glyph_fn(dl, sx, sy, w, h, glyph_col or (active and ICON_GLYPH_ON or ICON_GLYPH_OFF), active)
  return clicked
end

-- "+" and a region symbol. v0.7.31: drawn as a closed region BLOCK (top + bottom
-- edges + end caps) instead of a single bar with end caps — the old form read as
-- an "H". The top edge is the region label line.
local function glyph_region(dl, x, y, w, h, col)
  local cy = y + h * 0.5
  -- plus, left third
  local px, pr = x + w * 0.26, h * 0.17
  ImGui.DrawList_AddLine(dl, px - pr, cy, px + pr, cy, col, 1.9)
  ImGui.DrawList_AddLine(dl, px, cy - pr, px, cy + pr, col, 1.9)
  -- region block, right portion: top + bottom edges + end caps = a region
  local rx1, rx2 = x + w * 0.50, x + w * 0.84
  local cap = h * 0.20
  ImGui.DrawList_AddLine(dl, rx1, cy - cap, rx2, cy - cap, col, 1.9)  -- top (label edge)
  ImGui.DrawList_AddLine(dl, rx1, cy + cap, rx2, cy + cap, col, 1.9)  -- bottom
  ImGui.DrawList_AddLine(dl, rx1, cy - cap, rx1, cy + cap, col, 1.9)  -- left cap
  ImGui.DrawList_AddLine(dl, rx2, cy - cap, rx2, cy + cap, col, 1.9)  -- right cap
end

-- clock face (Time mode): circle + two hands
local function glyph_clock(dl, x, y, w, h, col)
  local cx, cy = x + w * 0.5, y + h * 0.5
  local r = math.min(w, h) * 0.30
  ImGui.DrawList_AddCircle(dl, cx, cy, r, col, 0, 1.6)
  ImGui.DrawList_AddLine(dl, cx, cy, cx, cy - r * 0.72, col, 1.6)        -- minute hand (up)
  ImGui.DrawList_AddLine(dl, cx, cy, cx + r * 0.55, cy + r * 0.18, col, 1.6) -- hour hand
end

-- Beats mode: two beamed eighth notes (v0.7.31 — the snare drum read as a "TV").
local function glyph_notes(dl, x, y, w, h, col)
  local r = math.min(w, h) * 0.12
  local h1x, h2x = x + w * 0.34, x + w * 0.64   -- note-head centres
  local hy = y + h * 0.66
  ImGui.DrawList_AddCircleFilled(dl, h1x, hy, r, col, 0)
  ImGui.DrawList_AddCircleFilled(dl, h2x, hy, r, col, 0)
  -- stems rise from the right edge of each head
  local sx1, sx2 = h1x + r * 0.85, h2x + r * 0.85
  local stem_top = y + h * 0.30
  ImGui.DrawList_AddLine(dl, sx1, hy - r * 0.4, sx1, stem_top, col, 1.6)
  ImGui.DrawList_AddLine(dl, sx2, hy - r * 0.4, sx2, stem_top, col, 1.6)
  -- beam joining the two stems
  ImGui.DrawList_AddLine(dl, sx1, stem_top, sx2, stem_top, col, 2.6)
end

-- crossfade: two crossing fade curves (bezier X) with the overlap lens shaded
local function glyph_crossfade(dl, x, y, w, h, col)
  local x1, x2   = x + w * 0.20, x + w * 0.80
  local top, bot = y + h * 0.26, y + h * 0.74
  local midy     = (top + bot) / 2
  -- shaded lens under the crossing = the overlapping region
  ImGui.DrawList_AddTriangleFilled(dl, x1, top, x2, midy, x1, bot, ICON_SHADE)
  ImGui.DrawList_AddTriangleFilled(dl, x2, top, x1, midy, x2, bot, ICON_SHADE)
  -- fade-out curve (high-left → low-right) + fade-in curve (low-left → high-right)
  ImGui.DrawList_AddBezierCubic(dl, x1, top, x + w * 0.45, top, x + w * 0.55, bot, x2, bot, col, 1.6, 0)
  ImGui.DrawList_AddBezierCubic(dl, x1, bot, x + w * 0.45, bot, x + w * 0.55, top, x2, top, col, 1.6, 0)
end

-- Auto-crossfade = a standalone toggle bound to REAPER's own option (40912
-- "Options: Auto-crossfade media items when editing"). User-driven: the icon
-- reflects the REAPER state and clicking flips it. Self-guards if unavailable.
local AUTOXFADE_CMD = 40912
local function autoxfade_on() return reaper.GetToggleCommandState(AUTOXFADE_CMD) == 1 end
local function toggle_autoxfade()
  if reaper.GetToggleCommandState(AUTOXFADE_CMD) == -1 then
    set_status('Crossfade: REAPER auto-crossfade option unavailable on this build')
    return
  end
  reaper.Main_OnCommand(AUTOXFADE_CMD, 0)
  set_status('Crossfade: ' .. (autoxfade_on() and 'ON' or 'OFF') .. ' (REAPER auto-crossfade)')
end

-- Show overlapping items in lanes: two stacked lanes with staggered item blocks
-- (two items overlapping in time, separated into rows). v0.7.36.
local function glyph_lanes(dl, x, y, w, h, col)
  local x1, x2   = x + w * 0.16, x + w * 0.84
  local top, bot = y + h * 0.22, y + h * 0.78
  local midy     = (top + bot) / 2
  ImGui.DrawList_AddLine(dl, x1, midy, x2, midy, col, 1.0)   -- lane divider
  -- top-lane item (left) + bottom-lane item (right), overlapping in x
  ImGui.DrawList_AddRectFilled(dl, x1, top, x + w * 0.58, midy - 1, ICON_SHADE)
  ImGui.DrawList_AddRect(dl,       x1, top, x + w * 0.58, midy - 1, col)
  ImGui.DrawList_AddRectFilled(dl, x + w * 0.42, midy + 1, x2, bot, ICON_SHADE)
  ImGui.DrawList_AddRect(dl,       x + w * 0.42, midy + 1, x2, bot, col)
end

-- Magnet (split-snap toggle, v0.7.38): horseshoe — rounded top, two legs, pole tips.
local function glyph_magnet(dl, x, y, w, h, col)
  local lx, rx = x + w * 0.30, x + w * 0.70
  local topy   = y + h * 0.22
  local arcy   = y + h * 0.44
  local legb   = y + h * 0.68
  ImGui.DrawList_AddBezierCubic(dl, lx, arcy, lx, topy, rx, topy, rx, arcy, col, 2.0, 0)   -- rounded top
  ImGui.DrawList_AddLine(dl, lx, arcy, lx, legb, col, 2.0)                                  -- left leg
  ImGui.DrawList_AddLine(dl, rx, arcy, rx, legb, col, 2.0)                                  -- right leg
  ImGui.DrawList_AddRectFilled(dl, lx - w * 0.08, legb, lx + w * 0.08, legb + h * 0.12, col) -- left pole
  ImGui.DrawList_AddRectFilled(dl, rx - w * 0.08, legb, rx + w * 0.08, legb + h * 0.12, col) -- right pole
end

-- "Show overlapping media items in lanes (when room)" — REAPER option 40507.
-- Standalone toggle bound to REAPER's own state (like the crossfade one): the
-- icon reflects the option and clicking flips it. Self-guards if unavailable.
local SHOWLANES_CMD = 40507
local function showlanes_on() return reaper.GetToggleCommandState(SHOWLANES_CMD) == 1 end
local function toggle_showlanes()
  if reaper.GetToggleCommandState(SHOWLANES_CMD) == -1 then
    set_status('Show in lanes: REAPER option unavailable on this build')
    return
  end
  reaper.Main_OnCommand(SHOWLANES_CMD, 0)
  set_status('Show overlapping items in lanes: ' .. (showlanes_on() and 'ON' or 'OFF'))
end

local function draw_toolbar()
  -- Layout: LEFT = +Region/len · CENTER = 3-way mode squares · RIGHT =
  -- Time/Beats + Gap len.
  local start_x = ImGui.GetCursorPosX(ctx)
  local total_w = start_x + select(1, ImGui.GetContentRegionAvail(ctx))   -- content right edge X

  -- LEFT: + Region icon with its own length field
  local sq = math.floor(ImGui.GetFrameHeight(ctx) + 0.5)
  -- +Region is an ACTION (one state) → force full-contrast glyph so it isn't faded.
  if icon_button('##addregion', math.floor(sq * 1.6), sq, false,
      'Add a region at the edit cursor, this long (honours Time/Beats + overlap mode)',
      glyph_region, ICON_GLYPH_ON) then
    add_region_at_cursor()
  end
  ImGui.SameLine(ctx); ImGui.TextDisabled(ctx, 'Length')
  ImGui.SameLine(ctx); ImGui.SetNextItemWidth(ctx, 64)
  -- v0.7.28: new-region length entry honours the Time/Beats toggle (was a
  -- seconds-only InputDouble). Buffer resyncs from the canonical seconds value
  -- whenever the field is NOT being edited, so a mode flip re-formats it
  -- (measures.beats <-> MM:SS.mmm) automatically; internal value stays seconds.
  local rv_l, nv_l = ImGui.InputText(ctx, '##newreglen',
    S.nrl_buf or fmt_time_full(S.new_region_len, 'len'))
  if rv_l then S.nrl_buf = nv_l end
  if not ImGui.IsItemActive(ctx) then S.nrl_buf = fmt_time_full(S.new_region_len, 'len') end
  if ImGui.IsItemDeactivatedAfterEdit(ctx) then
    local parsed = parse_time_full(S.nrl_buf, 'len')
    if parsed and parsed > 0 then S.new_region_len = math.max(0.1, parsed) end
    S.nrl_buf = fmt_time_full(S.new_region_len, 'len')
  end
  if ImGui.IsItemHovered(ctx) then tip('New region length — honours the Time/Beats toggle') end

  -- CENTER: standalone toggles bound to REAPER options — CROSSFADE (auto-crossfade)
  -- + SHOW-IN-LANES (40507, show overlapping items in lanes). v0.7.32 removed the
  -- old overlap/not-overlap toggle (overlap is now decided by gesture: drag a region
  -- into a lane row to stack; horizontal drag = ripple-reorder).
  local CENTER_W = sq * 3 + 8
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, math.max(ImGui.GetCursorPosX(ctx), (total_w - CENTER_W) / 2))
  local row_y = ImGui.GetCursorPosY(ctx)
  if icon_button('##crossfade', sq, sq, autoxfade_on(),
      'CROSSFADE — toggle REAPER auto-crossfade for overlapping items (on/off).', glyph_crossfade) then
    toggle_autoxfade()
  end
  ImGui.SameLine(ctx, 0, 4); ImGui.SetCursorPosY(ctx, row_y)
  if icon_button('##showlanes', sq, sq, showlanes_on(),
      'SHOW IN LANES — REAPER option "Show overlapping media items in lanes (when room)" (on/off).', glyph_lanes) then
    toggle_showlanes()
  end
  ImGui.SameLine(ctx, 0, 4); ImGui.SetCursorPosY(ctx, row_y)
  -- v0.7.38: split-snap magnet. ON = SHIFT-drag split snaps to the grid; OFF =
  -- drop the new region anywhere (free split, no snap).
  if icon_button('##snapmag', sq, sq, S.split_snap,
      S.split_snap and 'SNAP: SHIFT-drag split snaps to the grid (click → free / drop anywhere).'
                    or 'FREE: SHIFT-drag split drops anywhere (click → snap to grid).', glyph_magnet) then
    S.split_snap = not S.split_snap
    set_status('Split snap: ' .. (S.split_snap and 'ON (grid)' or 'OFF (free)'))
  end
  ImGui.SameLine(ctx); ImGui.SetCursorPosY(ctx, row_y)   -- restore row baseline for the right group

  -- RIGHT: Time/Beats icon toggle (clock = time · snare = beats) + Gap len.
  local TIME_W = math.floor(sq * 1.3)
  local GAP_LABEL_W, GAP_FIELD_W = 52, 60
  local RIGHT_W = TIME_W + 12 + GAP_LABEL_W + GAP_FIELD_W
  ImGui.SameLine(ctx)
  ImGui.SetCursorPosX(ctx, math.max(ImGui.GetCursorPosX(ctx), total_w - RIGHT_W))
  local in_beats = (S.time_mode == 'beats')
  if icon_button('##timebeats', TIME_W, sq, true,
      'Start/Length display: ' ..
      (in_beats and 'measures.beats (click → MM:SS.mmm)' or 'MM:SS.mmm (click → measures.beats)'),
      in_beats and glyph_notes or glyph_clock) then
    S.time_mode = in_beats and 'time' or 'beats'
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
  -- Docking (v0.7.29): action a pending right-click dock toggle, then let REAPER
  -- own the size when docked (don't fight the docker with SetNextWindowSize).
  if S.dock_apply then
    ImGui.SetNextWindowDockID(ctx, S.dock_target, ImGui.Cond_Always)
    S.dock_apply = false
  end
  if not S.is_docked then
    ImGui.SetNextWindowSize(ctx, 760, 460, ImGui.Cond_FirstUseEver)
  end
  -- NoMove (v0.7.18c): disable ImGui's NATIVE drag-to-move. Plain-Text items (the
  -- per-digit time numbers) never become "active", so native move would grab the
  -- drag and slide the WINDOW instead of changing the number. Window moves now go
  -- SOLELY through the manual win_drag handler below, which already excludes
  -- num_drag / rename / edit / lane_drag — so dragging a number no longer moves the
  -- window, yet drag-anywhere (via SetWindowPos, unaffected by NoMove) still works.
  -- Floating only: a docked window is moved by REAPER, so NoMove + win_drag are off.
  local win_flags = ImGui.WindowFlags_NoTitleBar | ImGui.WindowFlags_NoCollapse
  if not S.is_docked then win_flags = win_flags | ImGui.WindowFlags_NoMove end
  local visible, open = ImGui.Begin(ctx, SCRIPT_TITLE, true, win_flags)
  if visible then
    S.is_docked = ImGui.IsWindowDocked(ctx)
    if S.is_docked then S.last_dock_id = ImGui.GetWindowDockID(ctx) end
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
    -- yank the window while you reach to drag a region (v0.7.18d). Floating only:
    -- a docked window is positioned by REAPER, so we never SetWindowPos it.
    if not S.is_docked then
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
    else
      S.win_drag = nil
    end

    -- Esc closes window when nothing else is being edited (otherwise Esc cancels edit)
    if not S.rename and not S.edit and not S.num_drag and ImGui.IsKeyPressed(ctx, ImGui.Key_Escape) then
      S.want_close = true
    end

    -- Keyboard passthrough (v0.7.29 / hardened v0.7.31): when not typing in a
    -- field, REAPER's shortcuts should work while ReaRanger is focused. The
    -- WantCaptureKeyboard release alone did NOT reliably forward Ctrl+Z (Poofox:
    -- "ctrl+z doesnt pass through"), so undo/redo are now dispatched EXPLICITLY via
    -- Main_OnCommand. On the frame we handle them we KEEP capture (don't release)
    -- so REAPER can't also process the same keypress → no double-undo. Other keys
    -- (space = play, etc.) still fall through via the release.
    if not ImGui.IsAnyItemActive(ctx) then
      local mods   = ImGui.GetKeyMods(ctx)
      local ctrl   = (mods & ImGui.Mod_Ctrl) ~= 0
      local shift  = (mods & ImGui.Mod_Shift) ~= 0
      local handled = false
      if ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_Z, false) then
        reaper.Main_OnCommand(shift and 40030 or 40029, 0)   -- redo : undo
        handled = true
      elseif ctrl and ImGui.IsKeyPressed(ctx, ImGui.Key_Y, false) then
        reaper.Main_OnCommand(40030, 0)                       -- redo
        handled = true
      end
      if not handled then ImGui.SetNextFrameWantCaptureKeyboard(ctx, false) end
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
