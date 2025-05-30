local vim = vim

local function setup(opts)
    local config = require("mdkasten.config").initConfig(opts)

    if config.config.mdkastenPath == nil then
        error("mdkastenPath cannot be empty. Please specify the mdkasten folder", 1)
        return
    end

    local navi = require("mdkasten.navigation")
    local listgen = require("mdkasten.fileListGen")
    local fileops = require("mdkasten.fileOps")
	local common = require("mdkasten.common")
	--require("mdkasten.deprecated")

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            --do not run the plugin if the current buffer is not in the mdkastenPath
            if not vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()):match(common.escapedMdkastenPath) then
				print(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()).." is does not match with "..config.config.mdkastenPath)
                return
            end

            -- Go to the node
            vim.api.nvim_create_user_command('MDKNodeFind', function()navi.suggestNodes(false)end, {})
            -- Insert the node to the current buffer
            vim.api.nvim_create_user_command('MDKNodeInsert', function()navi.suggestNodes(true)end, {})
            -- Custom go to file command
            vim.api.nvim_create_user_command('MDKCustomGF', navi.mdRoamCustomGF, {})

            --List map of contents
            vim.api.nvim_create_user_command('MDKListMoc',listgen.listMoc,{})
            --List orphan nodes
            vim.api.nvim_create_user_command('MDKListOrphans',listgen.listOrphans,{})
            --List nodes that has links to non-existent
            vim.api.nvim_create_user_command('MDKListLTNE',listgen.listLtne,{})

            --Node Update Title
            vim.api.nvim_create_user_command('MDKNodeTitleUpdate',fileops.nodeTitleUpdate,{})
            --Create Node
            vim.api.nvim_create_user_command('MDKNodeCreate',fileops.createNode,{})
            --Delete Current Node
            vim.api.nvim_create_user_command("MDKCurrentNodeDelete", fileops.currentNodeDelete, {})
        end
    })
end

return {setup = setup}
