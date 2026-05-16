-- Automatic workspace 3x2 grid layout for Hyprland 0.55+.
--
-- Register name: lua:workspace-grid-3x2
-- Primary order:
--   1 2 3
--   4 5 6
--
-- Windows 7+ are placed in a 10% overflow column. The overflow column is
-- absent until it is needed, so the first six windows use the full workspace
-- area. Window order is stable and compacted: closing any tiled window removes
-- it from the order and later windows shift forward automatically.

local state = {
	order = {},
	overflow_side = "right",
	overflow_ratio = 0.10,
}

local function target_id(target)
	local window = target.window
	return window and tostring(window.stable_id) or tostring(target.index)
end

local function index_of(tbl, value)
	for i, v in ipairs(tbl) do
		if v == value then
			return i
		end
	end
end

local function sync_order(ctx)
	local present = {}
	local targets = {}

	for _, target in ipairs(ctx.targets) do
		local id = target_id(target)
		present[id] = true
		targets[id] = target
	end

	local old_order = state.order
	state.order = {}

	for _, id in ipairs(old_order) do
		if present[id] then
			table.insert(state.order, id)
		end
	end

	for _, target in ipairs(ctx.targets) do
		local id = target_id(target)
		if not index_of(state.order, id) then
			table.insert(state.order, id)
		end
	end

	return targets
end

local function primary_area(ctx)
	if #state.order <= 6 then
		return ctx.area, nil
	end

	if state.overflow_side == "left" then
		return ctx:split(ctx.area, "right", 1.0 - state.overflow_ratio),
			ctx:split(ctx.area, "left", state.overflow_ratio)
	end

	return ctx:split(ctx.area, "left", 1.0 - state.overflow_ratio), ctx:split(ctx.area, "right", state.overflow_ratio)
end

local function primary_slot(ctx, area, slot)
	local left = ctx:split(area, "left", 1 / 3)
	local right_two = ctx:split(area, "right", 2 / 3)
	local middle = ctx:split(right_two, "left", 1 / 2)
	local right = ctx:split(right_two, "right", 1 / 2)

	local col = ((slot - 1) % 3) + 1
	local row = math.floor((slot - 1) / 3) + 1
	local column_area = ({ left, middle, right })[col]

	if row == 1 then
		return ctx:split(column_area, "top", 1 / 2)
	end

	return ctx:split(column_area, "bottom", 1 / 2)
end

local function overflow_slot(ctx, area, index, total)
	local remaining = area

	for i = 1, index - 1 do
		remaining = ctx:split(remaining, "bottom", 1.0 - (1 / (total - i + 1)))
	end

	if index == total then
		return remaining
	end

	return ctx:split(remaining, "top", 1 / (total - index + 1))
end

hl.layout.register("workspace-grid-3x2", {
	recalculate = function(ctx)
		local targets = sync_order(ctx)
		local grid_area, overflow_area = primary_area(ctx)
		local overflow_count = math.max(#state.order - 6, 0)

		for slot, id in ipairs(state.order) do
			local target = targets[id]
			if target then
				if slot <= 6 then
					target:place(primary_slot(ctx, grid_area, slot))
				else
					target:place(overflow_slot(ctx, overflow_area, slot - 6, overflow_count))
				end
			end
		end
	end,

	layout_msg = function(_, msg)
		local command = msg:match("^(%S+)")

		if command == "overflow-left" then
			state.overflow_side = "left"
		elseif command == "overflow-right" then
			state.overflow_side = "right"
		elseif command == "reset-order" then
			state.order = {}
		else
			return "workspace-grid-3x2: expected overflow-left, overflow-right, or reset-order"
		end

		return true
	end,
})
