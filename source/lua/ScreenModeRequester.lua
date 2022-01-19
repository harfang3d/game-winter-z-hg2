--[[
 ==============================================================================================================

              - HARFANG® 3D - www.harfang3d.com

                          - Lua -

                   Screen mode Requester

   Usage:
       Call request_screen_mode(ratio_filter) before Plus:RenderInit()
       ratio_filter: if you want to restrict the screen resolution to a specific ration (16/9, 4/3...)
                     0 means all resolutions appears in listing.

 ==============================================================================================================
]]--
hg = require("harfang")

local res_w=520
local res_h=160
local monitors=nil
local monitors_names={}
local modes=nil
local current_monitor=0
local current_mode=0
local ratio_filter=0
local flag_windowed=false

local screenModes={hg.WV_FullscreenMonitor1,hg.WV_FullscreenMonitor2,hg.WV_FullscreenMonitor3}
local smr_screenMode=hg.FullscreenMonitor1
local smr_resolution=hg.Vec2(1280,1024)

hg.InputInit()
hg.WindowSystemInit()

win = hg.NewWindow("Screen Mode Requester", res_w, res_h, 32)--, hg.WV_Fullscreen)
hg.RenderInit(win)
hg.RenderReset(res_w, res_h, hg.RF_MSAA8X | hg.RF_FlipAfterRender | hg.RF_FlushAfterRender | hg.RF_MaxAnisotropy | hg.RF_VSync)

hg.AddAssetsFolder("../assets_compiled")

-- initialize ImGui
imgui_prg = hg.LoadProgramFromAssets('shaders/imgui')
imgui_img_prg = hg.LoadProgramFromAssets('shaders/imgui_image')

hg.ImGuiInit(10, imgui_prg, imgui_img_prg)

function gui_ScreenModeRequester()
	dt = hg.TickClock()

	-- ImGui frame
	hg.ImGuiBeginFrame(res_w, res_h, dt, hg.ReadMouse(), hg.ReadKeyboard())
	hg.ImGuiSetNextWindowPosCenter(hg.ImGuiCond_Always)
    hg.ImGuiSetNextWindowSize(hg.Vec2(res_w, res_h), hg.ImGuiCond_Always)
    if hg.ImGuiBegin("Choose window size", true, hg.ImGuiWindowFlags_NoTitleBar | hg.ImGuiWindowFlags_MenuBar | hg.ImGuiWindowFlags_NoMove | hg.ImGuiWindowFlags_NoSavedSettings | hg.ImGuiWindowFlags_NoCollapse) then
        if hg.ImGuiBeginCombo("Monitor", monitors_names[current_monitor+1]) then
            for i=0,#monitors_names-1 do
                f = hg.ImGuiSelectable(monitors_names[i+1], current_monitor == i)
                if f then
                    current_monitor = i
                end
            end
            hg.ImGuiEndCombo()
        end
		if hg.ImGuiBeginCombo("Screen size", modes[current_monitor+1][current_mode+1].name) then
			for i=0,#modes[current_monitor+1]-1 do
				f = hg.ImGuiSelectable(modes[current_monitor+1][i+1].name.."##"..i, current_mode == i)
				if f then
                    current_mode = i
                end
            end
			hg.ImGuiEndCombo()
		end
		
		f, d = hg.ImGuiCheckbox("Windowed", flag_windowed)
		if f then
			flag_windowed = d
		end

		ok=hg.ImGuiButton("Ok")
		hg.ImGuiSameLine()
		cancel=hg.ImGuiButton("Quit")
    end
	hg.ImGuiEndFrame(0)

	if ok then return "ok"
    elseif cancel then return "quit"
    else return ""
    end
end

function request_screen_mode(p_ratio_filter)
	ratio_filter = p_ratio_filter or 0
	monitors = hg.GetMonitors()
	monitors_names = {}
	modes = {}
	for i=0,monitors:size()-1 do
		table.insert(monitors_names,hg.GetMonitorName(monitors:at(i)))
		f, m = hg.GetMonitorModes(monitors:at(i))
		table.insert(modes,{})
		for j=0,m:size()-1 do
			md=m:at(j)
			rect = md.rect
			epsilon = 0.01
			r = (rect.ex - rect.sx) / (rect.ey - rect.sy)
			if ratio_filter == 0 or ((ratio_filter>r - epsilon) and (ratio_filter < r + epsilon)) then
                table.insert(modes[i+1],md)
            end
        end
    end
	select=""
	while select=="" do
		select=gui_ScreenModeRequester()
		hg.SetView2D(0, 0, 0, res_w, res_h, -1, 1, hg.CF_Color | hg.CF_Depth, hg.Color.Black, 1, 0)
		hg.Frame()
		hg.UpdateWindow(win)
    end
    
	if select=="ok" then
		if flag_windowed then
			smr_screenMode=hg.Windowed
		else 
			smr_screenMode=screenModes[current_monitor+1]
		end
		rect=modes[current_monitor+1][current_mode+1].rect
        smr_resolution.x,smr_resolution.y=rect.ex-rect.sx,rect.ey-rect.sy
		hg.RenderShutdown()
		hg.DestroyWindow(win)
    end
	return select,smr_screenMode,smr_resolution
end