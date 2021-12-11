local K = {}
K.__index = K

function K.defaults ()
  return {
    values = {
      zoom         = 1.0,
      num_angles   = 9,

      scroll_speed = 0.01,
      rotate_speed = 0.01,
      cycle_speed  = 0.2,

      color_rate   = 1.0,
      color_phase  = 0.0,

      mirror_level = 1.0,
      feedback_level = 0.5,

      offset = math.random(),
      angle = math.random(),
      cycle = 0,
    },
    toggles = {
      scroll = true,
      rotate = true,
      cycle = false,
      filter = true,
      info = false,
      feedback = false,
    }
  }
end

function K.new ()
  local o = {}

  o.canvas_size = 1000
  o.shader = love.graphics.newShader('shaders/reflect.glsl')

  o.adjustments = {
    zoom         = {mul = 1.2, min = 0.1,   max = 10},
    num_angles   = {add = 1,   min = 1,     max = 100},

    scroll_speed = {mul = 1.5, min = 0.002, max = 1.0},
    rotate_speed = {mul = 1.5, min = 0.002, max = 1.0},
    cycle_speed  = {mul = 1.5, min = 0.05,  max = 8.0},

    color_rate   = {mul = 1.5, min=1.0,     max=100.0},
    color_phase  = {add = 0.2},
    mirror_level = {add = 0.5, min=-1,      max=1},

    feedback_level = {default = 0.5, add = 0.05, min=0.05, max = 0.95},
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
    ['o'] = {'feedback_level', 'inc'},
    ['l'] = {'feedback_level', 'dec'},
    ['.'] = {'feedback', 'toggle'},

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
  for k,v in pairs(self:defaults()) do self[k] = v end
end

function K:setImage (image_path)
  self.image = love.graphics.newImage(image_path)
end

function K:handle_keypress (key)
  if key == 'escape' then love.quit() end
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

  -- Set up shader parameters
  --
  -- Constantly changing parameters such as scrolling
  local scrolling_params = {
    offset = {toggle = 'scroll', delta = 'scroll_speed'},
    angle = {toggle = 'rotate', delta = 'rotate_speed'},
    color_phase = {toggle = 'cycle', delta = 'cycle_speed'},
  }
  for param,v in pairs(scrolling_params) do
    if self.toggles[v.toggle] then
      print(param, v.delta)
      self.values[param] = self.values[param] + dt*self.values[v.delta]
    end
  end
  -- Uniforms
  local uniforms = {
    'num_angles','offset','angle','zoom','color_phase','color_rate','mirror_level'
  }
  for _,uniform in ipairs(uniforms) do
    self.shader:send(uniform, self.values[uniform])
  end
  -- Scaling Filter
  local filt = self.toggles.filter and 'linear' or 'nearest'
  self.image:setFilter(filt,filt)

  if not self.toggles.feedback then
    -- No Feedback
    self.canvas_a = nil
    self.canvas_b = nil
    -- Scale with aspect
    love.graphics.setColor(1,1,1,1)
    love.graphics.setShader(self.shader)
    self:draw_fullscreen_crop(self.image)
    love.graphics.setShader()
  else
    local ss = self.canvas_size
    if not self.canvas_a then
      self.canvas_a = love.graphics.newCanvas(ss, ss)
      self.canvas_b = love.graphics.newCanvas(ss, ss)
    end
    -- Complex Feedback
    self.canvas_b:renderTo(function ()
        -- Render a copy of the input image to the inner canvas
        love.graphics.setShader()
        love.graphics.setColor(1,1,1,1)
        self:draw_to_size_stretch(self.image, ss, ss)
        love.graphics.setShader(self.shader)
        self.shader:send('color_phase', 0)
        self.shader:send('color_rate', 1)
        -- Render a copy of the Kaliedoscope canvas to the inner canvas
        love.graphics.setColor(1,1,1,self.values.feedback_level)
        love.graphics.draw(self.canvas_a)
        self.shader:send('color_phase', self.values.color_phase)
        self.shader:send('color_rate', self.values.color_rate / (1.0 - self.values.feedback_level))
    end)
    -- Render the kaliedoscope
    love.graphics.setColor(1,1,1,1)
    self:draw_fullscreen_crop(self.canvas_b)
    love.graphics.setShader()
    self.canvas_a, self.canvas_b = self.canvas_b, self.canvas_a
  end

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

-- Render something to 100% fill specified width and height
function K:draw_to_size_stretch(texture, w, h)
  local iw, ih = texture:getDimensions()
  love.graphics.draw(texture, 0, 0, 0, w/iw, h/ih)
end

-- Render something to the screen while preserving its aspect ratio.
function K:draw_fullscreen_crop(texture)
  local ww, wh = love.window.getMode()
  local iw, ih = texture:getDimensions()
  local larger = math.max(ww, wh)
  local sw, sh = larger/iw, larger/ih
  love.graphics.draw(texture, ww/2, wh/2, 0, sw, sh, iw/2, ih/2)
end

return K
