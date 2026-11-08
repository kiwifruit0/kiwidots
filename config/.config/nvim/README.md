Language servers and formatters are configured in `lua/config/languages.lua`.
Add a server to `servers` using its nvim-lspconfig name, for example
`rust_analyzer = {}`. Restart Neovim: Mason installs missing declared tools and
enables the server once installed. Only declared servers are enabled, even if
other servers remain installed in Mason. Server-specific options go in the
same table; upstream defaults supply commands, filetypes, and root detection.

Format with `<leader>gf` in normal mode or on a visual selection. Conform runs
the configured formatters in order: Python sorts imports with Ruff and then
formats with Ruff. Project formatter settings take precedence. Formatting is
manual; saving does not reformat files. Add filetype mappings to
`formatters_by_ft` and the formatter's Mason package name to `tools`.

| Action | Command | Shortcut |
| --- | --- | --- |
| Install missing declared tools | `:MasonToolsInstall` | Automatically on startup |
| Update declared servers, formatters, and debug adapters | `:MasonToolsUpdate` | `<leader>lu` |
| Manage installed tools | `:Mason` | `<leader>lm` |
| Inspect active LSP clients | `:checkhealth vim.lsp` | `<leader>li` |
| Inspect formatting providers and errors | `:ConformInfo` | `<leader>lf` |
| Update Neovim plugins and server configurations | `:Lazy update` | |

Plugin update checks run in the background; updates are applied explicitly.
`lazy-lock.json` records plugin revisions for restoring them with `:Lazy restore`.
Mason tools are separate executables and use the tool update command above.
After updating tools, restart Neovim so active clients use the updated binaries.

Diagnostics show signs and inline messages on affected lines.
Use `[d` / `]d` to navigate, `<leader>e` for a floating message,
and `<leader>q` for the buffer's diagnostic list. LSP mappings such as `gd`,
`gi`, `<leader>rn`, and `<leader>ca` are local to attached buffers. Neovim's
defaults include `K` for hover and `grr` for references.

Python hover documentation converts Sphinx fields into parameter, keyword
argument, return, and exception sections, with types beside their names.
Code examples and existing Markdown keep their original formatting. Press `K`
again to focus a long hover and scroll through it.

Switch C/C++ source and header files with `<leader>sh`. Matching filenames are
checked in the same folder and in `src`/`source` and `include`/`inc` folders,
including mirrored subdirectories. This works before compiling or attaching
clangd; save new files first. Clangd handles pairs that the filename lookup
cannot find. To refresh compiler flags after adding sources to CMake, run
`cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`; compilation is not required.

Copilot suggestions use Blink's completion menu through `blink-copilot`, with
up to three suggestions and no extra ranking boost. Exact matches rank first.
`<C-f>` accepts a completion,
`<C-y>` opens completion/documentation, `<C-n>` / `<C-p>` select next/previous
entries (`<C-j>` / `<C-k>` also work) without inserting preview text.
`<C-e>` cancels, and `<Tab>` / `<S-Tab>` move between LuaSnip fields.
`<C-l>` cycles alternatives in a LuaSnip choice field. Friendly Snippets load
automatically; custom Lua snippets can go in `luasnippets/` under the Neovim
config directory. Colorful Menu formats and highlights completion signatures
and types while retaining the hover popup's colors and rounded borders.
LazyDev provides Neovim and plugin API types while editing Lua.

Clangd adds required `#include` directives when accepting completions for symbols
whose owning header is not already included (`--header-insertion=iwyu`).

LaTeX uses VimTeX for editing, compilation, and PDF navigation, with Texlab
providing Blink completion, diagnostics, and LSP navigation. Mason installs
Texlab automatically. LuaSnip loads the existing Friendly Snippets for LaTeX
and BibTeX. VimTeX supplies LaTeX syntax; Tree-sitter highlighting is skipped
for `tex` and `plaintex` buffers.

Install a TeX distribution with `latexmk` and `latexindent`, plus Zathura and a
PDF backend. On Arch, install the required packages with:

```sh
sudo pacman -S --needed texlive-latex texlive-latexrecommended texlive-binextra \
  perl-yaml-tiny perl-file-homedir zathura zathura-pdf-mupdf
```

The Perl packages are required for `latexindent` to run. The `zathura_simple`
integration supports forward/inverse search without requiring `xdotool`.
VimTeX configures the viewer's inverse-search command when launching it.

| LaTeX action | Command | Shortcut |
| --- | --- | --- |
| Start/stop continuous compilation | `:VimtexCompile` | `\ll` |
| Open PDF / jump to source position in PDF | `:VimtexView` | `\lv` |
| Table of contents | `:VimtexTocOpen` | `\lt` |
| Compilation errors | `:VimtexErrors` | `\le` |
| Compiler output | `:VimtexCompileOutput` | `\lo` |
| Project and tool information | `:VimtexInfo` | `\li` |

Start compilation once with `\ll`; subsequent saves rebuild the PDF. In
Zathura, Ctrl-click jumps back to the source. Texlab's build-on-save remains
disabled so VimTeX manages compilation. Set project-specific compiler options
in `.latexmkrc` or select an engine with a `% !TeX program = lualatex` directive
in the main document. For multi-file documents, a `% !TeX root = ../main.tex`
directive in a child file identifies the main document.

`<leader>gf` formats LaTeX with Texlab's `latexindent` formatter and BibTeX
with Texlab's built-in formatter through Conform's LSP fallback. Formatting
remains manual; saving only triggers compilation after `\ll` has started it.
