local Kalied = require 'Kaliedoscope'

local k

local image_index = 1
local image_paths = {
  'candyshop.jpg',
  'hologram.jpg',
  'lineart.png',
  'mask.png',
  'free-smile.jpg',
  'faces.jpg',
  'faces2.jpg',
  'rainbow.png',
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

function love.wheelmoved (_, y)
  k:alter_value('rotations', y < 0 and 'dec' or 'inc')
end

function love.mousepressed ()
  next_image()
end

function love.keypressed (key)
  if key == 'q' then
    love.event.quit()
  elseif key == 'space' then
    next_image()
  else
    local binds = {
      up = {'scroll_speed', 'inc'},
      down = {'scroll_speed', 'dec'},
      right = {'zoom', 'inc'},
      left = {'zoom', 'dec'},
      [']'] = {'contrast', 'inc'},
      ['['] = {'contrast', 'dec'},
      ['0'] = {'brightness', 'inc'},
      ['9'] = {'brightness', 'dec'},
      ['='] = {'rotations', 'inc'},
      ['-'] = {'rotations', 'dec'},
    }
    local b = binds[key]
    if b then
      k:alter_value(unpack(binds[key]))
    end
  end
end

function love.draw ()
  k:draw(dc)
  love.graphics.print('rotations: ' .. k.rotations, 0,0)
end
