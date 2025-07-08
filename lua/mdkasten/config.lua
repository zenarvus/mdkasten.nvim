local c = {}

c.config = {}

c.initConfig = function(opts)
	local root = opts.mdkastenPath or nil
	if root then c.config.mdkastenPath = vim.loop.fs_realpath(vim.fn.expand(root)) end

	c.config.titleType = opts.titleType or "heading" --heading or yaml
	c.config.linkType = opts.linkType or "markdown" --markdown or wiki
	c.config.filenameType = opts.filenameType or "id" --id or slug
	c.config.ignored = opts.ignored or {} -- files and folders to be excluded. Relative to mdkastenPath

	return c
end

return c
