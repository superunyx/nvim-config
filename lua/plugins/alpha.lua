return {
    'goolord/alpha-nvim',
    config = function()
        local dashboard = require('alpha.themes.dashboard')

        dashboard.config.layout = {
            { type = "padding", val = 1 },
            dashboard.section.header,
            { type = "padding", val = 2 },
            dashboard.section.buttons,
            dashboard.section.footer,
        }

        require('alpha').setup(dashboard.config)
    end,
}
