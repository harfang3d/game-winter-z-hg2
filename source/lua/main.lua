--[[

 ===========================================================

			  - HARFANG® 3D - www.harfang3d.com

					- Lua tutorial -

				   WinterZ - Main module

		   Original created by Wizital (Jerôme Sentex)

 ===========================================================
]]


hg = require("harfang")
smr = require("ScreenModeRequester")



-- ===================================================================================================

--   Classes

-- ===================================================================================================

local Main = {
	-- Display settings:
	plus = nil,
	z_depth = 100,
	original_resolution = hg.Vec2(455, 256),
	resolution = hg.Vec2(1280, 720),
	game_scale = 0,
	antialiasing = 0,
	screenMode = hg.Windowed,

	-- --- Sprites:
	sprites = {},
	ship = nil,
	flames = nil,

	-- --- Game parameters:
	scrolls_x = {},
	scrolling_speed = 0,
	distance_min = 26 * 3.5,
	num_doors = 4,
	num_pillars_bottom = 16,
	doors_counter = 0,
	pillars_doors = {},
	pillars_bottom = {},
	animations = {},

    game_speed = {easy = 0.8, normal = 1.0, hard = 1.05},
    collision_accuracy = { easy = 0.5, normal = 0.75, hard = 1.0},
    difficulty_level = "normal",

	score = 0,
	score_max = 0,

	delta_t = 0,

	-- --- Flash:
	collision_time = 0,
	flash_delay = 0.5,

	-- --- Sfx:
	audio = nil,
	sounds = {}
}



local Sprite =
{
	color = nil,
	position = nil,
	position_prec = nil,
	vertices = nil,
	texture = nil,
	textureinfo = nil,
	scale = nil,
	center = nil
}

function Sprite:new( fileName, scale, center)
		o={}
		setmetatable(o,self)
		self.__index=self
		o.color = hg.Color.White
		o.position = hg.Vec2(0, 0)
		o.position_prec = hg.Vec2(0, 0)
		o.vertices = hg.Vertices(vtx_layout, 4)
		o.texture, o.textureinfo = hg.LoadTextureFromAssets(fileName, hg.TF_UClamp | hg.TF_VClamp | hg.TF_SamplerMinPoint | hg.TF_SamplerMagPoint)
		o.scale = scale
		if center == nil then
			o.center = hg.Vec2(o.textureinfo.width / 2, o.textureinfo.height / 2)
		else
			o.center = hg.Vec2(center)
		end
		return o
end

function Sprite:draw(position, color)
		--if position == nil then
		--	position = self.position
		--end
		--if color == nil then
		--	color = self.color
		--end
		--dimensions = hg.Vec2(self.textureinfo.width, self.textureinfo.height)
		--p0 = self.center * -self.scale + hg.Vec2(position.x * Main.resolution.x, position.y * Main.resolution.y)
		--p1 = p0 + dimensions * self.scale
		--Main.plus:Quad2D(p0.x, p0.y, p0.x, p1.y, p1.x, p1.y, p1.x, p0.y, color, color, color, color, self.texture)
		self:draw_rot(0, position, color)
end
		
function Sprite:draw_rot(angle, position, color)
		if position == nil then
			position = self.position
		end
		if color == nil then
			color = self.color
		end
		w, h = self.textureinfo.width, self.textureinfo.height
		-- Rotate:
		p0 = self.center * -1
		p1 = p0 + hg.Vec2(w, h)
		Main.z_depth = Main.z_depth - 0.1

		mat = hg.TransformationMat4(
			hg.Vec3(position.x * Main.resolution.x, position.y * Main.resolution.y, 0), hg.Vec3(0, 0, angle),
			hg.Vec3(self.scale, self.scale, 1))

		self.vertices:Clear()
		self.vertices:Begin(0):SetPos(mat * hg.Vec3(p0.x, p0.y, Main.z_depth)):SetTexCoord0(hg.Vec2(0, 1)):End()
		self.vertices:Begin(1):SetPos(mat * hg.Vec3(p0.x, p1.y, Main.z_depth)):SetTexCoord0(hg.Vec2(0, 0)):End()
		self.vertices:Begin(2):SetPos(mat * hg.Vec3(p1.x, p1.y, Main.z_depth)):SetTexCoord0(hg.Vec2(1, 0)):End()
		self.vertices:Begin(3):SetPos(mat * hg.Vec3(p1.x, p0.y, Main.z_depth)):SetTexCoord0(hg.Vec2(1, 1)):End()
		quad_idx = {0, 3, 2, 0, 2, 1}

		-- Display:
		uniformvalues = hg.MakeUniformSetValue("color", hg.Vec4(color.r, color.g, color.b, color.a))
		hg.DrawTriangles(0, quad_idx, self.vertices, shader_texture, {uniformvalues}, {hg.MakeUniformSetTexture("s_texTexture", self.texture, 0)}, render_state_quad)


