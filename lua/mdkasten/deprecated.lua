-- Update current node filename and make it an id

local common = require("mdkasten.common")
local config = require("mdkasten.config")

local navi = require("mdkasten.navigation")

local vim = vim

-------MARKDOWN UPDATE LINKS ON FILE RENAME-------
local function update_links_on_rename(new_name)
	new_name=new_name..".md"
	local current_buf = vim.api.nvim_get_current_buf()
	local current_buf_path = vim.api.nvim_buf_get_name(current_buf)
	local current_buf_name = vim.fn.fnamemodify(current_buf_path, ":t")
	local files = vim.fn.systemlist("rg --files --glob '!.*' --glob '*.md' "..config.config.mdkastenPath)
	local update_count=0
	-- Check if the new file name already exists
	local new_file_path = config.config.mdkastenPath .. '/' .. new_name
	if vim.fn.filereadable(new_file_path) == 1 then
		print("File already exists: " .. new_name)
		return
	end
	for _, file in ipairs(files) do
		if file ~= current_buf_path then
			local content = vim.fn.readfile(file)
			local updated = false
			-- Replace old file name with new file name
			for i, line in ipairs(content) do
				--old link format
				local new_line = line:gsub('%[%[(' .. vim.pesc(current_buf_name) .. ')%|(.-)%]%]', '[[' .. new_name .. '|%1]]')
				if new_line ~= line then
					updated = true
					content[i] = new_line
				end

				local new_line2 = line:gsub('%[(.-)%]%((' .. vim.pesc(current_buf_name) .. ')%)', '[%1](' .. new_name .. ')')
				if new_line2 ~= line then
					updated = true
					content[i] = new_line2
				end
			end
			-- Write the updated content back to the file if changes were made
			if updated then
				update_count=update_count+1
				vim.fn.writefile(content, file)
			end
		end
	end
	-- Save the current buffer with the new name
	vim.cmd('saveas ' .. vim.fn.fnameescape(new_file_path))
	--close old file buffer
	vim.cmd('bdelete ' .. vim.fn.fnameescape(current_buf_path))
	-- Open the newly saved file
	vim.cmd('edit ' .. vim.fn.fnameescape(new_file_path))
	-- Delete the old file
	vim.fn.delete(current_buf_path)
	print("links are updated in "..update_count.." files")
end
-- Define the command
vim.api.nvim_create_user_command('Rn', function(opts)
	update_links_on_rename(opts.args)
end, {
	nargs = 1, -- Requires exactly one argument
})
-------RENAME-------
local function rename()
	local suffix = ""
	for _ = 1, 5 do
		suffix = suffix .. string.char(math.random(65, 90))
	end
	local name = common.toBase62(os.time()) --.. suffix
	update_links_on_rename(name)
	navi.updateTelescopeItems()
end
vim.api.nvim_create_user_command('RenameMDK', function()rename()end, {})
