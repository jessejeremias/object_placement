local global 	= exports.global
local fonts 	= exports.fonts

local screenWidth, screenHeight = guiGetScreenSize()
local testShader, tec 			= nil, nil
local greenShader 				= nil
local previewObj 				= nil
local previewObjName			= ""
local previewObjCost			= 999999999
local defaultFont 				= nil
local firstClickDisabled		= false
local rotZ 						= 0
local obstructed				= false

function onClientResourceStart()
	
	defaultFont 	= fonts:getFont("circular", "medium")
	testShader, tec = dxCreateShader( "fx/block_world.fx", 0, 0, false, "object" )

	if not testShader then
		global:print( "Could not create shader. Please use debugscript 3" )
	else
		greenShader = dxCreateShader( "fx/block_world.fx", 0, 0, false, "object" )
	end
end

function createPreview(objectId, objectName, objectCost)
	if ( isElement( previewObj )) then
		outputChatBox("* Cancel your current object placement first.", 255, 0, 0)
		return false
	end

	previewObjName = objectName or "object"
	previewObjCost = objectCost or 999999999

	local playerPos = localPlayer:getPosition()

	-- Prevents opening the menu whilst placing objects
	localPlayer:setData("preview:enabled", true)

	previewObj = Object(objectId, playerPos)
	previewObj:setCollisionsEnabled(false)
	previewObj:setAlpha(150)
	previewObj:setData("store:preview", true)

	showCursor(true)
	bindKey("mouse1", "DOWN", placement_place)
	bindKey("mouse2", "DOWN", placement_destroy)
	bindKey("mouse_wheel_up", "both", placement_rotate)
	bindKey("mouse_wheel_down", "both", placement_rotate)

	if ( greenShader ) then
		engineApplyShaderToWorldTexture( greenShader, string.format("*"), previewObj)
		engineRemoveShaderFromWorldTexture( greenShader, "tx*" )
		dxSetShaderValue ( greenShader, "COLORIZE", 0, 0.9, 0 )
	end

	addEventHandler("onClientCursorMove", root, placement_move)
	addEventHandler("onClientRender", root, placement_render)
end

function placement_rotate( key )
	if ( key == "mouse_wheel_up" ) then
		rotZ = ( rotZ < 360 ) and rotZ + 10 or 0
	else
		rotZ = ( rotZ > 0 ) and rotZ - 10 or 360
	end

	previewObj:setRotation(0, 0, rotZ)
end

function placement_place()
	if ( obstructed ) then
		return false
	end

	if ( firstClickDisabled ) then
		firstClickDisabled = false
		return false
	end

	local previewPosition = previewObj.position
	local previewRotation = previewObj.rotation
	local previewModel = previewObj.model

	local x, y, z = previewPosition.x, previewPosition.y, previewPosition.z
	local rx, ry, rz = previewRotation.x, previewRotation.y, previewRotation.z

	triggerServerEvent("placement:create", root, previewModel, x, y, z, rx, ry, rz, previewObjCost, previewObjName )
	placement_destroy()
end

function placement_destroy()
	if ( isElement(previewObj)) then
		destroyElement(previewObj)
	end

	rotZ = 0
	showCursor(false)
	unbindKey("mouse1", "DOWN", placement_place)
	unbindKey("mouse2", "DOWN", placement_destroy)
	unbindKey("mouse_wheel_up", "both", placement_rotate)
	unbindKey("mouse_wheel_down", "both", placement_rotate)
	removeEventHandler("onClientCursorMove", root, placement_move)
	removeEventHandler("onClientRender", root, placement_render)
end

function placement_move(cursorX, cursorY, absX, absY, worldX, worldY, worldZ)
	if ( isElement( previewObj ) and isCursorShowing() ) then
		local camX, camY, camZ = getCameraMatrix()
		local hit, hitX, hitY, hitZ = processLineOfSight(camX, camY, camZ, worldX, worldY, worldZ, true, false, true, false, false, false, false, false, localPlayer )

		if ( hit ) then
			local ground = getGroundPosition(hitX, hitY, hitZ)
			local x, y, z = getElementPosition(previewObj)
			local x0, y0, z0, x1, y1, z1 = getElementBoundingBox( previewObj )

			local hitLeft = processLineOfSight( x + ( x0 / 1.5 ), y, z + 0.5, x + ( x1 / 1.5 ), y, z + 0.5, true, true, true, true, true, false, false, false, previewObj )
			local hitRight = processLineOfSight( x - ( x0 / 1.5 ), y, z + 0.5, x - ( x1 / 1.5 ), y, z + 0.5, true, true, true, true, true, false, false, false, previewObj )

			local hitTop = processLineOfSight( x, y + y0, z + 0.5, x, y + ( y1 + 0.5), z + 0.5, true, true, true, true, true, false, false, false, previewObj )
			local hitBottom = processLineOfSight( x, y - y0, z + 0.5, x, y - ( y1 + 0.5), z + 0.5, true, true, true, true, true, false, false, false, previewObj )

			local hitDiagonal = processLineOfSight( x + x0, y, z + 0.5, x + x1, y + y1, z + 0.5, true, true, true, true, true, false, false, false, previewObj )

			if ( hitLeft or hitRight or hitTop or hitBottom or hitDiagonal ) then
				obstructed = true
				dxSetShaderValue ( greenShader, "COLORIZE", 0.9, 0, 0 )
			else
				obstructed = false
				dxSetShaderValue ( greenShader, "COLORIZE", 0, 0.9, 0 )
			end

			previewObj:setPosition(global:round(hitX, 1), global:round(hitY, 1), hitZ)
		end
	end
end

function placement_render()
	local cX, cY = getCursorPosition()
	local sX, sY = screenWidth * cX, screenHeight * cY
	local fontScale = 0.8

	local text = "Left-click to place #FFAA00" .. previewObjName .. "#FFFFFF\nRight-click to cancel\nScroll to rotate object"
	local textWidth = dxGetTextWidth( text, fontScale, defaultFont, true )
	local fontHeight = dxGetFontHeight(fontScale, defaultFont)

	dxDrawRectangle( sX + 5, sY + 10, textWidth + 10, fontHeight * 3 + 5, tocolor(40,40,40,255))
	dxDrawText(text, sX + 10, sY + 11, screenWidth, screenHeight, tocolor(255,255,255,255), fontScale, defaultFont, "left", "top", false, false, false, true )
end

addEventHandler( "onClientResourceStart", resourceRoot, onClientResourceStart )