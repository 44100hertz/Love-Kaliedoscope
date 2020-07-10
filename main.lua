local Kalied = require 'Kaliedoscope'

local k

local image_index = 1
local image_paths = {
  'candyshop.jpg',
  'hologram.jpg',
  'lineart.png',
  'mask.png',
  'free-smile.jpg',
}
local function next_image ()
  k:setImage(image_paths[image_index])
  image_index = (image_index % #image_paths) + 1
end

function love.load ()
  love.window.setMode(800,600,{fullscreen=true})
  k = Kalied.new()
  next_image()
end

local dc = 4

function love.wheelmoved (_, y)
  local off = y < 0 and -1 or 1
  dc = math.min(10, math.max(0, dc + off))
end

function love.mousepressed ()
  next_image()
end

function love.keypressed (key)
  if key == 'q' then
    love.event.quit()
  elseif key == '=' then
    dc = dc + 1
  elseif key == '-' then
    dc = dc - 1
  elseif key == 'space' then
    next_image()
  else
    local binds = {
      up = {'scroll_speed', 'inc'},
      down = {'scroll_speed', 'dec'},
      right = {'rotate_speed', 'inc'},
      left = {'rotate_speed', 'dec'},
      [']'] = {'contrast', 'inc'},
      ['['] = {'contrast', 'dec'},
      ['0'] = {'brightness', 'inc'},
      ['9'] = {'brightness', 'dec'},
    }
    local b = binds[key]
    if b then
      k:alter_value(unpack(binds[key]))
    end
  end
end

function love.draw ()
  k:draw(dc)
  love.graphics.print(string.format('Dose: %d', dc))
end
