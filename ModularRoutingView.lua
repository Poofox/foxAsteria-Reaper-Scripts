--[[
================================================================================
HACKEY MACHINES - FOX & PLANTY FORK
Patch Instructions v0.90-fp1
================================================================================

Apply these changes to your existing Hackey_Machines v0.89 file.
Changes are organized by section for easy application.

================================================================================
CHANGE 1: Update script header (lines 1-30)
================================================================================
Replace the @description and @version lines:
--]]

--[[
@description Hackey-Machines (Fox & Planty Fork): An interface plugin for REAPER 5.x and up designed to mimick the machine editor in Jeskola Buzz.
@author: Joep Vanlier (original), Fox & Planty (fork)
@version 0.90-fp1
--]]

-- Add to changelog (after v0.89 entry):
--[[
 * v0.90-fp1 (2026-01-02) [Fox & Planty Fork]
   + Added bezier curve wire rendering
   + Removed dead code (oldInTriangle)
   + Added bezier control point configuration
   + Added 'B' key to toggle bezier wires
--]]

-- Update scriptName:
scriptName = "Hackey Machines v0.90-fp1 (Fox & Planty Fork)"

--[[
================================================================================
CHANGE 2: Add bezier config options (after onlyShowTopEffect config, ~line 95)
================================================================================
--]]

-- Fox & Planty Fork: Bezier curve settings
machineView.config.useBezierWires   = 1
machineView.cfgInfo.useBezierWires  = 'Use bezier curves for wire rendering (0 = straight lines, 1 = bezier curves).'
machineView.config.bezierTension    = 0.5
machineView.cfgInfo.bezierTension   = 'Bezier curve tension (0 = straight, 1 = very curved).'
machineView.config.bezierSegments   = 20
machineView.cfgInfo.bezierSegments  = 'Number of segments for bezier curve rendering (higher = smoother).'

--[[
================================================================================
CHANGE 3: Add toggle key in initializeKeys function (~line 170, after toggleKeymap)
================================================================================
--]]

-- Add this line in the keys initialization:
keys.toggleBezier       = {        2,    2,    2,    2,     0,     0,      0,      98 }           -- toggle bezier (b)

-- Add to help table:
{"B", "Toggle bezier wire curves"},

--[[
================================================================================
CHANGE 4: Add bezier point calculation function (before the box function, ~line 480)
================================================================================
--]]

-- Fox & Planty Fork: Bezier curve calculation
-- Attempt to compute a cubic bezier point at parameter t
local function bezierPoint(t, p0, p1, p2, p3)
  local u = 1 - t
  local tt = t * t
  local uu = u * u
  local uuu = uu * u
  local ttt = tt * t
  
  local x = uuu * p0[1] + 3 * uu * t * p1[1] + 3 * u * tt * p2[1] + ttt * p3[1]
  local y = uuu * p0[2] + 3 * uu * t * p1[2] + 3 * u * tt * p2[2] + ttt * p3[2]
  
  return x, y
end

--[[
================================================================================
CHANGE 5: Add bezier functions to wgfx table (~line 750, inside wgfx = {...})
================================================================================
Add these functions inside the wgfx table after the existing rect function:
--]]

  -- Fox & Planty Fork: Bezier curve drawing
  bezier = function(x1, y1, x2, y2, tension)
    local cfg = machineView.config
    tension = tension or cfg.bezierTension
    local segments = cfg.bezierSegments
    
    -- Transform to screen space
    local sx1, sy1 = xtrafo(x1), ytrafo(y1)
    local sx2, sy2 = xtrafo(x2), ytrafo(y2)
    
    -- Calculate control points for smooth curve
    local dx = sx2 - sx1
    local dy = sy2 - sy1
    local dist = math.sqrt(dx*dx + dy*dy)
    
    -- Create S-curve by offsetting control points
    local offset = dist * tension * 0.5
    
    -- Control point 1: offset from start
    local cp1x = sx1 + dx * 0.25
    local cp1y = sy1 + offset
    
    -- Control point 2: offset from end (opposite direction)
    local cp2x = sx1 + dx * 0.75
    local cp2y = sy2 - offset
    
    local p0 = {sx1, sy1}
    local p1 = {cp1x, cp1y}
    local p2 = {cp2x, cp2y}
    local p3 = {sx2, sy2}
    
    local lastX, lastY = sx1, sy1
    for i = 1, segments do
      local t = i / segments
      local px, py = bezierPoint(t, p0, p1, p2, p3)
      gfx.line(lastX, lastY, px, py)
      lastX, lastY = px, py
    end
  end,
  
  -- Fox & Planty Fork: Thick bezier curve (for highlighted wires)
  thickbezier = function(x1, y1, x2, y2, w, stepsize, color, tension)
    local cfg = machineView.config
    tension = tension or cfg.bezierTension
    local segments = cfg.bezierSegments
    
    local sx1, sy1 = xtrafo(x1), ytrafo(y1)
    local sx2, sy2 = xtrafo(x2), ytrafo(y2)
    
    local dx = sx2 - sx1
    local dy = sy2 - sy1
    local dist = math.sqrt(dx*dx + dy*dy)
    local offset = dist * tension * 0.5
    
    local cp1x = sx1 + dx * 0.25
    local cp1y = sy1 + offset
    local cp2x = sx1 + dx * 0.75
    local cp2y = sy2 - offset
    
    local p0 = {sx1, sy1}
    local p1 = {cp1x, cp1y}
    local p2 = {cp2x, cp2y}
    local p3 = {sx2, sy2}
    
    local rt = 3*reaper.time_precise()
    gfx.set(table.unpack(color))
    
    local lastX, lastY = sx1, sy1
    local j = 0
    
    for i = 1, segments do
      local t = i / segments
      local px, py = bezierPoint(t, p0, p1, p2, p3)
      
      local ldx = px - lastX
      local ldy = py - lastY
      local llen = math.sqrt(ldx*ldx + ldy*ldy)
      if llen > 0 then
        ldx = ldx / llen
        ldy = ldy / llen
      end
      
      gfx.a = math.abs( math.sin(10*j + rt) )
      j = j + stepsize
      
      local nx, ny = -ldy * w, ldx * w
      gfx.line(lastX + nx, lastY + ny, px + nx, py + ny)
      gfx.line(lastX - nx, lastY - ny, px - nx, py - ny)
      gfx.triangle(lastX + nx, lastY + ny, px + nx, py + ny, lastX - nx, lastY - ny)
      gfx.triangle(px + nx, py + ny, px - nx, py - ny, lastX - nx, lastY - ny)
      
      lastX, lastY = px, py
    end
  end,

