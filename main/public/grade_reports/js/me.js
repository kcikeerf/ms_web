var diagnoseEchart;
var gradeNumScale;
var FourSections;
var checkpointHorizon;
var classPupilNum;
var checkpointStr;
var classPupilNumStr;
var answerCase;
$(function() {
	var ParameterInfo = GetRequest();
	console.log(ParameterInfo);
	var urlData = {
		'report_id': ParameterInfo.report_id
	};
	$.get('/reports/get_grade_report', urlData, function(data){
		//诊断图
		diagnoseEchart = diagnoseEchartHandle(data.data.charts);
		//年级各分段人数比例
		gradeNumScale = gradeNumScaleHandle(data.data.each_level_number);
		//四分位区间表现
		FourSections = getFourSections(data.data.four_sections);
		//各指标表现水平图
		checkpointHorizon = getCheckpointHorizon(data.data.each_checkpoint_horizon);
		//各班人数比例;
		classPupilNum = getClassPupilNum(data.data.each_class_pupil_number_chart);
		//各班表现情况;
		checkpointStr = getCheckpointStr(data.data.each_checkpoint_horizon);
		//各班人数比例情况;
		classPupilNumStr = getPupilNumStr(data.data.each_class_pupil_number_chart);
		//学生答题情况统计;
		answerCase = getAnswerCase(data.data.average_percent);
		//报告解读
		readReport = data.data.report_explanation;
	})

});

