local config = require("mdkasten.config")

local common = require("mdkasten.common")

local vim = vim

local navi = {}

------LIST MARKDOWN FILES ATTACH TO BUFFER OR GO TO THEM------
local telescopePickers = require('telescope.pickers')
local telescopeFinders = require('telescope.finders')
local telescopeActions = require('telescope.actions')
local telescopeState = require('telescope.actions.state')
local telescopeConf = require("telescope.config").values

-- telescopeItems: {file="filepath", access="lastAccessTime", title="nodeTitle"}
local telescopeItems = {}
local getTelescopeItems = function(updateList)
    local oldItemInfo = {}
    for _, item in ipairs(telescopeItems) do
        oldItemInfo[item.file] = {access = item.access, title = item.title}
    end

    local newItems = {}

    local all_files = vim.fn.systemlist("rg --files --glob '!.*' " .. config.config.mdkastenPath)

	local nodeTitleMap = {}
	--Get the titles of all of the notes.
	if updateList then
		local rgNodeTitles = vim.fn.systemlist("rg --type=md --color=never -m1 -NU '(?s)^---.*^title:\\s*([^\\n]+)\\n^---|^\\+\\+\\+.*^title\\s*=\\s*([^\\n]+)\\n^\\+\\+\\+|^#\\s+([^\\n]+)' -or '$1$2$3/EOT' " .. config.config.mdkastenPath)
		for _, rgLine in ipairs(rgNodeTitles) do
			local filePath = rgLine:match("(.*%.md):")
			local nodeTitle = rgLine:match("%.md:(.*)%/EOT$")
			if filePath and nodeTitle then
				nodeTitleMap[filePath] = nodeTitle
			end
		end
	end

    for _, file in ipairs(all_files) do
        local access = os.time()
		local title = ""
        --preserve the old item access values
		--also preserve the title if its not updated
        if oldItemInfo[file] then
            access = oldItemInfo[file].access
        end

		--Get the old titles if the updateList is false
		if (not updateList) then
			if oldItemInfo[file] then
				title = oldItemInfo[file].title
			else title = vim.fn.fnamemodify(file, ":t") end
		else
			if nodeTitleMap[file] then
				title = nodeTitleMap[file]
			else title = vim.fn.fnamemodify(file, ":t") end
		end

        table.insert(newItems, { file = file, access = access, title = title })
    end

    --sort items based on score -- for new files
    table.sort(newItems, function(a, b)
        return a.access > b.access
    end)

    return newItems
end

telescopeItems = getTelescopeItems(true)

local function updateTelescopeScore(file)
    for _, item in ipairs(telescopeItems) do
        if item.file == file then
            item.access = os.time()
            break
        end
    end

    --sort items based on score
    table.sort(telescopeItems, function(a, b)
        return a.access > b.access
    end)
end

navi.updateTelescopeItems = function()
    telescopeItems = getTelescopeItems(true)
end

navi.suggestNodes = function(linsert)
	telescopeItems = getTelescopeItems()

    -- Check if there are any items in telescopeItems
    if #telescopeItems == 0 then
        print("No items found.")
        return
    end

    -- Use Telescope to select a suggestion
    telescopePickers.new({}, {
        prompt_title = "Select Markdown Link",
        finder = telescopeFinders.new_table {
            results = telescopeItems,
            entry_maker = function(entry)
                local file = entry.file

                local display
                local heading
                if file:match("%.md$") then
                    heading = entry.title
                    display = string.format("%s (%s)", heading, file:gsub("^"..config.config.mdkastenPath.."/", ""))
                else
                    --as we cannot go to the media files, add them to the list only if we are going to insert
                    if linsert == true then
                        display = entry.title
                        heading = entry.title
                    end
                end
                return {
                    path = file,
                    value = heading,
                    display = display,
                    ordinal = display,
                }
            end,
        },
        sorter = telescopeConf.file_sorter(),
        attach_mappings = function(prompt_bufnr, _)
            telescopeActions.select_default:replace(function()
                telescopeActions.close(prompt_bufnr)
                local selection = telescopeState.get_selected_entry()
                -- print(vim.inspect(selection))
                if selection then
                    updateTelescopeScore(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
                    if linsert==true then
                        local link = ""
                        if config.config.linkType == "markdown" then
                            link = string.format("[%s](%s)", selection.value, selection.path:gsub("^"..config.config.mdkastenPath.."/", ""))
                        elseif config.config.linkType == "wiki" then
                            link = string.format("[[%s|%s]]", selection.path:gsub("^"..config.config.mdkastenPath.."/", ""), selection.value)
                        end
                        vim.api.nvim_put({ link }, 'c', true, true) -- Insert the link at the cursor position
                    else
                        -- Open the selected file
                        vim.cmd("edit " .. selection.path)
                    end
                end
            end)
            return true
        end,
    }):find()
end

-------CUSTOM GF-------
navi.mdRoamCustomGF = function()
    local line = vim.api.nvim_get_current_line()
    local links = {}

    --wiki link
    for link in line:gmatch('%[%[(.*)%|.-%]%]') do
        table.insert(links, link)
    end
    --markdown link
    for link in line:gmatch('%[.-%]%((.*)%)') do
        local sanitizedLink = link:gsub("#.*$","")
        table.insert(links, sanitizedLink)
    end
    --another link format that i do not know its name
    for link in line:gmatch('<([a-z]+:%/%/.*)>') do
        table.insert(links, link)
    end

    if #links == 1 then
      if links[1]:match("%.mdx?$") then
        if vim.fn.filereadable(config.config.mdkastenPath.."/"..links[1]) ~= 0 then
            vim.cmd("edit "..config.config.mdkastenPath.."/"..links[1])
        else
            print("File not found.")
            return
        end
      else
        if links[1]:match("[a-z]+:%/%/.*") then
            os.execute("xdg-open "..links[1].." > /dev/null 2>&1 &")
        else
            os.execute("xdg-open "..config.config.mdkastenPath.."/"..links[1].." &")
        end
      end

    elseif #links > 1 then
      local file_under_cursor = vim.fn.expand('<cfile>')
      if file_under_cursor:match("%.mdx?$") then
        vim.cmd("edit "..config.config.mdkastenPath.."/"..file_under_cursor)
      else
        if file_under_cursor:match("[a-z]+:%/%/.*") then
            os.execute("xdg-open "..file_under_cursor.." > /dev/null 2>&1 &")
        else
            os.execute("xdg-open "..config.config.mdkastenPath.."/"..file_under_cursor.." &")
        end
      end

    else
      print("no link found")
    end
end

return navi
