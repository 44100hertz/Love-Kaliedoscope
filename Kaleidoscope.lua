local K = {}
K.__index = K

function K.new ()
  local o = {}

  -- Dimensions
  o.shader = love.graphics.newShader('shaders/reflect.glsl')

  -- Variables
  o.angle = math.random()
  o.offset = math.random()

  o.toggles = {}
  o.toggles.scroll = true
  o.toggles.rotate = true
  o.toggles.cycle = false
  o.toggles.filter = true

  o.scroll_speed = 0.01
  o.rotate_speed = 0.01
  o.cycle_speed = 0.2

  o.color_period = 1.0
  o.color_phase = 0
  o.mirror_level = 1.0

  o.rotations = 9
  o.zoom = 1.0
  o.last_step = love.timer.getTime()

  o.keybinds = {
      ['['] = {'rotations', 'inc'},
      [']'] = {'rotations', 'dec'},
      ['='] = {'zoom', 'inc'},
      ['-'] = {'zoom', 'dec'},

      q = {'scroll_speed', 'inc'},
      a = {'scroll_speed', 'dec'},
      z = {'scroll', 'toggle'},
      w = {'rotate_speed', 'inc'},
      s = {'rotate_speed', 'dec'},
      x = {'rotate', 'toggle'},
      e = {'cycle_speed', 'inc'},
      d = {'cycle_speed', 'dec'},
      c = {'cycle', 'toggle'},
      f = {'filter', 'toggle'},

      t = {'color_period', 'inc'},
      g = {'color_period', 'dec'},
      y = {'color_phase', 'inc'},
      h = {'color_phase', 'dec'},
      u = {'mirror_level', 'inc'},
      j = {'mirror_level', 'dec'},
  }

  return setmetatable(o, K)
end

function K:setImage (image_path)
  self.image = love.graphics.newImage(image_path)
end

function K:handle_keypress (key)
  local b = self.keybinds[key]
  if b then
    self:alter_value(unpack(b))
    return true
  else
    return false
  end
end

function K:alter_value (value, operation)
  if operation == 'toggle' then
    local v = self.toggles[value] ~= nil
    if v then
      self.toggles[value] = not self.toggles[value]
    else
      print('warning: invalid toggle:', value)
    end
    return
  end

  local ops = {
    zoom = {mul = 1.2, min = 0.1, max = 10},
    rotations = {add = 1, min = 1, max = 100},

    scroll_speed = {mul = 1.5, min = 0.002, max = 1.0},
    rotate_speed = {mul = 1.5, min = 0.002, max = 1.0},
    cycle_speed = {mul = 1.5, min = 0.05, max = 8.0},

    color_period = {mul=1.5, min=1.0, max=30.0},
    color_phase = {add = 0.2},
    mirror_level = {add = 0.5, min=-1, max=1},
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

  local deltas = {
    {'scroll','offset','scroll_speed'},
    {'rotate','angle','rotate_speed'},
    {'cycle', 'color_phase','cycle_speed'},
  }
  for _,t in ipairs(deltas) do
    local tog, var, delta = unpack(t)
    if self.toggles[tog] then
      self[var] = self[var] + dt*self[delta]
    end
  end

  local filt = self.toggles.filter and 'linear' or 'nearest'
  self.image:setFilter(filt,filt)

  local ww, wh = love.window.getMode()
  local larger = math.max(ww, wh)
  local iw, ih = self.image:getDimensions()
  local sw, sh = larger/iw, larger/ih

  love.graphics.setColor(1,1,1,1)

  self.shader:send('num_angles', self.rotations)

  self.shader:send('offset', self.offset)
  self.shader:send('angle', self.angle)
  self.shader:send('zoom', self.zoom)

  self.shader:send('color_phase', self.color_phase)
  self.shader:send('color_period', self.color_period)
  self.shader:send('mirror_level', self.mirror_level)

  love.graphics.draw(self.image, ww/2, wh/2, 0, sw, sh, iw/2, ih/2)
  love.graphics.setShader()
end

return K
