# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
# Rails.application.config.assets.initialize_on_precompile = false

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile += 
	%w( default/users.css users.js
			zhengjuan.css init_zhengjuan.js ztree.js ztree.css
			report.css init_report.js
			echarts.min.js
			managers/mains.css managers/mains.js
			managers/subject_checkpoints.js managers/checkpoints.js managers/checkpoints.css
			jquery.remotipart.js
			default/ques-bank.css
		)
# # 用户中心
# Rails.application.config.assets.precompile += ['default/users.css.scss', 'users.js']
# # 整卷解析
# Rails.application.config.assets.precompile += ['zhengjuan.css', 'init_zhengjuan.js']
# # 诊断报告
# Rails.application.config.assets.precompile += ['report.css', 'init_report.js']
# # 百度eCharts.js
# Rails.application.config.assets.precompile += ['echarts.min.js']

# Rails.application.config.assets.precompile += ['managers/mains.css', 'managers/mains.js']

# Rails.application.config.assets.precompile += ['managers/checkpoints.css', 'managers/checkpoints.js']

# Rails.application.config.assets.precompile += ['managers/subject_checkpoints.js']

# Rails.application.config.assets.precompile += ['jquery.remotipart.js']

# Rails.application.config.assets.precompile += ['default/ques-bank.css']