--[[
================================================================================
CHANGE 6: Remove dead code - oldInTriangle function (~line 850)
================================================================================
DELETE this entire function (it's never called):
--]]

-- DELETE THIS:
local function oldInTriangle( triangle, point )
  -- Compute vectors        
  local v0 = sub(triangle[3], triangle[1] );
  local v1 = sub(triangle[2], triangle[1] );
  local v2 = sub(point, triangle[1] );

  -- Compute dot products
  local dot00 = dot(v0, v0);
  local dot01 = dot(v0, v1);
  local dot02 = dot(v0, v2);
  local dot11 = dot(v1, v1);
  local dot12 = dot(v1, v2);

  -- Compute barycentric coordinates
  local invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01);
  local u = (dot11 * dot02 - dot01 * dot12) * invDenom;
  local v = (dot00 * dot12 - dot01 * dot02) * invDenom;

  -- Check if point is in triangle
  return (u >= 0) and (v >= 0) and (u + v < 1);
end

--[[
================================================================================
CHANGE 7: Modify sink.draw() to use bezier curves (~line 1850)
================================================================================
Find the sink draw function and modify the wire drawing section.
Replace the straight line drawing with conditional bezier:
--]]

  self.draw = function(self)
    local cfg = machineView.config
    if ( hideWires == 1 ) then
      return
    end
  
    local wireColor = colors.wireColor
    gfx.set( table.unpack( wireColor ) )
    local other = self.other
    local this  = self.this
    
    local alpha = wireColor[4]
    if ( self.type == 1 ) then
       alpha = cfg.sendAlpha * wireColor[4]
    elseif ( self.type == 2 ) then
       alpha = cfg.parentAlpha * wireColor[4]    
    end
    
    if ( this.hidden == 0 and other.hidden == 0 or (showHidden == 1) ) then
      local indicatorPoly = self.indicatorPoly
      if ( self:arrowVisible() ) then
        gfx.a = alpha
        wgfx.line( indicatorPoly[1][1], indicatorPoly[1][2], indicatorPoly[2][1], indicatorPoly[2][2] )
        wgfx.line( indicatorPoly[2][1], indicatorPoly[2][2], indicatorPoly[3][1], indicatorPoly[3][2] )
        wgfx.line( indicatorPoly[1][1], indicatorPoly[1][2], indicatorPoly[3][1], indicatorPoly[3][2] )
      end

      if ( self.accent == 1 or self.ctrls ) then
        -- Fox & Planty Fork: Use bezier for highlighted wires
        if cfg.useBezierWires == 1 then
          wgfx.thickbezier( this.x, this.y, other.x, other.y, machineView.config.thickWireWidth, 5, colors.selectionColor )
        else
          wgfx.thickline( this.x, this.y, other.x, other.y, machineView.config.thickWireWidth, 5, colors.selectionColor )
        end
      else
        if ( hideWires == 0 or (hideWires == 2 and self.accent == 2) ) then
          gfx.a = alpha
          -- Fox & Planty Fork: Use bezier for normal wires
          if cfg.useBezierWires == 1 then
            wgfx.bezier( this.x, this.y, self.indicatorPoly[4][1], self.indicatorPoly[4][2] )
            wgfx.bezier( indicatorPoly[1][1], indicatorPoly[1][2], other.x, other.y )
          else
            wgfx.line( this.x, this.y, self.indicatorPoly[4][1], self.indicatorPoly[4][2] )
            wgfx.line( indicatorPoly[1][1], indicatorPoly[1][2], other.x, other.y )
          end
        end
      end
    end
  end

--[[
================================================================================
CHANGE 8: Add key handler for toggle bezier (~line 3900, in the keyboard input section)
================================================================================
Add this after the other key handlers (near 'colorbarToggle'):
--]]

        elseif ( inputs('toggleBezier') ) then
          machineView.config.useBezierWires = 1 - machineView.config.useBezierWires
          if ( machineView.config.useBezierWires == 1 ) then
            self:printMessage( "Bezier wire curves enabled" )
          else
            self:printMessage( "Straight wire lines enabled" )
          end

--[[
================================================================================
DONE! Summary of changes:
================================================================================

1. Updated header/version info
2. Added 3 new config options (useBezierWires, bezierTension, bezierSegments)
3. Added toggleBezier key binding ('B')
4. Added bezierPoint() helper function
5. Added wgfx.bezier() and wgfx.thickbezier() functions
6. Removed oldInTriangle() dead code
7. Modified sink.draw() to use bezier when enabled
8. Added keyboard handler for 'B' key

The bezier curves create smooth S-shaped connections between machines,
making the signal flow more visually elegant. Tension can be adjusted
in the config file (0 = straight, 1 = very curved, 0.5 = default).

Fox & Planty Fork - 2026-01-02
93 93/93 🐙🌱
--]]
