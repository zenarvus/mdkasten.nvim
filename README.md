# markdown-roam.nvim
![GitHub stars](https://img.shields.io/github/stars/zenarvus/mdkasten.nvim?style=flat-square)
![Forks](https://img.shields.io/github/forks/zenarvus/mdkasten.nvim?style=flat-square)
![Issues](https://img.shields.io/github/issues/zenarvus/mdkasten.nvim?style=flat-square)
![License](https://img.shields.io/badge/license-GPL%20v3-blue.svg?style=flat-square)

A NeoVim plugin for easy navigation and linking between Markdown notes.

## Installation
### Requirements
- [ripgrep](https://github.com/BurntSushi/ripgrep)

### Using lazy.vim
```lua
{"zenarvus/mdkasten.nvim",
    config = function ()
        require("mdkasten").setup({
            -- Required: Set The Vault Path
            mdkastenPath="~/notes"
        })
        -- Optional: Set Keymaps
        vim.keymap.set('n', 'gf', ":MDKCustomGF<CR>")
        vim.keymap.set('n', 'gh', ":MDKNodeFind<CR>")
        vim.keymap.set('n', 'gH', ":MDKNodeInsert<CR>")
        vim.keymap.set('n', 'gb', ":MDKNodeCreate<CR>")
    end
},
```
## Commands
> [!WARNING]
> It is recommended to use only the provided functions to create and delete nodes or to update the titles.
> Otherwise, the navigation commands may malfunction.

### File Operations
#### Create Node
Use the `:MDKNodeCreate` command to create a node and insert its link to the current buffer. The created node will be a child of the current buffer.

#### Delete The Current Node
To delete the current node, use the `:MDKCurrentNodeDelete` command. When it asks you a yes and no question, press "y" and enter.

#### Update Title of The Node
Use the `:MDKNodeTitleUpdate` command to change the node title, and update it on all other nodes.

### Navigation
#### Telescope
The `:MDKNodeFind` command lists all the nodes, and navigates to the selected node.

The `:MDKNodeInsert` command lists all the files inside the vault, and inserts the selected one to the current buffer.

#### Custom GF Function
The `:MDKCustomGF` command navigates to the file on the cursor, or in the current line if its in the markdown format. Otherwise, it uses the **xdg-open** command to open it.

### File List Generation
#### List Map of Contents
When a node links to another node using an "@" symbol in the beginning, it is considered as a child node. For example:
`@[node2](node2.md)`

The `:MDKListMoc` command retrieves all child nodes of the current buffer and displays them between the `<!--moc:s-->` and `<!--moc:e-->`.

If the `<!--moc:s-->` and `<!--moc:e-->` comments are not present in the current buffer, the list generation will not work.

#### List Orphan Files
The `:MDKListOrphans` command identifies and lists all the files that do not have links in any other nodes.

If the `<!--orphan:s-->` and `<!--orphan:e-->` comments are missing from the current buffer, the list generation will not work.

#### List Nodes Linking to Non-Existent Files
The `:MDKListLTNE` command lists the nodes to the current buffer that contain links to non-existent files.

If the `<!--ltne:s-->` and `<!--ltne:e-->` comments are not found in the current buffer, the list generation will not work.
