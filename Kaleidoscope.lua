local K = {}
K.__index = K

function K.new ()
  local o = {}

  -- Dimensions
  o.shader = love.graphics.newShader('shaders/reflect.glsl')

  -- Variables
  o.tex_offset = math.random()
  o.scroll_speed = 0.0131
  o.contrast = 1.5
  o.brightness = 0
  o.rotations = 9
  o.zoom = 1.0
  o.last_step = love.timer.getTime()
  return setmetatable(o, K)
end

function K:setImage (image_path)
  self.image = love.graphics.newImage(image_path)
  self.image:setFilter('nearest','nearest')
end

function K:alter_value (value, operation)
  local ops = {
    scroll_speed = {mul = 1.5},
    zoom = {mul = 1.2},
    contrast = {mul = 1.5},
    brightness = {add = 0.2},
    rotations = {add = 1, min = 1, max = 100},
  }
  local o = ops[value]
  if o then
    if o.mul then
      self[value] = operation == 'inc' and self[value]*o.mul or self[value]/o.mul
    elseif o.add then
      self[value] = operation == 'inc' and self[value]+o.add or self[value]-o.add
    end
    if o.min then self[value] = math.max(o.min, self[value]) end
    if o.max then self[value] = math.min(o.max, self[value]) end
  else
    print('warning: bad operation', value, operation)
  end
end

function K:draw ()
  local dt = love.timer.getTime() - self.last_step
  self.last_step = self.last_step + dt

  love.graphics.setShader(self.shader)

  self.tex_offset = self.tex_offset + dt*self.scroll_speed

  local ww, wh = love.window.getMode()
  local larger = math.max(ww, wh)
  local iw, ih = self.image:getDimensions()
  local sw, sh = larger/iw, larger/ih

  love.graphics.setColor(1,1,1,1)
  self.shader:send('offset', self.tex_offset)
  self.shader:send('zoom', self.zoom)
  self.shader:send('num_angles', self.rotations)
  self.shader:send('brightness', self.brightness)
  self.shader:send('contrast', self.contrast)

  love.graphics.draw(self.image, ww/2, wh/2, 0, sw, sh, iw/2, ih/2)
  love.graphics.setShader()
end

return K
