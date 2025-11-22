local orig_virtual_text = vim.diagnostic.handlers.virtual_text

vim.diagnostic.handlers.virtual_text = {
  show = function(namespace, bufnr, diagnostics, opts)
    local filtered = {}
    local most_severe_per_line = {}

    -- Find the most severe diagnostic per line
    for _, d in ipairs(diagnostics) do
      local existing = most_severe_per_line[d.lnum]
      if not existing or d.severity < existing.severity then
        most_severe_per_line[d.lnum] = d
      end
    end

    -- Collect them into a list
    for _, d in pairs(most_severe_per_line) do
      table.insert(filtered, d)
    end

    -- Show only the filtered diagnostics
    orig_virtual_text.show(namespace, bufnr, filtered, opts)
  end,

  hide = orig_virtual_text.hide,
}
