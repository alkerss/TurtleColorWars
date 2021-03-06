--[[ API calls:
	Go( [ { x, z, y [,f] } ], [isRelative], [,style]).
		EXAMPLE: Lets say we are at coordinates X=2, Z=-3, Y=4 and if we want to go to X=0,Z=0,Y=0 then all the following will do.
			Nav.Go()
			Nav.Go({0,0,0})
			Nav.Go({0,0,0,1})
			Nav.Go({0,0,0},false,"Normal")
			Nav.Go({-2,3,-4},true,"Normal")
			pos = {x=0, z=0, y=0}; Nav.Go(pos)
		INPUT:
			table { num x, num z, num y [,num f]} : target position and face. If table is nil then default is current position and undefined face. Returns nil if X or Z or Y is nil. F are:
				0: North/X+
				1: East/Z+
				2: South/X-
				3: West/Z-
				else Undefined
			num isRelative : defines if coords are given in absolute or relative. 
				Nil|false|0: Absolute
				true|1: Relative
				2+: Relative to facing direction
			string style : defines different styles how to move around, mostly pathfinding function.
				Default: use "Normal"
				"Normal": combination of "Careful" and "DigCareful" - prefers not to dig but digs if very needed. Recommended for most purposes.
				"Careful": move carefully (recalculate path if block is in a way, doesn't destroy blocks), good for moving inside a base, but inefficient.
				"Dig": move and destroy blocks if one is in a way except if tagged "Use with caution, may destroy other turtles! Use "DigCareful"
				"DigCareful": like "Dig" but returns if there is a turtle in 2sq in front.
				"Explore": move carefully AND check sides if they are unexplored. Good for mapping, but slow.
				"SurfaceExplore": like "Exlore" but ignores Y coordinate and moves on surface, ignoring openings 3+sq deep and 1-2sq wide.
				else use Default
		OUTPUT: 
			Returns true if succeeded, false if not.
	Nav.TurnRight()
		INPUT: nothing
		OUTPUT: nothing
	Nav.TurnLeft()
		INPUT: nothing
		OUTPUT: nothing
	Nav.TurnAround()
		INPUT: nothing
		OUTPUT: nothing
	Nav.GetPos([string switchXZYF])
		INPUT: 
			string switchXZYF: any of the following values "x", "X", "z", "Z", "y", "Y", "f", "F"
		OUTPUT: 
			Default: table {x, z, y, f}, where XZY is absolute coordinates and f is facing direction (0 to 3)
			if switchXZYF: num returnXZYF, a numeric value depending on input string
--]]

-- Private Variables
local Pos = {} --
Pos.x = 0 -- North
Pos.z = 0 -- East
Pos.y = 0 -- Height
Pos.f = 0 -- Facing direction, modulus of 4 // 0,1,2,3 = North, East, South, West
local Map = {} -- Id={nil=unexplored,false=air,0=RandomBlock,####=Block}, Updated=server's time, Tag={nil,true if tagged by special events}
Map.InitTime = os.time()
Map.UpdatedTime = os.time()

-- Public API's
function Step(...)
	return Move(GetPos("f"),{...})
end
function GetPos ( ... ) -- Input Position (table), FacingDirection (num) and returnSwitch (string) in any order
	local Face = nil
	local Switch = nil
	local P = {}
	local Arg = {}
	P.x = Pos.x
	P.z = Pos.z
	P.y = Pos.y
	P.f = Pos.f
	
	for i=1,select('#',...) do
		Arg[i] = select(i,...)
	end
	
	for i=1,3,1 do
		if type(Arg[i]) == "number" then Face = Arg[i]
		elseif type(Arg[i]) == "table" then 
			P.x = Arg[i].x or Arg[i][1] or Pos.x
			P.z = Arg[i].z or Arg[i][2] or Pos.z
			P.y = Arg[i].y or Arg[i][3] or Pos.y
			P.f = Arg[i].f or Arg[i][4] or Pos.f
		elseif Arg[i] == "x" or Arg[i] == "X" then Switch = Arg[i]
		elseif Arg[i] == "z" or Arg[i] == "Z" then Switch = Arg[i]
		elseif Arg[i] == "y" or Arg[i] == "Y" then Switch = Arg[i]
		elseif Arg[i] == "f" or Arg[i] == "F" then Switch = Arg[i]
		end
	end
	
	if Switch == nil or type(Switch) ~= "string" then
		if Face == nil then return {P.x, P.z, P.y} 
		elseif Face == 0 then return {P.x+1, P.z, P.y}
		elseif Face == 1 then return {P.x, P.z+1, P.y}
		elseif Face == 2 then return {P.x-1, P.z, P.y}
		elseif Face == 3 then return {P.x, P.z-1, P.y}
		elseif Face == 4 then return {P.x, P.z, P.y+1}
		elseif Face == 5 then return {P.x, P.z, P.y-1}
		else return {P.x, P.z, P.y}
		end
	elseif Switch == "x" or Switch == "X" then
		if Face == nil then return P.x
		elseif Face == 0 then return P.x+1
		elseif Face == 1 then return P.x
		elseif Face == 2 then return P.x-1
		elseif Face == 3 then return P.x
		elseif Face == 4 then return P.x
		elseif Face == 5 then return P.x
		else return P.x
		end	
	elseif Switch == "z" or Switch == "Z" then
		if Face == nil then return P.z
		elseif Face == 0 then return P.z
		elseif Face == 1 then return P.z+1
		elseif Face == 2 then return P.z
		elseif Face == 3 then return P.z-1
		elseif Face == 4 then return P.z
		elseif Face == 5 then return P.z
		else return P.z
		end
	elseif Switch == "y" or Switch == "Y" then
		if Face == nil then return P.y
		elseif Face == 0 then return P.y
		elseif Face == 1 then return P.y
		elseif Face == 2 then return P.y
		elseif Face == 3 then return P.y
		elseif Face == 4 then return P.y+1
		elseif Face == 5 then return P.y-1
		else return P.y
		end
	elseif Switch == "f" or Switch == "F" then
		if Face == nil then return P.f
		elseif Face == 0 then return Face
		elseif Face == 1 then return Face
		elseif Face == 2 then return Face
		elseif Face == 3 then return Face
		elseif Face == 4 then return P.f
		elseif Face == 5 then return P.f
		else return P.f
		end	
	end
	return nil
	end
function Go ( ... ) -- table position, num isRelative, text option1 [, text option2 ...]
	
	local target = {}
	local options = {}
	local isRelative = false
	
	for i=1,select('#',...) do
		local temp = select(i,...)
		if type(temp) == "table" then target = temp end
		if type(temp) == "boolean" then if temp == true then isRelative = 1 else isRelative = 0 end end
		if type(temp) == "number" then isRelative = temp end
		if type(temp) == "text" then options[table.maxn(options)+1] = temp end
	end
	
	target.x = target.x or target[1] or 0
	target.z = target.z or target[2] or 0
	target.y = target.y or target[3] or 0
	target.f = target.f or target[4] or GetPos("f")
	
	if isRelative and isRelative > 0 then
		if isRelative > 1 then
			if GetPos("f") == 0 then target.x = GetPos("x") + target.x; target.z = GetPos("z") + target.z end
			if GetPos("f") == 1 then target.x = GetPos("x") - target.z; target.z = GetPos("z") + target.x end
			if GetPos("f") == 2 then target.x = GetPos("x") - target.x; target.z = GetPos("z") - target.z end
			if GetPos("f") == 3 then target.x = GetPos("x") + target.z; target.z = GetPos("z") - target.x end
		else
			target.x = target.x + GetPos("x")
			target.z = target.z + GetPos("z")
		end	
	end
	
	for i=1,table.maxn(options) do
		if options[i] == "Normal" or options[i] == "normal" then options[i] = "Normal" 
		elseif options[i] == "Careful" or options[i] == "careful" then options[i] = "Careful" 
		elseif options[i] == "Dig" or options[i] == "dig" then return "Error: Style " .. options[i] .. " not implemented yet."
		elseif options[i] == "DigCareful" or options[i] == "Digcareful" or options[i] == "digcareful" then return "Error: Style " .. options[i] .. " not implemented yet."
		elseif options[i] == "Explore" or options[i] == "explore" then return "Error: Style " .. options[i] .. " not implemented yet."
		elseif options[i] == "SurfaceExplore" or options[i] == "Surfaceexplore" or options[i] == "surfaceexplore" then return "Error: Style " .. options[i] .. " not implemented yet."
		else options[i] = "Normal"
		end
	end
	
	
	local tries=32 -- TODO
	Logger.Debug("Nav.Go(%s,%s,%s) Style: %s\n", target.x, target.z, target.y, options[1])
	repeat
		if ComparePos(GetPos(),target) then return true else tries = tries - 1 end
		Logger.Debug("Nav.Go() @ (%s,%s,%s,F%s)/%s\n",GetPos("x"),GetPos("z"),GetPos("y"),GetPos("f"),tries)
		local fpath = GetPath(target,options)
		if fpath == nil then 
			Logger.Debug("Nav.Go() FPath=nil!")
			UpdateMap()
			TurnRight()
		else
			i = 1
			success = false
			while i <= table.maxn(fpath) and not success do 
				Logger.Debug("%s",i)
				Logger.Debug("@(%s,%s,%s),(%s,%s) Moving %s/%s ...\n", GetPos("x"),GetPos("z"),GetPos("y"),not fpath[i],not GetMap(GetPos(fpath[i]),"Id"),i,table.maxn(fpath))
				success = not Move(fpath[i], options)
				i = i + 1
			end
		end
	until tries < 0
	Logger.Debug("Nav.Go() Out-of-UNTIL! /%s",tries)
	return false
end
function TurnRight ()
	turtle.turnRight()
	Logger.Debug("Nav.TurnRight() Nav.Pos.f. %s => ",GetPos("f"))
	Pos.f = (GetPos("f")+1)%4
	Logger.Debug("%s\n",GetPos("f"))
	UpdateMap()
end
function TurnLeft ()
	turtle.turnLeft()
	Logger.Debug("Nav.TurnLeft() Nav.Pos.f. %s => ",GetPos("f"))
	Pos.f = (GetPos("f")+3)%4
	Logger.Debug("%s\n",GetPos("f"))
	UpdateMap()    
end
function TurnAround ()
	if 1==math.random(0,1) then
		TurnRight()
		TurnRight()
	else
		TurnLeft()
		TurnLeft()
	end
end
function UpdateMap (location,value) -- location{nil|dir|XZY), value{false=air,0=unknown block,1+=known block}
	--Logger.Check("UpdateMap:%s,%s",location,value)
	if type(location) == "nil" or type(location) == "number" then
		if turtle.detect() then PutMap(GetPos(GetPos("f")),"Id",0) else PutMap(GetPos(GetPos("f")),"Id",false) end
		if turtle.detectUp() then PutMap(GetPos(4),"Id",0) else PutMap(GetPos(4),"Id",false) end
		if turtle.detectDown() then PutMap(GetPos(5),"Id",0) else PutMap(GetPos(5),"Id",false) end
	elseif type(location)=="table" then
		location.x = location.x or location[1]
		location.z = location.z or location[2]
		location.y = location.y or location[3]
		location.f = location.f or location[4]		
		PutMap({location.x, location.x, location.y},"Id",value)
	end
end
function GetDistance (target, ...) -- Gets distance between your position and a target with given options
	local options = {}
	for i=1,select('#',...) do
		local temp = select(i,...)
		if type(temp) == "text" then options[table.maxn(options)+1] = temp end
	end
	return table.maxn( GetPath(target,options) )
end
-- Private API's
function GetPath (target,options)  -- TODO: multiple targets!
--[[ DISCLAIMER.
This code (May 04, 2014) is written by Akuukis 
	who based on code (Sep 21, 2006) by Altair
		who ported and upgraded code of LMelior
--]]
--[[ PRE.
Map[][][] is a 3d infinite array (.Id, .Updated, .Evade)
Pos.x is the player's current x or North
Z is the player's current z or East
Pos.y is the player's current y or Height (not yet implemented)
target.x is the target x
target.z is the target z
target.y is the target y (not yet implemented)
options is the preference (not yet implemented)

Note. all the x and z are the x and z to be used in the table.
By this I mean, if the table is 3 by 2, the x can be 1,2,3 and the z can be 1 or 2.
--]]
--[[ POST.
path is a list with all the x and y coords of the nodes of the path to the target.
OR nil if closedlist==nil
-- Intro to A* - http://www.raywenderlich.com/4946/introduction-to-a-pathfinding
-- Try it out! - http://zerowidth.com/2013/05/05/jump-point-search-explained.html
--]]
if target.y == nil then target.y = GetPos("y") end

CalcHeuristic = function (pos1, pos2, options)
	-- Useful - http://theory.stanford.edu/~amitp/GameProgramming/Heuristics.html
	AverageCost = 1
	for i=1,table.maxn(options) do
		if options[i] == "Manhattan" or options[i] == 1 then
			dx = math.abs(GetPos(pos1,"x")-GetPos(pos2,"x"))
			dz = math.abs(GetPos(pos1,"z")-GetPos(pos2,"z"))
			dy = math.abs(GetPos(pos1,"y")-GetPos(pos2,"y"))
			return AverageCost * (dx + dz + dy)
		elseif options[i] == "ManhattanTieBreaker" or options[i] == 2 then
			dx = math.abs(GetPos(pos1,"x")-GetPos(pos2,"x"))
			dz = math.abs(GetPos(pos1,"z")-GetPos(pos2,"z"))
			dy = math.abs(GetPos(pos1,"y")-GetPos(pos2,"y"))
			return AverageCost * (dx + dz + dy) * (1 + 1/1000)
		end
	end
	dx = math.abs(GetPos(pos1,"x")-GetPos(pos2,"x")) --Default
	dz = math.abs(GetPos(pos1,"z")-GetPos(pos2,"z"))
	dy = math.abs(GetPos(pos1,"y")-GetPos(pos2,"y"))
	return AverageCost * (dx + dz + dy) * (1 + 1/1000)
end
	
Logger.Debug("Nav.GetPath(%s,%s,%s)\n",target.x,target.z,target.y)

local closedlist = {}		-- Initialize table to store checked gridsquares
local openlist = {}			-- Initialize table to store possible moves
openlist[1] = {}					-- Make starting point in list
openlist[1].x = GetPos("x")
openlist[1].z = GetPos("z")
openlist[1].y = GetPos("y")
openlist[1].DistExactStart = 0
openlist[1].DistHeuristicTarget = CalcHeuristic(GetPos(),target,options)
openlist[1].DistSum = openlist[1].DistExactStart + openlist[1].DistHeuristicTarget
openlist[1].parent = 1
local openk = 1					-- Openlist counter
local closedk = 0				-- Closedlist counter
local DefaultWeight = 3 -- TODO!
-- Logger.Check("Openlist.x|y|z=%s,%s,%s\n",openlist[1].x,openlist[1].z,openlist[1].y)
Logger.Debug("Nav.GetPath() CurbaseXZ. %s",options[1])

while openk > 0  and table.maxn(closedlist)<256 do   -- Growing loop

	for i=1,table.maxn(options) do
		if options[i] == "Careful" and GetMap(target,"Id") and GetMap(target,"Id") > 0 then return nil end		-- return nil if target is not accessable
	end
	
	local lowestDS = openlist[openk].DistSum		-- Get the lowest f of the openlist
	local basis = openk
	for i = openk,1,-1 do -- Prefer newer nodes
		if openlist[i].DistSum < lowestDS then
			lowestDS = openlist[i].DistSum
			basis = i
		end
	end
	closedk = closedk + 1
	closedlist[closedk] = openlist[basis]
	local curbase = closedlist[closedk]				 -- define current base from which to grow list
	-- Logger.Check("Openlist.x|y|z=%s,%s,%s\n",openlist[1].x,openlist[1].z,openlist[1].y)
	Logger.Debug("\n%s/%s:(%s,%s,%s)(%s,%s,%s|%s)F:", closedk, openk, curbase.x, curbase.z, curbase.y, math.floor(curbase.DistExactStart), math.floor(curbase.DistHeuristicTarget), math.floor(curbase.DistSum), curbase.parent)
	table.remove(openlist,basis) -- This function deletes an element of a numerical table and moves up the remaining indices if necessary.
	openk = openk - 1
	
	local OK = {}
	for face=0,5 do OK[face] = 1 end  

	for i=1,table.maxn(options) do
		if options[i] == "Normal" then		-- If it IS on the map, check map for obstacles
			for face=0,5 do 
				--Logger.Debug("%s",GetMap(GetPos(curbase,face),"Id"))
				if GetMap(GetPos(curbase,face),"Id") then OK[face] = DefaultWeight end end
		elseif options[i] == "Careful" then
			for face=0,5 do if GetMap(GetPos(curbase,face),"Id") then OK[face] = false end end
		end
	end
	
	for face=0,5 do if GetMap(GetPos(curbase,face),"Tag") == true then OK[face] = false end end	-- Look through Tagged
	
	if closedk>0 then		-- Look through closedlist
		for i=1,closedk do
			for face=0,5 do 
				if ComparePos(GetPos(closedlist[i]),GetPos(curbase,face)) then OK[face] = false end 
			end
		end
	end

	for i=1,openk do		-- check if the move from the current base is shorter than from the former parent
		for face=0,5 do
			if OK[face] and openlist[i].DistExactStart > curbase.DistExactStart + OK[face] and ComparePos(GetPos(openlist[i]),GetPos(curbase,face)) then
				--tempDTT = math.abs((curbase.x+1)-target.x)+math.abs(curbase.z-target.z)
				openlist[i].DistExactStart = curbase.DistExactStart + OK[face] 
				openlist[i].DistSum = openlist[i].DistHeuristicTarget + openlist[i].DistExactStart
				openlist[i].parent = closedk
				NorthOK=false
			end
		end
	end

	for face=0,5 do Logger.Debug("%s",OK[face]) end

	for face=0,5 do		-- Add points to openlist
		if OK[face] then
			openk = openk + 1
			openlist[openk] = {}
			openlist[openk].x = GetPos(curbase,face,"x")
			openlist[openk].z = GetPos(curbase,face,"z")
			openlist[openk].y = GetPos(curbase,face,"y")
			openlist[openk].DistExactStart = curbase.DistExactStart + OK[face]
			openlist[openk].DistHeuristicTarget =  CalcHeuristic(GetPos(curbase,face),target,options)
			openlist[openk].DistSum = openlist[openk].DistExactStart + openlist[openk].DistHeuristicTarget
			openlist[openk].parent = closedk
			--Logger.Debug("F:%s:",face)
			--for n in pairs(openlist[openk]) do Logger.Debug("%s:%s,",n,openlist[openk][n]) end
			--Logger.Check("\n")
		end
	end
	
	--Logger.Check("")

	if ComparePos(closedlist[closedk],target) then
		--Logger.Debug("\n")
		--Logger.Debug("Nav.GetPath() Found the path! Openlist: %s, Closedlist: %s, Steps: ", openk, closedk)
		-- Change Closed list into a list of XZ coordinates starting with player
		local path = {} 
		local last = closedk
		local pathIndex = {}
		pathIndex[1] = closedk
		local i = 1 -- we will include starting position into a table, otherwise 1
		while pathIndex[i] > 1 do 
			i = i + 1
			pathIndex[i] = closedlist[pathIndex[i-1]].parent
		end
		--Logger.Debug("%s\n", i)
		--Logger.Debug("Nav.GetPath() Path. ")
		for i=1,table.maxn(pathIndex),1 do
			path[i] = {}
			path[i].x = closedlist[pathIndex[table.maxn(pathIndex)+1-i]].x
			path[i].z = closedlist[pathIndex[table.maxn(pathIndex)+1-i]].z
			path[i].y = closedlist[pathIndex[table.maxn(pathIndex)+1-i]].y 
			--Logger.Debug("%s|%s|%s, ", path[i].x,path[i].z,path[i].y)
		end

		--for i=1,table.maxn(pathIndex) do
		--	Logger.Debug("%s(%s,%s,%s)", i, path[i].x, path[i].z, path[i].y)
		--end
		
		closedlist=nil
		
		-- Change list of XZ coordinates into a list of directions
		--Logger.Debug("\n")      
		Logger.Debug("Nav.GetPath() FPath. ")
		local fpath = {}
		for i=1,table.maxn(path)-1,1 do
			if path[i+1].x > path[i].x then fpath[i]=0 end -- North
			if path[i+1].z > path[i].z then fpath[i]=1 end -- East
			if path[i+1].x < path[i].x then fpath[i]=2 end -- South
			if path[i+1].z < path[i].z then fpath[i]=3 end -- West
			if path[i+1].y > path[i].y then fpath[i]=4 end -- Up
			if path[i+1].y < path[i].y then fpath[i]=5 end -- Down
			Logger.Debug("%s, ", fpath[i])
			end
		Logger.Debug("\n")
		return fpath
		end
	end
	return nil
end
function Move (face, options) -- face={0=North|1=East|2=South|3=West|4=up|5=down}, returns true if succeeded
	options[1] = options[1] or "Normal" -- Usually "Normal" because Nav.Go will default on "Normal".
	local success = false
	local Id = GetMap(GetPos(face),"Id")
	--Logger.Debug("Nav.Move(%s,%s,%s)\n", face.f, face.id, options)
	Utils.Refuel()
	if face==4 then               -- Up
		success = turtle.up()
	elseif face==5 then         -- Down
		success = turtle.down()
	elseif face==GetPos("f")-1 or face==GetPos("f")+3 then -- Left
		TurnLeft()
		success = turtle.forward()
	elseif face==GetPos("f")-2 or face==GetPos("f")+2 then -- Right
		TurnAround()
		success = turtle.forward()
	elseif face==GetPos("f")-3 or face==GetPos("f")+1 then -- 180
		TurnRight()
		success = turtle.forward()
	else                       -- Forward
		success = turtle.forward()
	end
	if success then
		UpdatePos(face)
		UpdateMap(face)
		--Logger.Debug("Nav.Move() Return true\n")
		return true
	else
		Recalc = true
		if not Id and not GetMap(GetPos(face),"Id") then Recalc = false end
		if Id and GetMap(GetPos(face),"Id") and Id == GetMap(GetPos(face),"Id") then Recalc = false end 
		Logger.Debug("%s,%s",not GetMap(GetPos(face),"Tag"),Recalc)
		for i=1,table.maxn(options) do
			if not Recalc and not GetMap(GetPos(face),"Tag") and options[i] == "Normal" then
				--Logger.Check("TRUE")
				if face == 4 then turtle.digUp(); success = turtle.up()
				elseif face == 5 then success = turtle.digDown(); turtle.down()
				else turtle.dig(); success = turtle.forward()
				end
				if success then
					UpdatePos(face)
					UpdateMap(face)
					return true
				end
			else
				UpdateMap()
				--Logger.Debug("Nav.Move() Return false\n")
				return false
			end
		end
	end
end
function GetMap (pos,name)
	--Logger.Debug("GetMap(%s,%s,%s)\n", x,z,y)
	if Map[GetPos(pos,"x")] == nil then Map[GetPos(pos,"x")]={} end
	if Map[GetPos(pos,"x")][GetPos(pos,"z")] == nil then Map[GetPos(pos,"x")][GetPos(pos,"z")]={} end
	if Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")] == nil then Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")]={} end
	
	if name == nil then 
		return Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")] 
	else 
		return Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")][name] 
	end
