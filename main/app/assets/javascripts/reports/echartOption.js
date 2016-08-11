var echartOption = {
	defaultColor: "#51b8c1",
	/*创建Echart*/
	createEchart: function(optionObj, Node) {
		var myChart = echarts.init(document.getElementById(Node));
		var option = optionObj;
		myChart.setOption(option);
		/*
		window.onresize = function () {
			myChart.resize();
		};
		*/
		return myChart;
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
						top: 0,
						right: 10,
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
							fontSize: 14
						}
					},
					grid: {
						left: 10,
						right: 10,
						bottom: 10,
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						//boundaryGap: false,
						axisTick: {
							alignWithLabel: true
							//show: false
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
								fontSize: 14
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
						max: '100',
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					series: [{
						name: '年级中位数得分率',
						type: 'bar',
						barMaxWidth: 10,
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
						type: 'bar',
						barMaxWidth: 10,
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
						type: 'bar',
						barMaxWidth: 10,
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
						show: true,
						top: 0,
						right: 10,
						data: [{
							name: '中平差值正值',
							icon: 'circle',
						}, {
							name: '中平差值负值',
							icon: 'circle',
						}, ],
						itemWidth: 6,
						itemHeight: 6,
						textStyle: {
							fontSize: 14
						}
					},
					grid: {
						left: 10,
						right: 10,
						bottom: 10,
						containLabel: true,
					},
					xAxis: [{
						type: 'category',
						//boundaryGap: false,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
						axisTick: {
							alignWithLabel: true
							//show: false
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
								fontSize: 14
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
						//interval: 10,
						//min: '-100',
						//max: '100',
						splitNumber: 5,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
					}],
					series: [{
						name: '中平差值正值',
						type: 'bar',
						barMaxWidth: 10,
						stack: '百分比',
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
									offset: 0,
									color: '#ebf6ff'
								}, {
									offset: 1,
									color: '#15a892'
								}]),
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
						type: 'bar',
						barMaxWidth: 10,
						stack: '百分比',
						areaStyle: {
							normal: {
								color: new echarts.graphic.LinearGradient(0, 1, 0, 0, [{
									offset: 0,
									color: '#faa9a7'
								}, {
									offset: 1,
									color: '#fffefe'
								}]),
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
			          top: 0,
			          right: 10,
			          itemWidth: 14,
			          itemHeight: 14,
			          data:[{name:'知识',icon:'circle'},{name:'技能',icon:'triangle'},{name:'能力',icon:'rect'}],
			          textStyle: {fontSize:14}
			        },
			        grid: {
			          left: 10,
			          right: 10,
			          bottom: 10,
			          containLabel: true
			        },
			        tooltip:{},
			        xAxis : [
			          {
			            type : 'value',
			            name:'分化度',
			            nameLocation:'end',
			            nameTextStyle:{color:'#000',fontSize:14},
			            scale:true,
			            min:'0',
			            max:'200',
			            splitNumber:20,
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
			            max:'100',
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
			            label: {
			            	emphasis: {
			            		show: true,
			            		position: 'right',
			            		formatter: '{b}',
			            		textStyle: {
			            			color: '#000',
			            			fontWeight: 'bold'
			            		}
			            	}
			            },
			            symbolSize:14,
			            symbol:'circle',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: data.knowledge.data_node,
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: data.knowledge.maxkey,
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
			                  name: data.knowledge.minkey,
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
			            label: {
			            	emphasis: {
			            		show: true,
			            		position: 'right',
			            		formatter: '{b}',
			            		textStyle: {
			            			color: '#000',
			            			fontWeight: 'bold'
			            		}
			            	}
			            },	
			            symbolSize:15,
			            symbol:'triangle',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: data.skill.data_node,
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: data.skill.maxkey,
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
			                  name: data.skill.minkey,
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
			            label: {
			            	emphasis: {
			            		show: true,
			            		position: 'right',
			            		formatter: '{b}',
			            		textStyle: {
			            			color: '#000',
			            			fontWeight: 'bold'
			            		}
			            	}
			            },
			            symbolSize:12,
			            symbol:'rect',
			            itemStyle: {normal:{shadowColor:'rgba(0,0,0,0.3)',shadowOffsetX:3,shadowOffsetY:3,shadowBlur:3}},
			            data: data.ability.data_node,
			            markPoint : {
			              label:{
			                normal:{show:true,formatter:'{b}',textStyle:{color:'#fff'}}
			              },
			              data : [
			                {
			                  type : 'max',
			                  name: data.ability.maxkey,
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
			                  name: data.ability.minkey,
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
						top: 0,
						right: 10,
						//width: '120',
						//orient: 'vertical',
						data: ['得分率 ≥ 85', '60 ≤ 得分率 < 85', '得分率 < 60'],
						itemWidth: 10,
						itemHeight: 10,
					},
					grid: {
						left: 10,
						right: 20,
						bottom: 10,
						containLabel: true,
					},
					xAxis: {
						type: 'value',
						splitNumber: 5,
						max: 100,
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
						nameLocation: 'start',
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
						inverse: true
					},
					series: [{
						name: '得分率 ≥ 85',
						type: 'bar',
						animation: false,
						stack: '总量',
						barMaxWidth: 30,
						label: {
							normal: {
								show: true,
								position: 'inside',
								textStyle: {
									color: '#fff',
									fontSize: 14
								}
							}
						},
						data: data.data.excellent,
						itemStyle: {
							normal: {
								barBorderRadius: [20, 0, 0, 20],
								color: '#086a8e',
							}
						},
					}, {
						name: '60 ≤ 得分率 < 85',
						type: 'bar',
						legendHoverLink: false,
						animation: false,
						stack: '总量',
						barMaxWidth: 30,
						label: {
							normal: {
								show: true,
								position: 'inside',
								textStyle: {
									color: '#fff',
									fontSize: 14,
								}
							}
						},
						data: data.data.good,
						itemStyle: {
							normal: {
								barBorderRadius: 0,
								color: '#13ab9b',
							}
						},
					}, {
						name: '得分率 < 60',
						type: 'bar',
						legendHoverLink: false,
						animation: false,
						stack: '总量',
						barMaxWidth: 30,
						label: {
							normal: {
								show: true,
								position: 'inside',
								textStyle: {
									color: '#fff',
									fontSize: 14,
								}
							}
						},
						data: data.data.failed,
						itemStyle: {
							normal: {
								barBorderRadius: [0, 20, 20, 0],
								color: '#fa8471',
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
						//boundaryGap: false,
						splitLine: {
							lineStyle: {
								color: ['#efefef']
							}
						},
						axisTick: {
							alignWithLabel: true
							//show: false
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
						//name: '技能',
						name:'四分位',
						type: 'bar',
						barMaxWidth: 10,
						label: {
							normal: {
								show: true,
								textStyle: {
									color: echartOption.defaultColor
								}
							}
						},
						label: {
							normal: {
								show: true,
								position: 'top',
								textStyle: {
									color: '#111'
								}
							}
						},
						/*symbol: 'circle',
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
						},*/
						data: data.yaxis,
					}, ],
					color: [echartOption.defaultColor],
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
						top: '30%',
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
                  top: 0,
                  right: 10,
                  width:'220',
                  itemWidth: 6,
                  itemHeight: 6,
                  data:[{name:'班级平均得分率',icon:'rect'},{name:'年级平均得分率',icon:'rect'},{name:'分化度',icon:'rect'},{name:'班级中位数得分率',icon:'rect'}],
                  textStyle: {fontSize:10},
                },
                grid: {
                  left: 10,
                  right: 10,
                  bottom: 10,
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    splitLine: {lineStyle:{color:['#efefef']}},
					//boundaryGap: false,
					axisTick: {
						alignWithLabel: true
						//show: false
					},
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
                    max:'100',
                    splitLine: {lineStyle:{color:['#efefef']}},
                  }
                ],
                series : [
                  {
                    name:'分化度',
                    type:'bar',
                    barMaxWidth: 5,
/*                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},*/
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
                    type:'bar',
                    barMaxWidth: 5,
/*                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},*/
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
                    type:'bar',
                    barMaxWidth: 5,
/*                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},*/
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
                    type:'bar',
                    barMaxWidth: 5,
/*                    symbol:'circle',
                    symbolSize:5,
                    lineStyle:{normal:{width:1}},*/
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
				  top: 10,
                  right: 10,
                  data:[
                    {
                      name:'班级与年级平均得分率差值正值',
                      icon:'rect',
                    },
                    {
                      name:'班级与年级平均得分率差值负值',
                      icon:'rect',
                    }
                  ],
                  itemWidth:6,
                  itemHeight:6,
                  textStyle: {fontSize:10},
                  orient:'vertical'
                },
                grid: {
                  left: 10,
                  right: 10,
                  bottom: 10,
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    //boundaryGap:false,
                    splitLine: {lineStyle:{color:['#efefef']}},
                    axisTick: {
                    	//show:false
                    	alignWithLabel: true
                    },
                    data : data.xaxis,
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:2}},
                    axisLabel:{
                   	  margin: 20,
                      interval:0,
                      textStyle:{fontSize:11}
                    }/*
                    axisLabel:{
                   	  show: false
                    }*/
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
                    type:'bar',
                    barMaxWidth: 10,
                    stack: '百分比',
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
                    type:'bar',
                    barMaxWidth: 10,
                    stack: '百分比',
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
                  }
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
				  top: 10,
                  right: 10,
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
                  left: 10,
                  right: 10,
                  bottom: 10,
                  containLabel: true,
                },
                xAxis : [
                  {
                    type : 'category',
                    //boundaryGap:false,
                    splitLine: {lineStyle:{color:['#ededed']}},
                    axisTick: {
                    	//show:false
                    	alignWithLabel: true
                    },
                    data : data.xaxis,
                    axisLine:{lineStyle:{color:'#cacaca',shadowColor:'#cacaca',shadowOffsetX:0,shadowOffsetY:1}},
                    axisLabel:{
                      margin: 20,
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
                    type:'bar',
                    barMaxWidth: 10,
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
                    type:'bar',
                    barMaxWidth: 10,
                    stack: '百分比',
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
					top: '0',
					right: '0',
					width: '120',
					orient: 'vertical',
					data: ['得分率 ≥ 85', '60 ≤ 得分率 < 85', '得分率 < 60'],
					itemWidth: 10,
					itemHeight: 10,
				},
                  grid: {
                    left: 10,
                    right: 10,
                    bottom: 10,
                    containLabel: true,
                  },
                  xAxis:  {
                    type: 'value',
                    splitNumber:5,
                    max: 100,
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
                          position: 'inside',
                          textStyle:{color:'#fff',fontSize:14,}
                        }
                      },
                      barMaxWidth: 30,
                      data: data.data.excenllent,
                      itemStyle: {
                        normal: {
                          barBorderRadius:[20, 0, 0, 20],
                          color: '#65026b',
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
                          position: 'inside',
                          textStyle:{color:'#000',fontSize:14,}
                        }
                      },
                      barMaxWidth: 30,
                      data: data.data.good,
                      itemStyle: {
                        normal: {
                          barBorderRadius:0,
                          color: '#71ecd0',
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
                          position: 'inside',
                          textStyle:{color:'#000',fontSize:14,}
                        }
                      },
                      barMaxWidth: 30,
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
		                right: '0%',
		                orient: 'vertical',
		                itemWidth: 24,
		                itemHeight: 2,
		                textStyle: {fontSize: 12},
		                data: [ '年级平均水平','个人得分率']
		              },
		              grid: {
		                left: '5%',
		                right: '5%',
		                top:'10%',
		                bottom: '15%',
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
		                  startAngle:90,
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
		                  startAngle:90
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
					  top: 10,
		              right: 10,
		              //orient: 'vertical',
		              data:[
		                {
		                  name:'个\n人\n与\n年\n级\n平\n均\n得\n分\n率\n差\n值\n正\n值',
		                  icon:'rect',
		                },
		                {
		                  name:'个\n人\n与\n年\n级\n平\n均\n得\n分\n率\n差\n值\n负\n值',
		                  icon:'rect',
		                }
		              ],
		              itemWidth:8,
		              itemHeight:8,
		            },
		            grid: {
		              left: 40,
		              right: 100,
		              bottom: 10,
		            },
		            animation:false,
		            xAxis : [
		              {
		                type : 'category',
		                //boundaryGap : true,
	                    axisTick: {
	                    	//show:false
	                    	alignWithLabel: true
	                    },
		                //name: '',
		                //nameLocation: 'start',
		                //nameGap:-40,
		                splitLine: {show:false},
		                axisLabel: {show:false},
		                //axisTick: {show:false},
		                //axisLine: {onZero:true,lineStyle:{color:'#cacaca',width:4,shadowColor:'#21a793',shadowOffsetY:1}},
		                data : data.diff.xaxis
		              }
		            ],
		            yAxis : [
		              {
		                type : 'value',
		                splitNumber: 5,
		                axisLine: {show:false},
		                axisTick: {show:false},
		                axisLabel: {formatter:'{value}%'},
		                splitNumber:5,
		                splitLine: {lineStyle: {color:'#f4f4f4'}}
		              }
		            ],
		            series : [
		              {
		                name:'个\n人\n与\n年\n级\n平\n均\n得\n分\n率\n差\n值\n正\n值',
		                type:'bar',
		                barMaxWidth: 10,
		                stack: '百分比',
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
		                name:'个\n人\n与\n年\n级\n平\n均\n得\n分\n率\n差\n值\n负\n值',
		                type:'bar',
		                barMaxWidth: 10,
		                stack: '百分比',
		                /*symbol:'circle',
		                showAllSymbol:true,
		                symbolSize:0,
		                lineStyle: {normal: {width:0}},*/
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
