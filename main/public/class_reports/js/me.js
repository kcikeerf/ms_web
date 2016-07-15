//知识诊断图
var allStr_knowledge = '';
var allStr_skill = '';
var allStr_ability = '';
var excellent_str = '';
var good_str = '';
var failed_str = '';
var garde_section_obj = null;
var report_obj = null;
var evaluate_obj = null;
var echartData;
var classInfor; 
$(function(){
	//将获取的json处理成数组可以传参的形式;
	//获取url后面的参数;
	function GetRequest() {   
	   var url = location.search; //获取url中"?"符后的字串   
	   var theRequest = new Object();   
	   if (url.indexOf("?") != -1) {   
	      var str = url.substr(1);   
	      strs = str.split("&");   
	      for(var i = 0; i < strs.length; i ++) {   
	         theRequest[strs[i].split("=")[0]]=unescape(strs[i].split("=")[1]);   
	      }   
	   }   
	   return theRequest;   
	}   
	var ParameterInfo = GetRequest();
	//获取json数据;
	var urlData =  {'report_id':ParameterInfo.report_id};
	var urlStr = '/reports/get_class_report';
	$.get(urlStr,urlData,function(data){
		if(data.status == 200){
			console.log(data);
			allStr_knowledge = dataInTable(data.data.data_table.knowledge);
			allStr_skill = dataInTable(data.data.data_table.skill);
			allStr_ability = dataInTable(data.data.data_table.ability);
                        excellent_str = handleAnswer(data.data.average_percent.excellent);
                        good_str = handleAnswer(data.data.average_percent.good);
                        failed_str = handleAnswer(data.data.average_percent.failed);
			garde_section_obj = data.data.each_level_number;
			report_obj = data.data.report_explanation;
			evaluate_obj = data.data.quiz_comment;
			echartData = echartHandle(data.data.charts);
			classInfor = data.data.basic;
		}else{
			alert('您的网络出现问题！');
		}
		
	})
	//答题情况统计;
	function handleAnswer(obj){
		var str='';
		if(obj != null){
			var keyNames =  Object.keys(obj);
			var valueArr =  $.map(obj, function(value,index){
								return [value];
							});
			var len = keyNames.length;
			for(var i=0;i<len;i++){
				str += '<tr><td>'+keyNames[i]+'</td><td>'+valueArr[i]+'</td></tr>'
			}
		}
		return str;
	}
	//表格JSON处理函数;
	function dataInTable(obj){
		var allStr = '';
		//创建一级指标table ------ knowledge;
		var oneArrKey = Object.keys(obj);
		var oneArrValue =  $.map(obj, function(value,index){
								return [value];
							});
		var one_len = oneArrKey.length;
		for(var i = 0 ; i < one_len ; i++){
			var oneValueStr = ''; 
			var twoAllStr = '';
			//取得一级指标的键名;
			one_level_name = oneArrKey[i];
			var oneNameStr = '<td class="colbg">'+one_level_name+'</td>';
			//取得一级指标的键值对value；
			var oneValue = oneArrValue[i].value;
			var oneValueArr = [oneValue.cls_average,oneValue.cls_average_percent,oneValue.class_median_percent,oneValue.gra_average_percent,oneValue.cls_gra_avg_percent_diff,oneValue.cls_med_gra_avg_percent_diff,oneValue.diff_degree,oneValue.full_score];
			//插入具体数据;
			for(var k = 0; k < 8; k++){
				oneValueStr += '<td class="rowbg">'+oneValueArr[k]+'</td>';
			};
			var oneAllStr  = '<tr>'+oneNameStr + oneValueStr+'</tr>';
			//创建二级指标表格数据
			if(oneArrValue[i].items && oneArrValue[i].items != null){
				var two_len = Object.keys(oneArrValue[i].items).length;
				for(var j = 0; j<two_len;j++){
					var twoNameStr = '<td>'+Object.keys(oneArrValue[i].items)[j]+'</td>';
					var twoValueStr = '';
					var twoArrValue = $.map(oneArrValue[i].items , function(value,index){
								return [value];
						})[j].value;
						var twoValueArr = [twoArrValue.cls_average,twoArrValue.cls_average_percent,twoArrValue.class_median_percent,twoArrValue.gra_average_percent,twoArrValue.cls_gra_avg_percent_diff,twoArrValue.cls_med_gra_avg_percent_diff,twoArrValue.diff_degree,twoArrValue.full_score]
					for(var g = 0; g < 8; g++){
						 twoValueStr += '<td>'+ twoValueArr[g] +'</td>';
					};
					twoAllStr  +='<tr>'+twoNameStr + twoValueStr+'</tr>';
				}
			}else{
				return;
			}
			allStr += oneAllStr + twoAllStr;
		}
		return allStr;
	}
	function echartHandle(obj){
		return obj = {
			xaxis:{
				knowledge:getKeys(obj.knowledge_cls_mid_gra_avg_diff_line),
				skill:getKeys(obj.skill_cls_mid_gra_avg_diff_line),
				ability:getKeys(obj.ability_cls_mid_gra_avg_diff_line)
			},
			yaxis:{
				knowledge:{
					all_line:creatAllValue(obj.knowledge_all_lines),
					diff:{
						mid:creatDiffValue(obj.knowledge_cls_mid_gra_avg_diff_line),
						avg:creatDiffValue(obj.knowledge_gra_cls_avg_diff_line)
					}
				},
				skill:{
					all_line:creatAllValue(obj.skill_all_lines),
					diff:{
						mid:creatDiffValue(obj.skill_cls_mid_gra_avg_diff_line),
						avg:creatDiffValue(obj.skill_gra_cls_avg_diff_line)
					}
				},
				ability:{
					all_line:creatAllValue(obj.ability_all_lines),
					diff:{
						mid:creatDiffValue(obj.ability_cls_mid_gra_avg_diff_line),
						avg:creatDiffValue(obj.ability_gra_cls_avg_diff_line)
					}
				}
			}
		}
	}
	function creatDiffValue(obj){
		var arr = getValue(obj);
		var len = arr.length;
		console.log(len);
		var upArr=[];
		var downArr = [];
		for(var i = 0 ; i < len ; i++){
			if(arr[i] >= 0){
				upArr.push({value:arr[i],symbolSize:5});
				downArr.push({value:0,symbolSize:5});
			}else if(arr[i] < 0){
				downArr.push({value:arr[i],symbolSize:5});
				upArr.push({value:0,symbolSize:5});
			};
		};
		return obj = {
					up:upArr,
					down:downArr
				}
	}
	function creatAllValue(obj){
		return obj = {
			class_average_percent:getValue(obj.class_average_percent),
			class_median_percent:getValue(obj.class_median_percent),
			diff_degree:getValue(obj.diff_degree),
			grade_average_percent:getValue(obj.grade_average_percent)
		}
	}
	
	function getKeys(obj){
		return Object.keys(obj);
	}
	function getValue(obj){
		return $.map(obj,function(value,index){
			return [value];
		});
	}
	function splitValue(obj){
		var arrX = Object.keys(obj);
		var arrY = $.map(obj, function(value,index) {
			return [value];
		});
		var len = arrX.length;
		var upArrX = [];
		var downArrX = [];
		var upArrY = [];
		var downArrY = [];
		for(var i=0 ; i<len ; i++){
			if(arrY[i] < 0){
				downArrX.push(arrX[i]);
				downArrY.push(arrY[i]);
			}else{
				upArrX.push(arrX[i]);
				upArrY.push(arrY[i]);
			};
		}
		//链接两个数组;
		var allXvalue = upArrX.concat(downArrX);
		allXvalue.push('');
		allXvalue.unshift('');
		for(var i = 0 ; i <= downArrX.length ; i++){
			upArrY.push({value:0,symbolSize:0});
		}
		for(var i = 0; i <= upArrX.length ; i++){
			downArrY.unshift({value:0,symbolSize:0});
		}
		upArrY.unshift({value:0,symbolSize:0});
		downArrY.push({value:0,symbolSize:0});
		return allLine = {
			allX : allXvalue,
			up : upArrY,
			down : downArrY
		}
		
	}
	
})
