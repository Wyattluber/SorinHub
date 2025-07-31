-- SorinHub Tab System v1.0.0
    -- Automatisches Script-Loading aus GitHub Repository
    -- Repository: https://github.com/Wyattluber/SorinHub

    local TweenService = game:GetService("TweenService")
    local HttpService = game:GetService("HttpService")
    local Players = game:GetService("Players")

    local Player = Players.LocalPlayer
    local TabSystem = {}
    TabSystem.ActiveTab = nil
    TabSystem.Tabs = {}
    TabSystem.Scripts = {}
    TabSystem.Config = nil

    -- Farben aus dem Hauptscript
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

        headers["User-Agent"] = "SorinHub-TabSystem/1.0"

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

    -- GitHub Repository Scanner
    local function scanGitHubRepository()
        if not TabSystem.Config then
            warn("TabSystem: No config provided")
            return {}
        end

        local categories = {}
        local scriptsPath = TabSystem.Config.API_URL .. "scripts"

        -- Scripts-Ordner scannen
        local success, response, statusCode = makeRequest(scriptsPath)
        if not success or statusCode ~= 200 then
            warn("Failed to scan repository:", response)
            return {}
        end

        local repoData = HttpService:JSONDecode(response)

        -- Durch alle Ordner iterieren
        for _, item in pairs(repoData) do
            if item.type == "dir" then
                local categoryName = item.name
                local categoryPath = "scripts/" .. categoryName .. "/_category.json"

                -- Kategorie-Metadaten laden
                local categoryUrl = TabSystem.Config.API_URL .. categoryPath
                local catSuccess, catResponse, catStatusCode = makeRequest(categoryUrl)

                if catSuccess and catStatusCode == 200 then
                    local categoryFile = HttpService:JSONDecode(catResponse)
                    if categoryFile.content then
                        -- Base64 decode
                        local categoryData = game:GetService("HttpService"):JSONDecode(
                            game:GetService("HttpService"):base64Decode(categoryFile.content)
                        )

                        categories[categoryName] = categoryData

                        -- Scripts für diese Kategorie laden
                        TabSystem.Scripts[categoryName] = {}
                        if categoryData.scripts then
                            for _, scriptInfo in pairs(categoryData.scripts) do
                                scriptInfo.category = categoryName
                                table.insert(TabSystem.Scripts[categoryName], scriptInfo)
                            end
                        end

                        print("✅ Loaded category:", categoryName, "with", #(categoryData.scripts or {}),
    "scripts")
                    end
                else
                    warn("Failed to load category metadata for:", categoryName)
                    -- Fallback-Kategorie erstellen
                    categories[categoryName] = {
                        category = categoryName,
                        icon = "📁",
                        description = "Scripts in " .. categoryName,
                        color = "#7C50A0",
                        priority = 999
                    }
                    TabSystem.Scripts[categoryName] = {}
                end
            end
        end

        return categories
    end

    -- Tab erstellen
    function TabSystem.createTab(parent, tabData, index)
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. tabData.category
        tabButton.Text = (tabData.icon or "📁") .. " " .. tabData.category
        tabButton.Size = UDim2.new(0, 130, 0, 40)
        tabButton.Position = UDim2.new(0, (index - 1) * 135, 0, 0)
        tabButton.BackgroundColor3 = COLORS.Secondary
        tabButton.BackgroundTransparency = 0.3
        tabButton.BorderSizePixel = 0
        tabButton.Font = Enum.Font.GothamBold
        tabButton.TextSize = 12
        tabButton.TextColor3 = COLORS.TextSecondary
        tabButton.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = tabButton

        -- Aktiver Tab-Indikator
        local activeIndicator = Instance.new("Frame")
        activeIndicator.Name = "ActiveIndicator"
        activeIndicator.Size = UDim2.new(1, 0, 0, 4)
        activeIndicator.Position = UDim2.new(0, 0, 1, -4)
        activeIndicator.BackgroundColor3 = COLORS.Accent
        activeIndicator.BorderSizePixel = 0
        activeIndicator.BackgroundTransparency = 1
        activeIndicator.Parent = tabButton

        local indicatorCorner = Instance.new("UICorner")
        indicatorCorner.CornerRadius = UDim.new(0, 2)
        indicatorCorner.Parent = activeIndicator

        TabSystem.Tabs[tabData.category] = {
            button = tabButton,
            indicator = activeIndicator,
            data = tabData,
            content = nil
        }

        -- Click-Handler
        tabButton.MouseButton1Click:Connect(function()
            TabSystem.switchToTab(tabData.category)
        end)

        -- Hover-Effekte mit Bounce
        tabButton.MouseEnter:Connect(function()
            if TabSystem.ActiveTab ~= tabData.category then
                local tween = TweenService:Create(tabButton, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                    BackgroundColor3 = COLORS.Accent,
                    BackgroundTransparency = 0.1,
                    TextColor3 = COLORS.Text,
                    Size = UDim2.new(0, 135, 0, 42)
                })
                tween:Play()
            end
        end)

        tabButton.MouseLeave:Connect(function()
            if TabSystem.ActiveTab ~= tabData.category then
                local tween = TweenService:Create(tabButton, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
                    BackgroundColor3 = COLORS.Secondary,
                    BackgroundTransparency = 0.3,
                    TextColor3 = COLORS.TextSecondary,
                    Size = UDim2.new(0, 130, 0, 40)
                })
                tween:Play()
            end
        end)

        return tabButton
    end

    -- Tab-Inhalt erstellen
    function TabSystem.createTabContent(parent, tabName)
        local content = Instance.new("ScrollingFrame")
        content.Name = "Content_" .. tabName
        content.Size = UDim2.new(1, 0, 1, -60)
        content.Position = UDim2.new(0, 0, 0, 60)
        content.BackgroundTransparency = 1
        content.BorderSizePixel = 0
        content.ScrollBarThickness = 10
        content.ScrollBarImageColor3 = COLORS.Accent
        content.CanvasSize = UDim2.new(0, 0, 0, 0)
        content.Parent = parent
        content.Visible = false

        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 12)
        layout.Parent = content

        -- Auto-resize Canvas
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            content.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 30)
        end)

        TabSystem.Tabs[tabName].content = content
        return content
    end

    -- Script-Item erstellen (Enhanced Design)
    function TabSystem.createScriptItem(parent, scriptData)
        local item = Instance.new("Frame")
        item.Name = "ScriptItem_" .. (scriptData.name or "Unknown")
        item.Size = UDim2.new(1, -20, 0, 80)
        item.BackgroundColor3 = COLORS.Secondary
        item.BackgroundTransparency = 0.1
        item.BorderSizePixel = 0
        item.Parent = parent

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 12)
        corner.Parent = item

        -- Linker Akzent-Streifen
        local accentStripe = Instance.new("Frame")
        accentStripe.Name = "AccentStripe"
        accentStripe.Size = UDim2.new(0, 4, 1, 0)
        accentStripe.Position = UDim2.new(0, 0, 0, 0)
        accentStripe.BackgroundColor3 = scriptData.verified and COLORS.Success or COLORS.Accent
        accentStripe.BorderSizePixel = 0
        accentStripe.Parent = item

        local stripeCorner = Instance.new("UICorner")
        stripeCorner.CornerRadius = UDim.new(0, 12)
        stripeCorner.Parent = accentStripe

        -- Script-Name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "ScriptName"
        nameLabel.Text = (scriptData.verified and "✅ " or "") .. (scriptData.name or "Unknown Script")
        nameLabel.Size = UDim2.new(0.6, -30, 0, 25)
        nameLabel.Position = UDim2.new(0, 20, 0, 8)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextSize = 15
        nameLabel.TextColor3 = COLORS.Text
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.Parent = item

        -- Script-Beschreibung
        local descLabel = Instance.new("TextLabel")
        descLabel.Name = "ScriptDesc"
        descLabel.Text = scriptData.description or "No description available"
        descLabel.Size = UDim2.new(0.6, -30, 0, 18)
        descLabel.Position = UDim2.new(0, 20, 0, 30)
        descLabel.BackgroundTransparency = 1
        descLabel.Font = Enum.Font.Gotham
        descLabel.TextSize = 12
        descLabel.TextColor3 = COLORS.TextSecondary
        descLabel.TextXAlignment = Enum.TextXAlignment.Left
        descLabel.Parent = item

        -- Author & Version Info
        local infoLabel = Instance.new("TextLabel")
        infoLabel.Name = "InfoLabel"
        infoLabel.Text = "👤 " .. (scriptData.author or "Unknown") .. " | 🔢 " .. (scriptData.version or "v1.0")
        infoLabel.Size = UDim2.new(0.6, -30, 0, 15)
        infoLabel.Position = UDim2.new(0, 20, 0, 50)
        infoLabel.BackgroundTransparency = 1
        infoLabel.Font = Enum.Font.Gotham
        infoLabel.TextSize = 10
        infoLabel.TextColor3 = COLORS.TextSecondary
        infoLabel.TextXAlignment = Enum.TextXAlignment.Left
        infoLabel.Parent = item

        -- Status-Indikator
        local statusFrame = Instance.new("Frame")
        statusFrame.Name = "StatusFrame"
        statusFrame.Size = UDim2.new(0, 80, 0, 25)
        statusFrame.Position = UDim2.new(1, -190, 0, 8)
        statusFrame.BackgroundColor3 = scriptData.working and COLORS.Success or COLORS.Error
        statusFrame.BackgroundTransparency = 0.2
        statusFrame.BorderSizePixel = 0
        statusFrame.Parent = item

        local statusCorner = Instance.new("UICorner")
        statusCorner.CornerRadius = UDim.new(0, 6)
        statusCorner.Parent = statusFrame

        local statusLabel = Instance.new("TextLabel")
        statusLabel.Text = scriptData.working and "✅ Working" or "❌ Broken"
        statusLabel.Size = UDim2.new(1, 0, 1, 0)
        statusLabel.BackgroundTransparency = 1
        statusLabel.Font = Enum.Font.GothamBold
        statusLabel.TextSize = 10
        statusLabel.TextColor3 = COLORS.Text
        statusLabel.Parent = statusFrame

        -- Ausführen-Button
        local executeButton = Instance.new("TextButton")
        executeButton.Name = "ExecuteButton"
        executeButton.Text = "🚀 Execute"
        executeButton.Size = UDim2.new(0, 90, 0, 35)
        executeButton.Position = UDim2.new(1, -100, 0.5, -17)
        executeButton.BackgroundColor3 = COLORS.Accent
        executeButton.BackgroundTransparency = 0.1
        executeButton.BorderSizePixel = 0
        executeButton.Font = Enum.Font.GothamBold
        executeButton.TextSize = 12
        executeButton.TextColor3 = COLORS.Text
        executeButton.Parent = item

        local executeCorner = Instance.new("UICorner")
        executeCorner.CornerRadius = UDim.new(0, 8)
        executeCorner.Parent = executeButton

        -- Button-Funktionalität
        executeButton.MouseButton1Click:Connect(function()
            TabSystem.executeScript(scriptData)
        end)

        -- Hover-Effekte für das gesamte Item
        item.MouseEnter:Connect(function()
            local tween = TweenService:Create(item, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Background,
                BackgroundTransparency = 0,
                Size = UDim2.new(1, -15, 0, 85)
            })
            tween:Play()

            -- Execute Button Hover
            local buttonTween = TweenService:Create(executeButton, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.AccentHover,
                Size = UDim2.new(0, 95, 0, 38)
            })
            buttonTween:Play()
        end)

        item.MouseLeave:Connect(function()
            local tween = TweenService:Create(item, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Secondary,
                BackgroundTransparency = 0.1,
                Size = UDim2.new(1, -20, 0, 80)
            })
            tween:Play()

            -- Execute Button Reset
            local buttonTween = TweenService:Create(executeButton, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Accent,
                Size = UDim2.new(0, 90, 0, 35)
            })
            buttonTween:Play()
        end)

        return item
    end

    -- Tab wechseln
    function TabSystem.switchToTab(tabName)
        if TabSystem.ActiveTab == tabName then return end

        -- Alte Tab deaktivieren
        if TabSystem.ActiveTab and TabSystem.Tabs[TabSystem.ActiveTab] then
            local oldTab = TabSystem.Tabs[TabSystem.ActiveTab]

            -- Button zurücksetzen
            local resetButtonTween = TweenService:Create(oldTab.button, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Secondary,
                BackgroundTransparency = 0.3,
                TextColor3 = COLORS.TextSecondary,
                Size = UDim2.new(0, 130, 0, 40)
            })
            resetButtonTween:Play()

            -- Indikator verstecken
            local hideIndicatorTween = TweenService:Create(oldTab.indicator, TweenInfo.new(0.3), {
                BackgroundTransparency = 1
            })
            hideIndicatorTween:Play()

            -- Content verstecken
            if oldTab.content then
                oldTab.content.Visible = false
            end
        end

        -- Neue Tab aktivieren
        local newTab = TabSystem.Tabs[tabName]
        if newTab then
            TabSystem.ActiveTab = tabName

            -- Button aktivieren
            local activateButtonTween = TweenService:Create(newTab.button, TweenInfo.new(0.3), {
                BackgroundColor3 = COLORS.Accent,
                BackgroundTransparency = 0.1,
                TextColor3 = COLORS.Text,
                Size = UDim2.new(0, 135, 0, 42)
            })
            activateButtonTween:Play()

            -- Indikator zeigen
            local showIndicatorTween = TweenService:Create(newTab.indicator, TweenInfo.new(0.3), {
                BackgroundTransparency = 0
            })
            showIndicatorTween:Play()

            -- Content zeigen
            if newTab.content then
                newTab.content.Visible = true
            end

            -- Scripts für diese Kategorie laden
            TabSystem.loadScriptsForTab(tabName)
        end
    end

    -- Scripts für Tab laden
    function TabSystem.loadScriptsForTab(tabName)
        if not TabSystem.Tabs[tabName] or not TabSystem.Tabs[tabName].content then return end

        local content = TabSystem.Tabs[tabName].content

        -- Bestehende Scripts löschen
        for _, child in pairs(content:GetChildren()) do
            if child.Name:match("^ScriptItem_") then
                child:Destroy()
            end
        end

        -- Loading-Indikator
        local loadingLabel = Instance.new("TextLabel")
        loadingLabel.Name = "LoadingLabel"
        loadingLabel.Text = "🔄 Loading scripts..."
        loadingLabel.Size = UDim2.new(1, -20, 0, 50)
        loadingLabel.BackgroundTransparency = 1
        loadingLabel.Font = Enum.Font.GothamBold
        loadingLabel.TextSize = 16
        loadingLabel.TextColor3 = COLORS.TextSecondary
        loadingLabel.TextXAlignment = Enum.TextXAlignment.Center
        loadingLabel.TextYAlignment = Enum.TextYAlignment.Center
        loadingLabel.Parent = content

        -- Scripts für diese Kategorie anzeigen
        local scripts = TabSystem.Scripts[tabName] or {}

        wait(0.5) -- Kurze Verzögerung für Loading-Effekt
        loadingLabel:Destroy()

        if #scripts == 0 then
            -- Keine Scripts gefunden
            local noScriptsLabel = Instance.new("TextLabel")
            noScriptsLabel.Name = "NoScriptsLabel"
            noScriptsLabel.Text = "📭 No scripts available in this category"
            noScriptsLabel.Size = UDim2.new(1, -20, 0, 100)
            noScriptsLabel.BackgroundTransparency = 1
            noScriptsLabel.Font = Enum.Font.Gotham
            noScriptsLabel.TextSize = 14
            noScriptsLabel.TextColor3 = COLORS.TextSecondary
            noScriptsLabel.TextXAlignment = Enum.TextXAlignment.Center
            noScriptsLabel.TextYAlignment = Enum.TextYAlignment.Center
            noScriptsLabel.Parent = content
        else
            -- Scripts anzeigen
            for i, scriptData in pairs(scripts) do
                wait(0.1) -- Gestaffelte Animation
                local scriptItem = TabSystem.createScriptItem(content, scriptData)

                -- Einblende-Animation
                scriptItem.BackgroundTransparency = 1
                scriptItem.Size = UDim2.new(1, -20, 0, 0)

                local showTween = TweenService:Create(scriptItem, TweenInfo.new(0.3 + (i * 0.05)), {
                    BackgroundTransparency = 0.1,
                    Size = UDim2.new(1, -20, 0, 80)
                })
                showTween:Play()
            end
        end
    end

    -- Script ausführen
    function TabSystem.executeScript(scriptData)
        print("🚀 Executing script:", scriptData.name)

        if not TabSystem.Config then
            warn("❌ No config available for script execution")
            return
        end

        if scriptData.file then
            -- Script aus Repository laden
            local scriptPath = "scripts/" .. (scriptData.category or "universal") .. "/" .. scriptData.file
            local scriptUrl = TabSystem.Config.RAW_URL .. scriptPath

            local success, response, statusCode = makeRequest(scriptUrl)
            if success and statusCode == 200 then
                local executeSuccess, result = pcall(function()
                    loadstring(response)()
                end)

                if executeSuccess then
                    print("✅ Script executed successfully:", scriptData.name)
                else
                    warn("❌ Script execution failed:", result)
                end
            else
                warn("❌ Failed to load script from repository:", scriptUrl)
            end
        elseif scriptData.loadstring_url then
            -- Externe Loadstring ausführen
            local success, response, statusCode = makeRequest(scriptData.loadstring_url)
            if success and statusCode == 200 then
                local executeSuccess, result = pcall(function()
                    loadstring(response)()
                end)

                if executeSuccess then
                    print("✅ Loadstring executed successfully:", scriptData.name)
                else
                    warn("❌ Loadstring execution failed:", result)
                end
            else
                warn("❌ Failed to load loadstring:", scriptData.loadstring_url)
            end
        else
            warn("❌ No executable content found for script:", scriptData.name)
        end
    end

    -- Tab-System initialisieren
    function TabSystem.init(parent, config)
        TabSystem.Config = config

        print("🔄 Initializing SorinHub Tab System...")

        local tabContainer = Instance.new("Frame")
        tabContainer.Name = "TabContainer"
        tabContainer.Size = UDim2.new(1, 0, 1, 0)
        tabContainer.BackgroundTransparency = 1
        tabContainer.Parent = parent

        -- Tab-Header
        local tabHeader = Instance.new("Frame")
        tabHeader.Name = "TabHeader"
        tabHeader.Size = UDim2.new(1, 0, 0, 50)
        tabHeader.BackgroundTransparency = 1
        tabHeader.Parent = tabContainer

        -- Repository scannen
        local categories = scanGitHubRepository()

        if next(categories) == nil then
            -- Fallback wenn Repository nicht erreichbar
            local errorLabel = Instance.new("TextLabel")
            errorLabel.Text = "❌ Could not load scripts from repository.\nPlease check your internet connection."
            errorLabel.Size = UDim2.new(1, -20, 1, -20)
            errorLabel.Position = UDim2.new(0, 10, 0, 10)
            errorLabel.BackgroundTransparency = 1
            errorLabel.Font = Enum.Font.Gotham
            errorLabel.TextSize = 14
            errorLabel.TextColor3 = COLORS.Error
            errorLabel.TextXAlignment = Enum.TextXAlignment.Center
            errorLabel.TextYAlignment = Enum.TextYAlignment.Center
            errorLabel.Parent = tabContainer
            return tabContainer
        end

        -- Kategorien nach Priorität sortieren
        local sortedCategories = {}
        for _, categoryData in pairs(categories) do
            table.insert(sortedCategories, categoryData)
        end

        table.sort(sortedCategories, function(a, b)
            return (a.priority or 999) < (b.priority or 999)
        end)

        -- Tabs erstellen
        for i, categoryData in ipairs(sortedCategories) do
            TabSystem.createTab(tabHeader, categoryData, i)
            TabSystem.createTabContent(tabContainer, categoryData.category)
        end

        -- Erste Tab aktivieren
        if #sortedCategories > 0 then
            TabSystem.switchToTab(sortedCategories[1].category)
        end

        print("✅ Tab System initialized with", #sortedCategories, "categories")

        return tabContainer
    end

    return TabSystem