end
function PutMap (pos,name,value)
	-- local shout = os.difftime(os.time() - Map.UpdatedTime)
	Map.UpdatedTime = os.time()
	
	if Map[GetPos(pos,"x")] == nil then Map[GetPos(pos,"x")]={} end
	if Map[GetPos(pos,"x")][GetPos(pos,"z")] == nil then Map[GetPos(pos,"x")][GetPos(pos,"z")]={} end
	if Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")] == nil then Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")]={} end

	Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")]["Updated"] = Map.UpdatedTime
	Map[GetPos(pos,"x")][GetPos(pos,"z")][GetPos(pos,"y")][name] = value
	return shout
end
function Test ()
	return 1
	end
function ComparePos (position1,position2)
	if type(position1) ~= "table" then return "Nav TABLE" end
	if type(position2) ~= "table" then return "Nav TABLE" end
	pos1 = {}
	pos2 = {}
	pos1.x = position1.x or position1[1]
	pos1.z = position1.z or position1[2]
	pos1.y = position1.y or position1[3]
	pos1.f = position1.f or position1[4]
	pos2.x = position2.x or position2[1]
	pos2.z = position2.z or position2[2]
	pos2.y = position2.y or position2[3]
	pos2.f = position2.f or position2[4]
	if pos1.x ~= pos2.x then return false end
	if pos1.z ~= pos2.z then return false end
	if pos1.y ~= pos2.y then return false end
	if pos1.f and pos2.f and pos1.f ~= pos2.f then return false end
	return true
end
function UpdatePos (face)
--Logger.Debug("Nav.UpdateCoord(%s)\n",face)
	Pos.x = GetPos(face,"x")
	Pos.z = GetPos(face,"z")
	Pos.y = GetPos(face,"y")
end
--[[ Tutorials
General: http://www.lua.org/pil/contents.html
Varargs: http://lua-users.org/wiki/VarargTheSecondClassCitizen
Nav.ComparePos({1,2,3},{1,2,3})
--]]
	