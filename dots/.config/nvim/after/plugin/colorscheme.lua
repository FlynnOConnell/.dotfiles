-- Set the catppuccin flavour
vim.g.catppuccin_flavour = "mocha"

-- Get the palette of the selected flavour
local mocha = require("catppuccin.palettes").get_palette("mocha")

-- Configuration of the catppuccin theme
require("catppuccin").setup {
	compile = {
		-- Compile the theme on startup
		enabled = true,
		path = vim.fn.stdpath("cache") .. "/catppuccin",
	},
	dim_inactive = {
		enabled = true,
		shade = "dark",
		percentage = 0.70,
	},
	integrations = {
		lsp_trouble = true,
		treesitter = true,
		gitsigns = true,
		cmp = true,
		nvimtree = true,
		telescope = true,
		which_key = true,
		dap = {
			enabled = true,
			enable_ui = true,
		},
		noice = true,
	},

    highlight_overrides = {
		all = {},
		latte = {},
		frappe = {},
		macchiato = {},
		mocha = {
			-- Neovim Colours
			-- Tabline
			TabLineFill = { fg = mocha.lavender, bg = mocha.base },
			TabLineSel = { fg = mocha.subtext1, bg = mocha.surface1 },
			TabLine = { fg = mocha.overlay0, bg = mocha.surface0 },

			-- Editor
			Comment = { fg = mocha.overlay1 },
			CursorLineNR = { fg = mocha.yellow },

			-- Splits
			VertSplit = { fg = mocha.surface0 },

			-- Floats
			FloatNormal = { fg = mocha.text, bg = mocha.mantle },
			FloatBorder = { fg = mocha.surface2 },

			-- Mason Colours
			MasonHeader = { fg = mocha.base, bg = mocha.peach },
			MasonHeaderSecondary = { fg = mocha.base, bg = mocha.teal },

			MasonHighlight = { fg = mocha.teal },
			MasonHighlightBlock = { bg = mocha.teal, fg = mocha.base },
			MasonHighlightBlockBold = { bg = mocha.teal, fg = mocha.base, bold = true },

			MasonHighlightSecondary = { fg = mocha.red },
			MasonHighlightBlockSecondary = { bg = mocha.red, fg = mocha.base },
			MasonHighlightBlockBoldSecondary = { bg = mocha.red, fg = mocha.base, bold = true },

			MasonLink = { fg = mocha.rosewater },

			MasonMuted = { fg = mocha.overlay1 },
			MasonMutedBlock = { bg = mocha.surface0, fg = mocha.overlay1 },
			MasonMutedBlockBold = { bg = mocha.surface0, fg = mocha.overlay1, bold = true },

			MasonError = { fg = mocha.red },

			MasonHeading = { bold = true },

			-- Alpha Colours
			AlphaHeader = { fg = mocha.surface0 },
			AlphaFooter = { fg = mocha.surface2 },
			AlphaSectionHeader = { fg = mocha.surface2, bold = true },
			AlphaShortcut = { fg = mocha.surface2 },

			--Telescope Colours
			TelescopeNormal = { fg = mocha.text, bg = mocha.mantle },
			TelescopeBorder = { fg = mocha.surface2 },
			TelescopeTitle = { fg = mocha.subtext0 },
		},
	},
}

-- Apply the catppuccin theme
vim.api.nvim_command "colorscheme catppuccin"
