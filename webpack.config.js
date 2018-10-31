const path = require('path')
const srcPath = path.join(__dirname, 'src') + path.sep
const widgetWebpack = require('materia-widget-development-kit/webpack-widget')

const entries = widgetWebpack.getDefaultEntries()

delete entries['creator.js']
delete entries['player.js']

entries['modules/matching.js'] = [path.join(srcPath, 'modules', 'matching.coffee')]
entries['controllers/creator.js'] = [path.join(srcPath, 'controllers', 'creator.coffee')]
entries['controllers/player.js'] = [path.join(srcPath, 'controllers', 'player.coffee')]
entries['directives/audioControls.js'] = [path.join(srcPath, 'directives', 'audioControls.coffee')]
entries['directives/focusMe.js'] = [path.join(srcPath, 'directives', 'focusMe.coffee')]
entries['directives/ngEnter.js'] = [path.join(srcPath, 'directives', 'ngEnter.coffee')]
entries['directives/inputStateManager.js'] = [path.join(srcPath, 'directives', 'inputStateManager.coffee')]
entries['audioControls.css'] = [
	srcPath + 'audioControls.scss',
	srcPath + 'audioControls.html'
]

// options for the build
let options = {
	entries: entries
}

module.exports = widgetWebpack.getLegacyWidgetBuildConfig(options)