end
						 
function Sprite:set_center(cx, cy)
	self.center.x, self.center.y = cx, cy
end
	
function Sprite:get_width()
	return self.textureinfo.width
end
	
function Sprite:get_height()
	return self.textureinfo.width
end


local SpriteAnimator = {
		sprite = nil,
		start_position = nil,
		start_color = nil,
		end_color = nil,
		end_position = nil,
		duration = 0.25,
		start_delay = 0,
		start_date = -1
}

function SpriteAnimator:new(sprite, end_position, end_color, start_delay,duration)
		o={}
		setmetatable(o,self)
		self.__index=self
		o.sprite = sprite
		o.start_position = hg.Vec2(sprite.position)
		o.start_color = sprite.color
		o.end_color = end_color
		o.end_position = end_position
		o.duration = duration
		o.start_delay = start_delay
		o.start_date = -1
		return o
end
	
function SpriteAnimator:update_animation(tm)

	-- Start animation:
	if self.start_date < 0 then
		self.start_date = tm
		return true
	end
		
	-- Interpolate position / orientation / color:
	if self.start_date + self.start_delay < tm then
		if self.start_date + self.duration + self.start_delay > tm then
			tl = (tm - self.start_date - self.start_delay) / self.duration
			t = math.sin(tl * math.pi / 2)^4
			self.sprite.position = (self.start_position * (1 - t) + self.end_position * t)
			self.sprite.color = hg.Color(self.start_color * (1 - tl) + self.end_color * tl)
			return true

		-- End of animation:
		else
			return false
		end
	else
		return false
	end
end

local SpriteInstance={
	sprite = nil,
	position = nil
}

function SpriteInstance:new(sprite,position)
		o={}
		setmetatable(o,self)
		self.__index=self
		o.sprite = sprite
		o.position = hg.Vec2(position)
		return o
end

function SpriteInstance:draw()
		self.sprite:draw(self.position,nil)
end

local Ship = {
	position = nil,
	frames = nil,
	angle = 0,
	frame = 0,
	y_speed = 0,
	gravity = 4,
	booster_delay = 0.25,
	booster_counter = 0,
	is_broken = false,
	broken_face = false,
	width = 32,
	height = 16
}

function Ship:new(frames)
		o={}
		setmetatable(o,self)
		self.__index=self
		o.position = hg.Vec2(1 / 3, 0)
		o.frames = frames
		o.angle = 0
		o.frame = 0
		o.y_speed = 0
		o.gravity = 4
		o.booster_delay = 0.25
		o.booster_counter = 0
		o.is_broken = false
		o.broken_face = false
		o.width = 32
		o.height = 16
		return o
end

function Ship:inc_frame()
		self.frame = (self.frame+1) % 4
end
		
function Ship:draw()
		self.frames[self.frame+1]:draw_rot(self.angle, self.position, nil)
end
		
function Ship:start_booster()
		self.booster_counter = self.booster_delay
		self.y_speed = 1
end
		
function Ship:waiting()
	self:inc_frame()
	self.position.y = 0.67 + convy(5) * math.sin(hg.time_to_sec_f(hg.GetClock()) * 4)
end
	
function Ship:update_kinetic()
	-- Sprite animation:
	if self.booster_counter > 0 then
		self.booster_counter = self.booster_counter - Main.delta_t
		self:inc_frame()
	else
		self.frame = 0
	end

	-- Gravity and ground clamp:
	if self.position.y > convx(80) then
		self.y_speed = self.y_speed - self.gravity * Main.delta_t
		self.position.y = self.position.y + self.y_speed * Main.delta_t
	else
		self.position.y = convx(80)
	end
		
	-- Rotation:
	angle_max = 30
	self.angle = math.rad(math.max(math.min(self.y_speed * angle_max, angle_max), -angle_max))
end

function Ship:reset()
	self.y_speed = 0
	self.is_broken = false
	self.broken_face = false
	self.angle = 0
end


local Particle = {
	position = nil,
	angle = 0,
	color = nil,
	age = -1,
	scale = 1,
	x_speed = 0
}

function Particle:new()
		o={}
		setmetatable(o,self)
		self.__index=self
		o.position = nil
		o.angle = 0
		o.color = nil
		o.age = -1
		o.scale = 1
		o.x_speed = 0
		return o
end

