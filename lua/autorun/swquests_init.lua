local function Load(rootDir, subDir)
    timer.Simple(0, function()
        SWDS = SWDS or {}

        local sharedFiles = {}
        local clientFiles = {}
        local serverFiles = {}

        -- Function to classify files based on their prefix
        local function ClassifyFile(File, dir)
            local fileSide = string.lower(string.Left(File, 3))
            local fullPath = dir .. File

            if fileSide == "sh_" then
                table.insert(sharedFiles, fullPath)
            elseif fileSide == "cl_" then
                table.insert(clientFiles, fullPath)
            elseif fileSide == "sv_" then
                table.insert(serverFiles, fullPath)
            end
        end

        -- Function to recursively find files in directories
        local function FindFiles(dir)
            dir = dir .. "/"
            local files, directories = file.Find(dir .. "*", "LUA")

            -- Classify found files
            for _, fileName in ipairs(files) do
                if string.EndsWith(fileName, ".lua") then
                    ClassifyFile(fileName, dir)
                end
            end

            -- Recursively check subdirectories
            for _, directory in ipairs(directories) do
                FindFiles(dir .. directory)
            end
        end

        -- Function to load files based on their classification
        local function LoadFiles(fileList, loadFunc)
            for _, filePath in ipairs(fileList) do
                loadFunc(filePath)
            end
        end

        -- Include or AddCSLuaFile for different file types
        local function AddShared(filePath)
            if SERVER then AddCSLuaFile(filePath) end
            include(filePath)
        end

        local function AddClient(filePath)
            if SERVER then
                AddCSLuaFile(filePath)
            elseif CLIENT then
                include(filePath)
            end
        end

        local function AddServer(filePath)
            if SERVER then
                include(filePath)
            end
        end

        -- Start the loading process
        FindFiles(rootDir)
        if subDir then
            FindFiles(rootDir .. '/' .. subDir)
        end

        -- Load shared files first
        LoadFiles(sharedFiles, AddShared)

        -- Load client files next
        LoadFiles(clientFiles, AddClient)

        -- Load server files last
        LoadFiles(serverFiles, AddServer)
    end)
end

-- Call Load function for the target directory
Load("sw_quests")
