# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
# Rails.application.config.assets.initialize_on_precompile = false

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# # 用户中心
Rails.application.config.assets.precompile += ['default/users.css', 'users.js']
# # 整卷解析
Rails.application.config.assets.precompile += ['zhengjuan.css', 'init_zhengjuan.js', 'ztree.js', 'ztree.css']
# # 诊断报告
Rails.application.config.assets.precompile += ['report.css', 
	'init_report.js',
	'create_report.js',
	'000016090/report/new_report.css.scss',
	'000016090/report/init_new_report.js'
]
#Rails.application.config.assets.precompile += ['new_report.css.scss', 'init_new_report.js']

# # 百度eCharts.js
Rails.application.config.assets.precompile += ['echarts.min.js', 'echarts_themes/macarons.js', 'echarts_themes/vintage.js']

Rails.application.config.assets.precompile += ['managers/mains.css', 'managers/mains.js']

Rails.application.config.assets.precompile += ['managers/subject_checkpoints.css.scss', 'managers/subject_checkpoints.js', 'managers/checkpoints.css', 'managers/checkpoints.js']

Rails.application.config.assets.precompile += [
	'managers/selected_nodes_tree.js', 
	'managers/node_subject_checkpoints.js', 
	'managers/node_structure_catalog.js', 
	'managers/node_catalog_checkpoint_combination.js',
	'managers/node_catalog_checkpoint_display.js'
]

Rails.application.config.assets.precompile += ['jquery.remotipart.js']

Rails.application.config.assets.precompile += ['default/ques-bank.css']
