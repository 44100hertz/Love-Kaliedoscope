local K = {}
K.__index = K

function K.new (res_scale)
  local o = {}
  res_scale = res_scale or 1.0
  local sw, sh = love.window.getDesktopDimensions()
  local res = math.min(sw, sh) * res_scale

  -- Dimensions
  o.w = res
  o.h = res
  o.src_buf = love.graphics.newCanvas(o.w, o.h)
  o.dest_buf = love.graphics.newCanvas(o.w, o.h)
  o.shader = love.graphics.newShader('shader.glsl')

  -- Variables
  o.base_rot = 0
  o.rot = math.random()*10
  o.tex_offset = math.random()
  o.scroll_speed = 0.0131
  o.rotate_speed = 0.0611
  o.contrast = 2.0
  o.brightness = 0.0
  o.last_step = love.timer.getTime()
  return setmetatable(o, K)
end

function K:setImage (image_path)
  self.image = love.graphics.newImage(image_path)
end

function K:alter_value (value, operation, amount)
  -- Shoulda used lisp :PPPP
  local default_ops = {
    rotate_speed = {mul = 1.5, div = 1.5},
    scroll_speed = {mul = 1.5, div = 1.5},
    contrast = {mul = 1.5, div = 1.5},
    brightness = {add = 0.02, sub = 0.02},
    iterations = {add = 1, sub = 1},
  }
  local op_functions = {
    mul = function (a,b) return a*b end,
    div = function (a,b) return a/b end,
    add = function (a,b) return a+b end,
    sub = function (a,b) return a-b end,
  }
  local ops = default_ops[value]
  if ops then
    -- Aliases
    if operation == 'inc' then operation = (ops.add and 'add' or 'mul') end
    if operation == 'dec' then operation = (ops.sub and 'sub' or 'div') end

    -- Putting it together
    local default = ops[operation]
    local func = op_functions[operation]
    if func then
      self[value] = func(self[value], amount or default)
      return
    end
  end
  print('warning: bad operation', value, operation)
end

function K:draw (count)
  local dt = love.timer.getTime() - self.last_step
  self.last_step = self.last_step + dt

  love.graphics.setShader(self.shader)

  -- Reset textures
  self.tex_offset = (self.tex_offset + dt*self.scroll_speed) % 1.0
  self.base_rot = self.base_rot + dt*self.rotate_speed
  self.rot = math.pi * 2.0

  self.shader:send('rotation', self.base_rot)
  self.shader:send('offset', self.tex_offset)

  local function initdraw ()
    love.graphics.setColor(1,1,1,1)
    local iw, ih = self.image:getDimensions()
    local sw, sh = self.w/iw, self.h/ih
    love.graphics.draw(self.image, 0, 0, 0, sw, sh)
  end
  self.src_buf:renderTo(initdraw)
  self.dest_buf:renderTo(initdraw)

  self.shader:send('rotation', 0)
  self.shader:send('offset', 0)

  -- Kaliedoscope Iteration
  for i = 1,count do
    self.dest_buf:renderTo(function ()
        love.graphics.setColor(1,1,1,1)
        self.shader:send('rotation', self.rot)
        local bw, bh = self.src_buf:getDimensions()
        love.graphics.draw(self.src_buf, bw,0,0, -1,1)
        self.shader:send('rotation', 0)
    end)
    self.src_buf:renderTo(function ()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.draw(self.dest_buf)
    end)
    self.rot = self.rot / 2
  end

  -- Copy buffer to screen
  local ww, wh = love.window.getMode()
  local scale = math.max(ww/self.w, wh/self.h)
  love.graphics.setColor(1,1,1,1)
  self.shader:send('contrast', self.contrast)
  self.shader:send('brightness', self.brightness / math.sqrt(self.contrast))
  love.graphics.draw(self.src_buf, ww/2, wh/2, 0, scale, scale, self.w/2, self.h/2)
  self.shader:send('contrast', 1.0)
  love.graphics.setShader()
end

return K