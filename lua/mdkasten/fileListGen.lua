local config = require("mdkasten.config")

local common = require("mdkasten.common")

local vim = vim

local listgen = {}

-------CREATE MOC-------
listgen.listMoc = function()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_buf_path = vim.api.nvim_buf_get_name(current_buf)
  local current_buf_name = vim.fn.fnamemodify(current_buf_path, ":t")
  local current_buf_content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, true)
  -- Find <!--moc:s--> and <!--moc:e--> in the current buffer
  local moc_start, moc_end = nil, nil
  for i, line in ipairs(current_buf_content) do
    if line:match("<!%-%-moc:s%-%->") then
      moc_start = i
    elseif line:match("<!%-%-moc:e%-%->") then
      moc_end = i
      break
    end
  end
  if not moc_start or not moc_end then
    print("Markers <!--moc:s--> or <!--moc:e--> not found in the current buffer")
    return
  end
  -- Get all markdown files in the mdkastenPath
  local files = vim.fn.systemlist("rg --files --glob '!static/' --glob '!.*' --glob '*.md' " .. config.config.mdkastenPath)

  local file_matches = {}
  -- Check links in all markdown files
  for _, file in ipairs(files) do
    if file ~= current_buf_path then
      local file_content = vim.fn.readfile(file)
      local found_link = false
      local is_draft = false

      -- Get the parent links
      for _, line in ipairs(file_content) do
        --if line:find("<!%-%-draft%-%->") then
        --  is_draft=true
        --end
        if line:match("@%[.*%]%(.*%.md%)") then
          if line:match(vim.pesc(current_buf_name)) then
            found_link = true
            break
          end
        end
      end
      if found_link then
        -- Exclude filenames starting with ~
        if not is_draft then
          table.insert(file_matches, file)
        end
      end
    end
  end

  -- Insert the list of files after <!--moc--> in the current buffer
  if #file_matches > 0 then
    local new_lines = {}
    for _, file in ipairs(file_matches) do
        local title = common.getNoteTitle(file)
        if config.config.linkType == "markdown" then
            table.insert(new_lines, "- ["..title.."]("..file:gsub("^"..common.escapedMdkastenPath.."/", "")..")")
        elseif config.config.linkType == "wiki" then
            table.insert(new_lines, "- [["..file:gsub("^"..common.escapedMdkastenPath.."/", "").."|"..title.."]]")
        end
    end
    -- Remove old content between <!--moc:s--> and <!--moc:e-->
    for _ = moc_start + 1, moc_end - 1 do
        table.remove(current_buf_content, moc_start + 1)
    end
    -- Insert new lines
    for i, line in ipairs(new_lines) do
        table.insert(current_buf_content, moc_start + i, line)
    end
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, current_buf_content)
    print("Updated current buffer with files containing links to this buffer")
  else
    print("No links found in other files")
  end
end

-------LIST ORPHANS-------
listgen.listOrphans = function()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_path = vim.api.nvim_buf_get_name(current_buf)
    local current_buf_content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, true)
  -- Find <!--orphan:s--> and <!--orphan:e--> in the current buffer
  local orphan_start, orphan_end = nil, nil
  for i, line in ipairs(current_buf_content) do
    if line:match("<!%-%-orphan:s%-%->") then
      orphan_start = i
    elseif line:match("<!%-%-orphan:e%-%->") then
      orphan_end = i
      break
    end
  end
  if not orphan_start or not orphan_end then
    print("Markers <!--orphan:s--> or <!--orphan:e--> not found in the current buffer")
    return
  end

    -- Find all linked files
    local linked_files = {}
    -- all markdown files inside notes dir 
    for _, file in ipairs(vim.fn.systemlist("rg --files --glob '!static/' --glob '!.*' --glob '*.md' " .. config.config.mdkastenPath)) do
        for _, line in ipairs(vim.fn.readfile(file)) do
            for linked_file in line:gmatch("%[%[(.-)%|.-%]%]") do
				if not linked_file:match("^[a-zA-Z]+://") then
					table.insert(linked_files, linked_file)
				end
            end
            for linked_file in line:gmatch("%[.-%]%((.-)%)") do
				if not linked_file:match("^[a-zA-Z]+://") then
					table.insert(linked_files, linked_file)
				end
            end
        end
    end
    -- Find orphan files, files that are not linked by any markdown file
    local orphan_files = {}
    --all non hidden files in notes dir
    for _, file in ipairs(vim.fn.systemlist("rg --files --glob '!static/' --glob '!.*' " .. config.config.mdkastenPath)) do
        --while file contains the full path, linkked_files are relative to the notes vault so path prefix should be removed from file
        local compatible_path=file:gsub("^"..common.escapedMdkastenPath.."/", "")
        if not vim.tbl_contains(linked_files, compatible_path) then
            table.insert(orphan_files, compatible_path)
        end
    end
    -- Insert the list of files after <!--orphan:s--> in the current buffer
    if #orphan_files > 0 then
    local new_lines = {}
    for _, file in ipairs(orphan_files) do
        if file:find("%.md$") then
            local title = common.getNoteTitle(config.config.mdkastenPath.."/"..file)
            if config.config.linkType == "markdown" then
                table.insert(new_lines, "- ["..title.."]("..file..")")
            elseif config.config.linkType == "wiki" then
                table.insert(new_lines, "- [["..file.."|"..title.."]]")
            end
        else
            if config.config.linkType == "markdown" then
                table.insert(new_lines, "- ["..vim.fn.fnamemodify(file,":t").."]("..file..")")
            elseif config.config.linkType == "wiki" then
                table.insert(new_lines, "- [["..file.."|"..vim.fn.fnamemodify(file,":t").."]]")
            end
        end
    end
    -- Remove old content between <!--orphan:s--> and <!--orphan:e-->
    for _ = orphan_start + 1, orphan_end - 1 do
      table.remove(current_buf_content, orphan_start + 1)
    end
    -- Insert new lines
    for i, line in ipairs(new_lines) do
      table.insert(current_buf_content, orphan_start + i, line)
    end
    vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, current_buf_content)
    print("Updated current buffer with orphan files")
    else
      print("No orphan files found")
    end
