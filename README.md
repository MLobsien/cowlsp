# cowlsp.nvim

**Cowsay integration for every LSP client.
Let a cow (or whatever creature you prefer) diagnose your code!**

## Setup
```lua
require("cowlsp").setup()
```

## Prerequisites

- cowsay program in your path

## Configuration

| Option | Description | Type | Default |
| ------ | ----------- | ---- | ------- |
| cow | Which cowfile should be used | string | `"default"`
| random | Wether to use a random cowfile | boolean | `false`
| files | Restrict random selection to the given files | table\<string>
| eyes | Which eyes to use | string | `"oo"`
| tongue | Which tongue to use | string | `"  "`
| key | Triggers cowlsp hover | string | `"<S-k>"`
| callback | Function that modifies LSP responses. Takes the client responses as input and returns the lines that should be displayed | function(t: table) -> table\<string> |
