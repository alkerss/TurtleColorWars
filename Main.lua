--[[ Header
ColorWars algorithm for LUA
Authors: Akuukis, Hugo, LatvianModder, TomsG
Started: May 1, 2014
First Beta release: -
First Alpha release: -
Github address: https://github.com/Akuukis/TurtleColorWars
--]]
--[[Structure
Main - Starts Init. and afterwards runs Job,Supp,Comm in paralel. Subclasses Nav,Debug,Stats are present.
Init.## Initiation - Initiates the turtle so it could operate
Job.### Decision Making - Turtle weights alternatives, chooses his next AIM (strategy level) and does it (tactical level)
Supp.## Maintance - Turtle's AIM can be interrupted by inside events, like low on fuel, full backpack or afraid of night. Overrides AIM & does it.
Comm.## Communication - Turtle's AIM can be interrupted by outside events, like call for help or direct command. Sets AIM & does Job##.
Nav.### Navigation - Turtle goes to point XYZ (sub-tactical level) and constantly updates internal map.
Debug.# Debug - (sub-tactical level)
Stats.# Statistics - Turtle collents & stores individual statistics for fun purposes only.
--]]


function myformat( fmt, ... )
    local buf = {}
     for i = 1, select( '#', ... ) do
         local a = select( i, ... )
         if type( a ) ~= 'string' and type( a ) ~= 'number' then
             a = tostring( a )
         end
         buf[i] = a
     end
     return string.format( fmt, unpack( buf ) )
 end
printf=function(...)     
  io.write(myformat(...)) 
  end
printfs=function(...)
  --for w in string.gmatch(debug.traceback(nil,2+1), ".lua:") do printf("  ") end -- ComputerCraft doesn't have debug
  io.write(myformat(...)) 
  end  

printfs("\nInitializing the program...\n")

-- Classes
Init = {
  Born = function(self)
    Nav:UpdateMap({0,0,0},0)
    end
  }
Job = {
  }
Supp = {
  Refuel = function(self)
    if turtle.getFuelLevel() < 128 then
      if turtle.refuel()then 
        write("Refueled!\n")
        else 
        write("Fuel me!\n")
        end
      end
    return turtle.getFuelLevel()
    end
  }
Comm = {
  }
PControl = {
  }
IO = {
  }