local ParticlesEngine={
		particles_cnt = 0,
		particles_cnt_f = 0,
		sprite = sprite,
		main_scale = 0,
		start_scale = 0.5,
		end_scale = 1,
		num_particles = 24,
		flames_delay = 1,
		flow = 8,
		particles_delay = 3,
		y_speed = 0.2,
		particles = nil,
		min_scale = 0.75,
		max_scale = 1.25
}
		
function ParticlesEngine:new(sprite)
		o={}
		setmetatable(o,self)
		self.__index=self
		o.particles_cnt = 0
		o.particles_cnt_f = 0
		o.sprite = sprite
		o.main_scale = sprite.scale
		o.start_scale = 0.5
		o.end_scale = 1
		o.num_particles = 24
		o.flames_delay = 1
		o.flow = 8
		o.particles_delay = 3
		o.y_speed = 0.2
		o.particles = {}
		o.min_scale = 0.75
		o.max_scale = 1.25
		return o
end
		
function ParticlesEngine:reset()
	self.particles_cnt = 0
	self.particles_cnt_f = 0
	self.particles = {}
	for n=0,self.num_particles-1,1 do
		particle=Particle:new()
		table.insert(self.particles,particle)
	end
end
		
function ParticlesEngine:draw(position, scrool_x_speed)
	if Main.collision_time < self.flames_delay then
		f = Main.collision_time / self.flames_delay
		color = hg.Color(hg.Color.White * 1 - f + hg.Color.Black * f)
		self.min_scale = 1
		self.max_scale = 3
	else
		color = hg.Color(hg.Color.Black)
		self.min_scale = 0.75
		self.max_scale = 1.25
	end
		
	self.particles_cnt_f = self.particles_cnt_f + Main.delta_t * self.flow
	n = math.floor(self.particles_cnt_f) - self.particles_cnt
	if n > 0 then
		for i=0,n-1,1
		do
			particle = self.particles[((self.particles_cnt + i) % self.num_particles) + 1]
			particle.scale = uniform(self.min_scale, self.max_scale)
			particle.color = color
			particle.color.a = math.max(0.5, 1 - (particle.scale - self.min_scale) / (self.max_scale - self.min_scale))
			particle.age = 0
			particle.position = hg.Vec2(position)

			particle.x_speed = uniform(-0.02, 0.02)
		end
		self.particles_cnt = self.particles_cnt + n
	end
		
	for i,particle in pairs(self.particles) do
		if particle.age >= 0 and particle.age < self.particles_delay then
			particle.position.y = particle.position.y+ Main.delta_t * self.y_speed
			particle.position.x = particle.position.x + scrool_x_speed + particle.x_speed * Main.delta_t
			particle.angle = particle.angle - 1.8 * Main.delta_t
			particle.age = particle.age + Main.delta_t
			t = particle.age / self.particles_delay
			self.sprite.scale = self.main_scale * particle.scale * (self.start_scale * (1 - t) + self.end_scale * t)
			color = hg.Color(particle.color)
			color.a = color.a * (1 - t)
			self.sprite:draw_rot(particle.angle, particle.position, color)
		end
	end
end

-- ===================================================================================================

--   Functions

-- ===================================================================================================

function uniform(vmin,vmax)
	return math.random()*(vmax-vmin)+vmin
end

function convx(x)
	return x * Main.game_scale / Main.resolution.x
end

function convy(y)
	return y * Main.game_scale / Main.resolution.y
end

function init_game()
	-- --- Sprites:
	init_sprites()

	Main.ship = Ship:new(Main.sprites["ship"])
	Main.flames = ParticlesEngine:new(Main.sprites["explode"])

	-- --- Sfx:
	Main.sounds = {["collision"] = hg.LoadWAVSoundAsset("pipecollision.wav"),
				   ["crash"] = hg.LoadWAVSoundAsset("crash.wav"),
				   ["checkpoint"] = hg.LoadWAVSoundAsset("pipe.wav"),
				   ["thrust"]  = hg.LoadWAVSoundAsset("thrust.wav")}

	-- --- Game parameters:
	Main.scrolls_x = {0,0,0,0,0,0,0,0,0,0}
	Main.distance_min = 26 * 3
	Main.num_doors = 4
	Main.num_pillars_bottom = 16
end

function start_ambient_sound()
	sound = hg.LoadWAVSoundAsset("winterZ.wav")
	hg.PlayStereo(sound, hg.StereoSourceState(1, hg.SR_Loop))
end

