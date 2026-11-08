-- Run from the config directory: nvim --headless -u NONE -i NONE -l tests/python-docs.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
local docs = require("config.python-docs")
local checks = 0
local function equal(expected, actual)
  assert(vim.deep_equal(expected, actual), "Expected:\n" .. vim.inspect(expected) .. "\nGot:\n" .. vim.inspect(actual))
  checks = checks + 1
end

local signature = "```python\ndef query_items(query: str) -> CosmosItemPaged\n```"
local input = signature
  .. [=[

Return all results matching the given `query`.

:param str query: The Azure Cosmos DB SQL query to execute.  
:param parameters: Optional array of parameters to the query.  
    Each parameter is a dict() with 'name' and 'value' keys.
Ignored if no query is provided.  
:type parameters: \[list\[dict\[str, object\]\]\]  
:param partition\_key: Partition key at which the query request is targeted. If the partition key is set to  
    None, it will perform a cross partition query. See `here
<https://example.com/PartitionKeys.md>`\_.  
:type partition\_key: \~azure.cosmos.partition\_key.PartitionKeyType  
:keyword Literal\["Local", "Global"\] full\_text\_score\_scope: Sets the scope for computing BM25 statistics.  
    When set to "Local", statistics are computed only over the subset of documents.
:keyword response\_hook: A callable invoked with the response metadata.  
:paramtype response\_hook: Callable\[\[Mapping\[str, str\], dict\[str, Any\]\], None\]  
:keyword Union\[bool, dict\[str, Any\]\] availability\_strategy: Enables an availability strategy.  
    Can be True, False, or a dict with keys `threshold_ms` and `threshold_steps_ms`.
If not provided, uses the client's configured strategy.  
:paramtype availability\_strategy: Union\[bool, dict\[str, Any\]\]  
:returns: An Iterable of items (dicts).  
:rtype: CosmosItemPaged]=]

local expected = signature
  .. [=[

Return all results matching the given `query`.

**Parameters**

- `query` (`str`) — The Azure Cosmos DB SQL query to execute.
- `parameters` (`[list[dict[str, object]]]`) — Optional array of parameters to the query. Each parameter is a dict() with 'name' and 'value' keys. Ignored if no query is provided.
- `partition_key` (`azure.cosmos.partition_key.PartitionKeyType`) — Partition key at which the query request is targeted. If the partition key is set to None, it will perform a cross partition query. See [here](https://example.com/PartitionKeys.md).

**Keyword arguments**

- `full_text_score_scope` (`Literal["Local", "Global"]`) — Sets the scope for computing BM25 statistics. When set to "Local", statistics are computed only over the subset of documents.
- `response_hook` (`Callable[[Mapping[str, str], dict[str, Any]], None]`) — A callable invoked with the response metadata.
- `availability_strategy` (`Union[bool, dict[str, Any]]`) — Enables an availability strategy. Can be True, False, or a dict with keys `threshold_ms` and `threshold_steps_ms`. If not provided, uses the client's configured strategy.

**Returns**

`CosmosItemPaged` — An Iterable of items (dicts).]=]
equal(expected, docs.format(input))
equal(expected, docs.format(expected)) -- Safe to run more than once.

for _, text in ipairs({
  "Plain text with `code` and [a link](https://example.com).",
  "Args:\n    value (int): A value.\n\nReturns:\n    int: Result.",
  "Parameters\n----------\nvalue : int\n    A value.",
  "```python\n:param example: This is a code example.\n```",
  "~~~~rst\n:param example: Also a code example.\n~~~\n~~~~",
}) do
  equal(text, docs.format(text))
end

equal("**Returns**\n\n`list[str]`", docs.format(":rtype: list\\[str\\]"))
equal("**Parameters**\n\n- `value` (`int`)", docs.format(":type value: int"))
equal("**Parameters**\n\n- `value` (`int`) — Value.", docs.format(":type value: int\n:param value: Value."))
equal("**Raises**\n\n- `ValueError` — Invalid input.", docs.format(":raises ValueError: Invalid input."))
equal(
  "**Parameters**\n\n- `value` — First line. Second line. Third line.",
  docs.format(":param value: First line.\n&nbsp;&nbsp;&nbsp;&nbsp;Second line.\n\194\160Third line.")
)
equal(
  "**Parameters**\n\n- `value` (`package.Class`) — Value.",
  docs.format(":param value: Value.\n:type value: :class:`~package.Class`")
)

local fenced = "\n\n```python\n:param untouched: example\n```"
equal("**Parameters**\n\n- `value` (`str`) — Value." .. fenced, docs.format(":param str value: Value." .. fenced))

-- Exercise the Noice callback boundary, including legacy LSP content forms.
local received
package.loaded["noice.lsp.hover"] = {
  on_hover = function(err, result, ctx, config)
    received = { err = err, result = result, ctx = ctx, config = config }
  end,
}
docs.setup()
local handler = require("noice.lsp.hover").on_hover
docs.setup()
equal(handler, require("noice.lsp.hover").on_hover)
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].filetype = "python"
local ctx, config = { bufnr = buf }, { test = true }
local result = { contents = { kind = "markdown", value = input } }
handler(nil, result, ctx, config)
equal(expected, received.result.contents.value)
equal(input, result.contents.value) -- Do not mutate the LSP's response.
equal(ctx, received.ctx)
equal(config, received.config)

local legacy = { contents = { { language = "python", value = ":param code: untouched" }, ":param str value: Value." } }
handler(nil, legacy, ctx)
equal(legacy.contents[1], received.result.contents[1])
equal("**Parameters**\n\n- `value` (`str`) — Value.", received.result.contents[2])
handler(nil, { contents = { kind = "plaintext", value = input } }, ctx)
equal(input, received.result.contents.value)
vim.bo[buf].filetype = "lua"
handler(nil, result, ctx)
equal(result, received.result)
handler({ message = "Server error" }, nil, ctx)
equal(nil, received.result)
equal("Server error", received.err.message)
vim.api.nvim_buf_delete(buf, { force = true })
handler(nil, result, ctx)
equal(result, received.result)

print(("Python documentation: %d checks passed"):format(checks))
