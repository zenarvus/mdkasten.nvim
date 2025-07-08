--codes that are used in multiple files
local config = require("mdkasten.config")

local common = {}

local vim = vim

--Escape the special characters to prevent :match and :gsub from detecting them as pattern matching characters.
common.escapedMdkastenPath = config.config.mdkastenPath:gsub("([%.%^%$%*%+%-%?%(%)%[%]{}])", "%%%1")

common.getNoteTitle = function(filePath)
	local title = "Untitled"

	if config.config.titleType == "heading" then
		local file = io.open(filePath, "r")
		if file then
			for line in file:lines() do
				if line:match("^# ") then
					title = line:sub(3) -- Remove the "# " part
					break
				end
			end
			file:close()
		end
	elseif config.config.titleType == "yaml" then
		title = "Unsupported"
	else
		title = "Unsupported"
	end

	return title
end

common.toBase62 = function(num)
	local chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
	local base = #chars
	local result = ""

	while num > 0 do
		local remainder = num % base
		result = chars:sub(remainder + 1, remainder + 1) .. result
		num = math.floor(num / base)
	end

	return result
end

-------REMOVE ./ FROM FILE PATH FROM ALL LINKS-------
local function trim_link_prefix()
	-- Get the current buffer number
	local buf = vim.api.nvim_get_current_buf()
	-- Get the lines of the buffer
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	local pattern1 = "%[%[%./(.-)%|(.-)%]%]"
	local replacement1 = "[[%1|%2]]"

	local pattern2 = "%[(.-)%]%(%./(.-)%)"
	local replacement2 = "[%1](%2)"
	-- Create a new table to hold modified lines
	local new_lines = {}
	-- Loop through each line and perform the replacement
	for _, line in ipairs(lines) do
		local new_line = line:gsub(pattern1, replacement1):gsub(pattern2,replacement2)
		table.insert(new_lines, new_line)
	end
	-- Set the modified lines back to the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_lines)
end
-------REPLACE WIKILINK WITH MARKDOWN LINKS-------
local function replace_markdown_links_with_wikilinks()
	local buf = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

	for i, line in ipairs(lines) do
		local new_line = line:gsub('%[%[(.-)%|.-%]%]', function(file_path)
		--local new_line = line:gsub('%[.-%]%((.-)%)', function(file_path)
			-- Extract the file name from the path
			if file_path:find("%.md$") and not file_path:match("^[a-zA-Z]+://") then
				local file_content = vim.fn.readfile(config.config.mdkastenPath.."/"..file_path)
				local title="unnamed"
				for _, linkline in ipairs(file_content) do
					local new_title = linkline:match("^#+%s+(.+)")
					if new_title then
						title=new_title
						break -- Stop at the first match
					end
				end
				local file_name = title
				return string.format("[%s](%s)", file_name, file_path)
				--return string.format("[[%s|%s]]", file_path, file_name)
			end
		end)
		lines[i] = new_line
	end
	-- Set the modified lines back to the buffer
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end
-------FORMAT ON SAVE-------
local function save_processing()
	trim_link_prefix();
	replace_markdown_links_with_wikilinks()
end
-- Autocommand to trigger the function on save
vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*.md", -- Adjust this pattern if needed
	callback = save_processing,
})

return common