function init_sprites()
	Main.sprites = {["ship"] = {}, ["numbers"] = {}, ["min_numbers"] = {}, ["pillars"] = {}, ["parallaxes"] = {}, ["vapors"] = {},
					["background"] = Sprite:new("bg4_16_9.png", Main.game_scale, hg.Vec2(0, 0)),
					["flag"] = Sprite:new("checkpoint.png", Main.game_scale, hg.Vec2(5, 0)),
					["explode"] = Sprite:new("boom2.png", Main.game_scale,nil),
					["title"] = Sprite:new("title_x2.png", Main.game_scale,nil),
					["get_ready"] = Sprite:new("getready.png", Main.game_scale,nil),
					["explain"] = Sprite:new("explain_space.png", Main.game_scale,nil),
					["gameover"] = Sprite:new("gameover.png", Main.game_scale,nil),
					["panel"] = Sprite:new("panel.png", Main.game_scale,nil),
                    ["difficulty_level"] = {
                        ["easy"]=Sprite:new("level_easy.png", Main.game_scale,nil),
                        ["normal"]=Sprite:new("level_normal.png", Main.game_scale,nil),
                        ["hard"]=Sprite:new("level_hard.png", Main.game_scale,nil)
                        }
                    }
	-- Ship frames:
	for n=0, 4-1, 1
	do
		spr=Sprite:new("ship_"..n..".png", Main.game_scale, hg.Vec2(28, 20))
		table.insert(Main.sprites["ship"],spr)
	end
		
	-- Numbers font:
	for n=0, 10-1, 1
	do
		spr = Sprite:new(""..n..".png", Main.game_scale,nil)
		table.insert(Main.sprites["numbers"],spr)
		spr = Sprite:new("min"..n..".png", Main.game_scale,nil)
		table.insert(Main.sprites["min_numbers"],spr)
	end
		
	-- Pillars:
	for n=0, 4-1, 1
	do
		spr = Sprite:new("pillar_" ..n.. ".png", Main.game_scale, hg.Vec2(0, 0))
		table.insert(Main.sprites["pillars"],spr)
	end
	
	-- Parallaxes:
	for i,n in pairs({"front2bottom", "front2top", "front1bottom", "front1top", "ground", "bg1", "bg2", "bg3", "bg3b"}) do
		spr = Sprite:new(""..n..".png", Main.game_scale, hg.Vec2(0, 0))
		table.insert(Main.sprites["parallaxes"],spr)
	end
		
	-- Vapors:
	for i,n in pairs({"vapor0", "vapor1"}) do
		spr = Sprite:new("" .. n .. ".png", Main.game_scale,nil)
		table.insert(Main.sprites["vapors"],spr)
	end
end

function draw_flash()
	Main.collision_time = Main.collision_time + Main.delta_t
	if Main.collision_time < Main.flash_delay then
		f = Main.collision_time / Main.flash_delay
		color = hg.Color(1, 1, 1, 1 - f)
		--Main.plus:Quad2D(0, 0, 0, Main.resolution.y, Main.resolution.x, Main.resolution.y, Main.resolution.x, 0, color, color, color, color)
	end
end

function parse_digits(n,rev)
	ns=tostring(n)
	if rev then ns = string.reverse(ns) end
	digits = {}
	for i=1,string.len(ns),1 do
		nd = tonumber(string.sub(ns,i,i))
		table.insert(digits,nd)
	end
	return digits
end

function draw_score()
	digits = parse_digits(Main.score,false)
	total_width = 0  -- total width of all numbers to be printed
	for i,digit in pairs(digits) do
		total_width = total_width + Main.sprites['numbers'][digit+1]:get_width()
	end
		
	x_offset = 0.5 - convx(total_width) / 2

	for i,digit in pairs(digits) do
		spr=Main.sprites["numbers"][digit+1]
		spr:draw(hg.Vec2(x_offset, convy(216)))
		x_offset = x_offset + convx(spr:get_width())
	end
end

function draw_score_panel()
	score_digits = parse_digits(Main.score,true)
	score_max_digits = parse_digits(Main.score_max,true)
	pos = Main.sprites["panel"].position
	y_score = pos.y + convy(2)
	y_score_max = pos.y + convy(-18)

	x = pos.x + convx(51)
	for i,digit in pairs(score_digits) do
		spr=Main.sprites["min_numbers"][digit+1]
		x = x - convx(spr:get_width())
		spr:draw(hg.Vec2(x, y_score))
	end
		
	x = pos.x + convx(51)
	for i,digit in pairs(score_max_digits) do
		spr=Main.sprites["min_numbers"][digit+1]
		x = x - convx(spr:get_width())
		spr:draw(hg.Vec2(x, y_score_max))
	end
end
	
