# telescope-rg

`telescope-rg` is an extension for [telescope.nvim][], which enables users to utilize [ripgrep (rg)](https://github.com/BurntSushi/ripgrep) within the telescope interface.

[telescope.nvim]: https://github.com/nvim-telescope/telescope.nvim
[ripgrep (rg)]: https://github.com/BurntSushi/ripgrep

## Setup

To load the extension, use the following command:

```lua
require('telescope').load_extension('rg')
```

## Usage

```vim
:Rg your-search-query
```

This will also register the search results in the quickfix list.
