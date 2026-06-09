Config = {}

-- Chat Settings
Config.MaxMessages = 100
Config.MaxMessageLength = 255
Config.ChatKey = 'T'
Config.HideTimeout = 5000 -- 5 seconds before chat fades
Config.SuggestionLimit = 6

-- Visual Settings
Config.CommandPrefix = '/'
Config.SuggestCommands = true

-- Chat Types (clean labels for death freeroam)
Config.ChatTypes = {
    ['normal'] = { label = 'CHAT' },
    ['system'] = { label = 'SYSTEM' },
    ['admin'] = { label = 'ADMIN' },
    ['error'] = { label = 'ERROR' }
}

-- Simple commands for death freeroam (no RP)
Config.DefaultCommands = {
    { name = 'help', desc = 'Show available commands', args = '' },
    { name = 'clear', desc = 'Clear your chat', args = '' }
}
