local GUI = {
    allTrackers = {"base", "player", "rocket"}
}

local Camera = require("scripts.camera")
local ModGui = require("mod-gui")
local Tracker = require("scripts.tracker")
local Utils = require("scripts.utils")

local ticks_per_half_second = 30

local function findActiveTracker(trackers)
    for _, tracker in pairs(trackers) do
        if tracker.enabled == true then
            return tracker
        end
    end
end

function GUI.init(player)
    -- Add main button if if does not exist yet
    local buttonFlow = ModGui.get_button_flow(player)
    if buttonFlow["tlbe-main-icon"] == nil then
        buttonFlow.add {
            type = "sprite-button",
            style = ModGui.button_style,
            sprite = "tlbe-logo",
            name = "tlbe-main-icon"
        }
    end
end

function GUI.tick()
    if game.tick % ticks_per_half_second ~= 0 then
        return
    end

    -- TODO performance: Use some kind of event system to update the GUI for
    for _, player in pairs(game.players) do
        local playerSettings = global.playerSettings[player.index]
        if playerSettings.gui ~= nil then
            if playerSettings.gui.cameraInfo.valid then
                local camera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
                GUI.updateCameraInfo(playerSettings.gui.cameraInfo, camera)

                GUI.updateTrackerInfo(
                    playerSettings.gui.cameraTrackerInfo,
                    camera.trackers[playerSettings.guiPersist.selectedCameraTracker]
                )
            end

            if playerSettings.gui.cameraTrackerList.valid then
                GUI.createTrackerList(
                    playerSettings.gui.cameraTrackerList,
                    playerSettings.guiPersist.selectedCameraTracker,
                    playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                    "camera_tracker_",
                    GUI.addCameraTrackerButtons
                )
            end

            if playerSettings.gui.trackerInfo.valid then
                GUI.updateTrackerInfo(
                    playerSettings.gui.trackerInfo,
                    playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
                )
            end
        end
    end
end