function getAnswerCase(obj){
	return obj = {
		excellent : handleAnswerCaseStr(obj.excellent),
		good : handleAnswerCaseStr(obj.excellent),
		failed : handleAnswerCaseStr(obj.failed)
	}
};
function handleAnswerCaseStr(obj){
	if(obj != null){
		var qid = getKeys(obj);
		var correctRatio = getValue(obj);
		var str = '';
		for(var i = 0; i < qid.length ; i++){
			str += '<tr><td>'+qid[i]+'</td><td>'+correctRatio[i]+'</td></tr>';
		};
		return str;
	}else{
		return '';
	};
}
function getPupilNumStr(obj){
	return str = {
		knowledge:handlePupilNumStr(obj.knowledge),
		skill:handlePupilNumStr(obj.skill),
		ability:handlePupilNumStr(obj.ability)
	}
}
function handlePupilNumStr(obj){
	return str = {
		excellent_pupil_percent:handleNormStr(obj.excellent_pupil_percent),
		good_pupil_percent:handleNormStr(obj.good_pupil_percent),
		failed_pupil_percent:handleNormStr(obj.failed_pupil_percent)
	}
}
function getCheckpointStr(obj){
	return str = {
		knowledge:handleCheckpointStr(obj.knowledge),
		skill:handleCheckpointStr(obj.skill),
		ability:handleCheckpointStr(obj.ability)
	}
}
function handleCheckpointStr(obj){
	return str = {
		average_percent:handleNormStr(obj.average_percent),
		diff_degree:handleNormStr(obj.diff_degree),
		med_avg_diff:handleNormStr(obj.med_avg_diff),
		median_percent:handleNormStr(obj.median_percent)
	}
};
function handleNormStr(obj){
	var classNum = getKeys(obj).length;
	var classValue = getValue(obj);
	var normArr = getKeys(getValue(obj)[0]);
	var thStr = '<td>班级</td>';
	for(var i = 0 ; i < normArr.length ; i++){
		thStr += '<td>'+normArr[i]+'</td>';
	}
	var allStr = '';
	for(var i = 0 ; i < classNum ; i++){
		var str = '';
		for(var k = 0 ; k < normArr.length ; k++){
			str += '<td>'+getValue(getValue(obj)[i])[k]+'</td>';
		}
		if(classValue[i] == '年级'){
			str = '<td>年级</td>'+ str ;
		}else{
			str = '<td>'+(i+1)+'</td>'+ str ;
		}
		allStr += '<tr>'+str+'</tr>';
	}
	return allStr = '<tr>'+thStr+'</tr>' + allStr;
}
function getClassPupilNum(obj){
	return obj = {
		knowledge:handleClassPupilNum(obj.knowledge),
		skill:handleClassPupilNum(obj.skill),
		ability:handleClassPupilNum(obj.ability)
	}
}
function handleClassPupilNum(obj){
	var normkeyArr = getKeys(getValue(obj.good_pupil_percent)[0]);
	var classNameArr = getKeys(obj.good_pupil_percent);
	var normNum = normkeyArr.length;
	var colorArr = [] ;
	var normNameArr = [];
	for(var i = 0 ; i < normNum; i++){
		colorArr.push(getRandomColor());
		normNameArr.push({name:normkeyArr[i],icon:'rect'});
	};
	return obj = {
		xAxis:classNameArr,
		colorArr:colorArr,
		normNameArr:normNameArr,
		excellent_pupil_percent:handleNorm(obj.excellent_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
		good_pupil_percent:handleNorm(obj.good_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
		failed_pupil_percent:handleNorm(obj.failed_pupil_percent,colorArr,normkeyArr,normNum,classNameArr)
	};
}
function getCheckpointHorizon(obj){
	return obj = {
		knowledge:handleCheckpointData(obj.knowledge),
		skill:handleCheckpointData(obj.skill),
		ability:handleCheckpointData(obj.ability),
		total:handleCheckpointData(obj.total)
	}
}

function handleCheckpointData(obj){
	var normkeyArr = getKeys(getValue(obj.average_percent)[0]);
	//班级数组
	var classNameArr = getKeys(obj.average_percent);
	var normNum = normkeyArr.length;
	var colorArr = [] ;
	var normNameArr = [];
	for(var i = 0 ; i < normNum; i++){
		colorArr.push(getRandomColor());
		normNameArr.push({name:normkeyArr[i],icon:'rect'});
	};
	return obj = {
		xAxis:classNameArr,
		colorArr:colorArr,
		normNameArr:normNameArr,
		average_percent:handleNorm(obj.average_percent,colorArr,normkeyArr,normNum,classNameArr),
		diff_degree:handleNorm(obj.diff_degree,colorArr,normkeyArr,normNum,classNameArr),
		med_avg_diff:handleNorm(obj.med_avg_diff,colorArr,normkeyArr,normNum,classNameArr),
		median_percent:handleNorm(obj.median_percent,colorArr,normkeyArr,normNum,classNameArr)
	};
}
function handleNorm(obj,colorArr,normkeyArr,normNum,classNameArr){
	var classValue = getValue(obj);
	var classNum = classNameArr.length;
	var allArr = [];
	var series = [];
	for(var i = 0 ; i < normNum ; i++){
		var arr = [];
		for(var k = 0 ; k < classNum ; k++){
			arr.push(getValue(classValue[k])[i]);
		};
		allArr.push(arr);
	};
	for(var j = 0 ; j < normNum ; j++){
		series.push({
			name:normkeyArr[j],
            type:'line',
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
}
//获取随机颜色值
function getRandomColor(){ 
	return "#"+("00000"+((Math.random()*16777215+0.5)>>0).toString(16)).slice(-6); 
};

function getFourSections(obj){
	return obj = {
		xAxis:{
			knowledge:getKeys(obj.level0.knowledge),
			skill:getKeys(obj.level0.skill),
			ability:getKeys(obj.level0.ability)
		},
		le0:{
			knowledge:getValue(obj.level0.knowledge),
			skill:getValue(obj.level0.skill),
			ability:getValue(obj.level0.ability)
		},
		le25:{
			knowledge:getValue(obj.level0.knowledge),
			skill:getValue(obj.level0.skill),
			ability:getValue(obj.level0.ability)
		},
		le50:{
			knowledge:getValue(obj.level0.knowledge),
			skill:getValue(obj.level0.skill),
			ability:getValue(obj.level0.ability)
		},
		le75:{
			knowledge:getValue(obj.level0.knowledge),
			skill:getValue(obj.level0.skill),
			ability:getValue(obj.level0.ability)
		}
	}
}

function gradeNumScaleHandle(obj) {
	return obj = {
		yAxis:{
			knowledge:getKeys(obj.grade_knowledge),
			skill:getKeys(obj.grade_skill),
			ability:getKeys(obj.grade_ability)
		},
		data:{
			knowledge:creatGradeScaleArr(getValue(obj.grade_knowledge)),
			skill:creatGradeScaleArr(getValue(obj.grade_skill)),
			ability:creatGradeScaleArr(getValue(obj.grade_ability))
		}
	}
}
function creatGradeScaleArr(obj){
	var goodArr = [],
	    faildArr = [],
	    excellentArr = [];
	for(var i = 0 ; i < obj.length ; i++){
		excellentArr.push({
            name:'(得分率 ≥ 85)',
            value:obj[i].excellent_pupil_percent,
            yAxisIndex:i,
            itemStyle: {
              normal: {
                barBorderRadius:[20, 0, 0, 20],
                color: new echarts.graphic.LinearGradient(1, 0, 0, 0, [{
                  offset: 0,
                  color: '#086a8e'
                }, {
                  offset: 1,
                  color: '#65026b'
                }])
              }
            },
          });
		goodArr.push({
            name:'( 60 ≤ 得分率 < 85)',
            value:obj[i].good_pupil_percent,
            yAxisIndex:i,
            itemStyle: {
                normal: {
                    barBorderRadius:0,
                    color: new echarts.graphic.LinearGradient(1, 0, 0, 0, [{
                      offset: 0,
                      color: '#71ecd0'
                    }, {
                      offset: 1,
                      color: '#13ab9b'
                    }])
                  }
                },
          });
		faildArr.push({
                        name:'(得分率 < 60)',
                        value:obj[i].failed_pupil_percent,
                        itemStyle: {
                          normal: {
                            barBorderRadius: [0, 20, 20, 0],
                            color: new echarts.graphic.LinearGradient(1, 0, 0, 0, [{
                              offset: 0,
                              color: '#fa8471'
                            }, {
                              offset: 1,
                              color: '#f6f1c5'
                            }])
                          }
                        },
                      });
	}
	return obj  = {
		excellent:excellentArr,
		good:goodArr,
		failed:faildArr
	}
}
function diagnoseEchartHandle(obj) {
	return obj = {
		xaxis: {
			knowledge: pushArr(getKeys(obj.knowledge_med_avg_diff)),
			skill: pushArr(getKeys(obj.skill_med_avg_diff)),
			ability: pushArr(getKeys(obj.ability_med_avg_diff))
		},
		yaxis: {
			knowledge: {
				knowledge_3lines: {
					grade_average_percent: pushArr(getValue(obj.knowledge_3lines.grade_average_percent)),
					grade_diff_degree: pushArr(getValue(obj.knowledge_3lines.grade_diff_degree)),
					grade_median_percent: pushArr(getValue(obj.knowledge_3lines.grade_median_percent))
				},
				knowledge_med_avg_diff: creatDiffValue(obj.knowledge_med_avg_diff)
			},
			skill: {
				skill_3lines: {
					grade_average_percent: pushArr(getValue(obj.skill_3lines.grade_average_percent)),
					grade_diff_degree: pushArr(getValue(obj.skill_3lines.grade_diff_degree)),
					grade_median_percent: pushArr(getValue(obj.skill_3lines.grade_median_percent))
				},
				skill_med_avg_diff: creatDiffValue(obj.skill_med_avg_diff)
			},
			ability: {
				ability_3lines: {
					grade_average_percent: pushArr(getValue(obj.ability_3lines.grade_average_percent)),
					grade_diff_degree: pushArr(getValue(obj.ability_3lines.grade_diff_degree)),
					grade_median_percent: pushArr(getValue(obj.ability_3lines.grade_median_percent))
				},
				ability_med_avg_diff: creatDiffValue(obj.ability_med_avg_diff)
			}
		}
	}
}

function creatDiffValue(obj) {
	var arr = getValue(obj);
	var len = arr.length;
	var upArr = [];
	var downArr = [];
	for (var i = 0; i < len; i++) {
		if (arr[i] >= 0) {
			upArr.push({
				value: arr[i],
				symbolSize: 0
			});
			downArr.push({
				value: 0,
				symbolSize: 0
			});
		} else if (arr[i] < 0) {
			downArr.push({
				value: arr[i],
				symbolSize: 0
			});
			upArr.push({
				value: 0,
				symbolSize: 0
			});
		};
	};
	pushArr(upArr);
	pushArr(downArr);
	return obj = {
		up: upArr,
		down: downArr
	}
}

function pushArr(obj) {
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
}

function getKeys(obj) {
	if(obj == null){
		return [];
	}else{
		return Object.keys(obj);
	}
	
}

function getValue(obj) {
	if(obj == null){
		return [];
	}else{
		return $.map(obj, function(value, index) {
				return [value];
		});
	}
	
}

function GetRequest() {
	var url = location.search; //获取url中"?"符后的字串   
	var theRequest = new Object();
	if (url.indexOf("?") != -1) {
		var str = url.substr(1);
		strs = str.split("&");
		for (var i = 0; i < strs.length; i++) {
			theRequest[strs[i].split("=")[0]] = unescape(strs[i].split("=")[1]);
		}
	}
	return theRequest;
}
