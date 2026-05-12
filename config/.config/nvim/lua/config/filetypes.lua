vim.filetype.add({
    extension = {
        vil = "vil",
    },
})

vim.treesitter.language.register("json", "vil")

