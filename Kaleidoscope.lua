local K = {}
K.__index = K

function K.new ()
  local o = {}

  o.shader = love.graphics.newShader('shaders/reflect.glsl')

  o.adjustments = {
    zoom         = {default = 1.0, mul = 1.2, min = 0.1,   max = 10},
    num_angles   = {default = 9,   add = 1,   min = 1,     max = 100},

    scroll_speed = {default = 0.01,mul = 1.5, min = 0.002, max = 1.0},
    rotate_speed = {default = 0.01,mul = 1.5, min = 0.002, max = 1.0},
    cycle_speed  = {default = 0.2, mul = 1.5, min = 0.05,  max = 8.0},

    color_rate   = {default = 1.0, mul = 1.5, min=1.0,     max=100.0},
    color_phase  = {default = 0.0, add = 0.2},
    mirror_level = {default = 1.0, add = 0.5, min=-1,      max=1},
  }

  o.keybinds = {
      [']'] = {'num_angles', 'inc'},
      ['['] = {'num_angles', 'dec'},
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
      i = {'info', 'toggle'},

      t = {'color_rate', 'inc'},
      g = {'color_rate', 'dec'},
      y = {'color_phase', 'inc'},
      h = {'color_phase', 'dec'},
      u = {'mirror_level', 'inc'},
      j = {'mirror_level', 'dec'},
  }

  o.keybinds_by_value = {}
  for key,vvv in pairs(o.keybinds) do
    local value, op = unpack(vvv)
    if not o.keybinds_by_value[value] then
      o.keybinds_by_value[value] = {}
    end
    o.keybinds_by_value[value][op] = key
  end

  o.last_step = love.timer.getTime()

  o.values = {
    angle = math.random(),
    offset = math.random(),
  }

  setmetatable(o, K)
  o:default_values()

  return o
end

function K:default_values ()
  self.toggles = {
    scroll = true,
    rotate = true,
    cycle = false,
    filter = true,
    info = false,
  }
  for k,a in pairs(self.adjustments) do
    self.values[k] = a.default
  end
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

  local o = self.adjustments[value]
  if o then
    local vs = self.values
    if o.mul then
      vs[value] = operation == 'inc' and vs[value]*o.mul or vs[value]/o.mul
    elseif o.add then
      vs[value] = operation == 'inc' and vs[value]+o.add or vs[value]-o.add
    end
    if o.min then vs[value] = math.max(o.min, vs[value]) end
    if o.max then vs[value] = math.min(o.max, vs[value]) end
  else
    print('warning: bad operation', value, operation)
  end
end

function K:draw ()
  local dt = love.timer.getTime() - self.last_step
  self.last_step = self.last_step + dt

  love.graphics.setShader(self.shader)

  local adjustable_params = {
    offset = {toggle = 'scroll', delta = 'scroll_speed'},
    angle = {toggle = 'rotate', delta = 'rotate_speed'},
    color_phase = {toggle = 'cycle', delta = 'cycle_speed'},
  }
  for param,v in pairs(adjustable_params) do
    if self.toggles[v.toggle] then
      self.values[param] = self.values[param] + dt*self.values[v.delta]
    end
  end

  local uniforms = {
    'num_angles','offset','angle','zoom','color_phase','color_rate','mirror_level'
  }
  for _,uniform in ipairs(uniforms) do
    self.shader:send(uniform, self.values[uniform])
  end

  local filt = self.toggles.filter and 'linear' or 'nearest'
  self.image:setFilter(filt,filt)

  local ww, wh = love.window.getMode()
  local iw, ih = self.image:getDimensions()
  local larger = math.max(ww, wh)
  local sw, sh = larger/iw, larger/ih

  love.graphics.setColor(1,1,1,1)

  love.graphics.draw(self.image, ww/2, wh/2, 0, sw, sh, iw/2, ih/2)
  love.graphics.setShader()

  if self.toggles.info then
    local t = {}
    for k,v in pairs(self.toggles) do
      local kk = self.keybinds_by_value[k]
      local keystr = kk and string.format('(%s)',kk.toggle) or ''
      t[#t+1] = string.format('self.toggles.%s = %s %s',k,v,keystr)
    end
    for k,v in pairs(self.values) do
      local kk = self.keybinds_by_value[k]
      local keystr = kk and string.format('(%s/%s)',kk.inc,kk.dec) or ''
      t[#t+1] = string.format('self.values.%s = %s %s',k,v,keystr)
    end
    local f = love.graphics.getFont()
    local s = table.concat(t,'\n')
    local w,h = f:getWidth(s)+40, f:getHeight() * #t + 40
    love.graphics.setColor(0,0,0,0.7)
    love.graphics.rectangle('fill',0,0,w,h)
    love.graphics.setColor(1,1,1,1)
    love.graphics.print(s, 20, 20)
  end
end

return K
