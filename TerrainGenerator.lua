local xWidth = 16
local yWidth = 16
local intervalPerWidth = 100

local Block_Grass = script:GetCustomProperty('Grass')
local Block_Dirt = script:GetCustomProperty('Dirt')
local Block_Stone = script:GetCustomProperty('Stone')
local Block_Birch = script:GetCustomProperty('Birch')
local Block_Leaves = script:GetCustomProperty('Leaves')
local Block_Snow = script:GetCustomProperty('Snow')

local stonyBlocks = {Block_Stone,Block_Stone}
local topBlocks = {Block_Grass, Block_Snow}
local dirtBlocks = {Block_Dirt, Block_Snow}
local blocks = {stonyBlocks,dirtBlocks,topBlocks}
--Data Structure: Each layer 1 array is an x cord, each entry in there is a y height
local heights = {}
--Data Structure {{{{Block: asset_ref, Coreobjectref or nil, Active: bool, position, isSpawned}}}} Stored in the x, then the y, then the height
local placedBlocks = {}

--Data Structure {{x{y{Biome}}}}
local chunks = {}

local biomeHeightScales = {{55,15}, {55,15},{55,15}, {55,15}}

structure_tree_birch_1 = {
    'tree',
    {Block_Birch, Vector3.New(0,0,1)}, 
    {Block_Birch, Vector3.New(0,0,2)}, 
    {Block_Leaves, Vector3.New(0,0,3)}, 
    {Block_Leaves, Vector3.New(0,1,3)},
    {Block_Leaves, Vector3.New(0,-1,3)},
    {Block_Leaves, Vector3.New(1,1,3)},
    {Block_Leaves, Vector3.New(1,-1,3)},
    {Block_Leaves, Vector3.New(1,0,3)},
    {Block_Leaves, Vector3.New(-1,1,3)}, 
    {Block_Leaves, Vector3.New(-1,-1,3)}, 
    {Block_Leaves, Vector3.New(-1,0,3)}, 
    {Block_Leaves, Vector3.New(0,0,4)}, 
    {Block_Leaves, Vector3.New(0,1,4)},
    {Block_Leaves, Vector3.New(0,-1,4)},
    {Block_Leaves, Vector3.New(1,1,4)},
    {Block_Leaves, Vector3.New(1,-1,4)},
    {Block_Leaves, Vector3.New(1,0,4)},
    {Block_Leaves, Vector3.New(-1,1,4)}, 
    {Block_Leaves, Vector3.New(-1,-1,4)}, 
    {Block_Leaves, Vector3.New(-1,0,4)},    
}

local structures={structure_tree_birch_1}
perlin = {}

perlin.p = {}
perlin.permutation = { 151,160,137,91,90,15,
   131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
   190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
   88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
   77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
   102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
   135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
   5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
   223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
   129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
   251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
   49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
   138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
}

function shuffle(tbl)
    for i = #tbl, 2, -1 do
      local j = math.random(i)
      tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

perlin.permutation = shuffle(perlin.permutation)
perlin.size = 256
perlin.gx = {}
perlin.gy = {}
perlin.randMax = 256

function perlin:load(  )
    for i=1,self.size do
        self.p[i] = self.permutation[i]
        self.p[256+i] = self.p[i]
    end
end

function perlin:noise( x, y, z )
    local X = math.floor(x) % 256
    local Y = math.floor(y) % 256
    local Z = math.floor(z) % 256
    x = x - math.floor(x)
    y = y - math.floor(y)
    z = z - math.floor(z)
    local u = fade(x)
    local v = fade(y)
    local w = fade(z)
    local A  = self.p[X+1]+Y
    local AA = self.p[A+1]+Z
    local AB = self.p[A+2]+Z
    local B  = self.p[X+2]+Y
    local BA = self.p[B+1]+Z
    local BB = self.p[B+2]+Z

    return lerp(w, lerp(v, lerp(u, grad(self.p[AA+1], x  , y  , z  ),
                                   grad(self.p[BA+1], x-1, y  , z  )),
                           lerp(u, grad(self.p[AB+1], x  , y-1, z  ),
                                   grad(self.p[BB+1], x-1, y-1, z  ))),
                   lerp(v, lerp(u, grad(self.p[AB+2], x  , y  , z-1),
                                   grad(self.p[BA+2], x-1, y  , z-1)),
                           lerp(u, grad(self.p[AB+2], x  , y-1, z-1),
                                   grad(self.p[BB+2], x-1, y-1, z-1))))
