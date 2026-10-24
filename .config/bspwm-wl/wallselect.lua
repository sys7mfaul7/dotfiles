-- Config for wl-wallselect (swayimg gallery as a wallpaper picker)
swayimg.mode = "gallery"
swayimg.decoration = false
swayimg.imagelist.order = "alpha"
swayimg.imagelist.fsmon = false
swayimg.text.font = "JetBrains Mono"
swayimg.text.size = 18
swayimg.text.color = 0xffc0ffc0
swayimg.text.background = 0xcc000000
swayimg.text.timeout = 0
swayimg.gallery.thumb_size = 300
swayimg.gallery.aspect = "fit"
swayimg.gallery.padding_size = 8
swayimg.gallery.border_size = 4
swayimg.gallery.border_color = 0xff00ff41
swayimg.gallery.selected_scale = 1.08
swayimg.gallery.selected_color = 0xff1f6f2f
swayimg.gallery.unselected_color = 0xff000000
swayimg.gallery.window_color = 0xff000000
swayimg.gallery.hover = false
swayimg.gallery.preload = true
swayimg.gallery.set_text("topleft", { "{name}" })
swayimg.gallery.set_text("topright", { "{list.index}/{list.total}  Enter=set  Esc/q=cancel  (last tiles = plain colours)" })

local function pick()
  local img = swayimg.gallery.get_image()
  if img and img.path then
    io.stdout:write(img.path, "\n")
    io.stdout:flush()
  end
  swayimg.exit(0)
end
local function cancel() swayimg.exit(1) end

swayimg.gallery.on_key("Return", pick)
swayimg.gallery.on_key("KP_Enter", pick)
swayimg.gallery.on_key("Escape", cancel)
swayimg.gallery.on_key("q", cancel)
for _, d in ipairs({ "left", "right", "up", "down" }) do
  swayimg.gallery.on_key(d, function() swayimg.gallery.select(d) end)
end
swayimg.gallery.on_key("home", function() swayimg.gallery.select("first") end)
swayimg.gallery.on_key("end", function() swayimg.gallery.select("last") end)
swayimg.gallery.on_mouse("MouseLeft", pick)
