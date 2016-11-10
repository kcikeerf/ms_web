var reportPage = {
	getGradeUrl : '/reports/get_grade_report',
	getClassUrl : '/reports/get_class_report',
	getPupilUrl : '/reports/get_pupil_report',
	ProjectData : null,
	CurrentProjectId : null,
	CurrentProjectUrl : null,
	GradeData : null,
	CurrentGradeId : null,
	CurrentGradeUrl : null,
	KlassData : null,
	CurrentKlassId : null,
	CurrentKlassUrl : null,
	PupilData : null,
	CurrentPupilId : null,
	CurrentPupilUrl : null,
	CurrentBreadCrumb : null,
	ReportCkpStartLevel: 1,
	FullScore: 100,
	defaultColor: "#51b8c1",
	chartColor : ['#a2f6e6','#6cc2bd','#15a892','#88c2f8','#6789ce','#254f9e','#eccef9','#bf9ae0','#8d6095'],

	init: function(){
		// 导航添加事件
		$('.zy-grade-menu > li > a').on('click', function() {
			var reportType = $(this).attr('data_type');
			var reportId = $(this).attr('report_id');
			var reportName = $(this).attr('report_name');

			var reportInfo = {
				reportType: reportType,
				reportName: reportName,
				reportId: reportId,
				upperReportIds: {}
			}

			if(!reportId){
				return false;
			}
			$('.zy-report-type').html('年级报告');
			if(reportType == 'grade'){
				$('#reportContent').load('/reports/grade',function(){
					reportPage.baseFn.getReportAjax(reportInfo, reportPage.getGradeUrl);
				});
			}
		});
		/*默认显示*/
		$('.zy-grade-menu > li > a:first').trigger('click');

		reportPage.bindEvent();
	},
	bindEvent: function(){
		/*顶部导航*/
		reportPage.baseFn.report_menu_construct('.zy-report-nav-container');
		$('ul.zy-report-menu > li > a').on('click', function(){
			var data_type = $(this).attr('data_type');
			var report_url = $(this).attr('report_url');
			$('#reportContent').load('/reports/'+data_type,function(){

				var from_type = null; 
				switch(data_type){
					case "pupil":
						from_type = "klass";
						break;
					case "klass":
						from_type = "grade";
						break;
					case "grade":
						from_type = "project";
						break;
					case "project":
						// do nothing
						break;
				}
				var url_arr = report_url.split("/");
				var from_arr = url_arr.slice( 0, (url_arr.length - 2) );
				var from_url = from_arr.join("/") + ".json";

				var args = {
					from_type: from_type, 
					from_url: from_url, 
					end_type: data_type, 
					end_url: report_url
				}
				reportPage.baseFn.update_to_top(args);
				//reportPage.baseFn.getReportAjax(report_url,{reportType: data_type, to_create: true});
			});
		});
		$(document).on('show.bs.collapse','.panel-collapse',function(){
			$(this).prev().removeClass('collapse-close');
			$(this).prev().addClass('collapse-open');
		});
		$(document).on('hide.bs.collapse','.panel-collapse',function(){
			$(this).prev().removeClass('collapse-open');
			$(this).prev().addClass('collapse-close');
		});
	},
	/*基础方法*/
	baseFn: {
		getReportAjax: function(url,options={reportType: null}, callback, args={}){
			$.ajax({
				url: url,
				type: "GET",
				data: "",
				dataType: "json",
				success: function(data){
					var url_arr = url.split("/");
					var last_url_id = url_arr[ url_arr.length -1 ].split(".")[0];

					if (options.reportType == "project") {
						reportPage.ProjectData = data;
						reportPage.CurrentProjectId = last_url_id;

					} else if (options.reportType == "grade") {
						reportPage.GradeData = data;
						reportPage.CurrentGradeId = last_url_id;

					} else if (options.reportType == "klass") {
						reportPage.KlassData = data;
						reportPage.CurrentKlassId = last_url_id;

					} else if (options.reportType == "pupil") {
						reportPage.PupilData = data;
						reportPage.CurrentPupilId = last_url_id;

					}
					callback(args);
				},
				error: function(data){
					$('#reportContent').html(data.responseJSON.message);
					//$('#reportContent')[0].style = "position:relative;display: flex;"
					//$('#reportContent')[0].style = "display: block;"
				}
			});
		},
		update_to_top: function(args={}){
			from_type = args["from_type"];
			from_url = args["from_url"];
			end_type = args["end_type"];
			end_url = args["end_url"];

			if(!from_type || !end_type || !from_url || ! end_url){
				return false;
			}

			var from_url_arr = from_url.split("/");
			var currentId = from_url_arr[ from_url_arr.length -1 ].split(".")[0];
			var next_type = null;
			var reportCurrentId = null;
			var reportCurrentUrl = null;
			var next_arr = from_url_arr.slice( 0, (from_url_arr.length - 2) );
			var next_url = next_arr.join("/") + ".json";
	        var createReportFunc = null;

			switch(from_type){
				case "pupil":
					next_type = "klass";
					reportCurrentId = reportPage.PupilId;
					reportCurrentUrl = reportPage.CurrentPupilUrl;
					createReportFunc = reportPage.Pupil.createReport;
					break;
				case "klass":
					next_type = "grade";
					reportCurrentId = reportPage.KlassId;
					reportCurrentUrl = reportPage.CurrentKlassUrl;
					createReportFunc = reportPage.Class.createReport;
					break;
				case "grade":
					next_type = "project";
					reportCurrentId = reportPage.GradeId;
					reportCurrentUrl = reportPage.CurrentGradeUrl;
					createReportFunc = reportPage.Grade.createReport;
					break;
				case "project":
					next_type = end_type;
					reportCurrentId = reportPage.ProjectId;
					reportCurrentUrl = reportPage.CurrentProjectUrl;
					createReportFunc = reportPage.Project.createReport;
					break;
			}

			if( reportCurrentId != currentId ){
				if( from_type == end_type ){
					reportPage.baseFn.getReportAjax( end_url, { reportType: end_type }, createReportFunc );
				} else {
					args["from_type"] = next_type;
					args["from_url"] = next_url;
					reportPage.baseFn.getReportAjax( from_url, { reportType: from_type }, reportPage.baseFn.update_to_top, args);
				}
			}
		},
		report_menu_construct: function(current_list){
			$(current_list).hover(function(){
		 		$(this).children("ul.zy-report-menu").show();
		 		$(this).children("ul.zy-report-menu").children('li').show();
				reportPage.baseFn.report_menu_construct(current_list + " > ul.zy-report-menu > li ");
			},function(){
		 		$(this).children("ul.zy-report-menu").hide();
		 		$(this).children("ul.zy-report-menu").children('li').hide();
			});
		},
		/*答题情况*/
		getAnswerCaseTable : function(data){
			if(data != null){
				var qid = reportPage.baseFn.getArrayKeysNoModify(data);
				var correctRatio = reportPage.baseFn.getArrayValue(data);
				console.log(correctRatio);
				var str = '';
				for(var i = 0; i < qid.length ; i++){
					if(correctRatio[i].correct_ratio){
						str += '<tr><td>'+qid[i]+'</td><td>'+correctRatio[i].correct_ratio+'</td><td>'+ correctRatio[i].checkpoint +'</td></tr>';
					} else {
						str += '<tr><td>'+qid[i]+'</td><td>'+correctRatio[i]+'</td><td> - </td></tr>';
					}
				};
				return str;
			}else{
				return '';
			};
		},
		/*处理获取scale图表数据*/
		getScale : function(obj) {
			var goodArr = [],
				faildArr = [],
				excellentArr = [];
			for (var i = 0; i < obj.length; i++) {
				excellentArr.push({
					name: '(得分率 ≥ 85)',
					value: obj[i].excellent_pupil_percent,
					yAxisIndex: i,
				});
				goodArr.push({
					name: '( 60 ≤ 得分率 < 85)',
					value: obj[i].good_pupil_percent,
					yAxisIndex: i,
				});
				faildArr.push({
					name: '(得分率 < 60)',
					value: obj[i].failed_pupil_percent,
				});
			}
			return obj = {
				excellent: excellentArr,
				good: goodArr,
				failed: faildArr
			}
		},

		/*处理获取diff正负值*/
		getDiff: function(obj) {
			var arr = reportPage.baseFn.getValue(obj);
			var len = arr.length;
			var upArr = [];
			var downArr = [];
			for (var i = 0; i < len; i++) {
				if (arr[i] >= 0) {
					upArr.push({
						value: arr[i],
						symbolSize: 5
					});
					downArr.push({
						value: 0,
						symbolSize: 0
					});
				} else if (arr[i] < 0) {
					downArr.push({
						value: arr[i],
						symbolSize: 5
					});
					upArr.push({
						value: 0,
						symbolSize: 0
					});
				};
			};
			reportPage.baseFn.pushArr(upArr);
			reportPage.baseFn.pushArr(downArr);
			return obj = {
				up: upArr,
				down: downArr
			}
		},
		pushArr: function(obj) {
			if (Object.prototype.toString.call(obj[0]) == "[object String]") {
				obj.push('');
				obj.unshift('');
			} else {
				obj.push({
					value: 0,
					symbolSize: 0
				});
				obj.unshift({
					value: 0,
					symbolSize: 0
				});
			};
			return obj;
		},
		/*获取对象的key数组*/
		getKeys: function(obj) {
			if(obj){
				//return Object.keys(obj);
				return reportPage.baseFn.modifyKey($.map(Object.keys(obj), function(value, index) {
					return [value];
				}));
			}else{
				return [];
			}
		},
		/*获取对象的value数组*/
		getValue: function(obj) {
			if(obj){
				return $.map(obj, function(value, index) {
					return [value];
				});
		    } else {
		    	return [];
		    } 
		},
		/*获取答对题的key数组*/
		getArrayKeys: function(obj) {
			if(obj){
				return reportPage.baseFn.modifyKey($.map(obj, function(value, index) {
					return [value[0]];
				}));
			}else{
				return [];
			}
		},
		/*获取答对题的value数组*/
		getArrayValue: function(obj) {
			if(obj){
				return $.map(obj, function(value, index) {
					return [value[1]];
				});
		    } else {
		    	return [];
		    }
		},
		getBarValue: function(obj){
			var arr = reportPage.baseFn.getValue(obj);
			var len = arr.length;
			var result = [];
			for (var i = 0; i < len; i++) {
				result.push({
					value: arr[i],
					label: {
						normal:{
							position: 'top'
						}
					},
				});
			};
			return result;
		},
		/*获取对象的key数组*/
		getKeysNoModify: function(obj) {
			if(obj){
				//return Object.keys(obj);
				return $.map(Object.keys(obj), function(value, index) {
					return [value];
				});
			}else{
				return [];
			}
		},
		/*获取答对题的key数组*/
		getArrayKeysNoModify: function(obj) {
			if(obj){
				return $.map(obj, function(value, index) {
					return [value[0]];
				});
			}else{
				return [];
			}
		},
		modifyKey: function(arr){
			for(var i =0; i < arr.length; i++){
				c_arr = arr[i].split("");
				labelInterval = (c_arr.length > 10)? 2:1;
				for(var j =0; j < c_arr.length; j++){
					if(labelInterval == 1){
						if(c_arr[j] == "（" || c_arr[j] == "("){
							c_arr[j] = "︵";
						} else if(c_arr[j] == "）" || c_arr[j] == ")"){
							c_arr[j] = "︶";
						}}
					if((j+1)%labelInterval == 0 ){
						c_arr[j]+= "\n";
					}
				}
				arr[i] = c_arr.join("");
			}
			return arr;
		},
		modifyAKey: function(str){
			//for(var i =0; i < arr.length; i++){
				c_arr = str.split("");
				labelInterval = (c_arr.length > 10)? 2:1;
				for(var j =0; j < c_arr.length; j++){
					if(labelInterval == 1){
						if(c_arr[j] == "（" || c_arr[j] == "("){
							c_arr[j] = "︵";
						} else if(c_arr[j] == "）" || c_arr[j] == ")"){
							c_arr[j] = "︶";
						}}
					if((j+1)%labelInterval == 0 ){
						c_arr[j]+= "\n";
					}
				}
			//}
			return c_arr.join("");
		},
		extendObj: function(obj_arr){
		  var result = {};
		  var key = "";

          for(var i=0; i < obj_arr.length; i++){
          	$.extend(result, obj_arr[i]);
          }
          return result;
		},
		// [{"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}, {"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}]
		get_lv_n_ckp_data: function(value_arr, ckp_level=reportPage.ReportCkpStartLevel){
			var result_obj_arr = [];
			var next_obj_arr = [];

			result_obj_arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( value_arr )), function(value, index){ return value } );
			next_obj_arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( value_arr )), function(value, index){ return value.items } );
			for(var i = 1; i < ckp_level; i++){
				result_obj_arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( next_obj_arr )), function(value, index){ return value } );
				next_obj_arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( next_obj_arr )), function(value, index){ return value.items } );
			}
			return result_obj_arr;
		},
		// [{"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}, {"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}]
		get_key_values: function(value_arr, value_key, ckp_level=reportPage.ReportCkpStartLevel){
			//console.log(value_arr);
			// [{"key1":"value1", "key2":"value2"}, {"key1":"value1", "key2":"value2"}]
			var arr = reportPage.baseFn.get_lv_n_ckp_data(value_arr, ckp_level);//getValue(reportPage.baseFn.extendObj(value_arr));
			var keys = [];
			var values = [];

			for(var i=0 ; i < arr.length ; i++) {
				keys.push(reportPage.baseFn.modifyAKey(arr[i].checkpoint));
				values.push(reportPage.baseFn.formatTimesValue(arr[i][value_key]));
			}
			// [["value1", "value2"], ["value3", "value4"]]
			return [keys, values];
		},
		// [{"xxxxxx": {"key1":"value1", "key2":"value3"}}, {"xxxxxx": {"key1":"value1", "key2":"value4"}}]
		get_keys_diff_values: function(value1_arr, value2_arr, value1_key, value2_key=value1_key, ckp_level=reportPage.ReportCkpStartLevel){
			var value1_kv_arr = reportPage.baseFn.get_key_values(value1_arr, value1_key, ckp_level);
			var value2_kv_arr = reportPage.baseFn.get_key_values(value2_arr, value2_key, ckp_level);
			var keys_arr = [];
			var values_diff_arr = [];//to be continued
			for(var i=0; i < value1_kv_arr[1].length; i++) {
				if(value1_kv_arr[0][i] == value2_kv_arr[0][i]){
					keys_arr.push(value1_kv_arr[0][i]);
					values_diff_arr.push((value1_kv_arr[1][i] - value2_kv_arr[1][i]));
				}
			}
			// [["value1(key)"], ["value3 - value4(value)"]]
			return [keys_arr, values_diff_arr];
		},
		handleRadarData : function (data,value_key){
			var arr1 = reportPage.baseFn.getValue(reportPage.baseFn.extendObj(data));
			var arr2 = [];
			var dataArr1 = [];
			//var dataArr2 = [];
			var len = arr1.length;
			for(var i=0 ; i<len ; i++){
				dataArr1.push(
					{
						text: reportPage.baseFn.modifyAKey(arr1[i].checkpoint),
						max: 100
					}
				);
				arr2.push([arr1[i][value_key]*100]);
			}
			obj = {
				xaxis : {
					xAxis : dataArr1.reverse()
				},
				yaxis : {
					yAxis : arr2.reverse()
				}
			}
			return obj;
		},
		getBarDiff: function(data){
			var arr = data;
			var len = arr.length;
			var upArr = [];
			var downArr = [];
			for (var i = 0; i < len; i++) {
				var formattedValue = reportPage.baseFn.formatValue(arr[i]);
				if (arr[i] >= 0) {
					upArr.push({
						value: formattedValue,
						label: {
							normal:{
								position: 'top'
							}
						},
					});
					downArr.push({
						value: 0,
						label: {
							normal:{
								show: false
							}
						},
					});
				} else if (arr[i] < 0) {
					upArr.push({
						value: 0,
						label: {
							normal:{
								show: false
							}
						},
					});
					downArr.push({
						value: formattedValue,
						label: {
							normal:{
								position: 'bottom'
							}
						},
					});
				};
			};
			return obj = {
				up: upArr,
				down: downArr
			}
		},
		constructDataTableColLabel: function(value){
			var display_value = level1ValueArr.data[k];
			if(level1ValueArr.diff_ratio[k] < 0 && level1ValueArr.diff_ratio[k] > -0.3){
				level1ValueHtmlStr += '<td class="one-level-content one-level-wrong wrong">' + display_value + '</td>';
			}else if(level1ValueArr.diff_ratio[k] < -0.3){
				level1ValueHtmlStr += '<td class="one-level-content one-level-wrong wrong more-wrong">' + display_value + '</td>';
			}else{
				level1ValueHtmlStr += '<td class="one-level-content">' + display_value + '</td>';
			};
		},
		formatTimesValue: function(value){
			return (value*reportPage.FullScore).toFixed(2);
		},
		formatValue: function(value){
			return value.toFixed(2);
		}
	},

	Project: {
		createReport: function(){

		}
	},

	/*处理年级数据*/
	Grade: {
		createReport : function(data, upperReportIds){
			//设置年级表头；
			var basicData = data.data.basic;
			var gradeNavStr =
				/*
				'<b>学校</b>：<span>' +
				basicData.school +
				'&nbsp;|</span>&nbsp;&nbsp;<b>年级</b>：<span>' +
				basicData.grade +
				'&nbsp;|</span>&nbsp;&nbsp;' +
				*/
				'<b>班级数量</b>：<span>' +
				basicData.klass_count +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学生数量</b>：<span>' +
				basicData.pupil_number +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' +
				basicData.term +
				'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' +
				basicData.quiz_type +
				'&nbsp;|</span>&nbsp;&nbsp;' +
				'<b>测试日期</b>：<span>' +
				basicData.quiz_date +
				'</span>';
			var breadcrumb =
				'<ol class="breadcrumb zy-breadcrumb">' +
					'<li class="active">' +
						basicData.school +
					'</li>' +
					'<li class="active">' +
						basicData.grade +
					'</li>' +
				'</ol>';
			$('.zy-breadcrumb-container').html(breadcrumb);


			$('.zy-report-type').html('年级报告');
			$('#grade-top-nav').html(gradeNavStr);
			//创建年级的第一个诊断图;
			var grade_charts = reportPage.Grade.getGradeDiagnoseData(data.data.charts);
			var objArr = [grade_charts.knowledge,grade_charts.skill,grade_charts.ability];
			var nodeArrLeft = ['knowledge_diagnose_left','skill_diagnose_left','ability_diagnose_left'];
			var nodeArrRight = ['knowledge_diagnose_right','skill_diagnose_right','ability_diagnose_right'];
			var createdCharts = [];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionLeft = echartOption.getOption.Grade.setGradeDiagnoseLeft(objArr[i]);
				var optionRight = echartOption.getOption.Grade.setGradeDiagnoseRight(objArr[i]);
				createdCharts.push(echartOption.createEchart(optionLeft,nodeArrLeft[i]));
				createdCharts.push(echartOption.createEchart(optionRight,nodeArrRight[i]));
			}
			//创建年级分型图;
			createdCharts.push(echartOption.createEchart(echartOption.getOption.Grade.setGradePartingChartOption(grade_charts.disperse),'parting-chart'));

			window.onresize = function () {
				for(var i=0; i<createdCharts.length; i++){
					createdCharts[i].resize();
				}
			};

			$('#tab-menu li[data-id]').on('click', function (e) {
				createdCharts = [];
				var $dataId = $(e.target).attr('data-id');

				$('#myTabContent div.tab-pane').hide();
				$('#'+$dataId+'').fadeIn();
				$('#tab-menu li[data-id]').each(function(){
					$(this).removeClass('active');
				})
				$(this).addClass('active');


				if($dataId == 'grade-NumScale'){
					//创建人数比例图
					var NumScaleObj = reportPage.Grade.getGradeNumScaleData(data.data.each_level_number);
					var objArr = [NumScaleObj.knowledge,NumScaleObj.skill,NumScaleObj.ability];
					var nodeArr = ['KnowledgeScale','SkillScale','AbilityScale'];
					for(var i = 0 ; i < objArr.length ; i++){
						var option = echartOption.getOption.Grade.setGradeScaleOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					}
				}
				else if($dataId == 'grade-FourSections'){
					var FourSections = reportPage.Grade.getFourSectionsData(data.data.four_sections);
					var objArr = [FourSections.knowledge.le75,FourSections.skill.le75,FourSections.ability.le75,FourSections.knowledge.le50,FourSections.skill.le50,FourSections.ability.le50,FourSections.knowledge.le25,FourSections.skill.le25,FourSections.ability.le25,FourSections.knowledge.le0,FourSections.skill.le0,FourSections.ability.le0,];
					var nodeArr = ['knowledge_Four_L75','skill_Four_L75','ability_Four_L75','knowledge_Four_L50','skill_Four_L50','ability_Four_L50','knowledge_Four_L25','skill_Four_L25','ability_Four_L25','knowledge_Four_L0','skill_Four_L0','ability_Four_L0'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setFourSectionsOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
				}
				else if($dataId == 'grade-checkpoint-knowledge'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.knowledge.average_percent,Checkpoints.knowledge.median_percent,Checkpoints.knowledge.med_avg_diff,Checkpoints.knowledge.diff_degree];
					var nodeArr = ['knowledge_Grade_average_percent','knowledge_Grade_median_percent','knowledge_Grade_med_avg_diff','knowledge_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.average_percent);
					$('#knowledge_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.median_percent);
					$('#knowledge_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.med_avg_diff);
					$('#knowledge_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.diff_degree);
					$('#knowledge_diff_degree').html(diff_table);
				}
				else if($dataId == 'grade-checkpoint-skill'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.skill.average_percent,Checkpoints.skill.median_percent,Checkpoints.skill.med_avg_diff,Checkpoints.skill.diff_degree];
					var nodeArr = ['skill_Grade_average_percent','skill_Grade_median_percent','skill_Grade_med_avg_diff','skill_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.average_percent);
					$('#skill_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.median_percent);
					$('#skill_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.med_avg_diff);
					$('#skill_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.diff_degree);
					$('#skill_diff_degree').html(diff_table);
				}
				else if($dataId == 'grade-checkpoint-ability'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.ability.average_percent,Checkpoints.ability.median_percent,Checkpoints.ability.med_avg_diff,Checkpoints.ability.diff_degree];
					var nodeArr = ['ability_Grade_average_percent','ability_Grade_median_percent','ability_Grade_med_avg_diff','ability_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.average_percent);
					$('#ability_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.median_percent);
					$('#ability_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.med_avg_diff);
					$('#ability_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.diff_degree);
					$('#ability_diff_degree').html(diff_table);
				}
				else if($dataId == 'grade-checkpoint-total'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.total.average_percent,Checkpoints.total.median_percent,Checkpoints.total.med_avg_diff,Checkpoints.total.diff_degree];
					var nodeArr = ['total_Grade_average_percent','total_Grade_median_percent','total_Grade_med_avg_diff','total_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
				}
				else if($dataId == 'grade-classPupilNum-knowledge'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.knowledge.excellent_pupil_percent,ClassPupilNum.knowledge.good_pupil_percent,ClassPupilNum.knowledge.failed_pupil_percent];
					var nodeArr = ['knowledge_excellent','knowledge_good','knowledge_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.excellent_pupil_percent);
					$('#knowledge_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.good_pupil_percent);
					$('#knowledge_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.failed_pupil_percent);
					$('#knowledge_failed_table').html(faild_table);
				}
				else if($dataId == 'grade-classPupilNum-skill'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.skill.excellent_pupil_percent,ClassPupilNum.skill.good_pupil_percent,ClassPupilNum.skill.failed_pupil_percent];
					var nodeArr = ['skill_excellent','skill_good','skill_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.excellent_pupil_percent);
					$('#skill_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.good_pupil_percent);
					$('#skill_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.failed_pupil_percent);
					$('#skill_failed_table').html(faild_table);
				}
				else if($dataId == 'grade-classPupilNum-ability'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.ability.excellent_pupil_percent,ClassPupilNum.ability.good_pupil_percent,ClassPupilNum.ability.failed_pupil_percent];
					var nodeArr = ['ability_excellent','ability_good','ability_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.excellent_pupil_percent);
					$('#ability_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.good_pupil_percent);
					$('#ability_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.failed_pupil_percent);
					$('#ability_failed_table').html(faild_table);
				}
					/*
				else if($dataId == 'grade-checkpoint-table-knowledge'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.average_percent);
					$('#knowledge_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.median_percent);
					$('#knowledge_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.med_avg_diff);
					$('#knowledge_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.diff_degree);
					$('#knowledge_diff_degree').html(diff_table);
				}
				*/
					/*
				else if($dataId == 'grade-checkpoint-table-skill'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.average_percent);
					$('#skill_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.median_percent);
					$('#skill_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.med_avg_diff);
					$('#skill_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.diff_degree);
					$('#skill_diff_degree').html(diff_table);
				}
				*/
					/*
				else if($dataId == 'grade-checkpoint-table-ability'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.average_percent);
					$('#ability_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.median_percent);
					$('#ability_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.med_avg_diff);
					$('#ability_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.diff_degree);
					$('#ability_diff_degree').html(diff_table);
				}
				*/
					/*
				else if($dataId == 'grade-classPupilNum-table-knowledge'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.excellent_pupil_percent);
					$('#knowledge_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.good_pupil_percent);
					$('#knowledge_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.failed_pupil_percent);
					$('#knowledge_failed_table').html(faild_table);
				}
				else if($dataId == 'grade-classPupilNum-table-skill'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.excellent_pupil_percent);
					$('#skill_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.good_pupil_percent);
					$('#skill_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.failed_pupil_percent);
					$('#skill_failed_table').html(faild_table);
				}
				else if($dataId == 'grade-classPupilNum-table-ability'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.excellent_pupil_percent);
					$('#ability_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.good_pupil_percent);
					$('#ability_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.failed_pupil_percent);
					$('#ability_failed_table').html(faild_table);
				}
				*/
				else if($dataId == 'grade-answerCase'){
					var excellent_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.excellent);
					$('#excellent_answerCase_table').html(excellent_table);
					var good_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.good);
					$('#good_answerCase_table').html(good_table);
					var faild_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.failed);
					$('#failed_answerCase_table').html(faild_table);
				}
				/* 三维指标含义解读
				else if($dataId == 'grade-readReport-three'){
					$('#grade-readReport-three').html(data.data.report_explanation.three_dimesions);
				}
				*/
				else if($dataId == 'grade-readReport-statistics'){
					$('#grade-readReport-statistics').html(data.data.report_explanation.statistics);
				}
				// else if($dataId == 'grade-readReport-data'){
				// 	$('#grade-readReport-data').html(data.data.report_explanation.data);
				// }

				window.onresize = function () {
					for(var i=0; i<createdCharts.length; i++){
						createdCharts[i].resize();
					}
				};
			});
		},
		
		handleNormTable : function(data){
			var classValue = reportPage.baseFn.getArrayValue(data);

			var normkeyArr = reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(reportPage.baseFn.getArrayValue(data)[0])));
			var classNameArr = reportPage.baseFn.getArrayKeysNoModify(data);

			var thStr = '<td class="grade-titlt">班级</td>';
			for(var i = 0 ; i < normkeyArr.length ; i++){
				thStr += '<td>'+normkeyArr[i]+'</td>';
			}
			var allStr = '';
			for(var i = 0 ; i < classNameArr.length ; i++){
				var str = '';
				for(var k = 0 ; k < normkeyArr.length ; k++){
					var iNum = reportPage.baseFn.getValue(data[i][1][k][1])[0];
					if(iNum > -20  && iNum < 0){
						str += '<td class="wrong">'+iNum+'</td>';
					}else if(iNum < -20 ){
						str += '<td class="wrong more-wrong">'+iNum+'</td>';
					}else{
						str += '<td>'+iNum+'</td>';
					}
//					str += '<td>'+iNum+'</td>';
				}
				if(classValue[i] == '年级'){
					str = '<td>年级</td>'+ str ;
				}else{
					str = '<td>'+classNameArr[i]+'</td>'+ str ;
				}
				allStr += '<tr>'+str+'</tr>';
			}
			return allStr = '<tr>'+thStr+'</tr>' + allStr;
		},
		/*获取诊断图的数据*/
		getGradeDiagnoseData : function(obj){
			return obj = {
				knowledge : {
					xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.knowledge_med_avg_diff))),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.knowledge_3lines.grade_average_percent))),
							grade_diff_degree: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.knowledge_3lines.grade_diff_degree))),
							grade_median_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.knowledge_3lines.grade_median_percent)))
						},
						med_avg_diff : reportPage.baseFn.getBarDiff(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.knowledge_med_avg_diff)))
					}
				},
				skill : {
					xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.skill_med_avg_diff))),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.skill_3lines.grade_average_percent))),
							grade_diff_degree: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.skill_3lines.grade_diff_degree))),
							grade_median_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.skill_3lines.grade_median_percent)))
						},
						med_avg_diff : reportPage.baseFn.getBarDiff(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.skill_med_avg_diff)))
					}
				},
				ability : {
					xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.ability_med_avg_diff))),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.ability_3lines.grade_average_percent))),
							grade_diff_degree: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.ability_3lines.grade_diff_degree))),
							grade_median_percent: reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.ability_3lines.grade_median_percent)))
						},
						med_avg_diff : reportPage.baseFn.getBarDiff(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.ability_med_avg_diff)))
					}
				},
				disperse : {
					knowledge : reportPage.Grade.handleDisperse(obj.dimesion_disperse.knowledge),
					skill : reportPage.Grade.handleDisperse(obj.dimesion_disperse.skill),
					ability : reportPage.Grade.handleDisperse(obj.dimesion_disperse.ability),
				}
			}
		},
		getGradeNumScaleData : function(obj){
			var result = {
				knowledge :{
					yaxis : reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_knowledge))),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_knowledge))))
				},
				skill : {
					yaxis : reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_skill))),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_skill))))
				},
				ability : {
					yaxis : reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_ability))),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.grade_ability))))
				}
			};
			return result;
		},
		getFourSectionsData : function(obj){
			return arr = {
				knowledge : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.knowledge))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.knowledge)))
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.knowledge))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.knowledge)))
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.knowledge))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.knowledge)))
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.knowledge))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.knowledge)))
					}
				},
				skill : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.skill))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.skill)))
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.skill))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.skill)))
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.skill))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.skill)))
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.skill))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.skill)))
					}
				},
				ability : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.ability))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level0.ability)))
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.ability))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level25.ability)))
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.ability))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level50.ability)))
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.ability))),
						yaxis : reportPage.baseFn.getValue(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(obj.level75.ability)))
					}
				}
			}
		},
		getCheckpointData : function(obj){
			return obj = {
				knowledge:reportPage.Grade.handleCheckpoint(obj.knowledge),
				skill:reportPage.Grade.handleCheckpoint(obj.skill),
				ability:reportPage.Grade.handleCheckpoint(obj.ability),
				total:reportPage.Grade.handleCheckpoint(obj.total)
			};
		},
		getClassPupilNumData : function(obj){
			return obj = {
				knowledge:reportPage.Grade.handleClassPupilNum(obj.knowledge),
				skill:reportPage.Grade.handleClassPupilNum(obj.skill),
				ability:reportPage.Grade.handleClassPupilNum(obj.ability),
			}
		},
		//分型图
		handleDisperse : function(data){
			var keysArr = reportPage.baseFn.getKeysNoModify(data);
			var valsArr = reportPage.baseFn.getValue(data);
			var arr = [];
			var percentArr = [];
			var maxKey,minKey;
			for(var i = 0 ; i < keysArr.length; i++){
				arr.push({
					name:keysArr[i],value:[valsArr[i].diff_degree,valsArr[i].average_percent]
				});
				percentArr.push(valsArr[i].average_percent);
			};
			maxKey = keysArr[percentArr.indexOf(Math.max.apply(null,percentArr))];
			minKey = keysArr[percentArr.indexOf(Math.min.apply(null,percentArr))];
			return {
				data_node:arr,
				maxkey : maxKey,
				minkey : minKey
			}
		},
		creatGradeScaleArr : function(obj){
			var goodArr = [],faildArr = [],excellentArr = [];
			for(var i = 0 ; i < obj.length ; i++){
				excellentArr.push({
		            name:'(得分率 ≥ 85)',
		            value:obj[i].excellent_pupil_percent,
		            yAxisIndex:i,
		        });
				goodArr.push({
		            name:'( 60 ≤ 得分率 < 85)',
		            value:obj[i].good_pupil_percent,
		            yAxisIndex:i,
		        });
				faildArr.push({
                    name:'(得分率 < 60)',
                    value:obj[i].failed_pupil_percent,
                });
			}
			return obj  = {
				excellent:excellentArr,
				good:goodArr,
				failed:faildArr
			}
		},

        handleClassPupilNum : function(obj){
			var normkeyArr = reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(reportPage.baseFn.getArrayValue(obj.good_pupil_percent)[0])));
			var classNameArr = reportPage.baseFn.getArrayKeysNoModify(obj.good_pupil_percent);
			var normNum = normkeyArr.length;
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < normNum; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:normkeyArr[i],icon:'rect'});
			};
			return obj = {
				excellent_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.excellent_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				},
				good_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.good_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				},
				failed_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.failed_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				}
			};
		},
      
		handleCheckpoint : function(obj){
			var normkeyArr = reportPage.baseFn.getKeysNoModify(reportPage.baseFn.extendObj(reportPage.baseFn.getArrayValue(reportPage.baseFn.getArrayValue(obj.average_percent)[0])));
			var classNameArr = reportPage.baseFn.getArrayKeysNoModify(obj.average_percent);
			var normNum = normkeyArr.length;
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < normNum; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:normkeyArr[i],icon:'rect'});
			};
			return obj = {
				average_percent : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.average_percent,colorArr,normkeyArr,normNum,classNameArr)
				},
				diff_degree : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.diff_degree,colorArr,normkeyArr,normNum,classNameArr)
				},
				med_avg_diff : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.med_avg_diff,colorArr,normkeyArr,normNum,classNameArr)
				},
				median_percent : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleCheckpointNorm(obj.median_percent,colorArr,normkeyArr,normNum,classNameArr)
				},
			}
		},
		handleCheckpointNorm : function(obj,colorArr,normkeyArr,normNum,classNameArr){
			var classValue = reportPage.baseFn.getArrayValue(obj);
			var classNum = classNameArr.length;
			var allArr = [];
			var series = [];
			for(var i = 0 ; i < normNum ; i++){
				var arr = [];
				for(var k = 0 ; k < classNum ; k++){
					arr.push(reportPage.baseFn.getValue(classValue[k][i][1])[0]);
				};
				allArr.push(arr);
			};
			for(var j = 0 ; j < normNum ; j++){
				series.push({
					name:normkeyArr[j],
					type:'bar',
					barMaxWidth: 40,
					stack: "总量",
					label: {
						normal: {
							show: true,
							position: ['10%' ,'100%'],
							textStyle: {
								fontSize: 16,
								color: '#212121'
							}
						}
					},
					data:allArr[j],
				})
			};
			return series;
		},
		handleNorm : function(obj,colorArr,normkeyArr,normNum,classNameArr){
			var classValue = reportPage.baseFn.getArrayValue(obj);
			var classNum = classNameArr.length;
			var allArr = [];
			var series = [];
			for(var i = 0 ; i < normNum ; i++){
				var arr = [];
				for(var k = 0 ; k < classNum ; k++){
					arr.push(reportPage.baseFn.getValue(classValue[k][i][1])[0]);
				};
				allArr.push(arr);
			};
			for(var j = 0 ; j < normNum ; j++){
				series.push({
					name:normkeyArr[j],
		            type:'line',
		            barMaxWidth: 10,
		            stack: "总量",
		            symbol:'circle',
		            symbolSize:5,
		            lineStyle:{normal:{width:1}},
		            smooth:true,
		            areaStyle: {
		              	normal: {
		                	color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
			                  	offset: 0,
			                  	color:colorArr[j] 
		               		}, {
		                  		offset: 1,
		                  		color: '#f4fcfb'
		                	}]),
		                	opacity:0.9,
		            }},
		            data:allArr[j],
		            z:j+1
				})
			};
			return series;
		},
	},

	/*处理班级数据*/
	Class: {
		basicData: null,
		createReport : function(){
			//基本信息
			var classNavStr =
				'<b>班级人数</b>：<span>' + reportPage.KlassData.data.knowledge.base.pupil_number
			    +'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.KlassData.basic.term
			    +'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.KlassData.basic.quiz_type
			    +'&nbsp;|</span>&nbsp;&nbsp;' +'<b>测试日期</b>：<span>' + reportPage.KlassData.basic.quiz_date
			    +'</span>';
			$('#class-top-nav').html(classNavStr);
			$('.zy-report-type').html('班级报告');
			
			//诊断图
			var DiagnoseObj = reportPage.Class.getClassDiagnoseData();
			var objArr = [DiagnoseObj.knowledge,DiagnoseObj.skill,DiagnoseObj.ability];
			//array内为html中的id，之后考虑更改
			var nodeArrTotal = ['knowledge_diagnose_left','skill_diagnose_left','ability_diagnose_left'];
			var nodeArrAvgDiff = ['knowledge_diagnose_center','skill_diagnose_center','ability_diagnose_center'];
			var nodeArrMedDiff = ['knowledge_diagnose_right','skill_diagnose_right','ability_diagnose_right'];
			var createdCharts = [];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionTotal = echartOption.getOption.Class.setClassDiagnoseTotal(objArr[i]);
				var optionAvgDiff = echartOption.getOption.Class.setClassDiagnoseAvgDiff(objArr[i]);
				var optionMedDiff = echartOption.getOption.Class.setClassDiagnoseMedDiff(objArr[i]);
				createdCharts.push(echartOption.createEchart(optionTotal,nodeArrTotal[i]));
				createdCharts.push(echartOption.createEchart(optionAvgDiff,nodeArrAvgDiff[i]));
				createdCharts.push(echartOption.createEchart(optionMedDiff,nodeArrMedDiff[i]));
			};

			//导航菜单切换
			$('#tab-menu li[data-id]').on('click', function (e) {
				createdCharts = [];
				var $dataId = $(e.target).attr('data-id');

				$('#myTabContent div.tab-pane').hide();
				$('#'+$dataId+'').fadeIn();
				$('#tab-menu li[data-id]').each(function(){
					$(this).removeClass('active');
				})
				$(this).addClass('active');

				//班级人数比例
				if($dataId == 'class-NumScale'){
					// [dimesions, knowledge, skill, ability]
					var objArr = reportPage.Class.getClassScaleNumData();
					var nodeArr = ['scale_dimesions','scale_knowledge','scale_skill','scale_ability'];
					for(var i = 0 ; i　< objArr.length ; i++){
						var option = echartOption.getOption.Class.setClassScaleNumOption(objArr[i]);
						if(i > 0){
							option.legend = { show: false};
							option.grid.right = '3%';
						}
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
				}

				//数据表
				else if($dataId == 'table-data-knowledge'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.knowledge,'class','knowledge');
					$('#Class_knowledge_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.skill,'class','skill');
					$('#Class_skill_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.ability,'class','ability');
					$('#Class_ability_table').html(tableStr);
				}

				//答对率
				else if($dataId == 'class-answerCase'){
					var excellent_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.excellent);
					var good_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.good);
					var failed_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.failed);
					$('#excellent_answerCase_table').html(excellent_table);
					$('#good_answerCase_table').html(good_table);
					$('#failed_answerCase_table').html(failed_table);
				}

				//报告解读
				else if($dataId == 'report-read-checkpoint'){
					$('#report-read-checkpoint').html(data.data.report_explanation.statistics);
				}

				//测试评价
				else if($dataId == 'exam-knowledge'){
					$('#exam-knowledge').html(data.data.quiz_comment.knowledge);
				}else if($dataId == 'exam-skill'){
					$('#exam-skill').html(data.data.quiz_comment.skill);
				}else if($dataId == 'exam-ability'){
					$('#exam-ability').html(data.data.quiz_comment.ability);
				}else if($dataId == 'exam-total'){
					$('#exam-total').html(data.data.quiz_comment.total);
				}

				window.onresize = function () {
					for(var i=0; i<createdCharts.length; i++){
						createdCharts[i].resize();
					}
				};
			});
        },
        //获取诊断图数据
		getClassDiagnoseData : function(){
			var result = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					xaxis : reportPage.baseFn.get_key_values(reportPage.KlassData.data[dim].lv_n, "weights_score_average_percent")[0],
					yaxis : {
						all_line : reportPage.Class.getClassDiagnoseAllLine(dim),
						diff : {
							mid:reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.KlassData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "klass_median_percent", "weights_score_average_percent")[1]),
							avg:reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.KlassData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent")[1])
						}
					}
				}
			}
			return result; 
		},
		//获取诊断图第一个所有曲线汇总图数据
		getClassDiagnoseAllLine : function(dimesion){
			return {
				class_average_percent: reportPage.baseFn.get_key_values(reportPage.KlassData.data[dimesion].lv_n, "weights_score_average_percent")[1],
				class_median_percent: reportPage.baseFn.get_key_values(reportPage.KlassData.data[dimesion].lv_n, "klass_median_percent")[1],
				diff_degree: reportPage.baseFn.get_key_values(reportPage.KlassData.data[dimesion].lv_n, "klass_median_percent")[1],
				grade_average_percent: reportPage.baseFn.get_key_values(reportPage.GradeData.data[dimesion].lv_n, "weights_score_average_percent")[1]
			}
		},
		//班级人数比例处理
		getClassScaleNumData : function(data){
			var result = [];
			var dimesions_base_values_arr = [
				reportPage.KlassData.data.ability.base,
				reportPage.KlassData.data.skill.base,
				reportPage.KlassData.data.knowledge.base
			];
			result.push({ 
				yaxis: ['能力-班级','技能-班级','知识-班级'],
				data: reportPage.Class.handleClassScaleData(dimesions_base_values_arr)
			});

			var dimesion_base_values_arr = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			var dimesion_labels = [['知识-班级', '知识-年级'], ['技能-班级', '技能-年级'], ['能力-班级', '能力-年级']];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result.push({ 
					yaxis: dimesion_labels[i],
					data: reportPage.Class.handleClassScaleData([ reportPage.KlassData.data[dim].base, reportPage.GradeData.data[dim].base ])
				});
			}
			return result;
		},
		//人数比例图数据格式组装
		handleClassScaleData : function(data_arr){
			var excellent_arr = [], good_arr = [],failed_arr = [];
			for(var i=0; i < data_arr.length; i++){
				excellent_arr.push({
					name: '(得分率 ≥ 85)',
                    value: reportPage.baseFn.formatTimesValue(data_arr[i].excellent_percent),
                    yAxisIndex:1
				});
				good_arr.push({
                    name:'(60 ≤ 得分率 < 85)',
                    value: reportPage.baseFn.formatTimesValue(data_arr[i].good_percent)
				});
				failed_arr.push({
                    name:'(得分率 < 60)',
                    value: reportPage.baseFn.formatTimesValue(data_arr[i].failed_percent)
				});
			}
			return { excenllent: excellent_arr, good : good_arr, failed: failed_arr };
		},
		//处理数据表
		constructDataTable: function(dimesion) {
			var tableHtmlStr = '';
			var klassBase = reportPage.PupilData.data[dimesion].base;
			var dimesionRatio = reportPage.FullScore/klassBase.total_full_weights_score;
			var gradeBase = reportPage.GradeData.data[dimesion].base;
			var klassLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.PupilData.data[dimesion].lv_n )), function(value, index){ return value } );
			var gradeLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.GradeData.data[dimesion].lv_n )), function(value, index){ return value } );
			var baseArr = ["<tr>"];
			var lv1Arr = ["<tr>"];
			//总计
			//指标名;
			baseArr.push('<td class="one-level">' + "总计" + '</td>');
			//班级平均分值
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassBase.total_real_weights_score*dimesionRatio) + '</td>');
			//班级平均得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassBase.weights_score_average_percent) + '</td>');
			//班级中位数得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassBase.klass_median_percent) + '</td>');
			//年级平均得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(gradeBase.weights_score_average_percent) + '</td>');
			//班级与年级平均得分率差值
			baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassBase.weights_score_average_percent, gradeBase.weights_score_average_percent));
			//班级与年级中位数平均得分率差值
			baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassBase.klass_median_percent, gradeBase.grade_median_percent));
			//分化程度
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassBase.diff_degree) + '</td>');
			//满分值
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassBase.total_full_weights_score*dimesionRatio) + '</td>');
			baseArr.push("</tr>");
			tableHtmlStr += baseArr.join("");

			for (var i = 0; i < klassLv1Arr.length; i++) {
				var lv1Arr = ["<tr>"];
				//一级指标
				//指标名;
				lv1Arr.push('<td class="one-level">' + klassLv1Arr[i].checkpoint + '</td>');
				//班级平均分值
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].total_real_weights_score*dimesionRatio) + '</td>');
				//班级平均得分率
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassLv1Arr[i].weights_score_average_percent) + '</td>');
				//班级中位数得分率
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassLv1Arr[i].klass_median_percent) + '</td>');
				//年级平均得分率
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(gradeLv1Arr[i].weights_score_average_percent) + '</td>');
				//班级与年级平均得分率差值
				baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv1Arr[i].weights_score_average_percent, gradeBase.weights_score_average_percent));
				//班级与年级中位数平均得分率差值
				baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv1Arr[i].klass_median_percent, gradeBase.grade_median_percent));
				//分化程度
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].diff_degree) + '</td>');
				//满分值
				baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].total_full_weights_score*dimesionRatio) + '</td>');
				lv1Arr.push("</tr>");
				tableHtmlStr += lv1Arr.join("");

				var klassLv2Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( klassLv1Arr[i].items )), function(value, index){ return value } );
				var gradeLv2Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( gradeLv1Arr[i].items )), function(value, index){ return value } );
				for (var ii = 0; ii < klassLv2Arr.length; ii++) {
					var lv2Arr = ["<tr>"];
					//二级指标
					//指标名;
					lv2Arr.push('<td>' + klassLv2Arr[ii].checkpoint + '</td>');
					//班级平均分值
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv2Arr[i].total_real_weights_score*dimesionRatio) + '</td>');
					//班级平均得分率
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassLv2Arr[i].weights_score_average_percent) + '</td>');
					//班级中位数得分率
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(klassLv2Arr[i].klass_median_percent) + '</td>');
					//年级平均得分率
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(gradeLv2Arr[i].weights_score_average_percent) + '</td>');
					//班级与年级平均得分率差值
					baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv2Arr[i].weights_score_average_percent, gradeBase.weights_score_average_percent));
					//班级与年级中位数平均得分率差值
					baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv2Arr[i].klass_median_percent, gradeBase.grade_median_percent));
					//分化程度
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv2Arr[i].diff_degree) + '</td>');
					//满分值
					baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv2Arr[i].total_full_weights_score*dimesionRatio) + '</td>');
					lv2Arr.push("</tr>");
					tableHtmlStr += lv2Arr.join("");
				}
			}
			return tableHtmlStr;
		},
		/*针对班级的字段*/
		creatClassValueArr: function(obj,dimesion,index) {
			var result = {data: [], diff_ratio: [] }
			avg_ratio = obj.cls_gra_avg_percent_diff/obj.gra_average_percent;
            med_ratio = obj.cls_med_gra_avg_percent_diff/obj.gra_average_percent;

            var full_score = (obj.full_score * reportPage.Class.basicData.value_ratio[dimesion]).toFixed(2);
            var cls_average = (obj.cls_average * reportPage.Class.basicData.value_ratio[dimesion]).toFixed(2);
            if( index == 0 ){
            	full_score = Math.round(obj.full_score * reportPage.Class.basicData.value_ratio[dimesion]);
            }
			result.data = [
                cls_average, 
                (cls_average/full_score*100).toFixed(2), 
                obj.class_median_percent, 
                obj.gra_average_percent, 
                obj.cls_gra_avg_percent_diff, 
                obj.cls_med_gra_avg_percent_diff, 
                obj.diff_degree, 
                full_score
            ];
            result.diff_ratio = [
                0,
                0,
                0,
                0,
                avg_ratio,
                med_ratio,
                0,
                0
            ];
            return result;
		},
	},

	Pupil: {
		createReport : function(){
			//基本信息
			var pupilNavStr =
			'<b>分数</b>：<span>' + reportPage.baseFn.formatTimesValue(reportPage.PupilData.data.knowledge.base.weights_score_average_percent) +
			'&nbsp;|</span>&nbsp;&nbsp;' +
			'<b>名次</b>：<span>' + reportPage.PupilData.data.knowledge.base.grade_rank + 
			'&nbsp;|</span>&nbsp;&nbsp;' +
			'<b>性别</b>：<span>' + reportPage.PupilData.basic.sex +
			'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.PupilData.basic.term + 
			'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.PupilData.basic.quiz_type +
			'&nbsp;|</span>&nbsp;&nbsp;<b>测试日期</b>：<span>' + reportPage.PupilData.basic.quiz_date;

			$('.zy-report-type').html('学生报告');
			$('#pupil-top-nav').html(pupilNavStr);

			//诊断图
			var PupilDiagnoseObj = reportPage.Pupil.getPupilDiagnoseData();
			var objArr = [PupilDiagnoseObj.knowledge,PupilDiagnoseObj.skill,PupilDiagnoseObj.ability];
			var nodeArr_radar = ['pupil_knowledge_radar','pupil_skill_radar','pupil_ability_radar'];
			var nodeArr_diff = ['pupil_knowledge_diff','pupil_skill_diff','pupil_ability_diff'];
			var createdCharts = [];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionRadar = echartOption.getOption.Pupil.setPupilRadarOption(objArr[i]);
				var optionDiff = echartOption.getOption.Pupil.setPupilDiffOption(objArr[i]);
				createdCharts.push(echartOption.createEchart(optionRadar,nodeArr_radar[i]));
				createdCharts.push(echartOption.createEchart(optionDiff,nodeArr_diff[i]));
			}

			//更新诊断图
			window.onresize = function () {
				for(var i=0; i<createdCharts.length; i++){
					createdCharts[i].resize();
				}
			};

			//导航切换
			$('#tab-menu li[data-id]').on('click', function (e) {
				createdCharts = [];
				var $dataId = $(e.target).attr('data-id');

				$('#myTabContent div.tab-pane').hide();
				$('#'+$dataId+'').fadeIn();
				$('#tab-menu li[data-id]').each(function(){
					$(this).removeClass('active');
				})
				$(this).addClass('active');

				if($dataId == 'improve-sugg'){
					$('#improve-sugg').html(reportPage.PupilData.data.quiz_comment);
				}else if($dataId == 'table-data-knowledge'){
					var tableStr = reportPage.Pupil.constructDataTable('knowledge');
					//$('#pupil_knowledge_percentile').html(data.data.percentile.knowledge);
					$('#knowledge_data_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.Pupil.constructDataTable('skill');
					// $('#pupil_skill_percentile').html(data.data.percentile.skill);
					$('#skill_data_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.Pupil.constructDataTable('ability');
					// $('#pupil_ability_percentile').html(data.data.percentile.ability);
					$('#ability_data_table').html(tableStr);
				}
			})
		},
		//获取诊断图数据
		getPupilDiagnoseData : function(){
			var result = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					radar : {
						grade : reportPage.baseFn.handleRadarData(reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent"),
						pupil : reportPage.baseFn.handleRadarData(reportPage.PupilData.data[dim].lv_n, "weights_score_average_percent")
					},
					diff : {
						xaxis : reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", 2)[0],
						yaxis :	reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", 2)[1])
					}
				}
			}
			return result; 
		},
		//处理数据表
		constructDataTable: function(dimesion) {
			var tableHtmlStr = '';
			var pupilBase = reportPage.PupilData.data[dimesion].base;
			var dimesionRatio = reportPage.FullScore/pupilBase.total_full_weights_score;
			var gradeBase = reportPage.GradeData.data[dimesion].base;
			var pupilLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.PupilData.data[dimesion].lv_n )), function(value, index){ return value } );
			var gradeLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.GradeData.data[dimesion].lv_n )), function(value, index){ return value } );
			var baseArr = ["<tr>"];
			var lv1Arr = ["<tr>"];
			//总计
			//指标名;
			baseArr.push('<td class="one-level">' + "总计" + '</td>');
			//个人得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(pupilBase.weights_score_average_percent) + '</td>');
			//年级得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(gradeBase.weights_score_average_percent) + '</td>');
			//得分率差值
			baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", pupilBase.weights_score_average_percent, gradeBase.weights_score_average_percent));
			//个人得分
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(pupilBase.total_real_weights_score*dimesionRatio) + '</td>');
			//满分
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(pupilBase.total_full_weights_score*dimesionRatio) + '</td>');
			baseArr.push("</tr>");
			tableHtmlStr += baseArr.join("");
			for (var i = 0; i < pupilLv1Arr.length; i++) {
				var lv1Arr = ["<tr>"];
				//一级指标
				//指标名;
				lv1Arr.push('<td class="one-level">' + pupilLv1Arr[i].checkpoint + '</td>');
				//个人得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(pupilLv1Arr[i].weights_score_average_percent) + '</td>');
				//年级得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatTimesValue(gradeLv1Arr[i].weights_score_average_percent) + '</td>');
				//得分率差值
				lv1Arr.push(reportPage.Pupil.checkDataTableCol("one-level-content", pupilLv1Arr[i].weights_score_average_percent, gradeLv1Arr[i].weights_score_average_percent));
				//个人得分
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatValue(pupilLv1Arr[i].total_real_weights_score*dimesionRatio) + '</td>');
				//满分
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatValue(pupilLv1Arr[i].total_full_weights_score*dimesionRatio) + '</td>');
				lv1Arr.push("</tr>");
				tableHtmlStr += lv1Arr.join("");

				var pupilLv2Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( pupilLv1Arr[i].items )), function(value, index){ return value } );
				var gradeLv2Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( gradeLv1Arr[i].items )), function(value, index){ return value } );
				for (var ii = 0; ii < pupilLv2Arr.length; ii++) {
					var lv2Arr = ["<tr>"];
					//二级指标
					//指标名;
					lv2Arr.push('<td>' + pupilLv2Arr[ii].checkpoint + '</td>');
					//个人得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatTimesValue(pupilLv2Arr[ii].weights_score_average_percent) + '</td>');
					//年级得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatTimesValue(gradeLv2Arr[ii].weights_score_average_percent) + '</td>');
					//得分率差值
					lv2Arr.push(reportPage.Pupil.checkDataTableCol("", pupilLv2Arr[ii].weights_score_average_percent, gradeLv2Arr[ii].weights_score_average_percent));
					//个人得分
					lv2Arr.push('<td>' + reportPage.baseFn.formatValue(pupilLv2Arr[ii].total_real_weights_score*dimesionRatio) + '</td>');
					//满分
					lv2Arr.push('<td>' + reportPage.baseFn.formatValue(pupilLv2Arr[ii].total_full_weights_score*dimesionRatio) + '</td>');
					lv2Arr.push("</tr>");
					tableHtmlStr += lv2Arr.join("");
				}
			}
			return tableHtmlStr;
		},
		//针对数据表字段上色处理
		checkDataTableCol: function( col_class="", target_value=0, hikaku_value=1 ) {
			var result = "";
			var diff = target_value - hikaku_value;
			var diff_ratio = 0;
			diff_ratio = diff/hikaku_value;

			if(diff_ratio < 0 && diff_ratio > -0.3){
				result += '<td class="' + col_class + ' wrong">' + reportPage.baseFn.formatTimesValue(diff) + '</td>';
			}else if(diff_ratio < -0.3){
				result += '<td class="' + col_class + ' more-wrong">' + reportPage.baseFn.formatTimesValue(diff) + '</td>';
			}else{
				result += '<td class="' + col_class + '">' + reportPage.baseFn.formatTimesValue(diff) + '</td>';
			};
			return result;
		}
	}
}