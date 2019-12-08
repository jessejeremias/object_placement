# object_placement
Allows players to simply move and place an item in the world.
(This resource is still in development and therefore subject to change)

# Basic usage
By using this resource, players will be able to place and rotate their selected object in the world with their mouse.
Upon placing their selected object, the cost of the object will be automatically deducted from the players' money.

# Export functions
For now, there's only one export function.
```LUA
-- Client
createPreview(int objectID, string objectName, int objectCost)
```

# Example
```LUA
-- Client (Additional verification should be done server-sided in-case of client data tampering)
function onClientResourceStart()
  addCommandHandler("preview", onCreatePreviewCommand)
end

function onCreatePreviewCommand(commandName, objectId, objectName, objectCost)
  objectId = objectId or 1337
  objectName = objectName or "Dumpster"
  objectCost = objectCost or 0
  
  -- This will spawn an object with the specified parameters in the world attached to the cursor.
  exports.object_placement:createPreview(objectId, objectName, objectCost)
end

addEventHandler("onClientResourceStart", resourceRoot, onClientResourceStart)
```