end

-----------LIST NOTES THAT HAVE LINKS TO NON EXISTENT NOTES--------------
--Linked To Non-Existent
listgen.listLtne = function()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_path = vim.api.nvim_buf_get_name(current_buf)
    local current_buf_content = vim.api.nvim_buf_get_lines(current_buf, 0, -1, true)
    -- Find <!--ltne:s--> and <!--ltne:e--> in the current buffer
    local ltne_start, ltne_end = nil, nil
    for i, line in ipairs(current_buf_content) do
      if line:match("<!%-%-ltne:s%-%->") then
        ltne_start = i
      elseif line:match("<!%-%-ltne:e%-%->") then
        ltne_end = i
        break
      end
    end
    if not ltne_start or not ltne_end then
      print("Markers <!--ltne:s--> or <!--ltne:e--> not found in the current buffer")
      return
    end

    --local files = vim.fn.systemlist("find "..config.config.mdkastenPath.."/ -type f -not -path '*/.*'")
    local files = vim.fn.systemlist("rg --files --glob '!static/' --glob '!.*' " .. config.config.mdkastenPath)
    local ltne_files = {}

    -- Gather all linked files from various file types
    for _, file in ipairs(files) do
		local abs_file_path = vim.fn.fnamemodify(file, ":p")
		if abs_file_path ~= current_buf_path and file:match("%.md$") then
            for i, line in ipairs(vim.fn.readfile(file)) do
                -- Match different types of links
                for linked_file in line:gmatch("%[%[(.-)%|.-%]%]") do
					if not linked_file:match("^[a-zA-Z]+://") and not linked_file:match("^#") then
						local linked_path = config.config.mdkastenPath.."/"..linked_file
						if vim.fn.filereadable(linked_path) == 0 then
							local compatible_path=file:gsub("^"..common.escapedMdkastenPath.."/", "")
							if not vim.tbl_contains(ltne_files, compatible_path) then
								--print(compatible_path..", line: "..i)
								table.insert(ltne_files, compatible_path)
							end
						end
					end
                end
                for linked_file in line:gmatch("%[.-%]%((.-)%)") do
					if not linked_file:match("^[a-zA-Z]+://") and not linked_file:match("^#") then
						local linked_path = config.config.mdkastenPath.."/"..linked_file
						if vim.fn.filereadable(linked_path) == 0 then
							local compatible_path=file:gsub("^"..common.escapedMdkastenPath.."/", "")
							if not vim.tbl_contains(ltne_files, compatible_path) then
								--print(compatible_path..", line: "..i)
								table.insert(ltne_files, compatible_path)
							end
						end
					end
                end
            end
        end
    end

    -- Insert the list of files after <!--ltne:s--> in the current buffer
    if #ltne_files > 0 then
      local new_lines = {}
      for _, file in ipairs(ltne_files) do
        if file:find("%.md$") then
            local title = common.getNoteTitle(config.config.mdkastenPath.."/"..file)
            if config.config.linkType == "markdown" then
                table.insert(new_lines, "- ["..title.."]("..file..")")
            elseif config.config.linkType == "wiki" then
                table.insert(new_lines, "- [["..file.."|"..title.."]]")
            end
        else
            if config.config.linkType == "markdown" then
                table.insert(new_lines, "- ["..vim.fn.fnamemodify(file,":t").."]("..file..")")
            elseif config.config.linkType == "wiki" then
                table.insert(new_lines, "- [["..file.."|"..vim.fn.fnamemodify(file,":t").."]]")
            end
        end
      end
      -- Remove old content between <!--ltne:s--> and <!--ltne:e-->
      for _ = ltne_start + 1, ltne_end - 1 do
        table.remove(current_buf_content, ltne_start + 1)
      end
      -- Insert new lines
      for i, line in ipairs(new_lines) do
        table.insert(current_buf_content, ltne_start + i, line)
      end
      vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, current_buf_content)
      print("Updated current buffer with listed LTNE files")
    else
      print("No LTNE files found")
    end
end

return listgen
