angular.module('locale', ['pascalprecht.translate'])

	.config ($translateProvider) ->
		$translateProvider
			.useSanitizeValueStrategy 'escape'
			.useStaticFilesLoader
				prefix: 'locale/'
				suffix: '.json'
			.registerAvailableLanguageKeys ['en', 'zh_TW'],
				'en_*':	'en'
				'zh_*': 'zh_TW'
			.determinePreferredLanguage()
			.fallbackLanguage('en')
