local Modal = {}

function Modal.open(scene, id, component, opts)
  opts = opts or {}
  local layerOpts = {}

  for key, value in pairs(opts) do
    layerOpts[key] = value
  end

  layerOpts.kind = "modal"
  layerOpts.blocking = layerOpts.blocking ~= false
  layerOpts.align = layerOpts.align or "center"
  layerOpts.backdrop = layerOpts.backdrop ~= false

  return scene:push(id, component, layerOpts)
end

function Modal.close(scene, id)
  if id == nil then
    return scene:pop()
  end
  return scene:close(id)
end

function Modal.closeAll(scene)
  return scene:clear(function(layer)
    return layer.kind == "modal"
  end)
end

function Modal.isOpen(scene, id)
  local _, layer = scene:findIndex(id)
  return layer ~= nil and layer.kind == "modal" and layer.state ~= "exiting"
end

return Modal
