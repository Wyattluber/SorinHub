 -- SorinHub Script Loader v1.0.0
    -- Modern Script Loader für Roblox Executors
    -- Repository: https://github.com/Wyattluber/SorinHub
    -- Loadstring:
    loadstring(game:HttpGet("https://raw.githubusercontent.com/Wyattluber/SorinHub/main/ScriptLoader.lua"))()

    local TweenService = game:GetService("TweenService")
    local UserInputService = game:GetService("UserInputService")
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local CoreGui = game:GetService("CoreGui")

    local Player = Players.LocalPlayer

    -- Repository Konfiguration
    local CONFIG = {
        SUPABASE_URL = "https://iesugielppyhhvtdzsqq.supabase.co",
        EDGE_FUNCTION_URL = "https://iesugielppyhhvtdzsqq.supabase.co/functions/v1",
        ANON_KEY =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imllc3VnaWVscHB5aGh2dGR6c3FxIiwicm9sZSI6I
    mFub24iLCJpYXQiOjE3NDU4ODAyMDUsImV4cCI6MjA2MTQ1NjIwNX0.QQYxM6pz6h9IGWYGxysvW8p1KFmHk3O_RdqnpwJYE8w",

        -- GitHub Repository URLs
        GITHUB_REPO = "Wyattluber/SorinHub",
        RAW_URL = "https://raw.githubusercontent.com/Wyattluber/SorinHub/main/",
        API_URL = "https://api.github.com/repos/Wyattluber/SorinHub/contents/",

        -- UI Settings
        TITLE = "SorinHub | Script Loader",
        VERSION = "v1.0.0",
        CREATOR = "Wyatt"
    }

    -- UI-Farben (Modern Gray/Purple Theme)
    local COLORS = {
        Background = Color3.fromRGB(25, 25, 35),
        Secondary = Color3.fromRGB(35, 35, 50),
        Accent = Color3.fromRGB(120, 80, 160),
        AccentHover = Color3.fromRGB(140, 100, 180),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 200, 210),
        Success = Color3.fromRGB(80, 200, 120),
        Error = Color3.fromRGB(220, 80, 80),
        Warning = Color3.fromRGB(255, 200, 80)
    }

    -- Globale Variablen
    local SorinHub = {}
    local MainFrame
    local KeyValidated = false
    local CurrentKey = ""
    local UserData = {}
    local ScriptCache = {}

    -- Executor-Erkennung
    local function getExecutorInfo()
        local executor = "Unknown"
        local version = "Unknown"

        if identifyexecutor then
            executor, version = identifyexecutor()
        elseif syn and syn.request then
            executor = "Synapse X"
        elseif KRNL_LOADED then
            executor = "KRNL"
        elseif getgenv().solara then
            executor = "Solara"
            version = getgenv().solara.version or "Unknown"
        elseif getgenv().xeno then
            executor = "Xeno"
        elseif getgenv().volcano then
            executor = "Volcano"
        end

        return executor, version
    end

    -- HTTP Request Funktion
    local function makeRequest(url, method, data, headers)
        method = method or "GET"
        headers = headers or {}

        local requestData = {
            Url = url,
            Method = method,
            Headers = headers
        }

        if data then
            requestData.Body = HttpService:JSONEncode(data)
            headers["Content-Type"] = "application/json"
        end

        if CONFIG.ANON_KEY then
            headers["apikey"] = CONFIG.ANON_KEY
            headers["Authorization"] = "Bearer " .. CONFIG.ANON_KEY
        end

        local success, response = pcall(function()
            if syn and syn.request then
                return syn.request(requestData)
            elseif http_request then
                return http_request(requestData)
            elseif request then
                return request(requestData)
            else
                error("No HTTP request function available")
            end
        end)

        if success and response then
            return response.Success, response.Body, response.StatusCode
        else
            return false, "Request failed: " .. tostring(response), 500
        end
    end

    -- GitHub API Requests
    local function fetchFromGitHub(path)
        local url = CONFIG.API_URL .. path
        local success, response, statusCode = makeRequest(url, "GET", nil, {
            ["User-Agent"] = "SorinHub-ScriptLoader/1.0"
        })

        if success and statusCode == 200 then
            return HttpService:JSONDecode(response)
        else
            warn("GitHub API Error:", response)
            return nil
        end
    end

    -- Script von GitHub laden
    local function loadScriptFromGitHub(path)
        local url = CONFIG.RAW_URL .. path
        local success, response, statusCode = makeRequest(url, "GET", nil, {
            ["User-Agent"] = "SorinHub-ScriptLoader/1.0"
        })

        if success and statusCode == 200 then
            return response
        else
            warn("Failed to load script from:", url)
            return nil
        end
    end

    -- UI-Erstellung Funktionen
    local function createFrame(parent, name, size, position, backgroundColor, transparency)
        local frame = Instance.new("Frame")
        frame.Name = name
        frame.Size = size
        frame.Position = position
        frame.BackgroundColor3 = backgroundColor or COLORS.Background
        frame.BackgroundTransparency = transparency or 0.1
        frame.BorderSizePixel = 0
        frame.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = frame

        return frame
    end

    local function createButton(parent, name, text, size, position, callback)
        local button = Instance.new("TextButton")
        button.Name = name
        button.Text = text
        button.Size = size
        button.Position = position
        button.BackgroundColor3 = COLORS.Accent
        button.BackgroundTransparency = 0.1
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextSize = 14
        button.TextColor3 = COLORS.Text
        button.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = button

        -- Hover-Effekt mit Bounce
        local function onHover()
            local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                BackgroundColor3 = COLORS.AccentHover,
                Size = size + UDim2.new(0, 4, 0, 2)
            })
            tween:Play()
        end

        local function onLeave()
            local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                BackgroundColor3 = COLORS.Accent,
                Size = size
            })
            tween:Play()
        end

        button.MouseEnter:Connect(onHover)
        button.MouseLeave:Connect(onLeave)

        -- Click-Bounce-Effekt
        button.MouseButton1Click:Connect(function()
            local bounceIn = TweenService:Create(button, TweenInfo.new(0.1), {
                Size = size - UDim2.new(0, 8, 0, 4)
            })
            local bounceOut = TweenService:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                Size = size
            })

            bounceIn:Play()
            bounceIn.Completed:Connect(function()
                bounceOut:Play()
            end)

            if callback then
                callback()
            end
        end)

        return button
    end

    local function createTextBox(parent, name, placeholder, size, position)
        local textBox = Instance.new("TextBox")
        textBox.Name = name
        textBox.PlaceholderText = placeholder
        textBox.Size = size
        textBox.Position = position
        textBox.BackgroundColor3 = COLORS.Secondary
        textBox.BackgroundTransparency = 0.2
        textBox.BorderSizePixel = 0
        textBox.Font = Enum.Font.Gotham
        textBox.TextSize = 14
        textBox.TextColor3 = COLORS.Text
        textBox.PlaceholderColor3 = COLORS.TextSecondary
        textBox.Text = ""
        textBox.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = textBox

        return textBox
    end

    local function createLabel(parent, name, text, size, position, textSize)
        local label = Instance.new("TextLabel")
        label.Name = name
        label.Text = text
        label.Size = size
        label.Position = position
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = textSize or 16
        label.TextColor3 = COLORS.Text
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = parent

        return label
    end

    -- Key-Validierung
    local function validateKey(key)
        local hwid = gethwid and gethwid() or "unknown"

        if hwid == "unknown" then
            return false, "HWID not available - unsupported executor"
        end

        local success, response, statusCode = makeRequest(
            CONFIG.EDGE_FUNCTION_URL .. "/validate-key",
            "POST",
            {
                key = key,
                hwid = hwid,
                roblox_id = Player.UserId
            }
        )

        if success and statusCode == 200 then
            local data = HttpService:JSONDecode(response)
            if data.valid then
                KeyValidated = true
                CurrentKey = key
                UserData = data.key_data
                return true, data.message
            end
        end

        local errorData = success and HttpService:JSONDecode(response) or {error = "Connection failed"}
        return false, errorData.error or "Unknown error"
    end

    -- Tab System laden
    local function loadTabSystem()
        local tabSystemCode = loadScriptFromGitHub("TabSystem.lua")
        if tabSystemCode then
            local success, TabSystem = pcall(function()
                return loadstring(tabSystemCode)()
            end)

            if success then
                return TabSystem
            else
                warn("Failed to load TabSystem:", TabSystem)
            end
        end
        return nil
    end

    -- UI-Erstellung
    local function createMainUI()
        -- Prüfe ob bereits vorhanden
        if CoreGui:FindFirstChild("SorinHubLoader") then
            CoreGui:FindFirstChild("SorinHubLoader"):Destroy()
        end

        -- Hauptfenster
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SorinHubLoader"
        screenGui.Parent = CoreGui
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

        MainFrame = createFrame(
            screenGui,
            "MainFrame",
            UDim2.new(0, 650, 0, 450),
            UDim2.new(0.5, -325, 0.5, -225),
            COLORS.Background,
            0.05
        )

        -- Schlagschatten
        local shadow = Instance.new("ImageLabel")
        shadow.Name = "Shadow"
        shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
        shadow.ImageTransparency = 0.8
        shadow.Size = UDim2.new(1, 20, 1, 20)
        shadow.Position = UDim2.new(0, -10, 0, -10)
        shadow.ZIndex = MainFrame.ZIndex - 1
        shadow.Parent = MainFrame

        -- Titel-Bar mit Branding
        local titleBar = createFrame(
            MainFrame,
            "TitleBar",
            UDim2.new(1, 0, 0, 60),
            UDim2.new(0, 0, 0, 0),
            COLORS.Secondary,
            0.1
        )

        local titleLabel = createLabel(
            titleBar,
            "Title",
            CONFIG.TITLE,
            UDim2.new(1, -200, 0, 25),
            UDim2.new(0, 20, 0, 10),
            20
        )

        local versionLabel = createLabel(
            titleBar,
            "Version",
            CONFIG.VERSION,
            UDim2.new(0, 100, 0, 20),
            UDim2.new(1, -120, 0, 5),
            12
        )
        versionLabel.TextColor3 = COLORS.TextSecondary
        versionLabel.TextXAlignment = Enum.TextXAlignment.Right

        local creatorLabel = createLabel(
            titleBar,
            "Creator",
            "by " .. CONFIG.CREATOR,
            UDim2.new(0, 100, 0, 20),
            UDim2.new(1, -120, 0, 25),
            12
        )
        creatorLabel.TextColor3 = COLORS.Accent
        creatorLabel.TextXAlignment = Enum.TextXAlignment.Right

        -- Close Button
        local closeButton = createButton(
            titleBar,
            "CloseButton",
            "✕",
            UDim2.new(0, 30, 0, 30),
            UDim2.new(1, -40, 0, 15),
            function()
                screenGui:Destroy()
            end
        )
        closeButton.BackgroundColor3 = COLORS.Error

        -- Key-Eingabe Sektion
        local keySection = createFrame(
            MainFrame,
            "KeySection",
            UDim2.new(1, -40, 0, 180),
            UDim2.new(0, 20, 0, 80),
            COLORS.Secondary,
            0.2
        )

        local keyLabel = createLabel(
            keySection,
            "KeyLabel",
            "🔑 Enter your SorinHub access key:",
            UDim2.new(1, -20, 0, 30),
            UDim2.new(0, 15, 0, 15),
            16
        )

        local keyTextBox = createTextBox(
            keySection,
            "KeyInput",
            "Your key here...",
            UDim2.new(1, -140, 0, 40),
            UDim2.new(0, 15, 0, 50)
        )

        local validateButton = createButton(
            keySection,
            "ValidateButton",
            "Validate Key",
            UDim2.new(0, 120, 0, 40),
            UDim2.new(1, -130, 0, 50),
            function()
                local key = keyTextBox.Text
                if key == "" then
                    -- Fehler-Animation
                    local errorTween = TweenService:Create(keyTextBox, TweenInfo.new(0.1), {
                        BackgroundColor3 = COLORS.Error
                    })
                    local resetTween = TweenService:Create(keyTextBox, TweenInfo.new(0.5), {
                        BackgroundColor3 = COLORS.Secondary
                    })
                    errorTween:Play()
                    errorTween.Completed:Connect(function()
                        resetTween:Play()
                    end)
                    return
                end

                validateButton.Text = "Validating..."
                validateButton.BackgroundColor3 = COLORS.Warning

                local success, message = validateKey(key)

                if success then
                    validateButton.Text = "✓ Valid"
                    validateButton.BackgroundColor3 = COLORS.Success

                    -- Erfolgs-Animation
                    local successTween = TweenService:Create(keyTextBox, TweenInfo.new(0.3), {
                        BackgroundColor3 = COLORS.Success
                    })
                    successTween:Play()

                    wait(1)
                    showMainDashboard()
                else
                    validateButton.Text = "✗ Invalid"
                    validateButton.BackgroundColor3 = COLORS.Error

                    -- Status-Nachricht anzeigen
                    local statusLabel = keySection:FindFirstChild("StatusLabel")
                    if statusLabel then
                        statusLabel.Text = "❌ " .. message
                        statusLabel.TextColor3 = COLORS.Error
                    end

                    -- Fehler-Animation
                    local errorTween = TweenService:Create(keyTextBox, TweenInfo.new(0.1), {
                        BackgroundColor3 = COLORS.Error
                    })
                    local resetTween = TweenService:Create(keyTextBox, TweenInfo.new(0.5), {
                        BackgroundColor3 = COLORS.Secondary
                    })
                    errorTween:Play()
                    errorTween.Completed:Connect(function()
                        resetTween:Play()
                    end)

                    wait(2)
                    validateButton.Text = "Validate Key"
                    validateButton.BackgroundColor3 = COLORS.Accent
                end
            end
        )

        local statusLabel = createLabel(
            keySection,
            "StatusLabel",
            "Ready to validate key",
            UDim2.new(1, -20, 0, 30),
            UDim2.new(0, 15, 1, -45),
            12
        )
        statusLabel.TextColor3 = COLORS.TextSecondary

        -- Footer mit Repository Link
        local footerLabel = createLabel(
            keySection,
            "Footer",
            "🌐 Repository: github.com/Wyattluber/SorinHub",
            UDim2.new(1, -20, 0, 20),
            UDim2.new(0, 15, 1, -25),
            10
        )
        footerLabel.TextColor3 = COLORS.TextSecondary

        return screenGui
    end

    -- Hauptdashboard nach erfolgreicher Key-Validierung
    function showMainDashboard()
        -- Key-Sektion ausblenden
        local keySection = MainFrame:FindFirstChild("KeySection")
        if keySection then
            local hideTween = TweenService:Create(keySection, TweenInfo.new(0.5), {
                Position = UDim2.new(0, -700, 0, 80),
                BackgroundTransparency = 1
            })
            hideTween:Play()
            hideTween.Completed:Connect(function()
                keySection:Destroy()
            end)
        end

        -- Dashboard erstellen
        local dashboard = createFrame(
            MainFrame,
            "Dashboard",
            UDim2.new(1, -40, 1, -140),
            UDim2.new(0, 20, 0, 80),
            COLORS.Secondary,
            0.2
        )

        -- Benutzer-Info Header
        local userInfo = createFrame(
            dashboard,
            "UserInfo",
            UDim2.new(1, -20, 0, 90),
            UDim2.new(0, 10, 0, 10),
            COLORS.Background,
            0.3
        )

        local welcomeLabel = createLabel(
            userInfo,
            "Welcome",
            "🎉 Welcome to SorinHub, " .. Player.Name .. "!",
            UDim2.new(1, -20, 0, 25),
            UDim2.new(0, 15, 0, 10),
            18
        )

        local playerIdLabel = createLabel(
            userInfo,
            "PlayerId",
            "👤 Player ID: " .. Player.UserId,
            UDim2.new(0.5, -10, 0, 20),
            UDim2.new(0, 15, 0, 35),
            12
        )
        playerIdLabel.TextColor3 = COLORS.TextSecondary

        local executorName, executorVersion = getExecutorInfo()
        local executorLabel = createLabel(
            userInfo,
            "Executor",
            "⚡ Executor: " .. executorName .. " " .. executorVersion,
            UDim2.new(0.5, -10, 0, 20),
            UDim2.new(0.5, 0, 0, 35),
            12
        )
        executorLabel.TextColor3 = COLORS.TextSecondary

        local gameLabel = createLabel(
            userInfo,
            "Game",
            "🎮 Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
            UDim2.new(1, -20, 0, 20),
            UDim2.new(0, 15, 0, 55),
            12
        )
        gameLabel.TextColor3 = COLORS.Accent

        -- Tab-System laden und initialisieren
        local TabSystem = loadTabSystem()

        if TabSystem then
            -- Tab Container
            local tabContainer = createFrame(
                dashboard,
                "TabContainer",
                UDim2.new(1, -20, 1, -120),
                UDim2.new(0, 10, 0, 110),
                COLORS.Background,
                0.4
            )

            -- Tab-System initialisieren
            TabSystem.init(tabContainer, CONFIG)
        else
            -- Fallback wenn TabSystem nicht geladen werden kann
            local errorLabel = createLabel(
                dashboard,
                "ErrorLabel",
                "⚠️ Tab system could not be loaded.\nPlease check your internet connection.",
                UDim2.new(1, -20, 1, -120),
                UDim2.new(0, 10, 0, 110),
                14
            )
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.TextYAlignment = Enum.TextYAlignment.Center
            errorLabel.TextColor3 = COLORS.Error
        end

        -- Dashboard einblenden mit Animation
        dashboard.Position = UDim2.new(0, 700, 0, 80)
        local showTween = TweenService:Create(dashboard, TweenInfo.new(0.6, Enum.EasingStyle.Back), {
            Position = UDim2.new(0, 20, 0, 80)
        })
        showTween:Play()
    end

    -- Draggable-Funktionalität
    local function makeDraggable(frame)
        local dragging = false
        local dragInput, mousePos, framePos

        local function updateInput(input)
            local delta = input.Position - mousePos
            local newPos = UDim2.new(
                framePos.X.Scale,
                framePos.X.Offset + delta.X,
                framePos.Y.Scale,
                framePos.Y.Offset + delta.Y
            )

            -- Smooth drag with bounce
            local tween = TweenService:Create(frame, TweenInfo.new(0.1), {Position = newPos})
            tween:Play()
        end

        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                mousePos = input.Position
                framePos = frame.Position

                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                updateInput(input)
            end
        end)
    end

    -- Loader initialisieren
    local function initializeSorinHub()
        print("🚀 Initializing SorinHub Script Loader...")
        print("📁 Repository: https://github.com/Wyattluber/SorinHub")
        print("👤 Creator: " .. CONFIG.CREATOR)
        print("🎯 Version: " .. CONFIG.VERSION)

        local gui = createMainUI()
        makeDraggable(MainFrame)

        -- Spectacular intro animation
        MainFrame.Size = UDim2.new(0, 0, 0, 0)
        MainFrame.Rotation = 180

        local introTween = TweenService:Create(MainFrame, TweenInfo.new(1.0, Enum.EasingStyle.Back), {
            Size = UDim2.new(0, 650, 0, 450),
            Rotation = 0
        })
        introTween:Play()

        local executorName, executorVersion = getExecutorInfo()
        print("⚡ Detected Executor: " .. executorName .. " " .. executorVersion)
        print("✅ SorinHub loaded successfully!")
    end

    -- Export für weitere Module
    SorinHub.Init = initializeSorinHub
    SorinHub.ValidateKey = validateKey
    SorinHub.Config = CONFIG
    SorinHub.LoadScript = loadScriptFromGitHub

    -- Auto-Start
    initializeSorinHub()

    return SorinHub
