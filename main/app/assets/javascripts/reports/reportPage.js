var reportPage = {
	getGradeUrl: '/reports/get_grade_report',
	getClassUrl: '/reports/get_class_report',
	getPupilUrl: '/reports/get_pupil_report',
	Gradedata: null,
	ClassData: null,
	PupilData: null,
	init: function(){
		//给左上角导航添加事件
		reportPage.bindEvent();
		$('#reportContent').load('/reports/grade',function(){
			$.get(reportPage.getGradeUrl, 'report_id=577b287827f0a50811c7e8ca', function(data) {
				if (data.status == '200'){
					reportPage.Grade.createReport(data);
				} else {
					alert('网络出现错误');
				};
			});
		});
		$('#report_menus .report_click_menu').on('click', function() {
			var dataType = $(this).attr('data_type');
			var reportId = $(this).attr('report_id');
			var params = "report_id=" + reportId;
			if(dataType == 'grade'){
				$('#reportContent').load('/reports/grade',function(){
					$.get(reportPage.getGradeUrl, params, function(data) {
						if (data.status == '200'){
							reportPage.Grade.createReport(data);
							
						} else {
							alert('网络出现错误');
						};
					});
				});
			}else if (dataType == 'klass') {
				$('#reportContent').load('/reports/klass',function(){
					$.get(reportPage.getClassUrl, params, function(data) {
						if (data.status == '200'){
							reportPage.Class.createReport(data);
						} else {
							alert('网络出现错误');
						};
					});
				});
				
			}else if (dataType == 'pupil') {
				$('#reportContent').load('/reports/pupil',function(){
					$.get(reportPage.getPupilUrl, params, function(data) {
						if (data.status == '200'){
							reportPage.Pupil.createReport(data);
						} else {
							alert('网络出现错误');
						};
					});
				});
			};
		});
	},
	/*处理年级数据*/
	Grade: {
		createReport : function(data){
			//设置年级表头；
			var basicData = data.data.basic;
			var gradeNavStr = '学校名称：<span>'+basicData.school+'</span>&nbsp;&nbsp;年级：<span>'+basicData.grade+'</span>&nbsp;&nbsp;'
						 +'班级数量：<span>'+basicData.klass_count+'</span>&nbsp;&nbsp;年级人数：<span>'+basicData.levelword2+'</span>&nbsp;&nbsp;'
						 +'难度：<span>'+basicData.levelword2+'</span>&nbsp;&nbsp;测试类型：<span>'+basicData.quiz_type+'</span>&nbsp;&nbsp;'
						 +'测试日期：<span>'+basicData.quiz_date+'</span>';
			$('#grade-top-nav').html(gradeNavStr);
			//创建年级的第一个诊断图;
			var grade_charts = reportPage.Grade.getGradeDiagnoseData(data.data.charts);
			var objArr = [grade_charts.knowledge,grade_charts.skill,grade_charts.ability];
			var nodeArrLeft = ['knowledge_diagnose_left','skill_diagnose_left','ability_diagnose_left'];
			var nodeArrRight = ['knowledge_diagnose_right','skill_diagnose_right','ability_diagnose_right'];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionLeft = echartOption.getOption.Grade.setGradeDiagnoseLeft(objArr[i]);
				var optionRight = echartOption.getOption.Grade.setGradeDiagnoseRight(objArr[i]);
				echartOption.createEchart(optionLeft,nodeArrLeft[i]);
				echartOption.createEchart(optionRight,nodeArrRight[i]);
			}
			$('#tab-menu li[data-id]').on('click', function (e) {
				var $dataId = $(e.target).attr('data-id');
				if($dataId == 'grade-NumScale'){
					//创建人数比例图
					var NumScaleObj = reportPage.Grade.getGradeNumScaleData(data.data.each_level_number);
					var objArr = [NumScaleObj.knowledge,NumScaleObj.skill,NumScaleObj.ability];
					var nodeArr = ['KnowledgeScale','SkillScale','AbilityScale'];
					for(var i = 0 ; i < objArr.length ; i++){
						var option = echartOption.getOption.Grade.setGradeScaleOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					}
				}else if($dataId == 'grade-FourSections'){
					var FourSections = reportPage.Grade.getFourSectionsData(data.data.four_sections);
					var objArr = [FourSections.knowledge.le75,FourSections.skill.le75,FourSections.ability.le75,FourSections.knowledge.le50,FourSections.skill.le50,FourSections.ability.le50,FourSections.knowledge.le25,FourSections.skill.le25,FourSections.ability.le25,FourSections.knowledge.le0,FourSections.skill.le0,FourSections.ability.le0,];
					var nodeArr = ['knowledge_Four_L75','skill_Four_L75','ability_Four_L75','knowledge_Four_L50','skill_Four_L50','ability_Four_L50','knowledge_Four_L25','skill_Four_L25','ability_Four_L25','knowledge_Four_L0','skill_Four_L0','ability_Four_L0'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setFourSectionsOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-checkpoint-knowledge'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.knowledge.average_percent,Checkpoints.knowledge.median_percent,Checkpoints.knowledge.med_avg_diff,Checkpoints.knowledge.diff_degree];
					var nodeArr = ['knowledge_Grade_average_percent','knowledge_Grade_median_percent','knowledge_Grade_med_avg_diff','knowledge_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					}
				}else if($dataId == 'grade-checkpoint-skill'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.skill.average_percent,Checkpoints.skill.median_percent,Checkpoints.skill.med_avg_diff,Checkpoints.skill.diff_degree];
					var nodeArr = ['skill_Grade_average_percent','skill_Grade_median_percent','skill_Grade_med_avg_diff','skill_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-checkpoint-ability'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.ability.average_percent,Checkpoints.ability.median_percent,Checkpoints.ability.med_avg_diff,Checkpoints.ability.diff_degree];
					var nodeArr = ['ability_Grade_average_percent','ability_Grade_median_percent','ability_Grade_med_avg_diff','ability_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-checkpoint-total'){
					var Checkpoints = reportPage.Grade.getCheckpointData(data.data.each_checkpoint_horizon);
					var objArr = [Checkpoints.total.average_percent,Checkpoints.total.median_percent,Checkpoints.total.med_avg_diff,Checkpoints.total.diff_degree];
					var nodeArr = ['total_Grade_average_percent','total_Grade_median_percent','total_Grade_med_avg_diff','total_Grade_diff_degree'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-classPupilNum-knowledge'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.knowledge.excellent_pupil_percent,ClassPupilNum.knowledge.good_pupil_percent,ClassPupilNum.knowledge.failed_pupil_percent];
					var nodeArr = ['knowledge_excellent','knowledge_good','knowledge_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-classPupilNum-skill'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.skill.excellent_pupil_percent,ClassPupilNum.skill.good_pupil_percent,ClassPupilNum.skill.failed_pupil_percent];
					var nodeArr = ['skill_excellent','skill_good','skill_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-classPupilNum-ability'){
					var ClassPupilNum = reportPage.Grade.getClassPupilNumData(data.data.each_class_pupil_number_chart);
					var objArr = [ClassPupilNum.ability.excellent_pupil_percent,ClassPupilNum.ability.good_pupil_percent,ClassPupilNum.ability.failed_pupil_percent];
					var nodeArr = ['ability_excellent','ability_good','ability_faild'];
					for(var i = 0 ; i < nodeArr.length ; i++){
						var option = echartOption.getOption.Grade.setCheckpointOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'grade-checkpoint-table-knowledge'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.average_percent);
					$('#knowledge_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.median_percent);
					$('#knowledge_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.med_avg_diff);
					$('#knowledge_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.knowledge.diff_degree);
					$('#knowledge_diff_degree').html(diff_table);
				}else if($dataId == 'grade-checkpoint-table-skill'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.average_percent);
					$('#skill_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.median_percent);
					$('#skill_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.med_avg_diff);
					$('#skill_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.skill.diff_degree);
					$('#skill_diff_degree').html(diff_table);
				}else if($dataId == 'grade-checkpoint-table-ability'){
					var avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.average_percent);
					$('#ability_average_percent').html(avg_table);
					var med_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.median_percent);
					$('#ability_median_percent').html(med_table);
					var med_avg_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.med_avg_diff);
					$('#ability_med_avg_diff').html(med_avg_table);
					var diff_table = reportPage.Grade.handleNormTable(data.data.each_checkpoint_horizon.ability.diff_degree);
					$('#ability_diff_degree').html(diff_table);
				}else if($dataId == 'grade-classPupilNum-table-knowledge'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.excellent_pupil_percent);
					$('#knowledge_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.good_pupil_percent);
					$('#knowledge_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.knowledge.failed_pupil_percent);
					$('#knowledge_failed_table').html(faild_table);
				}else if($dataId == 'grade-classPupilNum-table-skill'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.excellent_pupil_percent);
					$('#skill_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.good_pupil_percent);
					$('#skill_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.skill.failed_pupil_percent);
					$('#skill_failed_table').html(faild_table);
				}else if($dataId == 'grade-classPupilNum-table-ability'){
					var excellent_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.excellent_pupil_percent);
					$('#ability_excellent_table').html(excellent_table);
					var good_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.good_pupil_percent);
					$('#ability_good_table').html(good_table);
					var faild_table = reportPage.Grade.handleNormTable(data.data.each_class_pupil_number_chart.ability.failed_pupil_percent);
					$('#ability_failed_table').html(faild_table);
				}else if($dataId == 'grade-answerCase'){
					var excellent_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.excellent);
					$('#excellent_answerCase_table').html(excellent_table);
					var good_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.good);
					$('#good_answerCase_table').html(good_table);
					var faild_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.failed);
					$('#failed_answerCase_table').html(faild_table);
				}else if($dataId == 'grade-readReport-three'){
					$('#grade-readReport-three').html(data.data.report_explanation.three_dimesions);
				}else if($dataId == 'grade-readReport-statistics'){
					$('#grade-readReport-statistics').html(data.data.report_explanation.statistics);
				}else if($dataId == 'grade-readReport-data'){
					$('#grade-readReport-data').html(data.data.report_explanation.data);
				}
			});
		},
		
		handleNormTable : function(data){
			var classNum = reportPage.baseFn.getKeys(data).length;
			var classValue = reportPage.baseFn.getValue(data);
			var normArr = reportPage.baseFn.getKeys(reportPage.baseFn.getValue(data)[0]);
			var thStr = '<td class="grade-titlt">班级</td>';
			for(var i = 0 ; i < normArr.length ; i++){
				thStr += '<td>'+normArr[i]+'</td>';
			}
			var allStr = '';
			for(var i = 0 ; i < classNum ; i++){
				var str = '';
				for(var k = 0 ; k < normArr.length ; k++){
					str += '<td>'+reportPage.baseFn.getValue(reportPage.baseFn.getValue(data)[i])[k]+'</td>';
				}
				if(classValue[i] == '年级'){
					str = '<td>年级</td>'+ str ;
				}else{
					str = '<td>'+(i+1)+'</td>'+ str ;
				}
				allStr += '<tr>'+str+'</tr>';
			}
			return allStr = '<tr>'+thStr+'</tr>' + allStr;
		},
		/*获取诊断图的数据*/
		getGradeDiagnoseData : function(obj){
			return obj = {
				knowledge : {
					xaxis : reportPage.baseFn.pushArr(reportPage.baseFn.getKeys(obj.knowledge_med_avg_diff)),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.knowledge_3lines.grade_average_percent)),
							grade_diff_degree: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.knowledge_3lines.grade_diff_degree)),
							grade_median_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.knowledge_3lines.grade_median_percent))
						},
						med_avg_diff : reportPage.baseFn.getDiff(obj.knowledge_med_avg_diff)
					}
				},
				skill : {
					xaxis : reportPage.baseFn.pushArr(reportPage.baseFn.getKeys(obj.skill_med_avg_diff)),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.skill_3lines.grade_average_percent)),
							grade_diff_degree: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.skill_3lines.grade_diff_degree)),
							grade_median_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.skill_3lines.grade_median_percent))
						},
						med_avg_diff : reportPage.baseFn.getDiff(obj.skill_med_avg_diff)
					}
				},
				ability : {
					xaxis : reportPage.baseFn.pushArr(reportPage.baseFn.getKeys(obj.ability_med_avg_diff)),
					yaxis : {
						Alllines : {
							grade_average_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.ability_3lines.grade_average_percent)),
							grade_diff_degree: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.ability_3lines.grade_diff_degree)),
							grade_median_percent: reportPage.baseFn.pushArr(reportPage.baseFn.getValue(obj.ability_3lines.grade_median_percent))
						},
						med_avg_diff : reportPage.baseFn.getDiff(obj.ability_med_avg_diff)
					}
				}
			}
		},
		getGradeNumScaleData : function(obj){
			return obj = {
				knowledge :{
					yaxis : reportPage.baseFn.getKeys(obj.grade_knowledge),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(obj.grade_knowledge))
				},
				skill : {
					yaxis : reportPage.baseFn.getKeys(obj.grade_skill),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(obj.grade_skill))
				},
				ability : {
					yaxis : reportPage.baseFn.getKeys(obj.grade_ability),
					data : reportPage.Grade.creatGradeScaleArr(reportPage.baseFn.getValue(obj.grade_ability))
				},
			}
		},
		getFourSectionsData : function(obj){
			return arr = {
				knowledge : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(obj.level0.knowledge),
						yaxis : reportPage.baseFn.getValue(obj.level0.knowledge),
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(obj.level25.knowledge),
						yaxis : reportPage.baseFn.getValue(obj.level25.knowledge),
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(obj.level50.knowledge),
						yaxis : reportPage.baseFn.getValue(obj.level50.knowledge),
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(obj.level75.knowledge),
						yaxis : reportPage.baseFn.getValue(obj.level75.knowledge),
					}
				},
				skill : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(obj.level0.skill),
						yaxis : reportPage.baseFn.getValue(obj.level0.skill),
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(obj.level25.skill),
						yaxis : reportPage.baseFn.getValue(obj.level25.skill),
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(obj.level50.skill),
						yaxis : reportPage.baseFn.getValue(obj.level50.skill),
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(obj.level75.skill),
						yaxis : reportPage.baseFn.getValue(obj.level75.skill),
					}
				},
				ability : {
					le0 : {
						xaxis : reportPage.baseFn.getKeys(obj.level0.ability),
						yaxis : reportPage.baseFn.getValue(obj.level0.ability),
					},
					le25 : {
						xaxis : reportPage.baseFn.getKeys(obj.level25.ability),
						yaxis : reportPage.baseFn.getValue(obj.level25.ability),
					},
					le50 : {
						xaxis : reportPage.baseFn.getKeys(obj.level50.ability),
						yaxis : reportPage.baseFn.getValue(obj.level50.ability),
					},
					le75 : {
						xaxis : reportPage.baseFn.getKeys(obj.level75.ability),
						yaxis : reportPage.baseFn.getValue(obj.level75.ability),
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
		creatGradeScaleArr : function(obj){
			var goodArr = [],faildArr = [],excellentArr = [];
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
		},
		handleClassPupilNum : function(obj){
			var normkeyArr = reportPage.baseFn.getKeys(reportPage.baseFn.getValue(obj.good_pupil_percent)[0]);
			var classNameArr = reportPage.baseFn.getKeys(obj.good_pupil_percent);
			var normNum = normkeyArr.length;
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < normNum; i++){
				colorArr.push(reportPage.baseFn.getRandomColor());
				normNameArr.push({name:normkeyArr[i],icon:'rect'});
			};
			return obj = {
				excellent_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleNorm(obj.excellent_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				},
				good_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleNorm(obj.good_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				},
				failed_pupil_percent : {
					xaxis : classNameArr,
					colorArr:colorArr,
					normNameArr:normNameArr,
					series : reportPage.Grade.handleNorm(obj.failed_pupil_percent,colorArr,normkeyArr,normNum,classNameArr),
				}
			};
		},
		handleCheckpoint : function(obj){
			var normkeyArr = reportPage.baseFn.getKeys(reportPage.baseFn.getValue(obj.average_percent)[0]);
			var classNameArr = reportPage.baseFn.getKeys(obj.average_percent);
			var normNum = normkeyArr.length;
			var colorArr = [] ;
			var normNameArr = [];
			for(var i = 0 ; i < normNum; i++){
				colorArr.push(reportPage.baseFn.getRandomColor());
				normNameArr.push({name:normkeyArr[i],icon:'rect'});
			};
			return obj = {
				average_percent : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleNorm(obj.average_percent,colorArr,normkeyArr,normNum,classNameArr)
				},
				diff_degree : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleNorm(obj.diff_degree,colorArr,normkeyArr,normNum,classNameArr)
				},
				med_avg_diff : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleNorm(obj.med_avg_diff,colorArr,normkeyArr,normNum,classNameArr)
				},
				median_percent : {
					xaxis : classNameArr,
					colorArr : colorArr,
					normNameArr : normNameArr,
					series : reportPage.Grade.handleNorm(obj.median_percent,colorArr,normkeyArr,normNum,classNameArr)
				},
			};
		},
		handleNorm : function(obj,colorArr,normkeyArr,normNum,classNameArr){
			var classValue = reportPage.baseFn.getValue(obj);
			var classNum = classNameArr.length;
			var allArr = [];
			var series = [];
			for(var i = 0 ; i < normNum ; i++){
				var arr = [];
				for(var k = 0 ; k < classNum ; k++){
					arr.push(reportPage.baseFn.getValue(classValue[k])[i]);
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
		},
	},
	/*处理班级数据*/
	Class: {
		createReport : function(data){
			var basicData = data.data.basic;
			var classNavStr = '学校名称：<span>'+basicData.school+'</span>&nbsp;&nbsp;班级：<span>'+basicData.classroom+'</span>&nbsp;&nbsp;'
						 +'班级人数：<span>'+basicData.levelword2+'</span>&nbsp;&nbsp;测试类型：<span>'+basicData.quiz_type+'</span>&nbsp;&nbsp;'
						 +'班级主任：<span>'+basicData.head_teacher+'</span>&nbsp;&nbsp;科目老师：<span>'+basicData.subject_teacher+'</span>&nbsp;&nbsp;'
						 +'测试日期：<span>'+basicData.quiz_date+'</span>';
			$('#class-top-nav').html(classNavStr);
			var DiagnoseObj = reportPage.Class.getClassDiagnoseData(data.data.charts);
			var objArr = [DiagnoseObj.knowledge,DiagnoseObj.skill,DiagnoseObj.ability];
			var nodeArrLeft = ['knowledge_diagnose_left','skill_diagnose_left','ability_diagnose_left'];
			var nodeArrCenter = ['knowledge_diagnose_center','skill_diagnose_center','ability_diagnose_center'];
			var nodeArrRight = ['knowledge_diagnose_right','skill_diagnose_right','ability_diagnose_right'];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionLeft = echartOption.getOption.Class.setClassDiagnoseLeft(objArr[i]);
				var optionCenter = echartOption.getOption.Class.setClassDiagnoseCenter(objArr[i]);
				var optionRight = echartOption.getOption.Class.setClassDiagnoseRight(objArr[i]);
				echartOption.createEchart(optionLeft,nodeArrLeft[i]);
				echartOption.createEchart(optionCenter,nodeArrCenter[i]);
				echartOption.createEchart(optionRight,nodeArrRight[i]);
			};
			$('#tab-menu li[data-id]').on('click', function (e) {
				var $dataId = $(e.target).attr('data-id');
				if($dataId == 'class-NumScale'){
					var classScaleObj = reportPage.Class.getClassScaleNumData(data.data.each_level_number);
					var objArr = [classScaleObj.dimesions,classScaleObj.class_knowledge,classScaleObj.class_skill,classScaleObj.class_ability];
					var nodeArr = ['scale_dimesions','scale_knowledge','scale_skill','scale_ability'];
					for(var i = 0 ; i　< objArr.length ; i++){
						var option = echartOption.getOption.Class.setClassScaleNumOption(objArr[i]);
						echartOption.createEchart(option,nodeArr[i]);
					};
				}else if($dataId == 'table-data-knowledge'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.knowledge,'class');
					$('#Class_knowledge_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.skill,'class');
					$('#Class_skill_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.ability,'class');
					$('#Class_ability_table').html(tableStr);
				}else if($dataId == 'class-answerCase'){
					var excellent_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.excellent);
					var good_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.good);
					var failed_table = reportPage.baseFn.getAnswerCaseTable(data.data.average_percent.failed);
					$('#class_answer_excellent').html(excellent_table);
					$('#class_answer_good').html(good_table);
					$('#class_answer_failed').html(failed_table);
				}else if($dataId == 'report-read-three'){
					$('#report-read-three').html(data.data.report_explanation.three_dimesions);
				}else if($dataId == 'report-read-checkpoint'){
					$('#report-read-checkpoint').html(data.data.report_explanation.statistics);
				}else if($dataId == 'report-read-data'){
					$('#report-read-data').html(data.data.report_explanation.data);
				}else if($dataId == 'exam-knowledge'){
					$('#exam-knowledge').html(data.data.quiz_comment.knowledge);
				}else if($dataId == 'exam-skill'){
					$('#exam-skill').html(data.data.quiz_comment.skill);
				}else if($dataId == 'exam-ability'){
					$('#exam-ability').html(data.data.quiz_comment.ability);
				}else if($dataId == 'exam-total'){
					$('#exam-total').html(data.data.quiz_comment.total);
				}
			});
		},
		getClassDiagnoseData : function(obj){
			return obj = {
				knowledge : {
					xaxis : reportPage.baseFn.getKeys(obj.knowledge_cls_mid_gra_avg_diff_line),
					yaxis : {
						all_line : reportPage.Class.getClassDiagnoseAllLine(obj.knowledge_all_lines),
						diff : {
							mid:reportPage.baseFn.getDiff(obj.knowledge_cls_mid_gra_avg_diff_line),
							avg:reportPage.baseFn.getDiff(obj.knowledge_gra_cls_avg_diff_line)
						}
					}
				},
				skill : {
					xaxis : reportPage.baseFn.getKeys(obj.skill_cls_mid_gra_avg_diff_line),
					yaxis : {
						all_line : reportPage.Class.getClassDiagnoseAllLine(obj.skill_all_lines),
						diff : {
							mid:reportPage.baseFn.getDiff(obj.skill_cls_mid_gra_avg_diff_line),
							avg:reportPage.baseFn.getDiff(obj.skill_gra_cls_avg_diff_line)
						}
					}
				},
				ability : {
					xaxis : reportPage.baseFn.getKeys(obj.ability_cls_mid_gra_avg_diff_line),
					yaxis : {
						all_line : reportPage.Class.getClassDiagnoseAllLine(obj.ability_all_lines),
						diff : {
							mid:reportPage.baseFn.getDiff(obj.ability_cls_mid_gra_avg_diff_line),
							avg:reportPage.baseFn.getDiff(obj.ability_gra_cls_avg_diff_line)
						}
					}
				}
			};
		},
		getClassDiagnoseAllLine : function(data){
			return obj = {
				class_average_percent:reportPage.baseFn.getValue(data.class_average_percent),
				class_median_percent:reportPage.baseFn.getValue(data.class_median_percent),
				diff_degree:reportPage.baseFn.getValue(data.diff_degree),
				grade_average_percent:reportPage.baseFn.getValue(data.grade_average_percent)
			}
		},
		getClassScaleNumData : function(data){
			return obj = {
				dimesions : reportPage.Class.getClassScaleGradeData(data.class_three_dimesions,['能力-班级','技能-班级','知识-班级']),
				class_knowledge : reportPage.Class.getClassScaleGradeData(data.class_grade_knowledge,['知识-年级','知识-班级']),
				class_skill :reportPage.Class.getClassScaleGradeData(data.class_grade_skill,['技能-年级','技能-班级']),
				class_ability :reportPage.Class.getClassScaleGradeData(data.class_grade_ability,['能力-年级','能力-班级'])
			};
		},
		getClassScaleGradeData : function(data,yaxis){
			return obj = {
				yaxis : yaxis ,
				data : reportPage.Class.handleClassScaleData(data),
			};
		},
		handleClassScaleData : function(data){
			var keys = reportPage.baseFn.getKeys(data);
			var values = reportPage.baseFn.getValue(data);
			var excellent = [], good = [],faild = [];
			for(var i = 0 ; i < keys.length ; i++){
				excellent.push({
					name:''+keys[i]+'(得分率 ≥ 85)',
                    value: values[i].excellent_pupil_percent,
                    yAxisIndex:1,
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
				good.push({
                    name:''+keys[i]+'(60 ≤ 得分率 < 85)',
                    value: values[i].good_pupil_percent,
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
				faild.push({
                    name:''+keys[i]+'(得分率 < 60)',
                    value:values[i].failed_pupil_percent,
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
			};
			return obj = {
				excenllent : excellent ,
				good : good ,
				faild :faild,
			};
		},
		/*针对班级的字段*/
		creatClassValueArr: function(obj) {
			return obj = [obj.cls_average, obj.cls_average_percent, obj.class_median_percent, obj.gra_average_percent, obj.cls_gra_avg_percent_diff, obj.cls_med_gra_avg_percent_diff, obj.diff_degree, obj.full_score]
		},
	},
	Pupil: {
		createReport : function(data){
			var basicData = data.data.basic;
			var pupilNavStr = ''+basicData.name+'/'+basicData.sex+'/'+basicData.grade+basicData.classroom+'/'+basicData.school+'/'+basicData.area+'难度:'+basicData.levelword2+'测试日期:'+basicData.quiz_date+'';
			$('#pupil-top-nav').html(pupilNavStr);
			var PupilDiagnoseObj = reportPage.Pupil.getPupilDiagnoseData(data.data);
			var objArr = [PupilDiagnoseObj.knowledge,PupilDiagnoseObj.skill,PupilDiagnoseObj.ability];
			var nodeArr_radar = ['pupil_knowledge_radar','pupil_skill_radar','pupil_ability_radar'];
			var nodeArr_diff = ['pupil_knowledge_diff','pupil_skill_diff','pupil_ability_diff'];
			for(var i = 0 ; i < objArr.length ; i++){
				var optionRadar = echartOption.getOption.Pupil.setPupilRadarOption(objArr[i]);
				var optionDiff = echartOption.getOption.Pupil.setPupilDiffOption(objArr[i]);
				echartOption.createEchart(optionRadar,nodeArr_radar[i]);
				echartOption.createEchart(optionDiff,nodeArr_diff[i]);
			}
			$('#tab-menu li[data-id]').on('click', function (e) {
				var $dataId = $(e.target).attr('data-id');
				if($dataId == 'improve-sugg'){
					$('#improve-sugg').html(data.data.quiz_comment);
				}else if($dataId == 'table-data-knowledge'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.knowledge,'pupil');
					$('#knowledge_data_table').html(tableStr);
				}else if($dataId == 'table-data-skill'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.skill,'pupil');
					$('#skill_data_table').html(tableStr);
				}else if($dataId == 'table-data-ability'){
					var tableStr = reportPage.baseFn.getTableStr(data.data.data_table.ability,'pupil');
					$('#ability_data_table').html(tableStr);
				}
			})
		},
		getPupilDiagnoseData : function(data){
			return obj = {
				knowledge : {
					radar : {
						grade : reportPage.Pupil.handlePupilRadarData(data.charts.knowledge_radar.grade_average),
						pupil : reportPage.Pupil.handlePupilRadarData(data.charts.knowledge_radar.pupil_average),
					},
					diff : {
						xaxis : reportPage.baseFn.getKeys(data.charts.knowledge_pup_gra_avg_diff_line),
						yaxis :	reportPage.baseFn.getDiff(data.charts.knowledge_pup_gra_avg_diff_line),
					}
				},
				skill : {
					radar : {
						grade : reportPage.Pupil.handlePupilRadarData(data.charts.skill_radar.grade_average),
						pupil : reportPage.Pupil.handlePupilRadarData(data.charts.skill_radar.pupil_average),
					},
					diff : {
						xaxis : reportPage.baseFn.getKeys(data.charts.skill_pup_gra_avg_diff_line),
						yaxis :	reportPage.baseFn.getDiff(data.charts.skill_pup_gra_avg_diff_line),
					}
				},
				ability : {
					radar : {
						grade : reportPage.Pupil.handlePupilRadarData(data.charts.ability_radar.grade_average),
						pupil : reportPage.Pupil.handlePupilRadarData(data.charts.ability_radar.pupil_average),
					},
					diff : {
						xaxis : reportPage.baseFn.getKeys(data.charts.ability_pup_gra_avg_diff_line),
						yaxis :	reportPage.baseFn.getDiff(data.charts.ability_pup_gra_avg_diff_line),
					}
				}
			};
		},
		handlePupilRadarData : function (data){
			var arr1 = reportPage.baseFn.getKeys(data);
			var dataArr1 = [];
			var dataArr2 = [];
			var len = arr1.length;
			for(var i=0 ; i<len ; i++){
				dataArr1.push({name : arr1[i],max : 100});
				dataArr2.push({name : '' , max : 100});
			}
			var arr2 = reportPage.baseFn.getValue(data);
			return obj = {
				xaxis : { nullAxis : dataArr2 , xAxis : dataArr1},
				yaxis : { yAxis : arr2}
			}
		},
		/*针对个人的字段*/
		creatPuilValueArr: function(obj) {
			return obj = [obj.average_percent, obj.gra_average_percent, obj.pup_gra_avg_percent_diff, obj.full_score, obj.correct_qzp_count];
		}
	},
	bindEvent: function(){
		/*顶部导航*/
		$('.dropdown_box').hover(function() {
			$('.dropdown_menu>li>ul').attr('class', 'submit_menu');
			$('.dropdown_menu').show();
			$('.dropdown_menu>li').on('mouseover', function() {
				$(this).addClass('active').siblings('li').removeClass('active');
				$(this).children('ul').show();
				$(this).siblings('li').children('ul').hide();
				var screenHeight = Math.floor($(window).height());
				var bodyHeight = Math.ceil($(this).children('ul').offset().top + $(this).children('ul').height() - $(document).scrollTop());
				if (bodyHeight > screenHeight) {
					$(this).children('ul').attr('class', 'active');
				}
			});
		}, function() {
			$('.dropdown_menu').hide();
			$('.dropdown_menu>li>ul').hide();
			$('.dropdown_menu>li').removeClass('active');
		});
		$(document).on('click','#tab-menu li[data-id]',function(event){
			
			$select = $(this).attr('data-id');
			$('#myTabContent div.tab-pane').hide();
			$('#'+$select+'').fadeIn();
			$('#tab-menu li[data-id]').each(function(){
				$(this).removeClass('active');
			})
			$(this).addClass('active');
		});
		$(document).on('click','#xialatab',function(event){
			var $this = $(this).children('ul');
			if($this.is(':hidden')){
				$this.slideDown();
			}else{
				$this.slideUp();
			}
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
		/*答题情况*/
		getAnswerCaseTable : function(data){
			if(data != null){
				var qid = reportPage.baseFn.getKeys(data);
				var correctRatio = reportPage.baseFn.getValue(data);
				var str = '';
				for(var i = 0; i < qid.length ; i++){
					str += '<tr><td>'+qid[i]+'</td><td>'+correctRatio[i]+'</td></tr>';
				};
				return str;
			}else{
				return '';
			};
		},
		/*处理数据表(type是班级还是个人)*/
		getTableStr: function(obj, type) {
			var allStr = '';
			//创建一级指标table ------ knowledge;
			var oneArrKey = reportPage.baseFn.getKeys(obj);
			var oneArrValue = reportPage.baseFn.getValue(obj)
			var one_len = oneArrKey.length;
			for (var i = 0; i < one_len; i++) {
				var oneValueStr = '';
				var twoAllStr = '';
				//取得一级指标的键名;
				one_level_name = oneArrKey[i];
				var oneNameStr = '<td class="one-level">' + one_level_name + '</td>';
				//取得一级指标的键值对value；
				var oneValue = oneArrValue[i].value;
				var oneValueArr = type == 'class' ? reportPage.Class.creatClassValueArr(oneValue) : reportPage.Pupil.creatPuilValueArr(oneValue);
				//插入具体数据;
				for (var k = 0; k < oneValueArr.length; k++) {
					oneValueStr += '<td class="one-level-content">' + oneValueArr[k] + '</td>';
				};
				var oneAllStr = '<tr>' + oneNameStr + oneValueStr + '</tr>';
				//创建二级指标表格数据
				if (oneArrValue[i].items && oneArrValue[i].items != null) {
					var two_len = reportPage.baseFn.getKeys(oneArrValue[i].items).length;
					
					for (var j = 0; j < two_len; j++) {
						var twoNameStr = '<td>' + reportPage.baseFn.getKeys(oneArrValue[i].items)[j] + '</td>';
						var twoValueStr = '';
						var twoArrValue = reportPage.baseFn.getValue(oneArrValue[i].items)[j].value;
						var twoValueArr = type == 'class' ? reportPage.Class.creatClassValueArr(twoArrValue) : reportPage.Pupil.creatPuilValueArr(twoArrValue);
						for (var g = 0; g <twoValueArr.length ; g++) {
							twoValueStr += '<td>' + twoValueArr[g] + '</td>';
						};
						twoAllStr += '<tr>' + twoNameStr + twoValueStr + '</tr>';
					}
				} else {
					return;
				}
				allStr += oneAllStr + twoAllStr;
			}
			return allStr;
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
					itemStyle: {
						normal: {
							barBorderRadius: [20, 0, 0, 20],
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
					name: '( 60 ≤ 得分率 < 85)',
					value: obj[i].good_pupil_percent,
					yAxisIndex: i,
					itemStyle: {
						normal: {
							barBorderRadius: 0,
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
					name: '(得分率 < 60)',
					value: obj[i].failed_pupil_percent,
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
				return Object.keys(obj);
			}else{
				return [];
			}
		},
		/*获取对象的value数组*/
		getValue: function(obj) {
			return $.map(obj, function(value, index) {
				return [value];
			});
		},
		/*获取随机的颜色值*/
		getRandomColor: function() {
			return "#" + ("00000" + ((Math.random() * 16777215 + 0.5) >> 0).toString(16)).slice(-6);
		},
		/*获取url中?后面传递的参数*/
		getRequest: function() {
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
	}
}