Nav = {
  X = 0, -- North
  Z = 0, -- East
  Y = 0, -- Height
  F = 0, -- Facing direction, modulus of 4 // 0,1,2,3 = North, East, South, West
  Map = {}, -- Id={nil=unexplored,false=air,####=Block}, Updated=server's time, Evade={nil,true if tagged by special events}
  GetPath = function(self,tx,tz,ty)  -- Based on code (Sep 21, 2006) by Altair who ported and upgraded code of LMelior
  --[[ PRE:
  Nav.Map is a 2d array
  Nav.X is the player's current x or North
  Nav.Z is the player's current z or East
  Nav.Y is the player's current y or Height (not yet implemented)
  tx is the target x
  tz is the target z
  ty is the target y (not yet implemented)

  Note: all the x and z are the x and z to be used in the table.
  By this I mean, if the table is 3 by 2, the x can be 1,2,3 and the z can be 1 or 2.
    --]]

  --[[ POST:
  path is a list with all the x and y coords of the nodes of the path to the target.
  OR nil if closedlist==nil
  --]]
  -- variables
  if ty == nil then ty = 0 end
  printfs("Nav:GetPath(%s, %s)\n",tx,tz,ty)
  local tempG=0
  local tempH=math.abs(Nav.X-tx)+math.abs(Nav.Y-tz) -- Manhattan's method
  local closedlist={}						-- Initialize table to store checked gridsquares
  local openlist={}                 				-- Initialize table to store possible moves
  openlist[1]={x=Nav.X, z=Nav.Z, g=0, h=tempH, f=0+tempH ,par=1}   	-- Make starting point in list
--  Map is infinite in TCW
--  local xsize=table.maxn(Nav.Map[1]) 				-- horizontal map size
--  local ysize=table.maxn(Nav.Map)					-- vertical map size
  local curbase={}						-- Current square from which to check possible moves
  local basis=1							-- Index of current base
  local openk=1                   				-- Openlist counter
  local closedk=0                					-- Closedlist counter
  Nav:ExploreMap(tx,tz,ty)
  printfs("Nav:GetPath() CurbaseXZ: ")
  while openk>0  and table.maxn(closedlist)<500 do   -- Growing loop
    --Debug:Check("")
    if Nav.Map[tx][tz][ty].Id then if Nav.Map[tx][tz][ty].Id > 0 then return nil end end
    
    -- Get the lowest f of the openlist
    local lowestF=openlist[openk].f
    basis=openk
    for i=openk,1,-1 do
      if openlist[i].f<lowestF then
        lowestF=openlist[i].f
        basis=i
        end
      end

    closedk=closedk+1
    table.insert(closedlist,closedk,openlist[basis]) --Inserts element openlist[basis] at position closedk in table closedlist, shifting up other elements to open space, if necessary. // HERE: inserts at the end. 

    curbase=closedlist[closedk]				 -- define current base from which to grow list
    curbase.y=0
    printf("(%s,%s@%s/%s) ",curbase.x, curbase.z,closedk,openk)
    
    local NorthOK=true
    local SouthOK=true           				 -- Booleans defining if they're OK to add
    local EastOK=true             				 -- (must be reset for each while loop)
    local WestOK=true

    -- If it IS on the map, check map for obstacles
    --(Lua returns an error if you try to access a table position that doesn't exist, so you can't combine it with above)
    local suc=true
    local id=0
    suc,id = pcall(function() if Nav.Map[curbase.x+1][curbase.z][curbase.y].Id>0 then return 1 else return 0 end end)
    if suc~=true then NorthOK = true elseif id == 0 then NorthOK = true else NorthOK = false; printf("North obstacle") end
    suc,id = pcall(function() if Nav.Map[curbase.x][curbase.z+1][curbase.y].Id>0 then return 1 else return 0 end end)
    if suc~=true then EastOK = true elseif id == 0 then EastOK = true else EastOK = false; printf("East obstacle") end
    suc,id = pcall(function() if Nav.Map[curbase.x-1][curbase.z][curbase.y].Id>0 then return 1 else return 0 end end)
    if suc~=true then SouthOK = true elseif id == 0 then SouthOK = true else SouthOK = false; printf("South obstacle") end
    suc,id = pcall(function() if Nav.Map[curbase.x][curbase.z-1][curbase.y].Id>0 then return 1 else return 0 end end)    
    if suc~=true then WestOK = true elseif id == 0 then WestOK = true else WestOK = false; printf("West obstacle") end    
        
    -- Look through closedlist
    if closedk>0 then
      for i=1,closedk do
        if (closedlist[i].x==curbase.x+1 and closedlist[i].z==curbase.z) then NorthOK=false end
        if (closedlist[i].x==curbase.x-1 and closedlist[i].z==curbase.z) then SouthOK=false end
        if (closedlist[i].x==curbase.x and closedlist[i].z==curbase.z+1) then EastOK=false  end
        if (closedlist[i].x==curbase.x and closedlist[i].z==curbase.z-1) then WestOK=false  end
      end
    end
    
    -- Check if next points are on the map and within moving distance
    --[[ Akuukis: Map is infinite
    if curbase.x+1>xsize then
      NorthOK=false
    end
    if curbase.x-1<1 then
      SouthOK=false
    end
    if curbase.z+1>ysize then
      EastOK=false
    end
    if curbase.z-1<1 then
      WestOK=false
    end
    --]]


    --[[
    if Nav.Map[curbase.x+1][curbase.z].Id~=false then NorthOK=false end
    if Nav.Map[curbase.x][curbase.z+1].Id~=false then EastOK=false  end
    if Nav.Map[curbase.x-1][curbase.z].Id~=false then SouthOK=false end
    if Nav.Map[curbase.x][curbase.z-1].Id~=false then WestOK=false  end
    --]]
    
    -- check if the move from the current base is shorter then from the former parent
    tempG=curbase.g+1
    for i=1,openk do
      if NorthOK and openlist[i].x==curbase.x+1 and openlist[i].z==curbase.z and openlist[i].g>tempG then
        tempH=math.abs((curbase.x+1)-tx)+math.abs(curbase.z-tz)
        table.remove(openlist,i)
        table.insert(openlist,i,{x=curbase.x+1, z=curbase.z, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
        NorthOK=false
        end
    
      if SouthOK and openlist[i].x==curbase.x-1 and openlist[i].z==curbase.z and openlist[i].g>tempG then
        tempH=math.abs((curbase.x-1)-tx)+math.abs(curbase.z-tz)
        table.remove(openlist,i)
        table.insert(openlist,i,{x=curbase.x-1, z=curbase.z, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
        SouthOK=false
        end

      if EastOK and openlist[i].x==curbase.x and openlist[i].z==curbase.z+1 and openlist[i].g>tempG then
        tempH=math.abs((curbase.x)-tx)+math.abs(curbase.z+1-tz)
        table.remove(openlist,i)
        table.insert(openlist,i,{x=curbase.x, z=curbase.z+1, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
        EastOK=false
        end

      if WestOK and openlist[i].x==curbase.x and openlist[i].z==curbase.z-1 and openlist[i].g>tempG then
        tempH=math.abs((curbase.x)-tx)+math.abs(curbase.z-1-tz)
        table.remove(openlist,i)
        table.insert(openlist,i,{x=curbase.x, z=curbase.z-1, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
        WestOK=false
        end
      end

    -- Add points to openlist
    -- Add point to the North of current base point
    if NorthOK then
      openk=openk+1
      tempH=math.abs((curbase.x+1)-tx)+math.abs(curbase.z-tz)
      table.insert(openlist,openk,{x=curbase.x+1, z=curbase.z, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
      end

    -- Add point to the South of current base point
    if SouthOK then
      openk=openk+1
      tempH=math.abs((curbase.x-1)-tx)+math.abs(curbase.z-tz)
      table.insert(openlist,openk,{x=curbase.x-1, z=curbase.z, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
      end

    -- Add point to the East of current base point
    if EastOK then
      openk=openk+1
      tempH=math.abs(curbase.x-tx)+math.abs((curbase.z+1)-tz)
      table.insert(openlist,openk,{x=curbase.x, z=curbase.z+1, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
      end

    -- Add point to the West of current base point
    if WestOK then
      openk=openk+1
      tempH=math.abs(curbase.x-tx)+math.abs((curbase.z-1)-tz)
      table.insert(openlist,openk,{x=curbase.x, z=curbase.z-1, g=tempG, h=tempH, f=tempG+tempH, par=closedk})
      end

    table.remove(openlist,basis)
    openk=openk-1
    
    if closedlist[closedk].x==tx and closedlist[closedk].z==tz then
      printf("\n")
      printfs("Nav:GetPath() Found the path! Openlist: %s, Closedlist: %s, Steps: ",table.maxn(openlist),table.maxn(closedlist))
      -- Change Closed list into a list of XZ coordinates starting with player
      local path={} 
      local pathIndex={}
      local last=table.maxn(closedlist)
      table.insert(pathIndex,1,last) 
      local i=1 -- we will include starting position into a table, otherwise 1
      while pathIndex[i]>1 do i=i+1; table.insert(pathIndex,i,closedlist[pathIndex[i-1]].par); end
      printf("%s\n", i)
      printfs("Nav:GetPath() Path: ")
      for i=table.maxn(pathIndex),1,-1 do table.insert(path,{x=closedlist[pathIndex[i]].x, z=closedlist[pathIndex[i]].z}); printf("%s(%s,%s)", last, path[table.maxn(pathIndex)-i+1].x, path[table.maxn(pathIndex)-i+1].z) end
      closedlist=nil
            
      -- Change list of XZ coordinates into a list of directions
      printf("\n")      
      printfs("Nav:GetPath() FPath: ")
      local fpath={}
      for i=1,table.maxn(path)-1,1 do 
        if path[i+1].x > path[i].x then fpath[i]=0 end -- North
        if path[i+1].z > path[i].z then fpath[i]=1 end -- East
        if path[i+1].x < path[i].x then fpath[i]=2 end -- South
        if path[i+1].z < path[i].z then fpath[i]=3 end -- West
        printf("%s, ", fpath[i])
        end
      printf("\n")
      return fpath
      end
    end

  return nil
  end,
  GoPath = function(self,tx,tz,tries)
    tx=tonumber(tx)
    tz=tonumber(tz)
    printfs("Nav:GoPath(%s,%s,%s)\n", tx, tz, tries)
    if tries == nil then tries = 32 end
    local j=1
    repeat
      if (Nav.X==tx and Nav.Z==tz) then return true else tries=tries-1 end
      printfs("Nav.GoPath() @(%s,%s,%s) /%s\n",Nav.X,Nav.Z,Nav.Y,tries)
      local fpath = Nav:GetPath(tx,tz)
      if fpath == nil then printfs("Nav.GoPath() FPath=nil!"); return false else j=0 end
      repeat
        j=j+1 
        printfs("Nav:GoPath() @(%s,%s,%s), Moving %s/%s ...\n", Nav.X,Nav.Z,Nav.Y,j,table.maxn(fpath))
        until not (Nav:Move(fpath[j]) and j<table.maxn(fpath))
      until tries<0
    printfs("Nav.GoPath() Out-of-UNTIL! /%s",tries)
    return false
    end,
  Move = function(self,dir) -- dir{0=North|1=East|2=South|3=West|4=up|5=down}, returns true if succeeded
    local success = 0
    printfs("Nav:Move(%s)\n", dir)
    Supp:Refuel()
    if dir==4 then               -- Up
      success = turtle.up()
      elseif dir==5 then         -- Down
      success = turtle.down()
      elseif dir==Nav.F-1 or dir==Nav.F+3 then -- Left
      Nav:TurnLeft()
      success = turtle.forward()
      elseif dir==Nav.F-2 or dir==Nav.F+2 then -- Right
      Nav:TurnAround()
      success = turtle.forward()
      elseif dir==Nav.F-3 or dir==Nav.F+1 then -- 180
      Nav:TurnRight()
      success = turtle.forward()
      else                       -- Forward
      success = turtle.forward()
      end
    if success then
      Nav:UpdateCoord(dir)
      Nav:UpdateMap(dir)
      --printfs("Nav:Move() Return true\n")
      return true
      else
      Nav:UpdateMap()
      printfs("Nav:Move() Return false\n")
      return false
      end
    end,
  TurnRight = function(self)
    turtle.turnRight()
    printfs("Nav:TurnRight() Nav.F: %s => ",Nav.F)
    Nav.F=(Nav.F+1)%4
    printf("%s\n",Nav.F)
    Nav:UpdateMap()
    end,
  TurnLeft = function(self)
    turtle.turnLeft()
    printfs("Nav:TurnLeft() Nav.F: %s => ",Nav.F)
    Nav.F=(Nav.F+3)%4
    printf("%s\n",Nav.F)
    Nav:UpdateMap()    
    end,
  TurnAround = function(self)
    if 1==math.random(0,1) then
      Nav:TurnRight()
      Nav:TurnRight()
      else
      Nav:TurnLeft()
      Nav:TurnLeft()
      end
    end,
  DirToCoord = function(self,dir) -- returns x,z,y
    --printfs("Nav:DirToCoord(%s)\n", dir)
    if dir==0 then return Nav.X+1, Nav.Z, Nav.Y end
    if dir==1 then return Nav.X, Nav.Z+1, Nav.Y end
    if dir==2 then return Nav.X-1, Nav.Z, Nav.Y end
    if dir==3 then return Nav.X, Nav.Z-1, Nav.Y end
    if dir==4 then return Nav.X, Nav.Z, Nav.Y+1 end
    if dir==5 then return Nav.X, Nav.Z, Nav.Y-1 end
    printfs("Nav:DirToCoord: ERROR\n")
    end,    
  UpdateCoord = function(self,dir)
      --printfs("Nav:UpdateCoord(%s)\n",dir)
      Nav.X,Nav.Z,Nav.Y = Nav:DirToCoord(dir)
    end,
  UpdateMap = function(self,location,value) -- location{nil|dir|XZY), value{0=air,1=unknown block,1+=known block}  
    --printfs("Nav:UpdateMap(%s,%s)\n",location,value)
    local x,z,y
    if type(location)=="nil" then
      x,z,y = Nav:DirToCoord(Nav.F)
      --printfs("Nav:UpdateMap: (nil) %s, %s, %s\n",x,z,y)
      Nav:ExploreMap(x,z,y)      
      Nav.Map[x][z][y].Updated = os.time()
      if turtle.detect() then Nav.Map[x][z][y].Id = 1 else Nav.Map[x][z][y].Id = 0 end
      elseif type(location)=="number" then
      x,z,y = Nav:DirToCoord(Nav.F)
      --printfs("Nav:UpdateMap: (number) %s, %s, %s\n",x,z,y)
      Nav:ExploreMap(x,z,y)
      Nav.Map[x][z][y].Updated = os.time()
      if turtle.detect() then Nav.Map[x][z][y].Id = 1 else Nav.Map[x][z][y].Id = 0 end
      if location~=5 then
        x,z,y = Nav:DirToCoord(4)
        Nav:ExploreMap(x,z,y)
        Nav.Map[x][z][y].Updated = os.time()
        if turtle.detectUp() then Nav.Map[x][z][y].Id = 1 else Nav.Map[x][z][y].Id = 0 end
        end
      if location~=4 then
        x,z,y = Nav:DirToCoord(5)
        Nav:ExploreMap(x,z,y)
        Nav.Map[x][z][y].Updated = os.time()
        if turtle.detectDown() then Nav.Map[x][z][y].Id = 1 else Nav.Map[x][z][y].Id = 0 end
        end      
      elseif type(location)=="table" then
      --printfs("Nav:UpdateMap: (table) %s, %s, %s\n",x,z,y)
      x,z,y = location[1] or location.x, location[2] or location.z, location[3] or location.y
      if value == nil then value = 1 end
      Nav:ExploreMap(x,z,y)
      Nav.Map[x][z][y].Updated = os.time()
      Nav.Map[x][z][y].Id = value
      end
    end,
  ExploreMap = function(self,x,z,y)
    --printfs("Nav:ExploreMap(%s,%s,%s)\n", x,z,y)
    if Nav.Map[x] == nil then Nav.Map[x]={} end
    if Nav.Map[x][z] == nil then Nav.Map[x][z]={} end
    if Nav.Map[x][z][y] == nil then Nav.Map[x][z][y]={} end
    end,
  Last = function(self)
    return 1
    end,
  }
Debug = {
  Hugo = function(self, x, y) -- Redundant
    modem.transmit(3, 1337, x.." "..y)
    end,
  PrintMap = function(self,Type)
    y=0;
    for x=Nav.X+3,Nav.X-3,-1 do
      for z=Nav.Z-19,Nav.Z+19,1 do
        if Nav.Map[x]==nil then
          printf(".")
          elseif Nav.Map[x][z]==nil then
          printf(".")
          else
          if (Nav.X==x and Nav.Z==z) then printf("#") else 
            if Nav.Map[x][z][y].Id==0 then printf(" ") else printf("%s",Nav.Map[x][z][y].Id) end
            end
          end
        end
      printf("\n")
      end
    end,
  Check = function(self,...)
    printfs(...)
    while true do
      event, param1 = os.pullEvent()
      if event == "key" then break end
      end
    end
  }
Stats = {
  GlobalSteps = 0,
  CountedSteps = 0,
  Step = function(self, x)
    x = x or 1 -- create object if user does not provide one
    Stats.GlobalSteps = Stats.GlobalSteps + 1
    Stats.CountedSteps = Stats.CountedSteps + 1
    end,
  GetGlobalSteps = function(self)
    return Stats.GlobalSteps
    end,
  GetCountedSteps = function(self)
    return Stats.CountedSteps
    end,
  ResetCountedSteps = function(self)
    Stats.CountedSteps = 0
    end
  }

  
printfs("Starting the program...\n")

Init:Born()

while 1 do
  Debug:PrintMap()
  Supp:Refuel()
  printf("A* Pathfinding supports only 2D\n")
  printf("Enter X coordinate: ")
  local x = io.read() -- = io.stdin:read'*l' ??
  printf("Enter Z coordinate: ")
  local z = io.read()

  if x=="" or x==nil then x=4 end
  if z=="" or z==nil then z=3 end
  
  if Nav:GoPath(x,z) then printfs("Succeeded!") else printfs("Exceeded 32 tries, failed!\n") end
  printf(" Coords: (%s,%s,%s), F:%s\n",Nav.X,Nav.Z,Nav.Y,Nav.F)
  end

 

 
