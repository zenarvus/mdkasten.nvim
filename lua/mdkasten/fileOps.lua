local config = require("mdkasten.config")

local common = require("mdkasten.common")

local navi = require("mdkasten.navigation")

local vim = vim

local fileops = {}

--update title
-------CHANGE TITLE AND UPDATE LINKS-------
fileops.nodeTitleUpdate = function()
    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_path = vim.api.nvim_buf_get_name(current_buf)

    local currentBufPathInMDKPath = current_buf_path:gsub(config.config.mdkastenPath.."/", "")

    local title = common.getNoteTitle(current_buf_path)
    local oldTitle = title

    local newTitle = vim.fn.input("Enter the node title: ", title)
    if newTitle == title or not newTitle then
        print("Title is not changed")
        return
    end

    title = newTitle

    if title and #title > 0 then
        local files = vim.fn.globpath(config.config.mdkastenPath, "*.md", false, 1)
        local update_count=0
        -- Check if the new file name already exists
        for _, file in ipairs(files) do
            if file ~= current_buf_path then
              local content = vim.fn.readfile(file)
                local updated = false
                -- Replace old file name with new file name
                for i, line in ipairs(content) do
                  local new_line=""
                  if config.config.linkType == "markdown" then
                      new_line = line:gsub('%[.-%]%(('..currentBufPathInMDKPath..')%)',
                            '['..title.."]("..currentBufPathInMDKPath..')')
                  elseif config.config.linkType == "wiki" then
                      new_line = line:gsub('%[%[('..currentBufPathInMDKPath..')%|.-%]%]',
                            '[['..currentBufPathInMDKPath.."|"..title..']]')
                  end

                  if new_line ~= line then
                    updated = true
                    content[i] = new_line
                  end
                end
                -- Write the updated content back to the file if changes were made
                if updated then
                    update_count=update_count+1
                    vim.fn.writefile(content, file)
                end
            end
        end
        print("links are updated in "..update_count.." files")

        local bufTitleUpdated = false
        --Change the title in the buffer
        local bufferContent = vim.api.nvim_buf_get_lines(current_buf, 0, -1, true)
        if config.config.titleType == "heading" then
            for i, line in ipairs(bufferContent) do
                --For the header title
                if line:match("^# "..oldTitle) then
                    bufferContent[i] = "# "..newTitle
                    bufTitleUpdated = true
                    break
                end
            end
        elseif config.config.titleType == "yaml" then
            --For the yaml title
            if bufferContent[1]:match("^---") then
                for i, line in ipairs(bufferContent) do
                    if line:match("title: *"..oldTitle) then
                        bufferContent[i] = "title: "..newTitle
                        bufTitleUpdated = true
                        break
                    end
                end
            else
                print("Error: YAML metadata must be at the beginning and inside the '---' characters.'")
                return
            end
        end

        if not bufTitleUpdated then
            print("Title in the buffer could not been updated.")
            return
        end

        vim.api.nvim_buf_set_lines(current_buf, 0, -1, false, bufferContent)
		vim.cmd("w")

        navi.updateTelescopeItems()
    else
        print("no title found")
    end
end

--create file, creates a file and inserts its link to the cursor point
fileops.createNode = function()
    local title = vim.fn.input("Enter the node title: ")
    if not title:match("[a-zA-Z0-9]") then
        print("The node title cannot be empty.")
        return
    end

    local suffix = ""
    for _ = 1, 5 do
        suffix = suffix .. string.char(math.random(65, 90))
    end
    local filename = common.toBase62(os.time()) --[[.. suffix]] .. ".md"

    local filePath = config.config.mdkastenPath .. "/" .. filename

    local current_buf = vim.api.nvim_get_current_buf()
    local current_buf_path = vim.api.nvim_buf_get_name(current_buf)
    local currentBufTitle = common.getNoteTitle(current_buf_path)

    local content = {}

    if config.config.titleType == "yaml" then
        table.insert(content, "---")
        table.insert(content, "title: "..title)
        table.insert(content, "---")
        table.insert(content, "")
    end

    if config.config.linkType == "markdown" then
        table.insert(content, "@["..currentBufTitle.."]("..current_buf_path:gsub(config.config.mdkastenPath.."/","")..")")
    elseif config.config.linkType == "wiki" then
        table.insert(content, "@[["..current_buf_path:gsub(config.config.mdkastenPath.."/","").."|"..currentBufTitle.."]]")
    end

    if config.config.titleType == "heading" then
        table.insert(content,"")
        table.insert(content, "# "..title)
    end

    vim.fn.writefile(content, filePath)

    if config.config.linkType == "markdown" then
        vim.api.nvim_put({ "["..title.."]("..filename..")" }, 'c', true, true)
    elseif config.config.linkType == "wiki" then
        vim.api.nvim_put({ "[["..filename.."|"..title.."]]" }, 'c', true, true)
    end

    navi.updateTelescopeItems()
end

--delete file
fileops.currentNodeDelete = function()
    local option = vim.fn.input("Delete the current buffer (y/N): ")

    if option and (option == "Y" or option == "y") then
        --Save the file
        vim.cmd(":w")

        --Get the file path
        local current_file = vim.fn.expand('%:p')  -- Get the full path of the current file
        if current_file == '' then
            print("No file to delete.")
            return
        end
        -- Delete the file
        local success, err = os.remove(current_file)
        if success then
            print("Deleted file: " .. current_file)
        else
            print("Error deleting file: " .. err)
        end

        --Remove from the buffer list
        vim.cmd(":bd")

        navi.updateTelescopeItems()

    elseif option and (option == "N" or option == "n") then
        print("Deletion cancelled")
    else
        print("Unrecognized option")
    end
end

return fileops