function GUI.onClick(event)
    local player = game.players[event.player_index]
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-main-icon" then
        GUI.toggleMainWindow(player)
    elseif event.element.name == "tlbe-main-window-close" then
        GUI.closeMainWindow(event)
    elseif event.element.name == "tlbe_camera_enable" then
        local selectedCamera = playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        selectedCamera.enabled = not selectedCamera.enabled

        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
    elseif event.element.name == "tlbe_camera_add" then
        table.insert(playerSettings.cameras, Camera.newCamera(player, playerSettings.cameras))
        playerSettings.guiPersist.selectedCamera = #playerSettings.cameras

        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.updateCameraInfo(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tlbe_camera_delete" then
        if #playerSettings.cameras == 1 then
            -- Paranoia check
            return
        end

        table.remove(playerSettings.cameras, playerSettings.guiPersist.selectedCamera)

        if playerSettings.guiPersist.selectedCamera > #playerSettings.cameras then
            playerSettings.guiPersist.selectedCamera = #playerSettings.cameras
        end

        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.updateCameraInfo(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createCameraTrackerList(playerSettings)
    else
        local _, index
        _, _, index = event.element.name:find("^camera_tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.guiPersist.selectedCameraTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.cameraTrackerList, index)
            GUI.updateTrackerInfo(
                playerSettings.gui.cameraTrackerInfo,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers[
                    playerSettings.guiPersist.selectedCameraTracker
                ]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.guiPersist.selectedTracker = index
            GUI.fancyListBoxSelectItem(playerSettings.gui.trackerList, index)
            GUI.updateTrackerConfig(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )
            GUI.updateTrackerInfo(
                playerSettings.gui.trackerInfo,
                playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
            )
            return
        end

        _, _, index = event.element.name:find("^tracker_(%d+)_enable$")
        if index ~= nil then
            index = tonumber(index)
            playerSettings.trackers[index].enabled = playerSettings.trackers[index].enabled == false

            GUI.createTrackerList(
                playerSettings.gui.trackerList,
                playerSettings.guiPersist.selectedTracker,
                playerSettings.trackers,
                "tracker_",
                GUI.addTrackerButtons
            )

            GUI.createTrackerList(
                playerSettings.gui.cameraTrackerList,
                playerSettings.guiPersist.selectedCameraTracker,
                playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
                "camera_tracker_",
                GUI.addCameraTrackerButtons
            )
            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_up$")
        if index ~= nil then
            index = tonumber(index)
            local cameraTrackers = playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
            local tmp = cameraTrackers[index]
            cameraTrackers[index] = cameraTrackers[index - 1]
            cameraTrackers[index - 1] = tmp
            if playerSettings.guiPersist.selectedCameraTracker == index then
                playerSettings.guiPersist.selectedCameraTracker = index - 1
            elseif playerSettings.guiPersist.selectedCameraTracker == index - 1 then
                playerSettings.guiPersist.selectedCameraTracker = index
            end

            GUI.createCameraTrackerList(playerSettings)

            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_down")
        if index ~= nil then
            index = tonumber(index)
            local cameraTrackers = playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
            local tmp = cameraTrackers[index]
            cameraTrackers[index] = cameraTrackers[index + 1]
            cameraTrackers[index + 1] = tmp
            if playerSettings.guiPersist.selectedCameraTracker == index then
                playerSettings.guiPersist.selectedCameraTracker = index + 1
            elseif playerSettings.guiPersist.selectedCameraTracker == index + 1 then
                playerSettings.guiPersist.selectedCameraTracker = index
            end

            GUI.createCameraTrackerList(playerSettings)

            return
        end

        _, _, index = event.element.name:find("^camera_tracker_(%d+)_remove$")
        if index ~= nil then
            index = tonumber(index)
            table.remove(playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers, index)
            local currentIndex = playerSettings.guiPersist.selectedCameraTracker
            if currentIndex > 1 and currentIndex >= index then
                -- Select previous entry if entry above was deleted (so same entry stays selected)
                playerSettings.guiPersist.selectedCameraTracker = currentIndex - 1
            end

            GUI.createCameraTrackerList(playerSettings)

            return
        end
    end
end

function GUI.onSelected(event)
    local playerSettings = global.playerSettings[event.player_index]

    if event.element.name == "tlbe-cameras-list" then
        playerSettings.guiPersist.selectedCamera = event.element.selected_index
        playerSettings.guiPersist.selectedCameraTracker = 1

        GUI.updateCameraActions(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
        GUI.updateCameraConfig(
            playerSettings.gui.cameraInfo,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera]
        )
        GUI.createTrackerList(
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )
        GUI.createCameraTrackerList(playerSettings)
    elseif event.element.name == "tlbe-tracker-add" then
        local trackerIndex = event.element.selected_index - 1
        if trackerIndex < 1 then
            -- Paranoia check: ignore first item (placeholder) in the list
            return
        end
        event.element.selected_index = 1

        local newTracker = Tracker.newTracker(GUI.allTrackers[trackerIndex], playerSettings.trackers)
        table.insert(playerSettings.trackers, newTracker)
        playerSettings.guiPersist.selectedTracker = #playerSettings.trackers

        GUI.createTrackerList(
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
        )

        GUI.updateTrackerConfig(
            playerSettings.gui.trackerInfo,
            playerSettings.trackers[playerSettings.guiPersist.selectedTracker]
        )
    elseif event.element.name == "tlbe-camera-add-tracker" then
        if event.element.selected_index <= 1 then
            -- Paranoia check: ignore first item (placeholder) in the list
            return
        end

        local trackerToAdd = Utils.findName(playerSettings.trackers, event.element.items[event.element.selected_index])

        table.insert(playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers, trackerToAdd)
        playerSettings.guiPersist.selectedCameraTracker =
            #playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers

        GUI.createTrackerList(
            playerSettings.gui.cameraTrackerList,
            1,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
            "camera_tracker_",
            GUI.addCameraTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
        )
    end
end

function GUI.onTextChanged(event)
    local playerSettings = global.playerSettings[event.player_index]
    if event.element.name == "camera-name" then
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].name = event.element.text

        GUI.updateCameraList(playerSettings.gui, playerSettings.guiPersist, playerSettings.cameras)
    elseif event.element.name == "tracker-name" then
        playerSettings.trackers[playerSettings.guiPersist.selectedTracker].name = event.element.text

        GUI.createTrackerList(
            playerSettings.gui.trackerList,
            playerSettings.guiPersist.selectedTracker,
            playerSettings.trackers,
            "tracker_",
            GUI.addTrackerButtons
        )

        GUI.createCameraAddTracker(
            playerSettings.gui.cameraTrackerListFlow,
            playerSettings.trackers,
            playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
        )
    elseif event.element.name == "camera-resolution-x" then
        Camera.setWidth(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
    elseif event.element.name == "camera-resolution-y" then
        Camera.setHeight(playerSettings.cameras[playerSettings.guiPersist.selectedCamera], event.element.text)
    end
end

function GUI.closeMainWindow(event)
    local player = game.players[event.player_index]
    if player.gui.screen["tlbe-main-window"] ~= nil then
        player.gui.screen["tlbe-main-window"].destroy()
    end
end

function GUI.toggleMainWindow(player)
    local playerSettings = global.playerSettings[player.index]
    if player.gui.screen["tlbe-main-window"] ~= nil then
        player.gui.screen["tlbe-main-window"].destroy()
        playerSettings.gui = nil
    else
        -- Create frame without caption (we have our own title_bar)
        local mainWindow = player.gui.screen.add {type = "frame", name = "tlbe-main-window", direction = "vertical"}
        playerSettings.gui = {}
        if playerSettings.guiPersist == nil then
            playerSettings.guiPersist = {
                -- initialize persisting gui configurations
                selectedCamera = 1,
                selectedCameraTracker = 1,
                selectedTracker = 1
            }
        end

        -- Add title bar
        local title_bar = mainWindow.add {type = "flow"}
        local title = title_bar.add {type = "label", caption = "TLBE Settings", style = "frame_title"}
        title.drag_target = mainWindow

        -- Add 'dragger' (filler) between title and (close) buttons
        local dragger = title_bar.add {type = "empty-widget", style = "draggable_space_header"}
        dragger.style.vertically_stretchable = true
        dragger.style.horizontally_stretchable = true
        dragger.drag_target = mainWindow

        title_bar.add {
            type = "sprite-button",
            style = "frame_action_button",
            sprite = "utility/close_white",
            name = "tlbe-main-window-close"
        }

        local tabPane = mainWindow.add {type = "tabbed-pane"}

        local cameraTab = tabPane.add {type = "tab", caption = "Camera"}
        tabPane.add_tab(
            cameraTab,
            GUI.createCameraSettings(
                tabPane,
                playerSettings.gui,
                playerSettings.guiPersist,
                playerSettings.cameras,
                playerSettings.trackers
            )
        )

        local trackerTab = tabPane.add {type = "tab", caption = "Tracker"}
        tabPane.add_tab(
            trackerTab,
            GUI.createTrackerSettings(tabPane, playerSettings.gui, playerSettings.guiPersist, playerSettings.trackers)
        )

        mainWindow.force_auto_center()
    end
end

function GUI.createCameraSettings(parent, playerGUI, guiPersist, cameras, trackers)
    local flow = parent.add {type = "flow", direction = "vertical"}

    -- Cameras
    local cameraBox = flow.add {type = "flow"}
    local cameraLeftFlow = cameraBox.add {type = "flow", direction = "vertical", style = "tlbe_fancy_list_parent"}

    playerGUI.cameraSelector =
        cameraLeftFlow.add {
        type = "drop-down",
        name = "tlbe-cameras-list",
        caption = "cameras",
        style = "tlbe_camera_dropdown"
    }
    GUI.updateCameraList(playerGUI, guiPersist, cameras)

    playerGUI.cameraActions = cameraLeftFlow.add {type = "flow"}
    GUI.updateCameraActions(playerGUI, guiPersist, cameras)

    -- Camera info
    playerGUI.cameraInfo = cameraBox.add {type = "table", column_count = 2}
    playerGUI.cameraInfo.add {type = "label", caption = "name: "}
    playerGUI.cameraInfo.add {type = "textfield", name = "camera-name", style = "tlbe_config_textfield"}
    playerGUI.cameraInfo.add {type = "label", caption = "resolution: "}
    local resolutionFlow = playerGUI.cameraInfo.add {type = "flow", name = "camera-resolution"}
    resolutionFlow.add {
        type = "textfield",
        name = "camera-resolution-x",
        style = "tlbe_config_half_width_textfield",
        numeric = true
    }
    resolutionFlow.add {type = "label", caption = "x", style = "tlbe_config_half_width_label"}
    resolutionFlow.add {
        type = "textfield",
        name = "camera-resolution-y",
        style = "tlbe_config_half_width_textfield",
        numeric = true
    }
    playerGUI.cameraInfo.add {type = "label", caption = "position: "}
    playerGUI.cameraInfo.add {type = "label", name = "camera-position"}
    playerGUI.cameraInfo.add {type = "label", caption = "zoom: "}
    playerGUI.cameraInfo.add {type = "label", name = "camera-zoom"}
    GUI.updateCameraConfig(playerGUI.cameraInfo, cameras[guiPersist.selectedCamera])
    GUI.updateCameraInfo(playerGUI.cameraInfo, cameras[guiPersist.selectedCamera])

    -- Trackers
    flow.add {type = "line"}
    flow.add {type = "label", caption = "Trackers"}
    local trackerBox = flow.add {type = "flow"}
    playerGUI.cameraTrackerListFlow =
        trackerBox.add {type = "flow", direction = "vertical", style = "tlbe_fancy_list_parent"}
    playerGUI.cameraTrackerList =
        playerGUI.cameraTrackerListFlow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        playerGUI.cameraTrackerList,
        guiPersist.selectedCameraTracker,
        cameras[guiPersist.selectedCamera].trackers,
        "camera_tracker_",
        GUI.addCameraTrackerButtons
    )

    GUI.createCameraAddTracker(playerGUI.cameraTrackerListFlow, trackers, cameras[guiPersist.selectedCamera].trackers)

    -- Tracker info
    playerGUI.cameraTrackerInfo = trackerBox.add {type = "table", column_count = 2}
    playerGUI.cameraTrackerInfo.add {type = "label", caption = "position: "}
    playerGUI.cameraTrackerInfo.add {type = "label", name = "tracker-position"}
    playerGUI.cameraTrackerInfo.add {type = "label", caption = "size: "}
    playerGUI.cameraTrackerInfo.add {type = "label", name = "tracker-size"}
    GUI.updateTrackerInfo(
        playerGUI.cameraTrackerInfo,
        cameras[guiPersist.selectedCamera].trackers[guiPersist.selectedCameraTracker]
    )

    return flow
end

function GUI.createTrackerSettings(parent, playerGUI, guiPersist, trackers)
    local flow = parent.add {type = "flow"}
    local trackersFlow = flow.add {type = "flow", direction = "vertical", style = "tlbe_fancy_list_parent"}

    -- New tracker GUI
    trackersFlow.add {
        type = "drop-down",
        selected_index = 1,
        name = "tlbe-tracker-add",
        items = {"<new tracker>", table.unpack(GUI.allTrackers)},
        style = "tble_tracker_add_dropdown"
    }

    -- Trackers
    playerGUI.trackerList =
        trackersFlow.add {
        type = "scroll-pane",
        name = "tlbe-tracker-list",
        horizontal_scroll_policy = "never",
        style = "tlbe_tracker_list"
    }
    GUI.createTrackerList(
        playerGUI.trackerList,
        guiPersist.selectedTracker,
        trackers,
        "tracker_",
        GUI.addTrackerButtons
    )

    -- Tracker info
    playerGUI.trackerInfo = flow.add {type = "table", column_count = 2}
    playerGUI.trackerInfo.add {type = "label", caption = "name: "}
    playerGUI.trackerInfo.add {type = "textfield", name = "tracker-name", style = "tlbe_config_textfield"}
    playerGUI.trackerInfo.add {type = "label", caption = "position: "}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-position"}
    playerGUI.trackerInfo.add {type = "label", caption = "position: "}
    playerGUI.trackerInfo.add {type = "label", name = "tracker-size"}
    GUI.updateTrackerConfig(playerGUI.trackerInfo, trackers[guiPersist.selectedTracker])
    GUI.updateTrackerInfo(playerGUI.trackerInfo, trackers[guiPersist.selectedTracker])

    return flow
end

function GUI.createTrackerList(trackerList, selectedIndex, trackers, namePrefix, addTrackerButtons)
    trackerList.clear()

    for index, tracker in pairs(trackers) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end

        local trackerRow =
            trackerList.add {
            type = "frame",
            name = namePrefix .. index,
            style = style
        }

        addTrackerButtons(index, trackers, trackerRow)

        trackerRow.add {
            type = "label",
            name = namePrefix .. index,
            caption = tracker.name,
            style = "tlbe_fancy_list_box_label"
        }
    end
end

function GUI.createCameraTrackerList(playerSettings)
    GUI.createTrackerList(
        playerSettings.gui.cameraTrackerList,
        playerSettings.guiPersist.selectedCameraTracker,
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers,
        "camera_tracker_",
        GUI.addCameraTrackerButtons
    )

    GUI.createCameraAddTracker(
        playerSettings.gui.cameraTrackerListFlow,
        playerSettings.trackers,
        playerSettings.cameras[playerSettings.guiPersist.selectedCamera].trackers
    )
end

function GUI.addCameraTrackerButtons(index, trackers, trackerRow)
    local tracker = trackers[index]
    local isActiveTracker = findActiveTracker(trackers) == tracker

    local orderFlow = trackerRow.add {type = "flow", direction = "vertical"}

    if index > 1 then
        orderFlow.add {
            type = "button",
            name = "camera_tracker_" .. index .. "_up",
            style = "tlbe_order_up_button"
        }
    else
        orderFlow.add {
            type = "empty-widget",
            style = "tlbe_order_hidden_button"
        }
    end

    if index < #trackers then
        orderFlow.add {
            type = "button",
            name = "camera_tracker_" .. index .. "_down",
            style = "tlbe_order_down_button"
        }
    else
        orderFlow.add {
            type = "empty-widget",
            style = "tlbe_order_hidden_button"
        }
    end

    trackerRow.add {
        type = "sprite-button",
        name = "camera_tracker_" .. index .. "_remove",
        sprite = "utility/close_black",
        style = "tlbe_tracker_remove_button"
    }

    if isActiveTracker then
        trackerRow.add {
            type = "sprite",
            sprite = "utility/play",
            style = "tlbe_fancy_list_box_image"
        }
    else
        trackerRow.add {
            type = "empty-widget",
            style = "tlbe_fancy_list_box_button_hidden"
        }
    end
end

function GUI.addTrackerButtons(index, trackers, trackerRow)
    local sprite = "utility/pause"
    local tracker = trackers[index]
    if tracker.enabled then
        sprite = "utility/play"
    end
    if tracker.userCanEnable then
        local style = "tlbe_tracker_disabled_button"
        if tracker.enabled then
            style = "tlbe_tracker_enabled_button"
        end

        trackerRow.add {
            type = "sprite-button",
            name = "tracker_" .. index .. "_enable",
            sprite = sprite,
            style = style
        }
    else
        trackerRow.add {
            type = "sprite",
            sprite = sprite,
            style = "tlbe_fancy_list_box_button_disabled"
        }
    end
end

function GUI.createCameraAddTracker(parent, allTrackers, cameraTrackers)
    if parent["tlbe-camera-add-tracker"] ~= nil then
        parent["tlbe-camera-add-tracker"].destroy()
    end

    local availableTrackers = Utils.filterOut(allTrackers, cameraTrackers)
    if #availableTrackers > 0 then
        local availableTrackerNames = {}
        for _, tracker in pairs(availableTrackers) do
            table.insert(availableTrackerNames, tracker.name)
        end
        parent.add {
            type = "drop-down",
            selected_index = 1,
            name = "tlbe-camera-add-tracker",
            items = {"<add tracker>", table.unpack(availableTrackerNames)},
            style = "tble_tracker_add_dropdown"
        }
    end
end

function GUI.updateCameraActions(playerGUI, guiPersist, cameras)
    playerGUI.cameraActions.clear()
    local selectedCamera = cameras[guiPersist.selectedCamera]

    local sprite = "utility/pause"
    local style = "tool_button_red"
    if selectedCamera.enabled then
        style = "tool_button_green"
        sprite = "utility/play"
    end

    playerGUI.cameraActions.add {
        type = "sprite-button",
        name = "tlbe_camera_enable",
        sprite = sprite,
        style = style
    }

    playerGUI.cameraActions.add {
        type = "button",
        caption = "+",
        name = "tlbe_camera_add",
        style = "tool_button"
    }

    if #cameras == 1 then
        -- playerGUI.cameraActions.add {type = "empty-widget", style = "tlbe_tool_button_hidden"}
        playerGUI.cameraActions.add {
            enabled = false,
            tooltip = "Cannot delete last camera",
            type = "sprite-button",
            name = "tlbe_camera_delete",
            sprite = "utility/trash_bin",
            style = "tool_button"
        }
    else
        playerGUI.cameraActions.add {
            type = "sprite-button",
            name = "tlbe_camera_delete",
            sprite = "utility/trash_bin",
            style = "tool_button_red"
        }
    end
end

function GUI.updateCameraList(playerGUI, guiPersist, cameras)
    local cameraItems = {}
    for index, camera in pairs(cameras) do
        cameraItems[index] = camera.name
    end

    playerGUI.cameraSelector.items = cameraItems
    playerGUI.cameraSelector.selected_index = guiPersist.selectedCamera
end

function GUI.updateCameraConfig(cameraInfo, camera)
    local resolutionFlow = cameraInfo["camera-resolution"]
    if camera == nil then
        cameraInfo["camera-name"].enabled = false
        cameraInfo["camera-name"].text = ""
        resolutionFlow["camera-resolution-x"].text = ""
        resolutionFlow["camera-resolution-y"].text = ""
    else
        cameraInfo["camera-name"].enabled = true
        cameraInfo["camera-name"].text = camera.name
        resolutionFlow["camera-resolution-x"].text = camera.width
        resolutionFlow["camera-resolution-y"].text = camera.height
    end
end

function GUI.updateCameraInfo(cameraInfo, camera)
    if camera == nil or camera.centerPos == nil then
        cameraInfo["camera-position"].caption = "unset"
    else
        cameraInfo["camera-position"].caption = string.format("%d, %d", camera.centerPos.x, camera.centerPos.y)
    end

    if camera == nil then
        cameraInfo["camera-zoom"].caption = "unset"
    else
        cameraInfo["camera-zoom"].caption = string.format("%2.2f", camera.zoom)
    end
end

function GUI.updateTrackerConfig(trackerInfo, tracker)
    if tracker == nil then
        trackerInfo["tracker-name"].text = ""
        trackerInfo["tracker-name"].enabled = false
    else
        trackerInfo["tracker-name"].enabled = true
        trackerInfo["tracker-name"].text = tracker.name
    end
end

function GUI.updateTrackerInfo(trackerInfo, tracker)
    if tracker == nil or tracker.centerPos == nil then
        trackerInfo["tracker-position"].caption = "unset"
    else
        trackerInfo["tracker-position"].caption = string.format("%d, %d", tracker.centerPos.x, tracker.centerPos.y)
    end

    if tracker == nil or tracker.size == nil then
        trackerInfo["tracker-size"].caption = "unset"
    else
        trackerInfo["tracker-size"].caption = string.format("%d, %d", tracker.size.x, tracker.size.y)
    end
end

function GUI.fancyListBoxSelectItem(fancyList, selectedIndex)
    for index, element in pairs(fancyList.children) do
        local style = "tlbe_fancy_list_box_item"
        if index == selectedIndex then
            style = "tlbe_fancy_list_box_item_selected"
        end
        element.style = style
    end
end

return GUI
