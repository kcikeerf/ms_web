var echartOption = {
	/*创建Echart*/
	createEchart: function(optionObj, Node) {
		var myChart = echarts.init(document.getElementById(Node));
		var option = optionObj;
		myChart.setOption(option);
	},
	getOption: {
		Grade: {
			//诊断图:
			setGradeDiagnoseLeft: function(data) {
				return option = {
					title: {
						text: ''
					},
					tooltip: {
						trigger: 'item',
					},
					legend: {
						right: '0',
						itemWidth: 6,
						itemHeight: 6,
						data: [{
							name: '年级中位数得分率',
							icon: 'rect'
						}, {
							name: '年级平均得分率',
							icon: 'rect'
						}, {
							name: '年级分化度',
							icon: 'rect'
						}],
						textStyle: {
							fontSize: 10
						}
					},
					grid: {
						left: '0',
						right: '3%',
						bottom: '5%',
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						boundaryGap: false,
						axisTick: {
							show: false
						},
						data: data.xaxis,
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
						axisLabel: {
							interval: 0,
							textStyle: {
								fontSize: 11
							}
						},
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					yAxis: [{
						type: 'value',
						nameTextStyle: {
							color: '#262626'
						},
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								width: 1,
							}
						},
						axisTick: {
							show: false
						},
						mix: '0',
						max: '120',
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					series: [{
						name: '年级中位数得分率',
						type: 'line',
						symbol: 'circle',
						symbolSize: 5,
						lineStyle: {
							normal: {
								width: 1
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
									offset: 0,
									color: '#3aceb8'
								}, {
									offset: 1,
									color: '#f4fcfb'
								}]),
								opacity: 0.5,
							}
						},
						data: data.yaxis.Alllines.grade_median_percent,
						z: 1
					}, {
						name: '年级平均得分率',
						type: 'line',
						symbol: 'circle',
						symbolSize: 5,
						lineStyle: {
							normal: {
								width: 1
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
									offset: 0,
									color: '#299bcb'
								}, {
									offset: 1,
									color: '#f4fcfb'
								}]),
								opacity: 0.5,
							}
						},
						data: data.yaxis.Alllines.grade_average_percent,
						z: 2
					}, {
						name: '年级分化度',
						type: 'line',
						symbol: 'circle',
						symbolSize: 5,
						lineStyle: {
							normal: {
								width: 1
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
									offset: 0,
									color: '#d0a0da'
								}, {
									offset: 1,
									color: '#f4e8f6'
								}]),
								opacity: 0.8,
							}
						},
						data: data.yaxis.Alllines.grade_diff_degree,
						z: 3
					}],
					color: ['#01bda1', '#057ec8', '#ac83b4'],
					animation: false,
				}
			},
			setGradeDiagnoseRight: function(data) {
				return option = {
					title: {},
					tooltip: {
						trigger: 'item'
					},
					legend: {
						right: 0,
						data: [{
							name: '中平差值正值',
							icon: 'rect',
						}, {
							name: '中平差值负值',
							icon: 'rect',
						}, ],
						itemWidth: 6,
						itemHeight: 6,
						textStyle: {
							fontSize: 10
						}
					},
					grid: {
						left: '0',
						right: '3%',
						bottom: '5%',
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						boundaryGap: false,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
						axisTick: {
							show: false
						},
						data: data.xaxis,
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
						axisLabel: {
							interval: 0,
							textStyle: {
								fontSize: 11
							}
						}
					}],
					yAxis: [{
						type: 'value',
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								width: 1,
							}
						},
						axisTick: {
							show: false
						},
						axisLabel: {
							formatter: '{value}'
						},
						splitNumber: 5,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					series: [{
						name: '中平差值正值',
						type: 'line',
						stack: '百分比',
						symbol: 'circle',
						showAllSymbol: true,
						symbolSize: 5,
						lineStyle: {
							normal: {
								width: 1
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
									offset: 0,
									color: '#ebf6ff'
								}, {
									offset: 1,
									color: '#15a892'
								}]),
								opacity: 0.8,
							}
						},
						data: data.yaxis.med_avg_diff.up,
						itemStyle: {
							normal: {
								color: '#15a892'
							}
						},
						LegendHoverLink: true,
					}, {
						name: '中平差值负值',
						type: 'line',
						stack: '百分比',
						symbol: 'circle',
						showSymbol: true,
						showAllSymbol: true,
						symbolSize: 0,
						lineStyle: {
							normal: {
								width: 0
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
									offset: 0,
									color: '#faa9a7'
								}, {
									offset: 1,
									color: '#fffefe'
								}]),
								opacity: 0.8,
							}
						},
						data: data.yaxis.med_avg_diff.down,
						itemStyle: {
							normal: {
								color: '#ac83b4'
							}
						},
						LegendHoverLink: true,
					}, ],
					animation: false,
				};
			},
			/*分型图*/
			setGradePartingChartOption : function(data){
				return option = {
			        legend: {
			          show:true,
			          top:'0',
			          right:'8%',
			          itemWidth: 14,
			          itemHeight: 14,
			          data:[{name:'知识',icon:'circle'},{name:'技能',icon:'triangle'},{name:'能力',icon:'rect'}],
			          textStyle: {fontSize:14}
			        },
			        grid: {
			          left: '3%',
			          right: '9%',
			          bottom: '3%',
			          containLabel: true
			        },
			        tooltip : {
			          trigger: 'item',
			          showDelay : 0,
			          formatter : '{b}:{c}'
			        },
			        xAxis : [
			          {
			            type : 'value',
			            name:'分化度',
			            nameLocation:'end',
			            nameTextStyle:{color:'#000',fontSize:14},
			            scale:true,
			            min:'0',
			            max:'200',
			            splitNumber:10,
			            axisLabel : {
			              formatter: '{value}',
			            },
			            axisTick: {show:false},
			            axisLine: {lineStyle:{color:'#c9c8c8',width:4}},
			            splitLine: {
			              lineStyle: {
			                type: 'dashed',color:'#cdcccc',
			              }
			            }
			          }
			        ],
			        yAxis : [
			          {
			            type : 'value',
			            name:'平均得分率',
			            nameLocation:'end',
			            nameTextStyle:{color:'#000',fontSize:14},
			            scale:true,
			            min:'0',
			            max:'120',
			            splitNumber:6,
			            axisLabel : {
			              formatter: '{value}',
			            },
			            axisTick: {show:false},
			            axisLine: {lineStyle:{color:'#c9c8c8',width:4}},
			            splitLine: {
			              lineStyle: {
			                type: 'dashed',color:'#cdcccc',
			              }
			            }
			          }
			        ],
			        series : [
			          {
			            name:'知识',
			            type:'scatter',
			            symbolSize:14,
			            symbol:'circle',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: [
			              {name:'语音（听）',value:[12, 103]},
			              {name:'词汇',value:[13, 85]},
			              {name:'词法',value:[14, 60]},
			              {name:'句法',value:[38, 33]},
			              {name:'文章',value:[100, 100]},
			              {name:'写作',value:[99, 85]}
			            ],
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: '语音（听）',
			                  label:{
			                    normal:{position:'insideTop'},
			                    emphasis:{position:'insideTop'}
			                  },
			                  symbolSize:[100,30],
			                  symbol:'image://img/tooltip_purple_up.svg',
			                  symbolOffset:['-2%', '-100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                },
			                {
			                  type : 'min',
			                  name: '句法',
			                  label:{
			                    normal:{position:'insideBottom'},
			                    emphasis:{position:'insideBottom'}
			                  },
			                  symbolSize:[100,25],
			                  symbol:'image://img/tooltip_purple_down.svg',
			                  symbolOffset:['2%', '100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                }
			              ]
			            }
			          },
			          {
			            name:'技能',
			            type:'scatter',
			            symbolSize:15,
			            symbol:'triangle',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: [
			              {name:'认知',value: [131, 82]},
			              {name:'理解（听）',value:[113, 84]},
			              {name:'理解（读）',value:[125, 22]},
			              {name:'信息提取（听）',value:[140, 90]},
			              {name:'信息提取（读）',value:[165, 81]},
			              {name:'推理（听）',value:[141, 52]},
			              {name:'推理（读）',value:[153, 64]},
			              {name:'分析',value:[133, 34]},
			              {name:'表达',value:[105, 54]}
			            ],
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: '信息提取（听）',
			                  label:{
			                    normal:{position:'insideTop'},
			                    emphasis:{position:'insideTop'}
			                  },
			                  symbolSize:[100,30],
			                  symbol:'image://img/tooltip_cyan_up.svg',
			                  symbolOffset:['-2%', '-100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                },
			                {
			                  type : 'min',
			                  name: '理解（读）',
			                  label:{
			                    normal:{position:'insideBottom'},
			                    emphasis:{position:'insideBottom'}
			                  },
			                  symbolSize:[100,25],
			                  symbol:'image://img/tooltip_cyan_down.svg',
			                  symbolOffset:['2%', '100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                }
			              ]
			            }
			          },
			          {
			            name:'能力',
			            type:'scatter',
			            symbolSize:12,
			            symbol:'rect',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: [
			              {name:'词汇辨析',value:[38, 96]},
			              {name:'语言理解',value:[88, 80]},
			              {name:'逻辑分析',value:[112, 61]},
			              {name:'人际理解',value:[125, 40]}
			            ],
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: '词汇辨析',
			                  label:{
			                    normal:{position:'insideTop'},
			                    emphasis:{position:'insideTop'}
			                  },
			                  symbolSize:[100,30],
			                  symbol:'image://img/tooltip_blue_up.svg',
			                  symbolOffset:['-2%', '-100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                },
			                {
			                  type : 'min',
			                  name: '人际理解',
			                  label:{
			                    normal:{position:'insideBottom'},
			                    emphasis:{position:'insideBottom'}
			                  },
			                  symbolSize:[100,25],
			                  symbol:'image://img/tooltip_blue_down.svg',
			                  symbolOffset:['2%', '100%'],
			                  itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			                }
			              ]
			            }
			          },
			        ],
			        color:['#dca2ea','#15a892','#4a8ad3']
			    };
			},
			/*scale比例图*/
			setGradeScaleOption: function(data) {
				return option = {
					tooltip: {
						trigger: 'item',
						axisPointer: {
							type: 'shadow',
						},
						formatter: '{a}<br>{b}: {c}%'
					},
					legend: {
						top: '0',
						right: '10',
						width: '120',
						orient: 'vertical',
						data: ['得分率 ≥ 85', '60 ≤ 得分率 < 85', '得分率 < 60'],
						itemWidth: 10,
						itemHeight: 10,
					},
					grid: {
						left: '3%',
						top: '0%',
						right: '22%',
						bottom: '3%',
						containLabel: true,
					},
					xAxis: {
						type: 'value',
						splitNumber: 10,
						axisTick: {
							show: false
						},
						axisLabel: {
							formatter: '{value}%',
							textStyle: {
								color: '#000',
								fontSize: 14,
							}
						},
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								width: 3,
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
					},
					yAxis: {
						type: 'category',
						data: data.yaxis,
						axisLine: {
							show: false
						},
						axisTick: {
							show: false
						},
						splitLine: {
							show: false
						},
						axisLabel: {
							textStyle: {
								color: '#000',
								fontSize: 14
							}
						},
						inverse: true,
					},
					series: [{
						name: '得分率 ≥ 85',
						type: 'bar',
						animation: false,
						stack: '总量',
						label: {
							normal: {
								show: true,
								position: 'bottom',
								textStyle: {
									color: '#000',
									fontSize: 14
								}
							}
						},
						barWidth: 20,
						data: data.data.excellent,
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
					}, {
						name: '60 ≤ 得分率 < 85',
						type: 'bar',
						legendHoverLink: false,
						animation: false,
						stack: '总量',
						label: {
							normal: {
								show: true,
								position: 'bottom',
								textStyle: {
									color: '#000',
									fontSize: 14,
								}
							}
						},
						barWidth: 20,
						data: data.data.good,
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
					}, {
						name: '得分率 < 60',
						type: 'bar',
						legendHoverLink: false,
						animation: false,
						stack: '总量',
						label: {
							normal: {
								show: true,
								position: 'bottom',
								textStyle: {
									color: '#000',
									fontSize: 14,
								}
							}
						},
						barWidth: 20,
						data: data.data.failed,
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
					}]
				};
			},
			/*四分位图*/
			setFourSectionsOption: function(data) {
				return option = {
					title: {
						text: ''
					},
					tooltip: {
						trigger: 'item',
					},
					legend: {},
					grid: {
						left: '-5%',
						right: '8%',
						top: '8%',
						bottom: '3%',
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						boundaryGap: false,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
						axisTick: {
							show: false
						},
						data: data.xaxis,
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
						axisLabel: {
							interval: 0,
							textStyle: {
								fontSize: 11
							}
						},
					}],
					yAxis: [{
						type: 'value',
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								width: 1,
							}
						},
						axisTick: {
							show: false
						},
						mix: '0',
						max: '100',
						splitLine: {
							lineStyle: {
								color: ['#efefef'],
								type: 'dashed'
							}
						},
						splitNumber: 10,
						axisLabel: {
							show: false
						},
					}],
					series: [{
						name: '技能',
						type: 'line',
						symbol: 'circle',
						symbolSize: 3,
						label: {
							normal: {
								show: true,
								textStyle: {
									color: '#111'
								}
							}
						},
						lineStyle: {
							normal: {
								width: 0
							}
						},
						smooth: true,
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
									offset: 0,
									color: '#2ed1b9'
								}, {
									offset: 1,
									color: '#fff'
								}]),
								opacity: 0.8,
							}
						},
						data: data.yaxis,
					}, ],
					color: ['#06917c'],
					animation: false,
				};
			},
			/*各指标水平表现图*/
			setCheckpointOption: function(data) {
				return option = {
					title: {
						text: ''
					},
					tooltip: {
						trigger: 'item',
					},
					legend: {
						right: '0',
						itemWidth: 13,
						itemHeight: 8,
						data: data.normNameArr,
						textStyle: {
							fontSize: 10
						}
					},
					grid: {
						left: '0',
						right: '3%',
						top: '13%',
						bottom: '3%',
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						boundaryGap: false,
						axisTick: {
							show: false
						},
						data: data.xaxis,
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
						axisLabel: {
							interval: 0,
							textStyle: {
								fontSize: 11
							}
						},
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					yAxis: [{
						type: 'value',
						axisLine: {
							lineStyle: {
								color: '#828282',
								width: 1,
							}
						},
						axisTick: {
							show: false
						},
						mix: '-100',
						max: '100',
						splitLine: {
							lineStyle: {
								color: ['#efefef'],
								type: 'dashed'
							}
						},
						splitNumber: 5,
						axisLabel: {
							show: true
						},
					}],
					series: data.series,
					color: data.colorArr,
					animation: false,
				};
			},
			/*人数比例表现图*/
			setClassPupilNumOption: function(data) {
				return option = {
					title: {
						text: ''
					},
					tooltip: {
						trigger: 'item',
					},
					legend: {
						right: '0',
						orient: 'vertical',
						itemWidth: 23,
						itemHeight: 8,
						data: data.normNameArr,
						textStyle: {
							fontSize: 10
						}
					},
					grid: {
						left: '0',
						right: '20%',
						top: '3%',
						bottom: '3%',
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						boundaryGap: false,
						axisTick: {
							show: false
						},
						data: data.xAxis,
						axisLine: {
							lineStyle: {
								color: '#cacaca',
								shadowColor: '#cacaca',
								shadowOffsetX: 0,
								shadowOffsetY: 2
							}
						},
						axisLabel: {
							interval: 0,
							textStyle: {
								fontSize: 11
							}
						},
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					yAxis: [{
						type: 'value',
						axisLine: {
							lineStyle: {
								color: '#828282',
								width: 1,
							}
						},
						axisTick: {
							show: false
						},
						splitLine: {
							lineStyle: {
								color: ['#efefef'],
								type: 'dashed'
							}
						},
						splitNumber: 10,
						axisLabel: {
							show: true
						},
					}],
					series: data.pupil_percent,
					color: data.colorArr,
					animation: false,
				};
			},
		},
		Class: {
			setClassDiagnoseLeft : function(data){
				return option = {
                title: {
                  text: ''
                },
                tooltip : {
                  trigger: 'item',
                },
                legend: {
                  top:'0',
                  right:'3%',
                  width:'220',
                  itemWidth: 6,
                  itemHeight: 6,
                  data:[{name:'班级平均得分率',icon:'rect'},{name:'年级平均得分率',icon:'rect'},{name:'分化度',icon:'rect'},{name:'班级中位数得分率',icon:'rect'}],
                  textStyle: {fontSize:10},
                },
                grid: {
                  left: '0',
                  top:'25%',
                  right: '5%',
                  bottom: '5%',
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    boundaryGap:false,
                    splitLine: {lineStyle:{color:['#efefef']}},
                    axisTick: {show:false},
                    data : data.xaxis,
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:2}},
                    axisLabel:{
                      interval:0,
                      textStyle:{fontSize:11}
                    },
                  }
                ],
                yAxis : [
                  {
                    type : 'value',
                    nameTextStyle: {color:'#262626'},
                    axisLine: {lineStyle:{color:'#f0f0f0',width:1,}},
                    axisTick: {show:false},
                    mix:'0',
                    max:'120',
                    splitLine: {lineStyle:{color:['#efefef']}},
                  }
                ],
                series : [
                  {
                    name:'分化度',
                    type:'line',
                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#062755'
                        }, {
                          offset: 1,
                          color: '#90f3e9'
                        }]),
                        opacity:0.5,
                      }},
                    data:data.yaxis.all_line.diff_degree,
                    z:4
                  },
                  {
                    name:'班级中位数得分率',
                    type:'line',
                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#ce15a9'
                        }, {
                          offset: 1,
                          color: '#90f3e9'
                        }]),
                        opacity:0.5,
                      }},
                    data:data.yaxis.all_line.class_median_percent,
                    z:3
                  },
                  {
                    name:'年级平均得分率',
                    type:'line',
                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#1eb9c7'
                        }, {
                          offset: 1,
                          color: '#90f3e9'
                        }]),
                        opacity:0.5,
                      }},
                    data:data.yaxis.all_line.grade_average_percent,
                    z:2
                  },
                  {
                    name:'班级平均得分率',
                    type:'line',
                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#25e8cf'
                        }, {
                          offset: 1,
                          color: '#90f3e9'
                        }]),
                        opacity:0.5,
                      }},
                    data:data.yaxis.all_line.class_average_percent,
                    z:1
                  },
                ],
                color: ['#062755','#ce15a9','#04838f','#25e8cf'],
                animation:false,
              };
			},
			setClassDiagnoseCenter : function(data){
				return option = {
					color: ['#333'],
                title: {
                },
                tooltip : {
                  trigger: 'item'
                },
                legend: {
                  right:0,
                  data:[
                    {
                      name:'班级与年级平均得分率差值正值',
                      icon:'rect',
                    },
                    {
                      name:'班级与年级平均得分率差值负值',
                      icon:'rect',
                    },
                  ],
                  itemWidth:6,
                  itemHeight:6,
                  textStyle: {fontSize:10},
                  orient:'vertical'
                },
                grid: {
                  left: '0',
                  right: '5%',
                  bottom: '5%',
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    boundaryGap:false,
                    splitLine: {lineStyle:{color:['#efefef']}},
                    axisTick: {show:false},
                    data : data.xaxis,
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:2}},
                    axisLabel:{
                      interval:0,
                      textStyle:{fontSize:11}
                    }
                  }
                ],
                yAxis : [
                  {
                    type : 'value',
                    axisLine: {show:false},
                    axisTick: {show:false},
                    axisLabel: {formatter:'{value}'},
                    splitNumber:5,
                    splitLine: {lineStyle:{color:['#efefef']}},
                  }
                ],
                series : [
                  {
                    name:'班级与年级平均得分率差值正值',
                    type:'line',
                    stack: '百分比',
                    symbol:'circle',
                    showSymbol:true,
                    showAllSymbol: true,
                    symbolSize:5,
                    lineStyle: {normal: {width:0}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
                          offset: 0,
                          color: '#51b8c1'
                        }, {
                          offset: 1,
                          color: '#fcfcfc'
                        }]),
                        opacity:0.8,
                      }},
                    data:data.yaxis.diff.avg.up,
                    itemStyle: {
                      normal: {color:'#51b8c1'}
                    },
                    LegendHoverLink: true,
                  },
                  {
                    name:'班级与年级平均得分率差值负值',
                    type:'line',
                    stack: '百分比',
                    symbol:'circle',
                    showSymbol:true,
                    showAllSymbol: true,
                    symbolSize:5,
                    lineStyle: {normal: {width:0}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
                          offset: 0,
                          color: '#fff'
                        }, {
                          offset: 1,
                          color: '#c90303'
                        }]),
                        opacity:0.8,
                      }},
                    data:data.yaxis.diff.avg.down,
                    itemStyle: {
                      normal: {color:'#c90303'}
                    },
                    LegendHoverLink: true,
                  },
                ],
                animation:false,
              };
				
			},
			setClassDiagnoseRight : function(data){
				return option = {
                color: ['#333'],
                title: {
                },
                tooltip : {
                  trigger: 'item'
                },
                legend: {
                  right:0,
                  data:[
                    {
                      name:'班级中位数得分率与年级平均差值正值',
                      icon:'rect',
                    },
                    {
                      name:'班级中位数得分率与年级平均差值负值',
                      icon:'rect',
                    }
                  ],
                  itemWidth:6,
                  itemHeight:6,
                  textStyle: {fontSize:10},
                  orient:'vertical'
                },
                grid: {
                  left: '0',
                  right: '5%',
                  bottom: '5%',
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    boundaryGap:false,
                    splitLine: {lineStyle:{color:['#ededed']}},
                    axisTick: {show:false},
                    data : data.xaxis,
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:1}},
                    axisLabel:{
                      interval:0,
                      textStyle:{fontSize:11}
                    }
                  }
                ],
                yAxis : [
                  {
                    type : 'value',
                    axisLine: {show:false},
                    axisTick: {show:false},
                    axisLabel: {formatter:'{value}'},
                    splitNumber:4,
                    splitLine: {lineStyle:{color:['#efefef']}},
                  }
                ],
                series : [
                  {
                    name:'班级中位数得分率与年级平均差值正值',
                    type:'line',
                    stack: '百分比',
                    symbol:'circle',
                    showSymbol:true,
                    showAllSymbol: true,
                    symbolSize:5,
                    lineStyle: {normal: {width:0}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#51b8c1'
                        }, {
                          offset: 1,
                          color: '#fcfcfc'
                        }]),
                        opacity:0.8,
                      }},
                    data:data.yaxis.diff.mid.up,
                    itemStyle: {
                      normal: {color:'#51b8c1'}
                    },
                    LegendHoverLink: true,
                  },
                  {
                    name:'班级中位数得分率与年级平均差值负值',
                    type:'line',
                    stack: '百分比',
                    symbol:'circle',
                    showSymbol:true,
                    showAllSymbol: true,
                    symbolSize:5,
                    lineStyle: {normal: {width:0}},
                    areaStyle: {
                      normal: {
                        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                          offset: 0,
                          color: '#fff'
                        }, {
                          offset: 1,
                          color: '#c90303'
                        }]),
                        opacity:0.8,
                      }},
                    data:data.yaxis.diff.mid.down,
                    itemStyle: {
                      normal: {color:'#c90303'}
                    },
                    LegendHoverLink: true,
                  },
                ],
                animation:false,
              };
			},
			setClassScaleNumOption : function(data){
				return option = {
                  tooltip : {
                    trigger: 'item',
                    axisPointer : {  
                      type : 'shadow',
                    },
                    formatter: '{a}<br>{b}: {c}%',
                  },
                  legend: {
                    show:false,
                  },
                  grid: {
                    left: '6%',
                    top: '0%',
                    right: '8%',
                    bottom: '3%',
                    containLabel: true,
                  },
                  xAxis:  {
                    type: 'value',
                    splitNumber:5,
                    axisTick:{show:false},
                    axisLabel: {formatter:'{value}%',textStyle:{color:'#000',fontSize:14,}},
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:2}}
                  },
                  yAxis: {
                    type: 'category',
                    data: data.yaxis,
                    axisLine:{show:false},
                    axisTick:{show:false},
                    splitLine:{show:false},
                    axisLabel: {textStyle:{color:'#000',fontSize:14,}},
                  },
                  series: [
                    {
                      name: '得分率 ≥ 85',
                      type: 'bar',
                      animation:false,
                      stack: '总量',
                      label: {
                        normal: {
                          show: true,
                          position: 'bottom',
                          textStyle:{color:'#000',fontSize:14,}
                        }
                      },
                      barWidth:28,
                      data: data.data.excenllent,
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
                    },
                    {
                      name: '60 ≤ 得分率 < 85',
                      type: 'bar',
                      legendHoverLink:false,
                      animation:false,
                      stack: '总量',
                      label: {
                        normal: {
                          show: true,
                          position: 'bottom',
                          textStyle:{color:'#000',fontSize:14,}
                        }
                      },
                      barWidth:28,
                      data: data.data.good,
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
                    },
                    {
                      name: '得分率 < 60',
                      type: 'bar',
                      legendHoverLink:false,
                      animation:false,
                      stack: '总量',
                      label: {
                        normal: {
                          show: true,
                          position: 'bottom',
                          textStyle:{color:'#000',fontSize:14,}
                        }
                      },
                      barWidth:28,
                      data: data.data.faild,
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
                    }
                  ]
                };
			}
		},
		
		Pupil: {
			setPupilRadarOption : function(data){
				return option = {
		              color: ['#EB595A','#15a892'],
		              title: {},
		              tooltip: {
		                trigger: 'item',
		              },
		              legend: {
		                right: '0',
		                orient: 'vertical',
		                itemWidth: 24,
		                itemHeight: 2,
		                textStyle: {fontSize: 12},
		                data: [ '年级平均水平','个人得分率'],
		              },
		              textStyle: {
		                color: '#333',
		                fontSize:12
		              },
		              radar: [
		                {
		                  z:2,
		                  indicator: data.radar.grade.xaxis.nullAxis,
		                  center: ['50%', '45%'],
		                  radius: '60%',
		                  splitNumber: 2,
		                  splitLine: {show:false},
		                  splitArea: {
		                    areaStyle: {
		                      opacity: 0,
		                    }
		                  },
		                  axisLine: {show:false},
		                  startAngle:45,
		                },
		                {
		                  z:1,
		                  indicator: data.radar.grade.xaxis.xAxis,
		                  center: ['50%', '45%'],
		                  radius: '60%',
		                  splitNumber: 2,
		                  splitArea: {
		                    areaStyle: {
		                      color: ['#fff']
		                    }
		                  },
		                }
		              ],
		              series: [
		                {
		                  name: '',
		                  type: 'radar',
		                  radarIndex: 1,
		                  data : [
		                    {
		                      value : data.radar.grade.yaxis.yAxis,
		                      name : '年级平均水平',
		                      symbol : '',
		                      symbolSize: 8,
		                      lineStyle: {normal:{width:0}},
		                      areaStyle: {
		                        normal: {
		                          opacity: 0.55,
		                          color: new echarts.graphic.RadialGradient(0.5, 0.5, 1, [
		                            {
		                              color: '#fff',
		                              offset: 0
		                            },
		                            {
		                              color: '#f76f89',
		                              offset: 1
		                            }
		                          ])
		                        }
		                      },
		                      z:1
		                    },
		                    {
		                      value : data.radar.pupil.yaxis.yAxis,
		                      name : '个人得分率',
		                      symbol : '',
		                      symbolSize: 8,
		                      lineStyle: {normal:{width:0}},
		                      areaStyle: {
		                        normal: {
		                          opacity: 0.55,
		                          color: new echarts.graphic.RadialGradient(0.5, 0.5, 1, [
		                            {
		                              color: '#64f0db',
		                              offset: 0
		                            },
		                            {
		                              color: '#1aa2ae',
		                              offset: 1
		                            }
		                          ])
		                        }
		                      },
		                      z:2
		                    }
		                  ]
		                }
		              ],
		              animation:false,
		            };
			},
			setPupilDiffOption : function(data){
				return option = {
		            color: ['#048a76','#c90303'],
		            textStyle:{fontSize:12},
		            title: {},
		            tooltip : {
		              trigger: 'item'
		            },
		            legend: {
		              right:0,
		              orient: 'vertical',
		              data:[
		                {
		                  name:'个人与年级平均得分率差值正值',
		                  icon:'rect',
		                },
		                {
		                  name:'个人与年级平均得分率差值负值',
		                  icon:'rect',
		                }
		              ],
		              itemWidth:8,
		              itemHeight:8,
		            },
		            grid: {
		              left: '10%',
		              right: '0',
		              top:'20%',
		              bottom: '15%',
		            },
		            animation:false,
		            xAxis : [
		              {
		                type : 'category',
		                boundaryGap : true,
		                name: '',
		                nameLocation: 'start',
		                nameGap:-40,
		                splitLine: {show:false},
		                axisLabel: {show:false},
		                axisTick: {show:false},
		                axisLine: {onZero:true,lineStyle:{color:'#cacaca',width:4,shadowColor:'#21a793',shadowOffsetY:1}},
		                data : data.diff.xaxis
		              }
		            ],
		            yAxis : [
		              {
		                type : 'value',
		                axisLine: {show:false},
		                axisTick: {show:false},
		                axisLabel: {formatter:'{value}%'},
		                splitNumber:5,
		                splitLine: {lineStyle: {color:'#f4f4f4'}},
		                interval:10,
		              }
		            ],
		            series : [
		              {
		                name:'个人与年级平均得分率差值正值',
		                type:'line',
		                stack: '百分比',
		                symbol:'circle',
		                showAllSymbol:true,
		                symbolSize:8,
		                lineStyle: {normal: {width:0}},
		                areaStyle: {
		                  normal: {
		                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
		                      offset: 0,
		                      color: '#51b8c1'
		                    }, {
		                      offset: 1,
		                      color: '#fcfcfc'
		                    }]),
		                    opacity:0.5,
		                  }},
		                data: data.diff.yaxis.up,
		                label: {normal:{show:true,position:'top',textStyle:{color:'#333'},formatter:'{b}'}},
		              },
		              {
		                name:'个人与年级平均得分率差值负值',
		                type:'line',
		                stack: '百分比',
		                symbol:'circle',
		                showAllSymbol:true,
		                symbolSize:0,
		                lineStyle: {normal: {width:0}},
		                areaStyle: {
		                  normal: {
		                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
		                      offset: 0,
		                      color: '#fff'
		                    }, {
		                      offset: 1,
		                      color: '#c90303'
		                    }]),
		                    opacity:0.1,
		                  }},
		                data:data.diff.yaxis.down,
		                label: {normal:{show:true,position:'bottom',textStyle:{color:'#333'},formatter:'{b}'}}
		              }
		            ]
		          };
			}
		},
	}
}