end

function fade( t )
    return t * t * t * (t * (t * 6 - 15) + 10)
end

function lerp( t, a, b )
    return a + t * (b - a)
end

function grad( hash, x, y, z )
    local h = hash % 16
    local u = h < 8 and x or y
    local v = h < 4 and y or ((h == 12 or h == 14) and x or z)
    return ((h % 2) == 0 and u or -u) + ((h % 3) == 0 and v or -v)
end

perlin:load()  

function generateTerrain(chunk, biome, chunkExact)
    local maxheightScale = biomeHeightScales[biome][1]
    local orHeightScale = biomeHeightScales[biome][1]
    if chunks[chunkExact.x] then
        if chunks[chunkExact.x][chunkExact.y-1] then
            --print('yahoo')
            orHeightScale = biomeHeightScales[chunks[chunkExact.x][chunkExact.y-1][1]][1]
            --warn('or heightScale is '  .. orHeightScale)
            --warn(tostring(maxheightScale))
        end    
    end  
    if chunks[chunkExact.x-1] then
        if chunks[chunkExact.x-1][chunkExact.y] then
            --print('yahoo')
            orHeightScale = (orHeightScale + biomeHeightScales[chunks[chunkExact.x-1][chunkExact.y][1]][1])/2
        end    
    end  
    local heightAdd = biomeHeightScales[biome][2]
    for x = chunk.x + 1, chunk.x + 1 + xWidth do
        if not placedBlocks[x] then
            placedBlocks[x] = {}
        end
        for y=chunk.y + 1, chunk.y + 1 + yWidth do
            if not placedBlocks[x][y] then
                placedBlocks[x][y] = {}
            end
            local yDif = ((chunk.y + yWidth + 1) - y) / yWidth
            local xDif = ((chunk.x + xWidth + 1) - x) / xWidth
            local Dif = (yDif + xDif) * 2
            heightScale = CoreMath.Lerp(maxheightScale, orHeightScale, Dif)
            --print(heightScale)

            height = CoreMath.Clamp(math.floor(perlin:noise(x/20,y/20,0.1) * heightScale + heightAdd), 9, 999) 

            spawnBlock(x,y,height, true,3)
            for i=0, height - 1 do
                if height - i < 2 then
                    spawnBlock(x,y,i,false,2)  
                else    
                spawnBlock(x,y,i,false,1)  
                end
            end 
            Task.Wait(0.001)   
        end 
        --heightScale = CoreMath.Lerp(heightScale, maxheightScale, 0.1)   
    end
    cleanUpUnusedBlocks(chunk)
end

function spawnBlock(x,y,z,isTop,type)   
    local blockGroup = blocks[type]
    local block = nil
    if z > 25 then
        block = blockGroup[2]
    else    
        block = blockGroup[1]
    end
    local spawnedBlock   = nil
    if isTop then
        if z > 25 then
            spawnedBlock = World.SpawnAsset(Block_Snow, { position = Vector3.New(x*100, y*100, z*100)})
        else
            spawnedBlock = World.SpawnAsset(Block_Grass, { position = Vector3.New(x*100, y*100, z*100)})         
        end   
        local structure = math.random(1,75)
        if structures[structure] then
            spawnStructure(structures[structure], Vector3.New(x, y, z))
        end
    else
        spawnedBlock = World.SpawnAsset(block, { position = Vector3.New(x*100, y*100, z*100)})
    end    
    if block == nil then
    end     
    if placedBlocks[x][y][z] then
        if placedBlocks[x][y][z][2] then
            placedBlocks[x][y][z][2]:Destroy()
        end    
    end   
    placedBlocks[math.floor(x)][math.floor(y)][z] = {block, spawnedBlock, false, Vector3.New(x*100, y*100, z*100), true}
end 


