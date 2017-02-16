# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
# Rails.application.config.assets.initialize_on_precompile = false

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )


Rails.application.config.assets.precompile += [
#用户中心
	'default/users.css', 
	'users.js',
#整卷解析
	'zhengjuan.css', 
	'init_zhengjuan.js', 
	'ztree.js', 
	'ztree.css',
	'000016090/paper/zheng_juan.js',
#诊断报告
	'report.css', 
	'init_report.js',
	'create_report.js',
	'000016090/report/new_report.css.scss',
	'000016090/report/init_new_report.js',
	'00016110/report.css.scss',
	'00016110/report/init_report.js',
#百度eCharts.js
	'echarts.min.js', 
	'echarts_themes/macarons.js', 
	'echarts_themes/vintage.js',
	'jquery.remotipart.js',
	'default/ques-bank.css']
