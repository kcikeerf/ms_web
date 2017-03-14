var reportPage = {
	rootGroup: null,
	rootUrl: null,
	paperInfoUrl: null,
	ckp_level: null,
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
	CurrentBreadCrumbChildren : [],
	TopGroup : null,
	BreadCrumbs : [],
	GroupRoute : ["test", "project", "grade", "klass", "pupil", "end"],
	BreadCrumbObj :{
		test: {selected: 0, list: [], html_str: ""}, 
		project: {selected: 0, list: [], html_str: ""}, 
		grade: {selected: 0, list: [], html_str: ""}, 
		klass: {selected: 0, list: [], html_str: ""}, 
		pupil: {selected: 0, list: [], html_str: ""},
		end: {selected: 0, list: [], html_str: ""}
	},
	ReportCkpStartLevel: 1,
    DimesionRatio: {
      knowledge: 0.5,
      skill: 0.4,
      ability: 0.1
    },
	FullScore: 0,
	defaultColor: "#51b8c1",
	chartColor : ['#a2f6e6','#6cc2bd','#15a892','#88c2f8','#6789ce','#254f9e','#eccef9','#bf9ae0','#8d6095'],

	init: function(root_group, root_url, paper_info_url, ckp_level){
		reportPage.rootGroup = root_group;
		reportPage.rootUrl = root_url;
		reportPage.paperInfoUrl = paper_info_url;
		reportPage.ckp_level = typeof ckp_level !== 'undefined' ? ckp_level : 1;
		
		//
		reportPage.bindEvent();
		//

		$.ajax({
			url: reportPage.paperInfoUrl,
			type: "GET",
			data: "",
			dataType: "json",
			success: function(data){
				//获取试卷信息
				reportPage.FullScore = (data && data.score)? parseInt(data.score) : 100;

				//获取初始报告信息
				reportPage.baseFn.getReportAjax( root_url, { report_group: root_group }, function(data){
					reportPage.baseFn.update_current_node(data.root_group, data.root_url);
				},{ root_group: root_group, root_url: root_url });
			},
			error: function(data){

			}
		});

	},
	bindEvent: function(){
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
		getReportAjax: function(url,options, callback, args){
			options = typeof options !== 'undefined' ? options : {reportType: null, ajax_type: null};
			args = typeof args !== 'undefined' ? args : {};
			$.ajax({
				url: url,
				type: "GET",
				data: "",
				dataType: "json",
				success: function(data){
					var url_arr = url.split("/");
					var last_url_id = url_arr[ url_arr.length -1 ].split(".")[0];

					// 保存当前报告的信息
					if (options.reportType == "project") {
						reportPage.ProjectData = data;
						reportPage.CurrentProjectId = last_url_id;
						reportPage.CurrentProjectUrl = url;
					} else if (options.reportType == "grade") {
						reportPage.GradeData = data;
						reportPage.CurrentGradeId = last_url_id;
						reportPage.CurrentGradeUrl = url;
					} else if (options.reportType == "klass") {
						reportPage.KlassData = data;
						reportPage.CurrentKlassId = last_url_id;
						reportPage.CurrentKlassUrl = url;
					} else if (options.reportType == "pupil") {
						reportPage.PupilData = data;
						reportPage.CurrentPupilId = last_url_id;
						reportPage.CurrentPupilUrl = url;
					} else  {
						// do nothing
					}

					// 若是来自导航信息的请求
					if (options.ajax_type == "nav" || options.ajax_type == "nav_only") {
						if(args["current_group"] == "test"){
							args.data = data[""];
						} else {
							args.data = data[args["current_group"]];
							var target_height = 50 * args.data.length;
							target_height = (target_height < 520)? "520" : target_height;
							$('.zy-chart-container.dynamic_change_items').css("height", target_height);
						}
						if(options.ajax_type != "nav_only"){
							reportPage.CurrentBreadCrumbChildren = args.data.slice(0);
						}
					} else if (options.ajax_type == "crumb_children") {
						if(data.basic){
							reportPage.CurrentBreadCrumbChildren[args.data.length].resp = data;
						} else {
							var from = (args.data.length == 0 ) ? 0 : args.data.length ;
							reportPage.CurrentBreadCrumbChildren.splice(from,1);
						}
						console.log(reportPage.CurrentBreadCrumbChildren);
					}

					callback(args);
				},
				error: function(data){
					console.log("error!")
					//$('#reportContent').html(data.responseJSON.message);
					//$('#reportContent')[0].style = "position:relative;display: flex;"
					//$('#reportContent')[0].style = "display: block;"
				}
			});
		},

		// 当前menu触发
		update_current_node: function(current_group, report_url){
			$('#reportContent').load('/reports/'+current_group,function(){
				// 当前节点触发事件处理
				var from_type = null; 
				switch(current_group){
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
						from_type = "project";
						break;
				}
				var url_arr = report_url.split("/");
				var from_arr = url_arr.slice( 0, (url_arr.length - 2) );
				var from_url = from_arr.join("/") + ".json";
				var args = {
					from_type: from_type, 
					from_url: from_url, 
					end_type: current_group, 
					end_url: report_url
				};
				// 先获取祖先节点信息
				reportPage.baseFn.get_crumb_left(args);
			});
		},
		// 获取当前节点祖先节点信息
		get_crumb_left: function(args){
			args = typeof args !== 'undefined' ? args : {};

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
					reportCurrentId = reportPage.CurrentPupilId;
					reportCurrentUrl = reportPage.CurrentPupilUrl;
					createReportFunc = reportPage.Pupil.createReport;
					break;
				case "klass":
					next_type = "grade";
					reportCurrentId = reportPage.CurrentKlassId;
					reportCurrentUrl = reportPage.CurrentKlassUrl;
					createReportFunc = reportPage.Class.createReport;
					break;
				case "grade":
					next_type = "project";
					reportCurrentId = reportPage.CurrentGradeId;
					reportCurrentUrl = reportPage.CurrentGradeUrl;
					createReportFunc = reportPage.Grade.createReport;
					break;
				case "project":
					next_type = end_type;
					reportCurrentId = reportPage.CurrentProjectId;
					reportCurrentUrl = reportPage.CurrentProjectUrl;
					createReportFunc = reportPage.Project.createReport;
					break;
			}

			if( reportCurrentId != currentId ){
				if( from_type == end_type ){
					if( end_type == "project" || end_type == "grade" ){
						reportPage.baseFn.getReportAjax( end_url, { reportType: end_type }, reportPage.baseFn.get_current_node_children_nav, {current_url: end_url, current_group: end_type } );
					} else {
						reportPage.baseFn.getReportAjax( end_url, { reportType: end_type }, createReportFunc );
					}
					return true;
				} else {
					args["from_type"] = next_type;
					args["from_url"] = next_url;
					reportPage.baseFn.getReportAjax( from_url, { reportType: from_type }, reportPage.baseFn.get_crumb_left, args);
				}
			} else {
				args["from_type"] = next_type;
				args["from_url"] = next_url;
				reportPage.baseFn.get_crumb_left(args);
			}
		},
		// 获取下级导航信息
		get_current_node_children_nav: function(args){
			if(!args["current_url"] || !args["current_group"]){
				return false;
			}
			var current_url = args["current_url"];
			var url_arr = current_url.split(".json");
			var nav_url = url_arr[0] + "/nav.json";
			var args = { current_group: args["current_group"], current_url: current_url};
			reportPage.baseFn.getReportAjax( nav_url, { ajax_type: "nav"}, reportPage.baseFn.get_crumb_right, args );
		},
		// 获取当前节点的字节点信息
		// 根据样式限于： project, grade
		get_crumb_right: function(args){
			if ( args.data.length == 0 ) {
				var createReportFunc = null;
				switch(args["current_group"]){
					case "project":
						createReportFunc = reportPage.Project.createReport;
						break;
					case "grade":
						createReportFunc = reportPage.Grade.createReport;
						break;
					case "klass":
					 	// do nothing
					 	break;
					case "pupil":
						// do nothing
						break;
				}
				reportPage.baseFn.getReportAjax( args["current_url"], { reportType: args["current_group"]}, createReportFunc );
				return true;
			} else {
				var current_sub_crumb = args.data.pop();
				reportPage.baseFn.getReportAjax( current_sub_crumb[1].report_url, {ajax_type: "crumb_children"}, reportPage.baseFn.get_crumb_right, args );
			}
		},
		construct_bread_crumbs: function(next_group, current_group, current_report_url) {
			// 学生的情况，只更新名字
			if(current_group == "pupil"){
				if(reportPage.BreadCrumbObj["pupil"].list.length > 0){
					reportPage.BreadCrumbObj["end"].html_str = '<li>'+reportPage.BreadCrumbObj["pupil"].list[reportPage.BreadCrumbObj["pupil"].selected][1].label;+'</li>';
				} else {
					reportPage.BreadCrumbObj["end"].html_str = '<li>'+reportPage.PupilData.basic.name+'</li>';
				}

				reportPage.baseFn.update_bread_crumbs();
				return true;
			}

			// 清空下级菜单
			var current_group_index = reportPage.GroupRoute.findIndex(function(item){ return item == next_group });
			// var family_groups = reportPage.GroupRoute.slice(current_group_index, reportPage.GroupRoute.length);
			var children_groups = reportPage.GroupRoute.slice(current_group_index+1, reportPage.GroupRoute.length);
			for (var index in children_groups){
				reportPage.BreadCrumbObj[children_groups[index]].html_str = "";
				reportPage.BreadCrumbObj[children_groups[index]].list = [];
			}

			//获取
			var url_arr = current_report_url.split(".json");
			var nav_url = url_arr[0] + "/nav.json";

			reportPage.baseFn.getReportAjax( nav_url, { ajax_type: "nav_only", }, function(data){
				if(!data){ return false; }
				var resp = data;
				reportPage.BreadCrumbObj[resp.next_group].list = resp.data;
				var current_crumb_label = "";
				//var current_crumb_report_url = "";
				switch(resp.current_group){
					// case "pupil":
					// 	current_crumb_label = reportPage.BreadCrumbObj["pupil"].list[reportPage.BreadCrumbObj["pupil"].selected][1].label;
					// 	//current_crumb_report_url = reportPage.CurrentPupilUrl;
					// 	break;
					case "klass":
						current_crumb_label = reportPage.BreadCrumbObj["klass"].list[reportPage.BreadCrumbObj["klass"].selected][1].label;
						//current_crumb_report_url = reportPage.CurrentKlassUrl;					
						break;
					case "grade":
					    if(reportPage.BreadCrumbObj["grade"].list.length > 0){
							current_crumb_label = reportPage.BreadCrumbObj["grade"].list[reportPage.BreadCrumbObj["grade"].selected][1].label;
						} else {
							current_crumb_label = reportPage.GradeData.basic.grade;
						}
						//current_crumb_report_url = reportPage.CurrentGradeUrl;						
						break;
					case "project":
						current_crumb_label = "项目报告";//reportPage.BreadCrumbObj["project"].list[reportPage.BreadCrumbObj["project"].selected][1].label;
						//current_crumb_report_url = reportPage.CurrentProjectUrl;	
						break;
					case "test":
						current_crumb_label = "Home";
						//current_crumb_report_url = current_url;	
						break;
				}
				
				var html_str = '<li class="dropdown report_menu_item">'+
					'<a href="#" class="dropdown-toggle" data-toggle="dropdown" data_type="'+resp.current_group+'" report_url="'+current_report_url+'">'+
					current_crumb_label+'</a><span class="glyphicon glyphicon-menu-down"></span><ul class="dropdown-menu">';
				
				for (var index in resp.data){
					html_str += ('<li class="report_menu_item"><a href="#" '
						+ ' menu_index=' + index
						+ ' data_type="' + resp.next_group
						+ '" report_url="' + resp.data[index][1].report_url + '">' 
						+ resp.data[index][1].label 
						+ '</a></li>');
				}
				html_str += '</ul></li>';
				reportPage.BreadCrumbObj[resp.next_group].html_str = html_str;
				reportPage.baseFn.update_bread_crumbs();
			},{next_group: next_group,current_group: current_group});
		},
		update_bread_crumbs: function(){
			reportPage.BreadCrumbs = []
			reportPage.BreadCrumbs.push('<ol class="breadcrumb zy-breadcrumb">');
			for (var index in reportPage.GroupRoute){
				var target_html = reportPage.BreadCrumbObj[reportPage.GroupRoute[index]].html_str;
				if(target_html){
					reportPage.BreadCrumbs.push(target_html);
				}
			}
			reportPage.BreadCrumbs.push("</ol>");
			$('.zy-breadcrumb-container').html(reportPage.BreadCrumbs.join(""));
			$('.report_menu_item > a').on('click', function(){
				if($(this).attr("menu_index")){
					reportPage.BreadCrumbObj[$(this).attr("data_type")].selected = $(this).attr("menu_index");
				}
				reportPage.baseFn.update_current_node($(this).attr("data_type"), $(this).attr("report_url"));
			});
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
		//==========================

		//////////////////////////////////////////
		// 获取对象的value数组
		find_all_indexes_of_a_value_in_arr: function(arr, value){
			var index_arr = [];
			for(var index in arr){
				if(arr[index] == value){
					index_arr.push(index);
				}
			}
			return index_arr;
		},
		find_all_max_min_keys_in_arr: function(keys, values, max_flag, value_range_flag){
			var result = [];
			var max_flag = typeof max_flag !== 'undefined' ? max_flag : true;
			var value_range_flag = typeof value_range_flag !== 'undefined' ? value_range_flag : true;

			var target_value = null;
			var target_flag = true;
			if(max_flag){
				target_value = Math.max.apply(null, values);
				if(value_range_flag){
					target_flag = (target_value > 0);
				}
			} else {
				target_value = Math.min.apply(null, values);
				if(value_range_flag){
					target_flag = (target_value < 0);
				}
			}
			if( target_flag ){
				var ckp_index_arr = reportPage.baseFn.find_all_indexes_of_a_value_in_arr(values, target_value);
				for(var i in ckp_index_arr){
					var ckp_index = ckp_index_arr[i];
					result.push(keys[ckp_index]);
				}
			}
			return result;
		},
		find_all_pos_neg_keys_in_arr: function(keys, values, value_flag){
			var result = [];
			var value_flag = typeof value_flag !== 'undefined' ? value_flag : true;

			for(var i in values){
				var target_index = null;
				if(value_flag && values[i] > 0){
					target_index = i;
				} else if(!value_flag && values[i] < 0){
					target_index = i;
				}
				if(target_index){
					result.push(keys[target_index]);
				}
			}
			return result;
		},
		getValue: function(obj) {
			if(obj){
				return $.map(obj, function(value, index) {
					return [value];
				});
		    } else {
		    	return [];
		    } 
		},
		//调整指标Label显示： 横向 ｜ 纵向
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
		//合并Object
		extendObj: function(obj_arr){
			var result = {};
			var key = "";

			for(var i=0; i < obj_arr.length; i++){
				$.extend(result, obj_arr[i]);
			}
			return result;
		},
		// [{"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}, {"xxxxxx": {"key1":"value1", "key2":"value2", items: []}}]
		get_lv_n_ckp_data: function(value_arr, ckp_level){
			ckp_level = typeof ckp_level !== 'undefined' ? ckp_level : reportPage.ReportCkpStartLevel;

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
		get_key_values: function(value_arr, value_key, ckp_level,vertical_key){
			ckp_level = typeof ckp_level !== 'undefined' ? ckp_level : reportPage.ReportCkpStartLevel;
			vertical_key = typeof vertical_key !== 'undefined' ? vertical_key : true;

			// [{"key1":"value1", "key2":"value2"}, {"key1":"value1", "key2":"value2"}]
			var arr = reportPage.baseFn.get_lv_n_ckp_data(value_arr, ckp_level);//getValue(reportPage.baseFn.extendObj(value_arr));
			var keys = [];
			var values = [];

			for(var i=0 ; i < arr.length ; i++) {
				var modified_key = arr[i].checkpoint;
				if(vertical_key){
					modified_key = reportPage.baseFn.modifyAKey( modified_key );
				}
				keys.push(modified_key);
				var processed_value = arr[i][value_key];
				var regex_matched = value_key.match(/.*percent$/);
				if( regex_matched ){
					processed_value = reportPage.baseFn.formatHundredValue(processed_value);
				} else {
					processed_value = reportPage.baseFn.formatValue(processed_value);
				}
				values.push(processed_value);
			}
			// [["value1", "value2"], ["value3", "value4"]]
			return [keys, values];
		},
		// [{"xxxxxx": {"key1":"value1", "key2":"value3"}}, {"xxxxxx": {"key1":"value1", "key2":"value4"}}]
		get_keys_diff_values: function(value1_arr, value2_arr, value1_key, value2_key, ckp_level, vertical_key){
			ckp_level = typeof ckp_level !== 'undefined' ? ckp_level : reportPage.ReportCkpStartLevel;
			vertical_key = typeof vertical_key !== 'undefined' ? vertical_key : true;

			var value1_kv_arr = reportPage.baseFn.get_key_values(value1_arr, value1_key, ckp_level, vertical_key);
			var value2_kv_arr = reportPage.baseFn.get_key_values(value2_arr, value2_key, ckp_level, vertical_key);
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
		//组装差分柱状图数据
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
		//题目答对率统计表
		getQizpointCorrectRaioTable : function(data){
			var result = { excellent: "", good: "", failed: "" };
			for(var index in data.paper_qzps){
				var qzp = data.paper_qzps[index];
				if(qzp.value != undefined && qzp.value && qzp.value.weights_score_average_percent){
					var html_str = '<tr><td>' 
						+ qzp.qzp_order 
						+ '</td><td>' 
						+ reportPage.baseFn.formatHundredValue(qzp.value.weights_score_average_percent) 
						+ '</td><td>' 
						+ qzp.ckps.knowledge[0].checkpoint 
						+'</td></tr>';
					if( qzp.value.weights_score_average_percent >= 0.85 ) {
						result.excellent += html_str;
					} else if (qzp.value.weights_score_average_percent >= 0.6 && qzp.value.weights_score_average_percent < 0.85) {
						result.good += html_str;
					} else if (qzp.value.weights_score_average_percent >= 0 && qzp.value.weights_score_average_percent < 0.6 ) {
						result.failed += html_str;
					}
				}
			}

			return result;
		},
		//调整数据表格显示style
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
		//比较数值，返回： 高，等，低
		get_compare_level_label: function(value1, value2){
			var result = null;
			if(value1 > value2){
				result = "高";
			} else if (value1 == value2){
				result = "等";
			} else {
				result = "低";
			}
			return result;
		},
		get_score_level_label: function(value){
			var result = null;
			if(value >= 0.85){
				result = "优秀";
			} else if (value >= 0.6 && value < 0.85){
				result = "良好";
			} else if (value >= 0 && value < 0.6 ){
				result = "不及格";
			}
			return result;
		},
		// return: [ knowledge value, skill value, ability value ]
		construct_dimesions_value_arr: function(target_obj, target_key){
			var result = [];
			result = [
				target_obj.knowledge[target_key],
				target_obj.skill[target_key],
				target_obj.ability[target_key]
			];
			return result;
		},
		// dimesions_arr: [ knowledge value, skill value, ability value ]
		get_dimesion_label_max_or_min: function(dimesions_arr, max_flag){
			max_flag = typeof max_flag !== 'undefined' ? max_flag : true;
			var dimesion_label_arr = ["知识","技能","能力"];
			var result = [];
			if( max_flag ){
				var target_value = Math.max.apply(null,dimesions_arr);
			} else {
				var target_value = Math.min.apply(null,dimesions_arr);
			}
			if( target_value == null ){
				return result;
			}
			for(var index in dimesions_arr){
				if( dimesions_arr[index] == target_value ) {
					result.push(dimesion_label_arr[index]);
				}
			}
			return result;
		}, 
		//调整数据显示
		//按试卷满分倍增得分率（默认100），保留两位小数
		formatValueAccordingPaper: function(value){
			if(value != null){
				return (value*reportPage.FullScore).toFixed(2);
			} else {
				return 0.00;
			}
		},
		//按试卷满分倍增得分率（默认100），保留两位小数
		formatHundredValue: function(value){
			if(value != null){
				return (value*100).toFixed(2);
			} else {
				return 0.00;
			}
		},		
		//保留两位小数
		formatValue: function(value){
			if(value != null){
				return value.toFixed(2);
			} else {
				return 0.00;
			}
		}
	},

	/*处理Project数据*/
	Project: {
		createReport : function(){
			//面包屑　
			reportPage.baseFn.construct_bread_crumbs("grade", "project", reportPage.CurrentProjectUrl);
			if(!reportPage.ProjectData.basic){
				$('#reportContent').html(reportPage.ProjectData.message);
				return false;
			}
			//基本信息
			var gradeNavStr =
				'<b>学校数量</b>：<span>' + reportPage.CurrentBreadCrumbChildren.length +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学生数量</b>：<span>' + reportPage.ProjectData.data.knowledge.base.pupil_number +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.ProjectData.basic.term +
				'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.ProjectData.basic.quiz_type +
				'&nbsp;|</span>&nbsp;&nbsp;<b>测试日期</b>：<span>' + reportPage.ProjectData.basic.quiz_date +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学科</b>：<span>' + reportPage.ProjectData.basic.subject +
				'</span>';
			$('.zy-report-type').html('项目报告');
			$('#grade-top-nav').html(gradeNavStr);

			// 诊断图;
			var grade_charts = reportPage.Project.getGradeDiagnoseData();
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
			// 分型图;
			createdCharts.push(echartOption.createEchart(echartOption.getOption.Grade.setGradePartingChartOption(grade_charts.disperse),'parting-chart'));
			window.onresize = function () {
				for(var i=0; i<createdCharts.length; i++){
					createdCharts[i].resize();
				}
			};

			// 导航切换
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
					var NumScaleObj = reportPage.Project.getGradeNumScaleData();
					var objArr = [NumScaleObj.knowledge,NumScaleObj.skill,NumScaleObj.ability];
					var nodeArr = ['KnowledgeScale','SkillScale','AbilityScale'];
					for(var i = 0 ; i < objArr.length ; i++){
						var option = echartOption.getOption.Grade.setGradeScaleOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					}
				}
				else if($dataId == 'grade-FourSections'){
					//创建四分位区间图
					var FourSections = reportPage.Project.getFourSectionsData();
					var objArr = [
						FourSections.knowledge.level75,
						FourSections.skill.level75,
						FourSections.ability.level75,
						FourSections.knowledge.level50,
						FourSections.skill.level50,
						FourSections.ability.level50,
						FourSections.knowledge.level25,
						FourSections.skill.level25,
						FourSections.ability.level25,
						FourSections.knowledge.level0,
						FourSections.skill.level0,
						FourSections.ability.level0
					];
					//页面id
					var nodeArr = [
						'knowledge_Four_L75',
						'skill_Four_L75',
						'ability_Four_L75',
						'knowledge_Four_L50',
						'skill_Four_L50',
						'ability_Four_L50',
						'knowledge_Four_L25',
						'skill_Four_L25',
						'ability_Four_L25',
						'knowledge_Four_L0',
						'skill_Four_L0',
						'ability_Four_L0'
					];

					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setFourSectionsOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
				}
				else if($dataId == 'grade-checkpoint-knowledge'){
					createdCharts.concat(reportPage.Project.getCheckpointClassData("knowledge"));
					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index], "knowledge");
						$('#knowledge_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-skill'){
					createdCharts.concat(reportPage.Project.getCheckpointClassData("skill"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index], "skill");
						$('#skill_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-ability'){
					createdCharts.concat(reportPage.Project.getCheckpointClassData("ability"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index], "ability");
						$('#ability_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-total'){
					createdCharts.concat(reportPage.Project.getCheckpointClassData("total"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index], "total");
						$('#total_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-knowledge'){
					createdCharts.concat(reportPage.Project.getClassPupilNumData("knowledge"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index] + '_pupil_percent', "knowledge");
						$('#knowledge_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-skill'){
					createdCharts.concat(reportPage.Project.getClassPupilNumData("skill"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index] + '_pupil_percent', "skill");
						$('#skill_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-ability'){
					createdCharts.concat(reportPage.Project.getClassPupilNumData("ability"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Project.handleNormTable(value_type_arr[index] + '_pupil_percent', "ability");
						$('#ability_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-answerCase'){
					var table_list = reportPage.baseFn.getQizpointCorrectRaioTable(reportPage.ProjectData);
					$('#excellent_answerCase_table').html(table_list.excellent);
					$('#good_answerCase_table').html(table_list.good);
					$('#failed_answerCase_table').html(table_list.failed);
				}
				// else if($dataId == 'grade-readReport-statistics'){
				// 	//$('#grade-readReport-statistics').html(data.data.report_explanation.statistics);
				// }

				window.onresize = function () {
					for(var i=0; i<createdCharts.length; i++){
						createdCharts[i].resize();
					}
				};
			});
		},
		
		// 获取诊断图数据
		getGradeDiagnoseData : function(){
			//knowledge, skill, ability
			var result = {};
			result["disperse"] = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					xaxis : reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "weights_score_average_percent")[0],
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "weights_score_average_percent")[1],
							grade_diff_degree: reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "diff_degree")[1],
							grade_median_percent: reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "project_median_percent")[1]
						},
						med_avg_diff : reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.ProjectData.data[dim].lv_n, reportPage.ProjectData.data[dim].lv_n, "project_median_percent", "weights_score_average_percent")[1])
					}
				};
				result["disperse"][dim] = reportPage.Grade.handleDisperse(reportPage.ProjectData.data[dim].lv_n);
			}
			return result;
		},
		// 分型图
		handleDisperse : function(data){
			var keysArr = reportPage.baseFn.get_key_values(data, "weights_score_average_percent",2,false)[0];
			var averagePercentArr = reportPage.baseFn.get_key_values(data, "weights_score_average_percent",2,false)[1];
			var diffDegreeArr = reportPage.baseFn.get_key_values(data, "diff_degree",2,false)[1];

			var data_node_arr = [];
			var maxKey=minKey = null;
			for(var i = 0 ; i < keysArr.length; i++){
				data_node_arr.push({
					name: keysArr[i],
					value: [diffDegreeArr[i], averagePercentArr[i]]
				});
			};

			maxKey = keysArr[averagePercentArr.indexOf(String(Math.max.apply(null,averagePercentArr)))];
			minKey = keysArr[averagePercentArr.indexOf(String(Math.min.apply(null,averagePercentArr)))];
			return {
				data_node: data_node_arr,
				maxkey : maxKey,
				minkey : minKey
			};
		},
		// 年级人数比例图
		getGradeNumScaleData : function(){
			//knowledge, skill, ability
			var result = {};
			result["disperse"] = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					yaxis : reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "weights_score_average_percent",null,false)[0],
					data : reportPage.Grade.constructGradeNumScaleArr(reportPage.ProjectData.data[dim].lv_n)
				}
			}
			return result;
		},
		// 组装人数比例数据格式
		constructGradeNumScaleArr : function(data){
			var result = {excellent: [], good: [], failed: []};
			var excellentArr = goodArr = failedArr = [];
			var excellentPercentArr = reportPage.baseFn.get_key_values(data, "excellent_percent")[1];
			var goodPercentArr = reportPage.baseFn.get_key_values(data, "good_percent")[1];
			var failedPercentArr = reportPage.baseFn.get_key_values(data, "failed_percent")[1];

			for(var i = 0 ; i < excellentPercentArr.length ; i++){
				result.excellent.push({
		            name:'(得分率 ≥ 85)',
		            value: excellentPercentArr[i],
		            yAxisIndex:i,
		        });
				result.good.push({
		            name:'( 60 ≤ 得分率 < 85)',
		            value: goodPercentArr[i],
		            yAxisIndex:i
		        });
				result.failed.push({
                    name:'(得分率 < 60)',
                    value: failedPercentArr[i],
                });
			}
			return result;
		},
		// 四分位区间数据信息
		getFourSectionsData : function(){
			var result = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			var section_arr = ["level0", "level25", "level50", "level75"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				for (var j in section_arr) {
					var sec = section_arr[j];

					result[dim] = (result[dim])? result[dim] : {};
					result[dim][sec] = (result[dim][sec])? result[dim][sec] : {};
					result[dim][sec] = {
						xaxis : reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, "weights_score_average_percent")[0],
						yaxis : reportPage.baseFn.get_key_values(reportPage.ProjectData.data[dim].lv_n, sec+"_weights_score_average_percent")[1]
					};
				}
			}
			return result;
		},
		// 获取指标表现水平图
		getCheckpointClassData : function(dimesion){
			var result = [];
			var temp = reportPage.Project.constructCheckpointClassData(dimesion);
			var objArr = [
				temp.average_percent,
				temp.median_percent,
				temp.med_avg_diff,
				temp.diff_degree
			];
			var nodeArr = [
				dimesion + '_Grade_average_percent',
				dimesion + '_Grade_median_percent',
				dimesion + '_Grade_med_avg_diff',
				dimesion + '_Grade_diff_degree'
			];
			for(var i = 0 ; i < nodeArr.length ; i++){
				var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
				result.push(echartOption.createEchart(option,nodeArr[i]));
			};
			return result;
		},
		constructCheckpointClassData : function(dimesion){
			if(dimesion!="total"){
				var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			} else {
				var ckpArr = ["知识","技能","能力"];
			} 
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < ckpArr.length; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:ckpArr[i],icon:'rect'});
			};
			var result = {};
			var value_type_arr = ["average_percent", "diff_degree", "med_avg_diff", "median_percent"]
			for (var i in value_type_arr) {
				var value_type = value_type_arr[i];
				result[value_type] = {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Project.constructCheckpointClassSeries(value_type, dimesion, ckpArr, classNameArr)
				};
			}
			return result;
		},
		constructCheckpointClassSeries : function(value_type, dimesion, ckpArr, classNameArr){
			var class_data_arr = reportPage.Project.get_grade_data_arr(value_type, dimesion);

			var ckp_class_value_arr = [];
			var series = [];
			for(var i = 0 ; i < ckpArr.length ; i++){
				var ckp_value_arr = [];
				for(var k = 0 ; k < classNameArr.length ; k++){
					ckp_value_arr.push(class_data_arr[k][i]);
				};
				ckp_class_value_arr.push(ckp_value_arr);
			};
			for(var j = 0 ; j < ckpArr.length ; j++){
				series.push({
					name: ckpArr[j],
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
					data:ckp_class_value_arr[j]
				})
			};
			return series;
		},

		getClassPupilNumData : function(dimesion){
			var result = [];
            var objArr = reportPage.Project.constructClassPupilRatioData(dimesion);
			var nodeArr = [dimesion + '_excellent',dimesion + '_good', dimesion + '_faild'];
			for(var i = 0 ; i < nodeArr.length ; i++){
				var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
				result.push(echartOption.createEchart(option,nodeArr[i]));
			};
			return result;
		},


        constructClassPupilRatioData : function(dimesion){
			var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < ckpArr.length; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:ckpArr[i],icon:'rect'});
			};
			var result = [];
			var value_type_arr = ["excellent_pupil_percent", "good_pupil_percent", "failed_pupil_percent"];
			for (var i in value_type_arr) {
				var value_type = value_type_arr[i];
				result.push({
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Project.constructCheckpointClassSeries(value_type, dimesion, ckpArr, classNameArr)
				});
			}
			return result;
		},
      
		handleNormTable : function(value_type, dimesion){

			var class_data_arr = reportPage.Project.get_grade_data_arr(value_type, dimesion);
			if(dimesion != "total"){
				var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			} else {
				var ckpArr = ["知识","技能","能力"];
			} 
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});

			var thStr = '<td class="grade-titlt">班级</td>';
			for(var i = 0 ; i < ckpArr.length ; i++){
				thStr += '<td>'+ckpArr[i]+'</td>';
			}
			var allStr = '';
			for(var i = 0 ; i < classNameArr.length ; i++){
				var str = '';
				for(var k = 0 ; k < ckpArr.length ; k++){
					var iNum = class_data_arr[i][k];
					if(iNum > -20  && iNum < 0){
						str += '<td class="wrong">'+iNum+'</td>';
					}else if(iNum < -20 ){
						str += '<td class="wrong more-wrong">'+iNum+'</td>';
					}else{
						str += '<td>'+iNum+'</td>';
					}
//					str += '<td>'+iNum+'</td>';
				}
				if(class_data_arr[i] == '年级'){
					str = '<td>年级</td>'+ str ;
				}else{
					str = '<td>'+classNameArr[i]+'</td>'+ str ;
				}
				allStr += '<tr>'+str+'</tr>';
			}
			return allStr = '<tr>'+thStr+'</tr>' + allStr;
		},

		get_grade_data_arr: function(value_type, dimesion){
			var values = [];
			var class_data_arr = [];
			for( var index in reportPage.CurrentBreadCrumbChildren){
				var data = null;
				if(	reportPage.CurrentBreadCrumbChildren[index] && 
					reportPage.CurrentBreadCrumbChildren[index].resp &&
					reportPage.CurrentBreadCrumbChildren[index].resp.data){
					if(dimesion != "total"){
						data = reportPage.CurrentBreadCrumbChildren[index].resp.data[dimesion].lv_n;
					} else {
						knowledge_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["knowledge"].base;
						knowledge_obj.checkpoint = "知识";
						skill_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["skill"].base;
						skill_obj.checkpoint = "技能";
						ability_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["ability"].base;
						ability_obj.checkpoint = "能力";
					    data = [
							{knowledge: knowledge_obj},
							{skill: skill_obj},
							{ability: ability_obj}
						];
					}
				}
				switch(value_type){
					case "average_percent":
						values = reportPage.baseFn.get_key_values(data, "weights_score_average_percent")[1];
						break;
					case "diff_degree":
						values = reportPage.baseFn.get_key_values(data, "diff_degree")[1];
						break;
					case "median_percent":
						values = reportPage.baseFn.get_key_values(data, "grade_median_percent")[1];
						break;
					case "med_avg_diff":
						values = reportPage.baseFn.get_keys_diff_values(data, data, "grade_median_percent", "weights_score_average_percent")[1];
						values = $.map(values, function(value, index){ return reportPage.baseFn.formatValue(value); });
						break;
					case "excellent_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "excellent_percent")[1];
						break;
					case "good_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "good_percent")[1];
						break;
					case "failed_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "failed_percent")[1];
						break;
				}
				class_data_arr.push(values);
			}
			return class_data_arr;
		}
	},

	/*处理年级数据*/
	Grade: {
		createReport : function(){
			//面包屑　
			reportPage.baseFn.construct_bread_crumbs("klass", "grade", reportPage.CurrentGradeUrl);
			if(!reportPage.GradeData.basic){
				$('#reportContent').html(reportPage.GradeData.message);
				return false;
			}
			//基本信息
			var gradeNavStr =
				'<b>班级数量</b>：<span>' + reportPage.CurrentBreadCrumbChildren.length +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学生数量</b>：<span>' + reportPage.GradeData.data.knowledge.base.pupil_number +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.GradeData.basic.term +
				'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.GradeData.basic.quiz_type +
				'&nbsp;|</span>&nbsp;&nbsp;<b>测试日期</b>：<span>' + reportPage.GradeData.basic.quiz_date +
				'&nbsp;|</span>&nbsp;&nbsp;<b>学科</b>：<span>' + reportPage.GradeData.basic.subject +
				'</span>';
			$('.zy-report-type').html('年级报告');
			$('#grade-top-nav').html(gradeNavStr);

			// 诊断图;
			var grade_charts = reportPage.Grade.getGradeDiagnoseData();
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
			// 分型图;
			createdCharts.push(echartOption.createEchart(echartOption.getOption.Grade.setGradePartingChartOption(grade_charts.disperse),'parting-chart'));
			window.onresize = function () {
				for(var i=0; i<createdCharts.length; i++){
					createdCharts[i].resize();
				}
			};

			// 导航切换
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
					var NumScaleObj = reportPage.Grade.getGradeNumScaleData();
					var objArr = [NumScaleObj.knowledge,NumScaleObj.skill,NumScaleObj.ability];
					var nodeArr = ['KnowledgeScale','SkillScale','AbilityScale'];
					for(var i = 0 ; i < objArr.length ; i++){
						var option = echartOption.getOption.Grade.setGradeScaleOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					}
				}
				else if($dataId == 'grade-FourSections'){
					//创建四分位区间图
					var FourSections = reportPage.Grade.getFourSectionsData();
					var objArr = [
						FourSections.knowledge.level75,
						FourSections.skill.level75,
						FourSections.ability.level75,
						FourSections.knowledge.level50,
						FourSections.skill.level50,
						FourSections.ability.level50,
						FourSections.knowledge.level25,
						FourSections.skill.level25,
						FourSections.ability.level25,
						FourSections.knowledge.level0,
						FourSections.skill.level0,
						FourSections.ability.level0
					];
					//页面id
					var nodeArr = [
						'knowledge_Four_L75',
						'skill_Four_L75',
						'ability_Four_L75',
						'knowledge_Four_L50',
						'skill_Four_L50',
						'ability_Four_L50',
						'knowledge_Four_L25',
						'skill_Four_L25',
						'ability_Four_L25',
						'knowledge_Four_L0',
						'skill_Four_L0',
						'ability_Four_L0'
					];

					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setFourSectionsOption(objArr[i]);
						createdCharts.push(echartOption.createEchart(option,nodeArr[i]));
					};
				}
				else if($dataId == 'grade-checkpoint-knowledge'){
					createdCharts.concat(reportPage.Grade.getCheckpointClassData("knowledge"));
					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index], "knowledge");
						$('#knowledge_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-skill'){
					createdCharts.concat(reportPage.Grade.getCheckpointClassData("skill"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index], "skill");
						$('#skill_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-ability'){
					createdCharts.concat(reportPage.Grade.getCheckpointClassData("ability"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index], "ability");
						$('#ability_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-checkpoint-total'){
					createdCharts.concat(reportPage.Grade.getCheckpointClassData("total"));

					var value_type_arr = ["average_percent", "median_percent", "med_avg_diff", "diff_degree"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index], "total");
						$('#total_' + value_type_arr[index]).html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-knowledge'){
					createdCharts.concat(reportPage.Grade.getClassPupilNumData("knowledge"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index] + '_pupil_percent', "knowledge");
						$('#knowledge_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-skill'){
					createdCharts.concat(reportPage.Grade.getClassPupilNumData("skill"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index] + '_pupil_percent', "skill");
						$('#skill_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-classPupilNum-ability'){
					createdCharts.concat(reportPage.Grade.getClassPupilNumData("ability"));

					var value_type_arr = ["excellent", "good", "failed"];
					for (var index in value_type_arr){
						var value_table = reportPage.Grade.handleNormTable(value_type_arr[index] + '_pupil_percent', "ability");
						$('#ability_' + value_type_arr[index] + '_table').html(value_table);
					}
				}
				else if($dataId == 'grade-answerCase'){
					var table_list = reportPage.baseFn.getQizpointCorrectRaioTable(reportPage.GradeData);
					$('#excellent_answerCase_table').html(table_list.excellent);
					$('#good_answerCase_table').html(table_list.good);
					$('#failed_answerCase_table').html(table_list.failed);
				}
				// else if($dataId == 'grade-readReport-statistics'){
				// 	//$('#grade-readReport-statistics').html(data.data.report_explanation.statistics);
				// }

				window.onresize = function () {
					for(var i=0; i<createdCharts.length; i++){
						createdCharts[i].resize();
					}
				};
			});
		},
		
		// 获取诊断图数据
		getGradeDiagnoseData : function(){
			//knowledge, skill, ability
			var result = {};
			result["disperse"] = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					xaxis : reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent")[0],
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent")[1],
							grade_diff_degree: reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "diff_degree")[1],
							grade_median_percent: reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "grade_median_percent")[1]
						},
						med_avg_diff : reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.GradeData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "grade_median_percent", "weights_score_average_percent")[1])
					}
				};
				result["disperse"][dim] = reportPage.Grade.handleDisperse(reportPage.GradeData.data[dim].lv_n);
			}
			return result;
		},
		// 分型图
		handleDisperse : function(data){
			var keysArr = reportPage.baseFn.get_key_values(data, "weights_score_average_percent",2,false)[0];
			var averagePercentArr = reportPage.baseFn.get_key_values(data, "weights_score_average_percent",2,false)[1];
			var diffDegreeArr = reportPage.baseFn.get_key_values(data, "diff_degree",2,false)[1];

			var data_node_arr = [];
			var maxKey=minKey = null;
			for(var i = 0 ; i < keysArr.length; i++){
				data_node_arr.push({
					name: keysArr[i],
					value: [diffDegreeArr[i], averagePercentArr[i]]
				});
			};

			maxKey = keysArr[averagePercentArr.indexOf(String(Math.max.apply(null,averagePercentArr)))];
			minKey = keysArr[averagePercentArr.indexOf(String(Math.min.apply(null,averagePercentArr)))];
			return {
				data_node: data_node_arr,
				maxkey : maxKey,
				minkey : minKey
			};
		},
		// 年级人数比例图
		getGradeNumScaleData : function(){
			//knowledge, skill, ability
			var result = {};
			result["disperse"] = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				result[dim] = {
					yaxis : reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent",null,false)[0],
					data : reportPage.Grade.constructGradeNumScaleArr(reportPage.GradeData.data[dim].lv_n)
				}
			}
			return result;
		},
		// 组装人数比例数据格式
		constructGradeNumScaleArr : function(data){
			var result = {excellent: [], good: [], failed: []};
			var excellentArr = goodArr = failedArr = [];
			var excellentPercentArr = reportPage.baseFn.get_key_values(data, "excellent_percent")[1];
			var goodPercentArr = reportPage.baseFn.get_key_values(data, "good_percent")[1];
			var failedPercentArr = reportPage.baseFn.get_key_values(data, "failed_percent")[1];

			for(var i = 0 ; i < excellentPercentArr.length ; i++){
				result.excellent.push({
		            name:'(得分率 ≥ 85)',
		            value: excellentPercentArr[i],
		            yAxisIndex:i,
		        });
				result.good.push({
		            name:'( 60 ≤ 得分率 < 85)',
		            value: goodPercentArr[i],
		            yAxisIndex:i
		        });
				result.failed.push({
                    name:'(得分率 < 60)',
                    value: failedPercentArr[i],
                });
			}
			return result;
		},
		// 四分位区间数据信息
		getFourSectionsData : function(){
			var result = {};
			var dimesion_arr = ["knowledge", "skill", "ability"];
			var section_arr = ["level0", "level25", "level50", "level75"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];
				for (var j in section_arr) {
					var sec = section_arr[j];

					result[dim] = (result[dim])? result[dim] : {};
					result[dim][sec] = (result[dim][sec])? result[dim][sec] : {};
					result[dim][sec] = {
						xaxis : reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent")[0],
						yaxis : reportPage.baseFn.get_key_values(reportPage.GradeData.data[dim].lv_n, sec+"_weights_score_average_percent")[1]
					};
				}
			}
			return result;
		},
		// 获取指标表现水平图
		getCheckpointClassData : function(dimesion){
			var result = [];
			var temp = reportPage.Grade.constructCheckpointClassData(dimesion);
			var objArr = [
				temp.average_percent,
				temp.median_percent,
				temp.med_avg_diff,
				temp.diff_degree
			];
			var nodeArr = [
				dimesion + '_Grade_average_percent',
				dimesion + '_Grade_median_percent',
				dimesion + '_Grade_med_avg_diff',
				dimesion + '_Grade_diff_degree'
			];
			for(var i = 0 ; i < nodeArr.length ; i++){
				var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
				result.push(echartOption.createEchart(option,nodeArr[i]));
			};
			return result;
		},
		constructCheckpointClassData : function(dimesion){
			if (dimesion != "total"){
				var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			} else {
				var ckpArr = ["知识","技能","能力"];
			}
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < ckpArr.length; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:ckpArr[i],icon:'rect'});
			};
			var result = {};
			var value_type_arr = ["average_percent", "diff_degree", "med_avg_diff", "median_percent"]
			for (var i in value_type_arr) {
				var value_type = value_type_arr[i];
				result[value_type] = {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.constructCheckpointClassSeries(value_type, dimesion, ckpArr, classNameArr)
				};
			}
			return result;
		},
		constructCheckpointClassSeries : function(value_type, dimesion, ckpArr, classNameArr){
			var class_data_arr = reportPage.Grade.get_class_data_arr(value_type, dimesion);

			var ckp_class_value_arr = [];
			var series = [];
			for(var i = 0 ; i < ckpArr.length ; i++){
				var ckp_value_arr = [];
				for(var k = 0 ; k < classNameArr.length ; k++){
					ckp_value_arr.push(class_data_arr[k][i]);
				};
				ckp_class_value_arr.push(ckp_value_arr);
			};
			for(var j = 0 ; j < ckpArr.length ; j++){
				series.push({
					name: ckpArr[j],
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
					data:ckp_class_value_arr[j]
				})
			};
			return series;
		},

		getClassPupilNumData : function(dimesion){
			var result = [];
            var objArr = reportPage.Grade.constructClassPupilRatioData(dimesion);
			var nodeArr = [dimesion + '_excellent',dimesion + '_good', dimesion + '_faild'];
			for(var i = 0 ; i < nodeArr.length ; i++){
				var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
				result.push(echartOption.createEchart(option,nodeArr[i]));
			};
			return result;
		},


        constructClassPupilRatioData : function(dimesion){
			var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < ckpArr.length; i++){
				colorArr.push(reportPage.chartColor[i]);
				normNameArr.push({name:ckpArr[i],icon:'rect'});
			};
			var result = [];
			var value_type_arr = ["excellent_pupil_percent", "good_pupil_percent", "failed_pupil_percent"];
			for (var i in value_type_arr) {
				var value_type = value_type_arr[i];
				result.push({
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.constructCheckpointClassSeries(value_type, dimesion, ckpArr, classNameArr)
				});
			}
			return result;
		},
      
		handleNormTable : function(value_type, dimesion){

			var class_data_arr = reportPage.Grade.get_class_data_arr(value_type, dimesion);
			if(dimesion != "total"){
				var ckpArr = reportPage.baseFn.get_key_values(reportPage.CurrentBreadCrumbChildren[0].resp.data[dimesion].lv_n, "weights_score_average_percent", null, false)[0];
			} else {
				var ckpArr = ["知识","技能","能力"];
			}
			var classNameArr = $.map(reportPage.CurrentBreadCrumbChildren,function(value, index){return value[1].label});

			var thStr = '<td class="grade-titlt">班级</td>';
			for(var i = 0 ; i < ckpArr.length ; i++){
				thStr += '<td>'+ckpArr[i]+'</td>';
			}
			var allStr = '';
			for(var i = 0 ; i < classNameArr.length ; i++){
				var str = '';
				for(var k = 0 ; k < ckpArr.length ; k++){
					var iNum = class_data_arr[i][k];
					if(iNum > -20  && iNum < 0){
						str += '<td class="wrong">'+iNum+'</td>';
					}else if(iNum < -20 ){
						str += '<td class="wrong more-wrong">'+iNum+'</td>';
					}else{
						str += '<td>'+iNum+'</td>';
					}
//					str += '<td>'+iNum+'</td>';
				}
				if(class_data_arr[i] == '年级'){
					str = '<td>年级</td>'+ str ;
				}else{
					str = '<td>'+classNameArr[i]+'</td>'+ str ;
				}
				allStr += '<tr>'+str+'</tr>';
			}
			return allStr = '<tr>'+thStr+'</tr>' + allStr;
		},

		get_class_data_arr: function(value_type, dimesion){
			var values = [];
			var class_data_arr = [];
			for( var index in reportPage.CurrentBreadCrumbChildren){
				var data = null;
				if(	reportPage.CurrentBreadCrumbChildren[index] && 
					reportPage.CurrentBreadCrumbChildren[index].resp &&
					reportPage.CurrentBreadCrumbChildren[index].resp.data){
					if(dimesion != "total"){
						data = reportPage.CurrentBreadCrumbChildren[index].resp.data[dimesion].lv_n;
					} else {
						knowledge_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["knowledge"].base;
						knowledge_obj.checkpoint = "知识";
						skill_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["skill"].base;
						skill_obj.checkpoint = "技能";
						ability_obj = reportPage.CurrentBreadCrumbChildren[index].resp.data["ability"].base;
						ability_obj.checkpoint = "能力";
					    data = [
							{knowledge: knowledge_obj},
							{skill: skill_obj},
							{ability: ability_obj}
						];
					}
				}
				switch(value_type){
					case "average_percent":
						values = reportPage.baseFn.get_key_values(data, "weights_score_average_percent")[1];
						break;
					case "diff_degree":
						values = reportPage.baseFn.get_key_values(data, "diff_degree")[1];
						break;
					case "median_percent":
						values = reportPage.baseFn.get_key_values(data, "klass_median_percent")[1];
						break;
					case "med_avg_diff":
						values = reportPage.baseFn.get_keys_diff_values(data, data, "klass_median_percent", "weights_score_average_percent")[1];
						values = $.map(values, function(value, index){ return reportPage.baseFn.formatValue(value); });
						break;
					case "excellent_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "excellent_percent")[1];
						break;
					case "good_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "good_percent")[1];
						break;
					case "failed_pupil_percent":
						values = reportPage.baseFn.get_key_values(data, "failed_percent")[1];
						break;
				}
				class_data_arr.push(values);
			}
			return class_data_arr;
		}
	},

	/*处理班级数据*/
	Class: {
		createReport : function(){
			//面包屑　
			reportPage.baseFn.construct_bread_crumbs("pupil", "klass", reportPage.CurrentKlassUrl);
			if(!reportPage.KlassData.basic){
				$('#reportContent').html(reportPage.KlassData.message);
				return false;
			}
			//基本信息
			var classNavStr =
				'<b>班级人数</b>：<span>' + reportPage.KlassData.data.knowledge.base.pupil_number
			    +'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.KlassData.basic.term
			    +'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.KlassData.basic.quiz_type
			    +'&nbsp;|</span>&nbsp;&nbsp;<b>测试日期</b>：<span>' + reportPage.KlassData.basic.quiz_date
				+'&nbsp;|</span>&nbsp;&nbsp;<b>学科</b>：<span>' + reportPage.KlassData.basic.subject
				+ '</span>';
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
					var tableStr = reportPage.Class.constructDataTable('knowledge');
					$('#Class_knowledge_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.Class.constructDataTable('skill');
					$('#Class_skill_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.Class.constructDataTable('ability');
					$('#Class_ability_table').html(tableStr);
				}

				//答对率
				else if($dataId == 'class-answerCase'){
					var table_list = reportPage.baseFn.getQizpointCorrectRaioTable(reportPage.KlassData);
					$('#excellent_answerCase_table').html(table_list.excellent);
					$('#good_answerCase_table').html(table_list.good);
					$('#failed_answerCase_table').html(table_list.failed);
				}

				//报告解读
				else if($dataId == 'report-read-checkpoint'){
					$('#report-read-checkpoint').html(data.data.report_explanation.statistics);
				}

				//测试评价
				else if($dataId == 'exam-knowledge'){
					reportPage.Class.constructDiagnosisSuggestion("knowledge");
				}else if($dataId == 'exam-skill'){
					reportPage.Class.constructDiagnosisSuggestion("skill");
				}else if($dataId == 'exam-ability'){
					reportPage.Class.constructDiagnosisSuggestion("ability");
				}else if($dataId == 'exam-total'){
					reportPage.Class.constructDiagnosisSuggestion("total");
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
							avg:reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.KlassData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", "weights_score_average_percent")[1])
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
                    value: reportPage.baseFn.formatHundredValue(data_arr[i].excellent_percent),
                    yAxisIndex:1
				});
				good_arr.push({
                    name:'(60 ≤ 得分率 < 85)',
                    value: reportPage.baseFn.formatHundredValue(data_arr[i].good_percent)
				});
				failed_arr.push({
                    name:'(得分率 < 60)',
                    value: reportPage.baseFn.formatHundredValue(data_arr[i].failed_percent)
				});
			}
			return { excenllent: excellent_arr, good : good_arr, failed: failed_arr };
		},
		//处理数据表
		constructDataTable: function(dimesion) {
			var tableHtmlStr = '';
			var klassBase = reportPage.KlassData.data[dimesion].base;
			var dimesionRatio = reportPage.FullScore/klassBase.total_full_weights_score;
			var gradeBase = reportPage.GradeData.data[dimesion].base;
			var klassLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.KlassData.data[dimesion].lv_n )), function(value, index){ return value } );
			var gradeLv1Arr = $.map(reportPage.baseFn.getValue( reportPage.baseFn.extendObj( reportPage.GradeData.data[dimesion].lv_n )), function(value, index){ return value } );
			var baseArr = ["<tr>"];
			var lv1Arr = ["<tr>"];
			//总计
			//指标名;
			baseArr.push('<td class="one-level">' + "总计" + '</td>');
			//班级平均分值
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassBase.total_real_weights_score*dimesionRatio) + '</td>');
			//班级平均得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(klassBase.weights_score_average_percent) + '</td>');
			//班级中位数得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(klassBase.klass_median_percent) + '</td>');
			//年级平均得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(gradeBase.weights_score_average_percent) + '</td>');
			//班级与年级平均得分率差值
			baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassBase.weights_score_average_percent, gradeBase.weights_score_average_percent));
			//班级与年级中位数平均得分率差值
			baseArr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassBase.klass_median_percent, gradeBase.weights_score_average_percent));
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
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].total_real_weights_score*dimesionRatio) + '</td>');
				//班级平均得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(klassLv1Arr[i].weights_score_average_percent) + '</td>');
				//班级中位数得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(klassLv1Arr[i].klass_median_percent) + '</td>');
				//年级平均得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(gradeLv1Arr[i].weights_score_average_percent) + '</td>');
				//班级与年级平均得分率差值
				lv1Arr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv1Arr[i].weights_score_average_percent, gradeLv1Arr[i].weights_score_average_percent));
				//班级与年级中位数平均得分率差值
				lv1Arr.push(reportPage.Pupil.checkDataTableCol("one-level-content", klassLv1Arr[i].klass_median_percent, gradeLv1Arr[i].weights_score_average_percent));
				//分化程度
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].diff_degree) + '</td>');
				//满分值
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatValue(klassLv1Arr[i].total_full_weights_score*dimesionRatio) + '</td>');
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
					lv2Arr.push('<td>' + reportPage.baseFn.formatValue(klassLv2Arr[ii].total_real_weights_score*dimesionRatio) + '</td>');
					//班级平均得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatHundredValue(klassLv2Arr[ii].weights_score_average_percent) + '</td>');
					//班级中位数得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatHundredValue(klassLv2Arr[ii].klass_median_percent) + '</td>');
					//年级平均得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatHundredValue(gradeLv2Arr[ii].weights_score_average_percent) + '</td>');
					//班级与年级平均得分率差值
					lv2Arr.push(reportPage.Pupil.checkDataTableCol("", klassLv2Arr[ii].weights_score_average_percent, gradeLv2Arr[ii].weights_score_average_percent));
					//班级与年级中位数平均得分率差值
					lv2Arr.push(reportPage.Pupil.checkDataTableCol("", klassLv2Arr[ii].klass_median_percent, gradeLv2Arr[ii].weights_score_average_percent));
					//分化程度
					lv2Arr.push('<td>' + reportPage.baseFn.formatValue(klassLv2Arr[ii].diff_degree) + '</td>');
					//满分值
					lv2Arr.push('<td>' + reportPage.baseFn.formatValue(klassLv2Arr[ii].total_full_weights_score*dimesionRatio) + '</td>');
					lv2Arr.push("</tr>");
					tableHtmlStr += lv2Arr.join("");
				}
			}
			return tableHtmlStr;
		},
		//诊断测评
		constructDiagnosisSuggestion: function(dimesion){
			//指标分数状况
			if( dimesion != "total" ) {
				//班级
				var self_ckps_values = reportPage.baseFn.get_key_values(reportPage.KlassData.data[dimesion].lv_n, "weights_score_average_percent" ,2, false);				
				var self_best = reportPage.baseFn.find_all_max_min_keys_in_arr(self_ckps_values[0], self_ckps_values[1], true, false);
				var self_worst = reportPage.baseFn.find_all_max_min_keys_in_arr(self_ckps_values[0], self_ckps_values[1], false, false);

				//与年级比较
				var diff_with_grade_ckps_values = reportPage.baseFn.get_keys_diff_values(reportPage.KlassData.data[dimesion].lv_n, reportPage.GradeData.data[dimesion].lv_n, "weights_score_average_percent", "weights_score_average_percent",2, false);
				var compare_with_grade_best = reportPage.baseFn.find_all_pos_neg_keys_in_arr(diff_with_grade_ckps_values[0], diff_with_grade_ckps_values[1]);
				var compare_with_grade_worst = reportPage.baseFn.find_all_pos_neg_keys_in_arr(diff_with_grade_ckps_values[0], diff_with_grade_ckps_values[1], false);

				//班级平均得分率
				var self_weights_score_average_percent = reportPage.baseFn.formatHundredValue(reportPage.KlassData.data[dimesion].base.weights_score_average_percent);
				var self_weights_score_average_percent_level = reportPage.baseFn.get_score_level_label(reportPage.KlassData.data[dimesion].base.weights_score_average_percent);

				//与年级比较
				var grade_weights_score_average_percent = reportPage.baseFn.formatHundredValue(reportPage.GradeData.data[dimesion].base.weights_score_average_percent);
				var compare_with_grade_weights_score_average_percent = reportPage.baseFn.get_compare_level_label(self_weights_score_average_percent, grade_weights_score_average_percent);
			} else {
				//班级
				var dimesion_keys = ["知识", "技能", "能力"];
				var klass_base_values = [
					reportPage.KlassData.data.knowledge.base.weights_score_average_percent,
					reportPage.KlassData.data.skill.base.weights_score_average_percent,
					reportPage.KlassData.data.ability.base.weights_score_average_percent
				];
				var self_best = reportPage.baseFn.find_all_max_min_keys_in_arr(dimesion_keys, klass_base_values);
				var self_worst = reportPage.baseFn.find_all_max_min_keys_in_arr(dimesion_keys, klass_base_values, false, false);

				//与年级比较
				var compare_with_grade_best = [];
				var compare_with_grade_worst = []; 
				var dimesion_arr = ["knowledge", "skill", "ability"];
				for (var i in dimesion_arr) {
					var dim = dimesion_arr[i];
					var diff_value = reportPage.KlassData.data[dim].base.weights_score_average_percent - reportPage.GradeData.data[dim].base.weights_score_average_percent;
					if(diff_value > 0){
						compare_with_grade_best.push(dimesion_keys[i]);
					} else if(diff_value < 0){
						compare_with_grade_worst.push(dimesion_keys[i]);
					} else {
						//do nothing
					}
				}

				//班级平均得分率
				var self_weights_score_average_percent = reportPage.KlassData.data.knowledge.base.weights_score_average_percent * reportPage.DimesionRatio.knowledge +
					reportPage.KlassData.data.skill.base.weights_score_average_percent * reportPage.DimesionRatio.skill +
					reportPage.KlassData.data.ability.base.weights_score_average_percent * reportPage.DimesionRatio.ability;
				var self_weights_score_average_percent_level = reportPage.baseFn.get_score_level_label(self_weights_score_average_percent);
				
				//与年级比较
				var grade_weights_score_average_percent = reportPage.GradeData.data.knowledge.base.weights_score_average_percent * reportPage.DimesionRatio.knowledge +
					reportPage.GradeData.data.skill.base.weights_score_average_percent * reportPage.DimesionRatio.skill +
					reportPage.GradeData.data.ability.base.weights_score_average_percent * reportPage.DimesionRatio.ability;
				var compare_with_grade_weights_score_average_percent = reportPage.baseFn.get_compare_level_label(self_weights_score_average_percent, grade_weights_score_average_percent);

				//班级平均得分率转换
				self_weights_score_average_percent = reportPage.baseFn.formatHundredValue(self_weights_score_average_percent);
			}

			//班级最好
			$(".klass_diagnosis." + dimesion + " .self_best").html(self_best.join(", &nbsp;"));
			//班级最差
			$(".klass_diagnosis." + dimesion + " .self_worst").html(self_worst.join(", &nbsp;"));
			//好于年级
			$(".klass_diagnosis." + dimesion + " .grade_in_group_best").html(compare_with_grade_best.join(", &nbsp;"));
			//坏于年级
			$(".klass_diagnosis." + dimesion + " .grade_in_group_worst").html(compare_with_grade_worst.join(", &nbsp;"));
			//班级平均得分率
			$(".klass_diagnosis." + dimesion + " .self_weights_score_average_percent").html(self_weights_score_average_percent);
			$(".klass_diagnosis." + dimesion + " .self_weights_score_average_percent_level").html(self_weights_score_average_percent_level);
			//与年级比较
			$(".klass_diagnosis." + dimesion + " .compare_with_grade_weights_score_average_percent_level").html(compare_with_grade_weights_score_average_percent);

			//班级各等级人数比例
			var result_level_arr = ["excellent", "good", "failed"];
			for (var j in result_level_arr) {
				var level = result_level_arr[j];
				if(dimesion!="total"){
					// 班级部分
					var self_pupil_number_percent = reportPage.KlassData.data[dimesion].base[level+"_percent"];
					var grade_pupil_number_percent = reportPage.GradeData.data[dimesion].base[level+"_percent"];
					//与年级比较
					compare_with_grade_pupil_number_percent = reportPage.baseFn.get_compare_level_label(self_pupil_number_percent, grade_pupil_number_percent);
				} else {
					//暂时不实现
					// // 班级部分
					// var self_pupil_number_percent = reportPage.baseFn.construct_dimesions_value_arr(reportPage.KlassData.comment["version1.0"],"self_"+level+"_pupil_number_percent").reduce(function(a, b){ return a+b;})/3;
					// var grade_pupil_number_percent = reportPage.baseFn.construct_dimesions_value_arr(reportPage.GradeData.comment["version1.0"],"self_"+level+"_pupil_number_percent").reduce(function(a, b){ return a+b;})/3;
					// //与年级比较
					// compare_with_grade_pupil_number_percent = reportPage.baseFn.get_compare_level_label(self_pupil_number_percent, grade_pupil_number_percent);
					var self_pupil_number_percent = null;
					var compare_with_grade_pupil_number_percent = null;
				}
	
				//班级部分
				if(self_pupil_number_percent){
					$(".klass_diagnosis." + dimesion + " .self_" +level+ "_pupil_number_percent").html(reportPage.baseFn.formatHundredValue(self_pupil_number_percent));
				}

				//与年级比较
				if(compare_with_grade_pupil_number_percent){
					$(".klass_diagnosis." + dimesion + " .compare_with_grade_" +level+ "_pupil_number_percent").html(compare_with_grade_pupil_number_percent);
				}
			}
		}
	},

	Pupil: {
		createReport : function(){
			//面包屑　
			reportPage.baseFn.construct_bread_crumbs(null, "pupil", reportPage.CurrentPupilUrl);
			if(!reportPage.PupilData.basic){
				$('#reportContent').html(reportPage.PupilData.message);
				return false;
			}
			//基本信息
			var pupilNavStr =
			'<b>分数</b>：<span>' + reportPage.baseFn.formatValueAccordingPaper(reportPage.PupilData.data.knowledge.base.weights_score_average_percent) +
			'&nbsp;|</span>&nbsp;&nbsp;' +
			'<b>年级名次</b>：<span>' + reportPage.PupilData.data.knowledge.base.grade_rank + 
			'&nbsp;|</span>&nbsp;&nbsp;' +
			'<b>班级名次</b>：<span>' + reportPage.PupilData.data.knowledge.base.klass_rank + 
			'&nbsp;|</span>&nbsp;&nbsp;' +
			'<b>性别</b>：<span>' + reportPage.PupilData.basic.sex +
			'&nbsp;|</span>&nbsp;&nbsp;<b>学期</b>：<span>' + reportPage.PupilData.basic.term + 
			'&nbsp;|</span>&nbsp;&nbsp;<b>测试类型</b>：<span>' + reportPage.PupilData.basic.quiz_type +
			'&nbsp;|</span>&nbsp;&nbsp;<b>测试日期</b>：<span>' + reportPage.PupilData.basic.quiz_date +
			'&nbsp;|</span>&nbsp;&nbsp;<b>学科</b>：<span>' + reportPage.PupilData.basic.subject +
			'</span>';

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
					$('#pupil_knowledge_percentile').html(reportPage.PupilData.data.knowledge.base.grade_percentile);
					$('#knowledge_data_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.Pupil.constructDataTable('skill');
					$('#pupil_skill_percentile').html(reportPage.PupilData.data.skill.base.grade_percentile);
					$('#skill_data_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.Pupil.constructDataTable('ability');
					$('#pupil_ability_percentile').html(reportPage.PupilData.data.ability.base.grade_percentile);
					$('#ability_data_table').html(tableStr);
				}else if($dataId == 'pupil-improve-suggestion'){
					reportPage.Pupil.constructDiagnosisSuggestion();
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
						xaxis : reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", "weights_score_average_percent", 2)[0],
						yaxis :	reportPage.baseFn.getBarDiff(reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", "weights_score_average_percent",2)[1])
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
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(pupilBase.weights_score_average_percent) + '</td>');
			//年级得分率
			baseArr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(gradeBase.weights_score_average_percent) + '</td>');
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
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(pupilLv1Arr[i].weights_score_average_percent) + '</td>');
				//年级得分率
				lv1Arr.push('<td class="one-level">' + reportPage.baseFn.formatHundredValue(gradeLv1Arr[i].weights_score_average_percent) + '</td>');
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
					lv2Arr.push('<td>' + reportPage.baseFn.formatHundredValue(pupilLv2Arr[ii].weights_score_average_percent) + '</td>');
					//年级得分率
					lv2Arr.push('<td>' + reportPage.baseFn.formatHundredValue(gradeLv2Arr[ii].weights_score_average_percent) + '</td>');
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
		checkDataTableCol: function( col_class, target_value, hikaku_value ) {
			col_class = typeof col_class !== 'undefined' ? col_class : "";
			target_value = typeof target_value !== 'undefined' ? target_value : 0;
			hikaku_value = typeof hikaku_value !== 'undefined' ? hikaku_value : 1;

			var result = "";
			var diff = target_value - hikaku_value;
			var diff_ratio = 0;
			diff_ratio = diff/hikaku_value;

			if(diff_ratio < 0 && diff_ratio > -0.3){
				result += '<td class="' + col_class + ' wrong">' + reportPage.baseFn.formatHundredValue(diff) + '</td>';
			}else if(diff_ratio < -0.3){
				result += '<td class="' + col_class + ' more-wrong">' + reportPage.baseFn.formatHundredValue(diff) + '</td>';
			}else{
				result += '<td class="' + col_class + '">' + reportPage.baseFn.formatHundredValue(diff) + '</td>';
			};
			return result;
		},
		// 诊断测评
		constructDiagnosisSuggestion: function(){
			var dimesion_arr = ["knowledge", "skill", "ability"];
			for (var i in dimesion_arr) {
				var dim = dimesion_arr[i];

				// 个人部分
				var self_ckps_values = reportPage.baseFn.get_key_values(reportPage.PupilData.data[dim].lv_n, "weights_score_average_percent" ,2, false);				
				var ckps = reportPage.baseFn.find_all_max_min_keys_in_arr(self_ckps_values[0], self_ckps_values[1]);
				$(".pupil_diagnosis ." + dim + "_self_best").html(ckps.join(", &nbsp;"));

				// 与班级比较部分
				var diff_with_klass_ckps_values = reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.KlassData.data[dim].lv_n, "weights_score_average_percent", "weights_score_average_percent", 2, false);
				ckps = reportPage.baseFn.find_all_max_min_keys_in_arr(diff_with_klass_ckps_values[0], diff_with_klass_ckps_values[1]);
				$(".pupil_diagnosis ." + dim + "_klass_in_group_best").html(ckps.join(", &nbsp;"));

				// 与年级比较部分
				var diff_with_grade_ckps_values = reportPage.baseFn.get_keys_diff_values(reportPage.PupilData.data[dim].lv_n, reportPage.GradeData.data[dim].lv_n, "weights_score_average_percent", "weights_score_average_percent",2, false);
				ckps = reportPage.baseFn.find_all_max_min_keys_in_arr(diff_with_grade_ckps_values[0], diff_with_grade_ckps_values[1],false);
				$(".pupil_diagnosis ." + dim + "_grade_in_group_worst").html(ckps.join(", &nbsp;"));
			}
		}//constructDiagnosisSuggestion
	}
}