function reset_pillars()
	Main.pillars_doors = {}
	x = Main.original_resolution.x
	for n=1,Main.num_doors,1 do
		x = x + (Main.original_resolution.x + 26) / Main.num_doors
		table.insert(Main.pillars_doors,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(convx(x), 0)))
		table.insert(Main.pillars_doors,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(convx(x), 0)))
		random_pillars_doors_y(Main.pillars_doors[#Main.pillars_doors-1], Main.pillars_doors[#Main.pillars_doors])
	end
		
	Main.pillars_bottom = {}
	x = Main.original_resolution.x
	for n=1,Main.num_pillars_bottom,1 do
		x = x + (Main.original_resolution.x + 26) / Main.num_pillars_bottom
		table.insert(Main.pillars_bottom,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(convx(x), 0)))
		Main.pillars_bottom[#Main.pillars_bottom].position.y = random_pillar_bottom_y()
	end
end
	

function random_pillar_bottom_y()
	return convy(uniform(-80, - 20))
end

function random_pillars_doors_y(pillar_top, pillar_bottom)
	y_bottom = uniform(40, 160)
	y_top_min = math.max(Main.original_resolution.y - 121, y_bottom + Main.distance_min)
	y_top = uniform(y_top_min, y_top_min + 75)
	pillar_bottom.position.y = convy(y_bottom - 121)
	pillar_top.position.y = convy(y_top)
end

function draw_pillars(speed)
	x_restart = speed + convx(Main.original_resolution.x + 26)
	if Main.pillars_doors[1].position.x < -convx(26) + speed then
		x = Main.pillars_doors[1].position.x
		table.remove(Main.pillars_doors,1)
		table.remove(Main.pillars_doors,1)
		table.insert(Main.pillars_doors,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(x + x_restart, 0)))
		table.insert(Main.pillars_doors,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(x + x_restart, 0)))
		random_pillars_doors_y(Main.pillars_doors[#Main.pillars_doors-1], Main.pillars_doors[#Main.pillars_doors])
		
		Main.doors_counter = Main.doors_counter - 1
		if Main.doors_counter < 0 then
			Main.doors_counter = Main.num_doors - 1
		end
	end
	
	if Main.pillars_bottom[1].position.x < -convx(26) + speed then
		x = Main.pillars_bottom[1].position.x
		table.remove(Main.pillars_bottom,1)
		table.insert(Main.pillars_bottom,SpriteInstance:new(Main.sprites["pillars"][math.floor(uniform(1, 5))], hg.Vec2(x + x_restart, 0)))
		Main.pillars_bottom[#Main.pillars_bottom].position.y = random_pillar_bottom_y()
	end
		
	-- Movement:
	for i,pillar in pairs(Main.pillars_bottom) do
		pillar.position.x = pillar.position.x - speed
		pillar:draw(nil,nil)
	end
		
	for i,pillar in pairs(Main.pillars_doors) do
		pillar.position.x = pillar.position.x - speed
		pillar:draw(nil,nil)
	end
		
	-- draw flag:
	pos = Main.pillars_doors[2 * Main.doors_counter + 2].position
	Main.sprites["flag"].position_prec = Main.sprites["flag"].position
	Main.sprites["flag"].position = hg.Vec2(pos.x + convx(13), pos.y + convy(121))
	Main.sprites["flag"]:draw(nil,nil)
end



function random_vapor_pos(id)
	rds = {{convy(14), convy(80)}, {convy(100), convy(200)}}
	Main.sprites["vapors"][id+1].position.x = 0
	Main.sprites["vapors"][id+1].position.y = uniform(rds[id+1][1], rds[id+1][2])
end

function draw_vapor(id, x_speed)
	vapors_speed = {{0.0004, 0.0004}, {0.0005, 0.0003}}
	pos = Main.sprites["vapors"][id+1].position
	pos.x = pos.x + (vapors_speed[id+1][1] - x_speed)
	pos.y = pos.y + vapors_speed[id+1][2]
	if pos.x < convx(-110)then
		random_vapor_pos(id)
		pos.x = convx(Main.original_resolution.x + 97)
	end
	if pos.x > convx(Main.original_resolution.x + 110) then
		random_vapor_pos(id)
		pos.x = convx(-97)
	end
	Main.sprites["vapors"][id+1]:draw(nil,nil)
end

function draw_title()
	Main.sprites["title"]:draw(nil,nil)
	Main.sprites["explain"]:draw(nil,nil)
end

function draw_panel()
	Main.sprites["gameover"]:draw(nil,nil)
	Main.sprites["panel"]:draw(nil,nil)
end


function update_score()
	if Main.ship.position.x > Main.sprites["flag"].position.x and Main.ship.position.x < Main.sprites["flag"].position_prec.x then
		Main.score = Main.score + 1
		hg.PlayStereo(Main.sounds["checkpoint"], hg.StereoSourceState(1))
	end
end

function update_difficulty_level()
    Main.sprites["difficulty_level"][Main.difficulty_level]:draw(nil,nil)
    if keyboard:Pressed(hg.K_F1) then
        if Main.difficulty_level=="easy" then Main.difficulty_level="normal"
        elseif Main.difficulty_level=="normal" then Main.difficulty_level="hard"
        elseif Main.difficulty_level=="hard" then Main.difficulty_level="easy"
		end
	end
end

function collisions()

	-- Ground collision:
	if Main.ship.position.y < convy(79) then
		Main.ship.is_broken = true
		
	-- Pillars collision:
	else
		ws = (convx(Main.ship.width) / 2) * Main.collision_accuracy[Main.difficulty_level]
		hs = (convy(Main.ship.height) / 2) * Main.collision_accuracy[Main.difficulty_level]
		wp = (convx(Main.pillars_doors[1].sprite:get_width())) * Main.collision_accuracy[Main.difficulty_level]
		xmax = Main.ship.position.x + ws + Main.scrolls_x[4]
		xmin = Main.ship.position.x - ws + Main.scrolls_x[4]
		-- Doors pillars (only the 2 ones at the left of screen):
		for i=0,1,1 do
			pillar_top = Main.pillars_doors[i * 2 + 1]
			if pillar_top.position.x > xmin - wp and pillar_top.position.x  < xmax then
				pillar_bot = Main.pillars_doors[i * 2 + 2]
				if Main.ship.position.y + hs > pillar_top.position.y or Main.ship.position.y - hs < pillar_bot.position.y + convy(121) then
					Main.ship.is_broken = true
					hg.PlayStereo(Main.sounds["collision"], hg.StereoSourceState(1))
					if Main.ship.position.x + ws < pillar_top.position.x + Main.scrolls_x[4] then
						Main.ship.broken_face = true
					end
					return
				end
			end
		end

		-- Bottom pillars:
		for i=0,#Main.pillars_bottom-1,1 do
			pillar = Main.pillars_bottom[i+1]
			if pillar.position.x > xmax then    -- Don't test pillars in front of the ship
				break
			end
			if pillar.position.x > xmin - wp and pillar.position.x  < xmax then
				if Main.ship.position.y - hs < pillar.position.y + convy(121) then
					Main.ship.is_broken = true
					hg.PlayStereo(Main.sounds["collision"], hg.StereoSourceState(1))
					if Main.ship.position.x + ws < pillar.position.x + Main.scrolls_x[4] then
						Main.ship.broken_face = true
					end
					return
				end
			end
		end
	end
end



function parallax_scrolling()
	scrolls_sizes =  {convx(512), convx(512), convx(256), convx(0), convx(256), convx(0), convx(256), convx(0),convx(256), convx(256)}
	x_step = Main.scrolling_speed
	for i=0, #Main.scrolls_x-1, 1 do
		if i == 3 or i == 5 or i == 7 then
			Main.scrolls_x[i+1] = x_step * Main.delta_t
		else
			Main.scrolls_x[i+1] = Main.scrolls_x[i+1] - x_step * Main.delta_t
			if Main.scrolls_x[i+1] < -scrolls_sizes[i+1] then
				Main.scrolls_x[i+1] = Main.scrolls_x[i+1] + scrolls_sizes[i+1]
			end
		end
		x_step = x_step * 0.75
	end
end


function draw_parallaxes()
	-- plan 10
	Main.sprites["parallaxes"][9]:draw(hg.Vec2(Main.scrolls_x[10], convy(65)),nil)
	Main.sprites["parallaxes"][9]:draw(hg.Vec2(Main.scrolls_x[10] + convx(256), convy(65)),nil)
	Main.sprites["parallaxes"][9]:draw(hg.Vec2(Main.scrolls_x[10] + convx(512), convy(65)),nil)

	-- plan 9
	Main.sprites["parallaxes"][8]:draw(hg.Vec2(Main.scrolls_x[9], convy(65)),nil)
	Main.sprites["parallaxes"][8]:draw(hg.Vec2(Main.scrolls_x[9] + convx(256), convy(65)),nil)
	Main.sprites["parallaxes"][8]:draw(hg.Vec2(Main.scrolls_x[9] + convx(512), convy(65)),nil)

	-- plan 8: vapor 1
	draw_vapor(1, Main.scrolls_x[8])

	-- plan 7
	Main.sprites["parallaxes"][7]:draw(hg.Vec2(Main.scrolls_x[7], convy(24)),nil)
	Main.sprites["parallaxes"][7]:draw(hg.Vec2(Main.scrolls_x[7] + convx(256), convy(24)),nil)
	Main.sprites["parallaxes"][7]:draw(hg.Vec2(Main.scrolls_x[7] + convx(512), convy(24)),nil)

	-- plan 6 vapor 0
	draw_vapor(0, Main.scrolls_x[6])

	-- plan 5
	Main.sprites["parallaxes"][6]:draw(hg.Vec2(Main.scrolls_x[5], convy(14)),nil)
	Main.sprites["parallaxes"][6]:draw(hg.Vec2(Main.scrolls_x[5] + convx(256), convy(14)),nil)
	Main.sprites["parallaxes"][6]:draw(hg.Vec2(Main.scrolls_x[5] + convx(512), convy(14)),nil)

	-- plan 4 : pillars
	if #Main.pillars_doors > 0 then
		draw_pillars(Main.scrolls_x[4])
	end
		
	-- plan ship:
	Main.ship:draw()

	if Main.ship.is_broken then
		Main.flames:draw(Main.ship.position, -Main.scrolls_x[4] * 0.75)
		draw_flash()
	end
		
	-- plan 3
	Main.sprites["parallaxes"][5]:draw(hg.Vec2(Main.scrolls_x[3], convy(-6)),nil)
	Main.sprites["parallaxes"][5]:draw(hg.Vec2(Main.scrolls_x[3] + convx(256), convy(-6)),nil)
	Main.sprites["parallaxes"][5]:draw(hg.Vec2(Main.scrolls_x[3] + convx(512), convy(-6)),nil)

	-- plan 2
	Main.sprites["parallaxes"][4]:draw(hg.Vec2(Main.scrolls_x[2], convy(195)),nil)
	Main.sprites["parallaxes"][3]:draw(hg.Vec2(Main.scrolls_x[2], 0),nil)
	Main.sprites["parallaxes"][4]:draw(hg.Vec2(Main.scrolls_x[2] + convx(512), convy(195)),nil)
	Main.sprites["parallaxes"][3]:draw(hg.Vec2(Main.scrolls_x[2] + convx(512), 0),nil)

	-- plan 1
	Main.sprites["parallaxes"][2]:draw(hg.Vec2(Main.scrolls_x[1], convy(195)),nil)
	Main.sprites["parallaxes"][1]:draw(hg.Vec2(Main.scrolls_x[1], -convy(5)),nil)
	Main.sprites["parallaxes"][2]:draw(hg.Vec2(Main.scrolls_x[1] + convx(512), convy(195)),nil)
	Main.sprites["parallaxes"][1]:draw(hg.Vec2(Main.scrolls_x[1] + convx(512), -convy(5)),nil)
end
	
function play_animations()
	anims_playing = false
	for i,animation in pairs(Main.animations) do
		anims_playing = anims_playing or animation:update_animation(hg.time_to_sec_f(hg.GetClock()))
	end
	return anims_playing
end

-- -----------------------------------------------
--       Game phases
-- -----------------------------------------------


function reset_intro_phase()
	Main.pillars_doors, Main.pillars_bottom = {}, {}
	Main.ship:reset()
	Main.flames:reset()
	Main.scrolling_speed = 0.9

	-- Main.sprites["vapors"][0].position = hg.Vec2()
	-- Main.sprites["vapors"][1].position = hg.Vec2()

	random_vapor_pos(0)
	random_vapor_pos(1)

	Main.doors_counter = 0

	Main.sprites["title"].position = hg.Vec2(0.5, convy(300))
	Main.sprites["explain"].position = hg.Vec2(0.5, 0.67)
	Main.sprites["explain"].color = hg.Color(1, 1, 1, 0)

	Main.animations = {SpriteAnimator:new(Main.sprites["title"], hg.Vec2(0.5, convy(221)), hg.Color.White, 0, 0.5),
					   SpriteAnimator:new(Main.sprites["explain"], hg.Vec2(0.5, 0.67), hg.Color.White, 0.5, 0.5) }

    for i,sprite in pairs(Main.sprites["difficulty_level"]) do
        sprite.position=hg.Vec2(0.5,convy(120))
    end
end

function intro_phase()
	Main.ship:waiting()

	draw_parallaxes()

	parallax_scrolling()

	game_phase = intro_phase

	draw_title()
	update_difficulty_level()

	if not play_animations() then

		if keyboard:Pressed(hg.K_Space) then
			reset_ingame_phase()
			game_phase = ingame_phase
		end
	end
	return game_phase
end

function reset_ingame_phase()
	Main.doors_counter = Main.num_doors - 1
	reset_pillars()
	Main.flames:reset()
	Main.scrolling_speed = 0.9
	Main.score = 0
	Main.collision_time = 0
end

function ingame_phase()
	Main.ship:update_kinetic()

	draw_parallaxes()
	parallax_scrolling()
	update_score()
	draw_score()

	-- Ship control:
	game_phase = ingame_phase
	if not Main.ship.is_broken then
		if keyboard:Pressed(hg.K_Space) and Main.ship.position.y < 1 then
			Main.ship:start_booster()
			hg.PlayStereo(Main.sounds["thrust"], hg.StereoSourceState(1))
		end
		collisions()
	else
		if Main.ship.broken_face then
			Main.scrolling_speed = Main.scrolling_speed * 0.5
		else
			Main.scrolling_speed = Main.scrolling_speed * 0.97
		end
		if Main.ship.position.y < convy(79) then
			hg.PlayStereo(Main.sounds["crash"], hg.StereoSourceState(1))
			reset_score_phase()
			game_phase = score_phase
		end
	end
	return game_phase
end

function reset_score_phase()
	Main.sprites["title"] = Main.sprites["get_ready"]
	Main.sprites["gameover"].position = hg.Vec2(0.5, convy(224 + 150))
	Main.sprites["panel"].position = hg.Vec2(0.5, convy(164 + 150))
	if Main.score > Main.score_max then
		Main.score_max = Main.score
	end
	Main.animations = {SpriteAnimator:new(Main.sprites["gameover"], hg.Vec2(0.5, convy(224)), hg.Color.White, 0, 0.5),
					   SpriteAnimator:new(Main.sprites["panel"], hg.Vec2(0.5, convy(164)), hg.Color.White, 0, 0.5)}
end

function score_phase()
	Main.ship:update_kinetic()

	draw_parallaxes()
	parallax_scrolling()
	Main.scrolling_speed = Main.scrolling_speed * 0.97

	-- Ship control:
	game_phase = score_phase

	draw_panel()

	if not play_animations() then

		draw_score_panel()

		if keyboard:Pressed(hg.K_Space) then
			reset_intro_phase()
			game_phase = intro_phase
		end
	end
		
	return game_phase
end

-- ==================================================================================================

--                                   Program start here

-- ==================================================================================================

-- initialize  Harfang
hg.InputInit()
hg.AudioInit()
hg.WindowSystemInit()

keyboard = hg.Keyboard()
mouse = hg.Mouse()

sel,scr_mode,scr_res = request_screen_mode(16/9)

if sel == "ok" then
	res_x, res_y = 1920, 1080
	Main.resolution.x,Main.resolution.y=res_x,res_y
	Main.game_scale=Main.resolution.y / Main.original_resolution.y

	win = hg.NewWindow("WinterZ", res_x, res_y, 32)--, hg.WV_Fullscreen)
	hg.RenderInit(win)
	hg.RenderReset(res_x, res_y, hg.RF_MSAA8X | hg.RF_FlipAfterRender | hg.RF_FlushAfterRender | hg.RF_MaxAnisotropy | hg.RF_VSync)

	hg.AddAssetsFolder("../assets_compiled")

	vtx_layout = hg.VertexLayoutPosFloatTexCoord0UInt8()
	render_state_quad = hg.ComputeRenderState(hg.BM_Alpha, hg.DT_Less, hg.FC_Disabled)
	shader_texture = hg.LoadProgramFromAssets("shaders/texture")
	shader_white = hg.LoadProgramFromAssets("shaders/white")

	init_game()
	start_ambient_sound()

	Main.score = 0
	Main.score_max = 0
	reset_intro_phase()
	game_phase = intro_phase

	while not keyboard:Pressed(hg.K_Escape) do
		keyboard:Update()
		mouse:Update()
		dt = hg.TickClock()
		Main.z_depth = 100

		hg.SetViewClear(0, hg.CF_Color | hg.CF_Depth, hg.ColorI(64, 64, 64), 1, 0)
		hg.SetViewRect(0, 0, 0, res_x, res_y)

		Main.resolution.x,Main.resolution.y=res_x,res_y
		Main.game_scale=Main.resolution.y / Main.original_resolution.y

		Main.delta_t = hg.time_to_sec_f(dt) * Main.game_speed[Main.difficulty_level]

		hg.SetViewOrthographic(0, 0, 0, res_x, res_y, hg.TransformationMat4(hg.Vec3(res_x / 2, res_y / 2, 0), hg.Vec3(0, 0, 0), hg.Vec3(1, 1, 1)), 0, 101, res_y)

		Main.sprites["background"]:draw()

		game_phase = game_phase()

		hg.Frame()
		hg.UpdateWindow(win)
	end

	hg.AudioShutdown()
	hg.InputShutdown()
	hg.RenderShutdown()
	hg.DestroyWindow(win)
end
