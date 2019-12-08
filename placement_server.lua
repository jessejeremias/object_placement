addEvent("placement:create", true)

function placement_create(model, x, y, z, rx, ry, rz, cost, name)
	if ( client.money < cost ) then
		outputChatBox("* You lack the amount of money to purchase this product.", client, 255, 0, 0)
		return false
	end

	local object = Object(model, x, y, z, rx, ry, rz)
	local accountId = client:getData("account:id")

	-- Set object properties
	object:setData("object:owner", accountId, true)

	-- Finalize transaction
	client.money = math.min(client.money - cost, 0)

	-- Send confirmation
	exports.notices:addNotification(client, "Purchase successful", "success");
end

addEventHandler("placement:create", root, placement_create)