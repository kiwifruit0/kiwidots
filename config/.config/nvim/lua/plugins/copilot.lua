return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    suggestion = { enabled = false }, -- Suggestions appear in Blink's completion menu.
    panel = { enabled = false },
    filetypes = { rocq = false, coq = false },
  },
}
