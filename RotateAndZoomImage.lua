-- SamuelSVD
obs = obslua
bit = require("bit")

source_def = {}
source_def.id = "RotateAndZoomImage_source"
source_def.output_flags = bit.bor(obs.OBS_SOURCE_VIDEO, obs.OBS_SOURCE_CUSTOM_DRAW)

local zoom = 0;
local zoom_speed = 0.1;
local zoom_max = 10;

local rot = 0;
local rot_speed = 0.1;
local rot_min = 10;
local rot_max = 10;

local img_path = "";

function image_source_load(image, file)
	obs.obs_enter_graphics();
	obs.gs_image_file_free(image);
	obs.obs_leave_graphics();

	obs.gs_image_file_init(image, file);

	obs.obs_enter_graphics();
	obs.gs_image_file_init_texture(image);
	obs.obs_leave_graphics();

	if not image.loaded then
		print("failed to load texture " .. file);
	end  
	img_loaded = true;
end

function loadImg(data)
	if (not data.img_loaded) or (img_path ~= data.old_img_path) then
		image_source_load(data.image, img_path);
		data.img_loaded = true;
	end
	data.old_img_path = img_path;
end

function animate()
	zoom = zoom + zoom_speed;
	if (zoom > zoom_max) then
		zoom = zoom_max;
		zoom_speed = -zoom_speed;
	end
	if (zoom <= 0) then
		zoom = 0;
		zoom_speed = -zoom_speed;
	end
	
	rot = rot + rot_speed;
	if (rot > rot_max) then
		rot_speed = -rot_speed;
		rot = rot_max;
	end
	if (rot < rot_min) then
		rot_speed = -rot_speed;
		rot = rot_min;
	end
end
source_def.get_name = function()
	return "Rotate And Zoom Image"
end

source_def.create = function(source, settings)
	local data = {}
	data.image = obs.gs_image_file()
	data.old_img_path = "";
	data.img_loaded = false;

	image_source_load(data.image, img_path)

	return data
end

source_def.destroy = function(data)
	obs.obs_enter_graphics();
	obs.gs_image_file_free(data.image);
	obs.gs_image_file_free(data.hour_image);
	obs.gs_image_file_free(data.minute_image);
	obs.gs_image_file_free(data.second_image);
	obs.obs_leave_graphics();
end

source_def.video_render = function(data, effect)
	loadImg(data)

	if not data.image then
		return;
	end
	if not data.image.texture then
		return;
	end

	local time = os.date("*t")
	local seconds = time.sec
	local mins = time.min + seconds / 60.0;
	local hours = time.hour + (mins * 60.0) / 3600.0;

	effect = obs.obs_get_base_effect(obs.OBS_EFFECT_DEFAULT)

	obs.gs_blend_state_push()
	obs.gs_reset_blend_state()

	obs.gs_matrix_push()
	obs.gs_matrix_translate3f(250, 250, 0)
	obs.gs_matrix_rotaa4f(0.0, 0.0, 1.0, rot * math.pi / 180.0);
	obs.gs_matrix_translate3f(-250, -250, 0)

	while obs.gs_effect_loop(effect, "Draw") do
		obs.obs_source_draw(data.image.texture, zoom, zoom,  500 - zoom*2, data.image.cy * 500 / data.image.cx - zoom*2, false);
	end
	obs.gs_matrix_pop()

	obs.gs_blend_state_pop()
end

source_def.get_width = function(data)
	return 500
end

source_def.get_height = function(data)
	return 500
end

function script_description()
	return "Adds a \"RotateAndZoomImage\" source which animates an image."
end

obs.obs_register_source(source_def)

function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_float(props, "zoom_max", "Zoom (Max)", 0, 240, 1)
	obs.obs_properties_add_float(props, "zoom_speed", "Zoom Speed", 0, 100000, 1)
	obs.obs_properties_add_float(props, "rot_min", "Rotation (Min)", -100000, 100000, 1)
	obs.obs_properties_add_float(props, "rot_max", "Rotation (Max)", -100000, 100000, 1)
	obs.obs_properties_add_float(props, "rot_speed", "Rotation Speed", -100000, 100000, 1)
	obs.obs_properties_add_path(props, 'img_path', 'Image path', obs.OBS_PATH_FILE, '*.jpg *.png *.bmp', None)	

	img_loaded = false;
	
	return props
end

function script_defaults(settings)

	obs.obs_data_set_default_double(settings, "zoom_max", 10)
	obs.obs_data_set_default_double(settings, "zoom_speed", 10)
	obs.obs_data_set_default_double(settings, "rot_min", -10) 
	obs.obs_data_set_default_double(settings, "rot_max", 10)
	obs.obs_data_set_default_double(settings, "rot_speed", 10)
	obs.obs_data_set_default_string(settings, "img_path", "")

end

function script_update(settings)
	activate(false)

	zoom_max = obs.obs_data_get_double(settings, "zoom_max")
	zoom_speed = obs.obs_data_get_double(settings, "zoom_speed") / 100.0
	rot_min = obs.obs_data_get_double(settings, "rot_min")
	rot_max = obs.obs_data_get_double(settings, "rot_max")
	rot_speed = obs.obs_data_get_double(settings, "rot_speed") / 100.0
	img_path = obs.obs_data_get_string(settings, "img_path")
	
	reset(true)
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		obs.timer_add(animate, 30);
	else
		obs.timer_remove(animate);
	end
end

function reset(pressed)
	if not pressed then
		return
	end
	activate(false)
	activate(true)
end
