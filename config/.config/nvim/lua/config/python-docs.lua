local M = {}

local sections = {
  param = "Parameters",
  parameter = "Parameters",
  arg = "Parameters",
  argument = "Parameters",
  keyword = "Keyword arguments",
  key = "Keyword arguments",
  kwarg = "Keyword arguments",
  type = "type",
  paramtype = "type",
  returns = "Returns",
  ["return"] = "Returns",
  rtype = "rtype",
  raises = "Raises",
  raise = "Raises",
  except = "Raises",
  exception = "Raises",
}

local function unescape(text)
  return (text:gsub("\\([_%[%]*~])", "%1"))
end

local function code(text)
  text = unescape(vim.trim(text)):gsub(":[%w_:.%-]+:`~?([^`]+)`", "%1"):gsub("`", "")
  return "`" .. text:gsub("^~", "") .. "`"
end

local function inline(text)
  -- Pyright can split reST links across lines and escape their trailing underscore.
  text = text:gsub("&lt;", "<"):gsub("&gt;", ">")
  text = text:gsub("`([^`]-)%s*<([^>]+)>`\\?_", function(label, url)
    return "[" .. vim.trim(label) .. "](" .. url .. ")"
  end)
  text = text:gsub(":[%w_:.%-]+:`~?([^`]+)`", function(target)
    return code(target)
  end)
  return text
end

local function prose_line(text)
  -- Pyright encodes continuation indentation as HTML non-breaking spaces.
  return vim.trim(text:gsub("&nbsp;", " "):gsub("\194\160", " "))
end

-- This handles Sphinx info fields, rather than trying to parse all of reST.
-- Keep ordinary Markdown and fenced examples exactly as the server supplied them.
function M.format(text)
  local nodes, fields, types = {}, {}, {}
  local active, fence
  local function finish()
    active = nil
  end

  for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
    local marker = line:match("^%s*(```+)") or line:match("^%s*(~~~+)")
    if marker then
      finish()
      if not fence then
        fence = marker
      elseif marker:sub(1, 1) == fence:sub(1, 1) and #marker >= #fence and line:match("^%s*[`~]+%s*$") then
        fence = nil
      end
      nodes[#nodes + 1] = line
    elseif fence then
      nodes[#nodes + 1] = line
    else
      local tag, argument, body = line:match("^%s*:([%a]+)%s*(.-):%s*(.*)$")
      local section = sections[tag]
      if section then
        active = { section = section, argument = unescape(argument), body = { prose_line(body) } }
        fields[#fields + 1] = active
        nodes[#nodes + 1] = active
      elseif active and line:match("%S") and not tag then
        active.body[#active.body + 1] = prose_line(line)
      else
        finish()
        nodes[#nodes + 1] = line
      end
    end
  end
  if #fields == 0 then
    return text
  end

  local return_type, has_return
  for _, field in ipairs(fields) do
    field.description = inline(table.concat(field.body, " "))
    if field.section == "type" then
      types[field.argument] = field.description
    elseif field.section == "rtype" then
      return_type = field.description
    elseif field.section == "Returns" then
      has_return = true
    else
      -- Types can contain spaces (e.g. dict[str, Any]); the final token is the name.
      field.type, field.name = field.argument:match("^(.-)%s+([%w_.*]+)$")
      field.name = field.name or field.argument
    end
  end

  local documented = {}
  for _, field in ipairs(fields) do
    if field.name then
      documented[field.name] = true
    end
  end

  local output, section = {}, nil
  local function emit(group, value)
    if group ~= section then
      if #output > 0 and output[#output] ~= "" then
        output[#output + 1] = ""
      end
      output[#output + 1] = "**" .. group .. "**"
      output[#output + 1] = ""
      section = group
    end
    output[#output + 1] = value
  end

  for _, node in ipairs(nodes) do
    if type(node) == "string" then
      output[#output + 1] = node
      if node:match("%S") then
        section = nil
      end
    elseif node.section == "type" then
      if not documented[node.argument] then
        emit("Parameters", "- " .. code(node.argument) .. " (" .. code(node.description) .. ")")
      end
    elseif node.section == "rtype" then
      if not has_return then
        emit("Returns", code(node.description))
      end
    elseif node.section == "Returns" then
      local prefix = return_type and (code(return_type) .. " — ") or ""
      emit(node.section, prefix .. node.description)
    else
      local label = code(node.name)
      local kind = node.type or types[node.name]
      if kind then
        label = label .. " (" .. code(kind) .. ")"
      end
      emit(node.section, "- " .. label .. (node.description ~= "" and (" — " .. node.description) or ""))
    end
  end
  return table.concat(output, "\n")
end

function M.setup()
  local hover = require("noice.lsp.hover")
  if M.installed then
    return
  end
  M.installed = true
  local on_hover = hover.on_hover
  hover.on_hover = function(err, result, ctx, ...)
    if
      result
      and ctx
      and ctx.bufnr
      and vim.api.nvim_buf_is_valid(ctx.bufnr)
      and vim.bo[ctx.bufnr].filetype == "python"
    then
      result = vim.deepcopy(result)
      local function convert(contents)
        if type(contents) == "string" then
          return M.format(contents)
        elseif type(contents) == "table" then
          if contents.kind == "markdown" then
            contents.value = M.format(contents.value)
          elseif vim.islist(contents) then
            for i, item in ipairs(contents) do
              contents[i] = convert(item)
            end
          end
        end
        return contents
      end
      result.contents = convert(result.contents)
    end
    return on_hover(err, result, ctx, ...)
  end
end

return M
