local Kaleid = require 'Kaleidoscope'

local k

local image_index = 1
local image_paths = {
  'img/candyshop.jpg',
  'img/hologram.jpg',
  'img/lineart.png',
  'img/mask.png',
  'img/free-smile.jpg',
  'img/faces.jpg',
  'img/faces2.jpg',
  'img/rainbow.png',
}
local function next_image ()
  k:setImage(image_paths[image_index])
  image_index = (image_index % #image_paths) + 1
end

function love.load ()
  love.window.setMode(800,600,{fullscreen=true})
  k = Kaleid.new()
  next_image()
end

function love.mousepressed ()
  next_image()
end

function love.keypressed (_,key)
  if key == 'escape' then
    love.event.quit()
  elseif key == 'space' then
    next_image()
  else
    k:handle_keypress(key)
  end
end

function love.draw ()
  k:draw(dc)
end