function cleanUpUnusedBlocks(chunk)
    for x = chunk.x, chunk.x + xWidth do
        for y=chunk.y, chunk.y + yWidth do
            for z=0, 16 do
                if placedBlocks[x] then
                    if placedBlocks[x][y] then
                        if placedBlocks[x][y][z+1] and (placedBlocks[x][y][z-1] or z == 0) then
                            if placedBlocks[x+1] and placedBlocks[x-1] and placedBlocks[x][y+1] and placedBlocks[x][y-1] then
                                if placedBlocks[x+1][y] and placedBlocks[x-1][y] and placedBlocks[x][y + 1] and placedBlocks[x][y - 1] and placedBlocks[x+1][y+1] and placedBlocks[x-1][y+1] then
                                    if placedBlocks[x+1][y][z] and placedBlocks[x-1][y][z] and placedBlocks[x][y + 1][z] and placedBlocks[x][y - 1][z] and placedBlocks[x+1][y+1][z] and placedBlocks[x-1][y+1][z]then
                                        if placedBlocks[x][y][z] then                                        
                                            placedBlocks[x][y][z][3] = false
                                            placedBlocks[x][y][z][5] = false
                                            if Object.IsValid(placedBlocks[x][y][z][2]) then
                                                placedBlocks[x][y][z][2]:Destroy()
                                            end
                                        end
                                    end
                                end
                            end   
                        end    
                    end
                end
            end
        end    
    end
end    

function spawnStructure(struct, pos)
    local type
    for k, piece in pairs(struct) do
        if k > 1 then
            if type == 'tree' then
                if math.random (1,3) ~= 3 or piece[2].z < 3 then
                    local position = pos * 100 + piece[2] * 100
                    local spawnedBlock = World.SpawnAsset(piece[1], {position = position})
                    if not placedBlocks[position.x/100] then
                        placedBlocks[position.x/100] = {}
                    end    
                    if not placedBlocks[position.x/100][position.y/100] then
                        placedBlocks[position.x/100][position.y/100] = {}
                    end 
                    if placedBlocks[position.x/100][position.y/100][position.z/100] then
                        if placedBlocks[position.x/100][position.y/100][position.z/100][2] then
                            if Object.IsValid(placedBlocks[position.x/100][position.y/100][position.z/100][2]) then
                                placedBlocks[position.x/100][position.y/100][position.z/100][2]:Destroy()
                            end
                        end    
                    end    
                    placedBlocks[position.x/100][position.y/100][position.z/100] = {piece, spawnedBlock, false, position, true}
                end
            end
        else
            type = piece
        end    
    end   
end    

function getNearbyBlocks(x,y,z)
    local nearbyBlocks = {}
    if placedBlocks[x][y][z] then
        if placedBlocks[x+1] then
            if placedBlocks[x+1][y][z] then
                table.insert(nearbyBlocks, placedBlocks[x+1][y][z])
            end    
        end  
        if placedBlocks[x-1] then
            if placedBlocks[x-1][y][z] then
                table.insert(nearbyBlocks, placedBlocks[x-1][y][z])
            end    
        end   
        if placedBlocks[x][y+1] then
            if placedBlocks[x][y+1][z] then
                table.insert(nearbyBlocks, placedBlocks[x][y+1][z])
            end    
        end 
        if placedBlocks[x][y-1] then
            if placedBlocks[x][y-1][z] then
                table.insert(nearbyBlocks, placedBlocks[x][y-1][z])
            end    
        end 
        if placedBlocks[x][y][z+1] then
            table.insert(nearbyBlocks, placedBlocks[x][y][z+1])
        end   
        if placedBlocks[x][y][z-1] then
            table.insert(nearbyBlocks, placedBlocks[x][y][z-1])
        end    
    end   
    return nearbyBlocks
end    

local API = {}

function API.loadSurroundingBlocks(block)
    if block:IsA('CoreObject') then
        local x = block:GetWorldPosition().x / 100
        local y = block:GetWorldPosition().y / 100
        local z = block:GetWorldPosition().z / 100
        local nearbyBlocks = getNearbyBlocks(x,y,z)
        placedBlocks[x][y][z][3] = true
        block:Destroy() 
        if nearbyBlocks ~= {} then
            for _, surroundingBlock in pairs(nearbyBlocks) do
                if surroundingBlock[3] == false then
                    if placedBlocks[surroundingBlock[4].x/100][surroundingBlock[4].y/100][surroundingBlock[4].z/100][5] == false then
                        World.SpawnAsset(surroundingBlock[1], {position = surroundingBlock[4]})
                    end
                end    
            end   
        end
    end            
end


_G['terrainAPI'] = API
for x=1, 4 do
    for y=1,4 do
        local biome = math.random(1,1)
        generateTerrain(Vector2.New(1 + x*xWidth,1 + y*yWidth), math.random(1,2), Vector2.New(x,y))
        if not chunks[x] then
            chunks[x] = {}
        end    
        if not chunks[x][y] then
            chunks[x][y] = {}
        end    
        chunks[x][y] = {biome}
        Task.Wait(0.1)
    end
end