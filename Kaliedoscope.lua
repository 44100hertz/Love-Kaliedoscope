local K = {}
K.__index = K

function K.new (res_scale)
  local o = {}
  res_scale = res_scale or 1.0
  local sw, sh = love.window.getDesktopDimensions()

  -- Dimensions
  o.w = sw * res_scale
  o.h = sh * res_scale
  o.src_buf = love.graphics.newCanvas(o.w, o.h)
  o.dest_buf = love.graphics.newCanvas(o.w, o.h)
  o.shader = love.graphics.newShader('shader.glsl')

  -- Variables
  o.base_rot = 0
  o.rot = math.random()*10
  o.scale = 2.0
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
  local ww, wh = love.window.getMode()
  local sw, sh = self.scale*ww/self.w, self.scale*wh/self.h

  -- Reset textures
  self.tex_offset = (self.tex_offset + dt*self.scroll_speed) % 1.0
  self.base_rot = self.base_rot + dt*self.rotate_speed
  self.rot = math.pi * 2.0
  local function initdraw ()
    self.shader:send('offset', self.tex_offset)
    love.graphics.setColor(1,1,1,1)
    local iw, ih = self.image:getDimensions()
    local sw, sh = self.w/iw, self.h/ih
    love.graphics.draw(self.image, self.w/2, self.h/2, self.base_rot, sw, sh, iw/2, ih/2)
    self.shader:send('offset', 0.0)
  end
  self.src_buf:renderTo(initdraw)
  self.dest_buf:renderTo(initdraw)

  -- Kaliedoscope Iteration
  for i = 1,count do
    self.dest_buf:renderTo(function ()
        love.graphics.setColor(1,1,1,0.5)
        love.graphics.draw(self.src_buf, self.w/2, self.h/2, self.rot, -1,1, self.w/2, self.h/2)
    end)
    self.src_buf:renderTo(function ()
        love.graphics.setColor(1,1,1,1)
        love.graphics.draw(self.dest_buf)
    end)
    self.rot = self.rot / 2
  end

  -- Copy buffer to screen
  love.graphics.setColor(1,1,1,1)
  self.shader:send('contrast', self.contrast)
  self.shader:send('brightness', self.brightness / math.sqrt(self.contrast))
  love.graphics.draw(self.src_buf, ww/2, wh/2, 0, sw, sh, self.w/2, self.h/2)
  self.shader:send('contrast', 1.0)
  love.graphics.setShader()
end

return K
