var studentInfor;
var diaStr;
var tableData;
var echartDataObj;
$(function(){
	var ParameterInfo = GetRequest();
	var urlData = {'report_id':ParameterInfo.report_id};
	$.get('/reports/get_pupil_report',urlData,function(data){
		console.log(data);
		if(data.status == 200){
			var dataObj = data.data;
			console.log(dataObj)
			var basicInfor = dataObj.basic;
			/*顶部学生信息*/
			studentInfor = {
				name:basicInfor.name,
				sex:basicInfor.sex,
				className:''+basicInfor.grade+''+basicInfor.classroom+'',
				school:basicInfor.school,
				areaName:basicInfor.area,
				difficulty:basicInfor.difficulty,
				dateStr:basicInfor.quiz_date
			};
			/*诊断及改进建议的数据导入*/
			diaStr = dataObj.quiz_comment;
			//数据表格的导入;
			var knowledgeAllStr = dataInTable(dataObj.data_table.knowledge),
				skillAllStr = dataInTable(dataObj.data_table.skill),
				abilityAllStr = dataInTable(dataObj.data_table.ability);
			tableData = {
				knowledge:knowledgeAllStr,
				skill:skillAllStr,
				ability:abilityAllStr
			}
			console.log(tableData);
			//eChart数据导入
//			echartRadarHandle(dataObj.charts.knowledge_radar.class_average);
//			echartDiffHandle(dataObj.charts.knowledge_pup_gra_avg_diff_line);
			echartDataObj = {
				radar : {
					knowledge:{
						Pupil: echartRadarHandle(dataObj.charts.knowledge_radar.pupil_average),
						Grade: echartRadarHandle(dataObj.charts.knowledge_radar.grade_average)
					},
					skill:{
						Pupil: echartRadarHandle(dataObj.charts.skill_radar.pupil_average),
						Grade: echartRadarHandle(dataObj.charts.skill_radar.grade_average)
					},
					ability:{
						Pupil: echartRadarHandle(dataObj.charts.ability_radar.pupil_average),
					        Grade: echartRadarHandle(dataObj.charts.ability_radar.grade_average)
					}
				},
				diff : {
					knowledge:echartDiffHandle(dataObj.charts.knowledge_pup_gra_avg_diff_line),
					skill:echartDiffHandle(dataObj.charts.skill_pup_gra_avg_diff_line),
					ability:echartDiffHandle(dataObj.charts.ability_pup_gra_avg_diff_line)
				}
			};
			console.log(echartDataObj);
		}else{
			alert('您的网络出现问题！')
		}
	})
})
function echartDiffHandle(obj){
	var arr1 = Object.keys(obj);
	var arr2 = $.map(obj, function(value,index){
					return [value];
				});
	var len = arr1.length;
	var upData = [];
	var downData = [];
	for(var i=0 ; i<len ; i++){
		//正值;
		if(arr2[i] > 0){
			upData.push({value:arr2[i],symbolSize:8});
			downData.push({value:0,symbolSize:0});
		}else if(arr2[i] < 0){
			downData.push({value:arr2[i],symbolSize:8});
			upData.push({value:0,symbolSize:0});
		}else{
			upData.push({value:0,symbolSize:0});
			downData.push({value:0,symbolSize:0});
		}
	}
	arr1.push('');
	arr1.unshift('');
	upData.push({value:0,symbolSize:0});
	upData.unshift({value:0,symbolSize:0});
	downData.push({value:0,symbolSize:0});
	downData.unshift({value:0,symbolSize:0});
	return obj = {
		xaxis : { xAxis : arr1},
		yaxis : { upYAxis : upData , downYAxis : downData}
	}
}
function echartRadarHandle(obj){
	console.log(obj);
	var arr1 = Object.keys(obj);
	//创建坐标名称;
	var dataArr1 = [];
	var dataArr2 = [];
	var len = arr1.length;
	for(var i=0 ; i<len ; i++){
		dataArr1.push({name : arr1[i],max : 100});
		dataArr2.push({name : '' , max : 100});
	}
	//获取具体数据;
	var arr2 = $.map(obj, function(value,index){
					return [value];
				});
	return obj = {
		xaxis : { nullAxis : dataArr2 , xAxis : dataArr1},
		yaxis : { yAxis : arr2}
	}
}

function dataInTable(obj){
		var allStr = '';
		//创建一级指标table --- knowledge;
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
			var oneValueArr = [oneValue.average_percent,oneValue.gra_average_percent,oneValue.pup_gra_avg_percent_diff,oneValue.full_score,oneValue.correct_qzp_count];
			//插入具体数据;
			for(var k = 0; k < 5; k++){
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
						var twoValueArr = [twoArrValue.average_percent,twoArrValue.gra_average_percent,twoArrValue.pup_gra_avg_percent_diff,twoArrValue.full_score,twoArrValue.correct_qzp_count];
					for(var g = 0; g < 5; g++){
						 twoValueStr += '<td>'+ twoValueArr[g] +'</td>';
					};
					twoAllStr  +='<tr>'+twoNameStr + twoValueStr+'</tr>';
				}
			}else{
				return;
			}
			allStr += oneAllStr + twoAllStr;
		}
		console.log(allStr);
		return allStr;
	}
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
