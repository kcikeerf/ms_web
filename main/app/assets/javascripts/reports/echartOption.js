var echartOption = {
    defaultColor: "#51b8c1",
    /*创建Echart*/
    createEchart: function (optionObj, Node) {
        var myChart = echarts.init(document.getElementById(Node));
        var option = optionObj;
        myChart.setOption(option);
        return myChart;
    },
    getOption: {
        Grade: {
            //诊断图:
            setGradeDiagnoseLeft: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16
                    },
                    tooltip: {
                        trigger: 'item',
                    },
                    legend: {
                        top: 0,
                        right: 10,
                        data: [
                            {
                                name: '年级中位数得分率',
                                icon: 'rect'
                            },
                            {
                                name: '年级平均得分率',
                                icon: 'rect'
                            },
                            {
                                name: '年级分化度',
                                icon: 'rect'
                            }
                        ],
                    },
                    grid: {
                        top: 100,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: [{
                        type: 'category',
                        axisTick: {
                            alignWithLabel: true
                        },
                        data: data.xaxis,
                        axisLabel: {
                            interval: 0,
                            textStyle: {
                                fontSize: 16
                            }
                        },
                    }],
                    yAxis: [{
                        type: 'value',
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
                        axisLabel: {
                            textStyle: {
                                fontSize: 16
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
                        z: 1,
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
            setGradeDiagnoseRight: function (data) {
                return option = {
                    tooltip: {
                        trigger: 'item'
                    },
                    legend: {
                        top: 0,
                        right: 10,
                        data: [
                            {
                                name: '中平差值正值',
                                icon: 'rect',
                            },
                            {
                                name: '中平差值负值',
                                icon: 'rect',
                            }
                        ],
                        textStyle: {
                            fontSize: 16
                        }
                    },
                    grid: {
                        top: 100,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: [{
                        type: 'category',
                        axisTick: {
                            alignWithLabel: true
                        },
                        data: data.xaxis,
                        axisLabel: {
                            interval: 0,
                            textStyle: {
                                fontSize: 16
                            }
                        }
                    }],
                    yAxis: [{
                        type: 'value',
                        axisTick: {
                            show: false
                        },
                        axisLabel: {
                            formatter: '{value}',
                            textStyle: {
                                fontSize: 16
                            }
                        },
                        splitLine: {
                            lineStyle: {
                                color: ['#efefef']
                            }
                        },
                    }],
                    series: [{
                        name: '中平差值正值',
                        type: 'bar',
                        barMaxWidth: 15,
                        stack: '百分比',
                        data: data.yaxis.med_avg_diff.up,
                        itemStyle: {
                            normal: {
                                color: '#51b8c1'
                            }
                        },
                        LegendHoverLink: true,
                    }, {
                        name: '中平差值负值',
                        type: 'bar',
                        barMaxWidth: 15,
                        stack: '百分比',
                        data: data.yaxis.med_avg_diff.down,
                        itemStyle: {
                            normal: {
                                color: '#fa9daf'
                            }
                        },
                        LegendHoverLink: true,
                    },],
                    animation: false,
                };
            },
            /*分型图*/
            setGradePartingChartOption: function (data) {
                return option = {
                    legend: {
                        show: true,
                        top: 0,
                        right: 10,
                        itemWidth: 14,
                        itemHeight: 14,
                        data: [{name: '知识', icon: 'circle'}, {name: '技能', icon: 'triangle'}, {
                            name: '能力',
                            icon: 'rect'
                        }],
                        textStyle: {fontSize: 16}
                    },
                    grid: {
                        left: 10,
                        right: 80,
                        bottom: 10,
                        containLabel: true
                    },
                    tooltip: {},
                    xAxis: [
                        {
                            type: 'value',
                            name: '分化度',
                            nameLocation: 'end',
                            nameTextStyle: {color: '#000', fontSize: 16},
                            min: 0,
                            max: 200,
                            splitNumber: 20,
                            axisLabel: {
                                formatter: '{value}',
                                textStyle: {
                                    fontSize: 16
                                }
                            },
                            axisTick: {show: false},
                            splitLine: {
                                lineStyle: {
                                    type: 'dashed', color: '#cdcccc',
                                    opacity: 0.5,
                                }
                            },
                            z: 3
                        }
                    ],
                    yAxis: [
                        {
                            type: 'value',
                            name: '平均得分率',
                            nameLocation: 'end',
                            nameTextStyle: {color: '#000', fontSize: 16},
                            min: 0,
                            max: 100,
                            splitNumber: 6,
                            axisLabel: {
                                formatter: '{value}',
                            },
                            axisTick: {show: false},
                            splitLine: {
                                lineStyle: {
                                    type: 'dashed', color: '#cdcccc',
                                    opacity: 0.5,
                                }
                            },
                            z: 3
                        }
                    ],
                    series: [
                        {
                            name: '知识',
                            type: 'scatter',
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
                            symbolSize: 14,
                            symbol: 'circle',
                            itemStyle: {
                                normal: {
                                    shadowColor: 'rgba(0,0,0,0.3)',
                                    shadowOffsetX: 3,
                                    shadowOffsetY: 3,
                                    shadowBlur: 3
                                }
                            },
                            data: data.knowledge.data_node,
                            markPoint: {
                                label: {
                                    normal: {show: true, formatter: '{b}', textStyle: {color: '#fff'}}
                                },
                                data: [
                                    {
                                        type: 'max',
                                        name: data.knowledge.maxkey,
                                        label: {
                                            normal: {position: 'insideTop'},
                                            emphasis: {position: 'insideTop'}
                                        },
                                        symbolSize: [100, 30],
                                        symbol: 'image://img/tooltip_purple_up.svg',
                                        symbolOffset: ['-2%', '-100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    },
                                    {
                                        type: 'min',
                                        name: data.knowledge.minkey,
                                        label: {
                                            normal: {position: 'insideBottom'},
                                            emphasis: {position: 'insideBottom'}
                                        },
                                        symbolSize: [100, 25],
                                        symbol: 'image://img/tooltip_purple_down.svg',
                                        symbolOffset: ['2%', '100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    }
                                ]
                            },
                            markArea: {
                                silent: true,
                                label: {
                                    normal: {
                                        position: 'inside',
                                        textStyle: {
                                            color: '#212121',
                                            fontSize: 16,
                                        }
                                    }
                                },
                                data: [
                                    [
                                        {
                                            name: '高质高均衡',
                                            xAxis: 0,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#c4f5ee',
                                                    borderColor: '#c4f5ee',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '高质低均衡',
                                            xAxis: 30,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质高均衡',
                                            xAxis: 0,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 60,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质低均衡',
                                            xAxis: 30,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#fce9e9',
                                                    borderColor: '#fce9e9',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 60,
                                        }
                                    ],

                                ]
                            },
                            /*
                            markLine: {
                                lineStyle: {
                                    normal: {
                                        color: '#ffffff',
                                        wodth: 2,
                                        type: 'dashed'
                                    }
                                },
                                data: [
                                    {
                                        name: '平均得分率',
                                        yAxis: 80
                                    },
                                    {
                                        name: '分化度',
                                        xAxis: 20
                                    }

                                ]
                            },
                            */
                        },
                        {
                            name: '技能',
                            type: 'scatter',
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
                            symbolSize: 15,
                            symbol: 'triangle',
                            itemStyle: {
                                normal: {
                                    shadowColor: 'rgba(0,0,0,0.3)',
                                    shadowOffsetX: 3,
                                    shadowOffsetY: 3,
                                    shadowBlur: 3
                                }
                            },
                            data: data.skill.data_node,
                            markPoint: {
                                label: {
                                    normal: {show: true, formatter: '{b}', textStyle: {color: '#fff'}}
                                },
                                data: [
                                    {
                                        type: 'max',
                                        name: data.skill.maxkey,
                                        label: {
                                            normal: {position: 'insideTop'},
                                            emphasis: {position: 'insideTop'}
                                        },
                                        symbolSize: [100, 30],
                                        symbol: 'image://img/tooltip_cyan_up.svg',
                                        symbolOffset: ['-2%', '-100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    },
                                    {
                                        type: 'min',
                                        name: data.skill.minkey,
                                        label: {
                                            normal: {position: 'insideBottom'},
                                            emphasis: {position: 'insideBottom'}
                                        },
                                        symbolSize: [100, 25],
                                        symbol: 'image://img/tooltip_cyan_down.svg',
                                        symbolOffset: ['2%', '100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    }
                                ]
                            },
                            markArea: {
                                silent: true,
                                label: {
                                    normal: {
                                        position: 'inside',
                                        textStyle: {
                                            color: '#212121',
                                            fontSize: 16,
                                        }
                                    }
                                },
                                data: [
                                    [
                                        {
                                            name: '高质高均衡',
                                            xAxis: 0,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#c4f5ee',
                                                    borderColor: '#c4f5ee',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '高质低均衡',
                                            xAxis: 30,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质高均衡',
                                            xAxis: 0,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 60,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质低均衡',
                                            xAxis: 30,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#fce9e9',
                                                    borderColor: '#fce9e9',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 60,
                                        }
                                    ],

                                ]
                            },
                        },
                        {
                            name: '能力',
                            type: 'scatter',
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
                            symbolSize: 12,
                            symbol: 'rect',
                            itemStyle: {
                                normal: {
                                    shadowColor: 'rgba(0,0,0,0.3)',
                                    shadowOffsetX: 3,
                                    shadowOffsetY: 3,
                                    shadowBlur: 3
                                }
                            },
                            data: data.ability.data_node,
                            markPoint: {
                                label: {
                                    normal: {show: true, formatter: '{b}', textStyle: {color: '#fff'}}
                                },
                                data: [
                                    {
                                        type: 'max',
                                        name: data.ability.maxkey,
                                        label: {
                                            normal: {position: 'insideTop'},
                                            emphasis: {position: 'insideTop'}
                                        },
                                        symbolSize: [100, 30],
                                        symbol: 'image://img/tooltip_blue_up.svg',
                                        symbolOffset: ['-2%', '-100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    },
                                    {
                                        type: 'min',
                                        name: data.ability.minkey,
                                        label: {
                                            normal: {position: 'insideBottom'},
                                            emphasis: {position: 'insideBottom'}
                                        },
                                        symbolSize: [100, 25],
                                        symbol: 'image://img/tooltip_blue_down.svg',
                                        symbolOffset: ['2%', '100%'],
                                        itemStyle: {
                                            normal: {
                                                shadowColor: 'rgba(0,0,0,0.3)',
                                                shadowOffsetX: 3,
                                                shadowOffsetY: 3,
                                                shadowBlur: 3
                                            }
                                        },
                                    }
                                ]
                            },
                            markArea: {
                                silent: true,
                                label: {
                                    normal: {
                                        position: 'inside',
                                        textStyle: {
                                            color: '#212121',
                                            fontSize: 16,
                                        }
                                    }
                                },
                                data: [
                                    [
                                        {
                                            name: '高质高均衡',
                                            xAxis: 0,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#c4f5ee',
                                                    borderColor: '#c4f5ee',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '高质低均衡',
                                            xAxis: 30,
                                            yAxis: 80,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 100,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质高均衡',
                                            xAxis: 0,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#f2f2f2',
                                                    borderColor: '#f2f2f2',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 20,
                                            yAxis: 60,
                                        },
                                    ],
                                    [
                                        {
                                            name: '低质低均衡',
                                            xAxis: 30,
                                            yAxis: 0,
                                            itemStyle: {
                                                normal: {
                                                    color: '#fce9e9',
                                                    borderColor: '#fce9e9',
                                                    borderWidth: 2,
                                                    borderType: 'solid'
                                                }
                                            }
                                        },
                                        {
                                            xAxis: 200,
                                            yAxis: 60,
                                        }
                                    ],

                                ]
                            },
                        },
                    ],
                    color: ['#dca2ea', '#15a892', '#4a8ad3']
                };
            },
            /*scale比例图*/
            setGradeScaleOption: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16,
                        color: '#212121',
                    },
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
                        data: ['得分率 ≥ 85', '60 ≤ 得分率 < 85', '得分率 < 60'],
                    },
                    grid: {
                        left: 90,
                        right: 90,
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
                                fontSize: 16
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
                                fontSize: 16
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
            setFourSectionsOption: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16,
                        color: '#212121',
                    },
                    title: {
                        text: ''
                    },
                    tooltip: {
                        trigger: 'item',
                    },
                    legend: {},
                    grid: {
                        left: 10,
                        right: 10,
                        bottom: 50,
                        containLabel: true,
                    },
                    xAxis: [{
                        type: 'category',
                        axisTick: {
                            alignWithLabel: true
                        },
                        data: data.xaxis,
                        axisLabel: {
                            interval: 0,
                            textStyle: {
                                fontSize: 16
                            }
                        },
                    }],
                    yAxis: [{
                        type: 'value',
                        axisLine: {
                        },
                        axisTick: {
                        },
                        min: 0,
                        max: 100,
                        splitLine: {
                            lineStyle: {
                                color: ['#b6b6b6'],
                                type: 'dashed'
                            }
                        },
                        axisLabel: {
                            textStyle: {
                                fontSize: 16
                            }
                        },
                    }],
                    series: [{
                        //name: '技能',
                        name: '四分位',
                        type: 'bar',
                        barMaxWidth: 15,
                        label: {
                            normal: {
                                show: true,
                                position: 'top',
                            }
                        },
                        data: data.yaxis,
                    },],
                    color: [echartOption.defaultColor],
                    animation: false,
                };
            },
            /*各指标水平表现图*/
            setCheckpointOption: function (data) {
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
                            fontSize: 16
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
                                fontSize: 16
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
            setClassPupilNumOption: function (data) {
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
                            fontSize: 16
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
                                fontSize: 16
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
            setClassDiagnoseLeft: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16
                    },
                    title: {
                        text: ''
                    },
                    tooltip: {
                        trigger: 'item',
                    },
                    legend: {
                        top: 0,
                        right: 10,
                        data: [
                            {
                                name: '班级平均得分率',
                                icon: 'rect'
                            },
                            {
                                name: '年级平均得分率',
                                icon: 'rect'
                            },
                            {
                                name: '分化度',
                                icon: 'rect'
                            },
                            {
                                name: '班级中位数得分率',
                                icon: 'rect'
                            }
                        ],
                    },
                    grid: {
                        top: 100,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: [
                        {
                            type: 'category',
                            splitLine: {
                                lineStyle: {
                                    color: ['#efefef']
                                }
                            },
                            axisTick: {
                                alignWithLabel: true
                            },
                            data: data.xaxis,
                            axisLabel: {
                                interval: 0,
                            },
                            axisLabel: {
                                interval: 0,
                                textStyle: {
                                    fontSize: 16
                                }
                            }
                        }
                    ],
                    yAxis: [
                        {
                            type: 'value',
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
                            textStyle: {
                                fontSize: 16
                            },
                        }
                    ],
                    series: [
                        {
                            name: '分化度',
                            type: 'bar',
                            barMaxWidth: 15,
                            areaStyle: {
                                normal: {
                                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                                        offset: 0,
                                        color: '#062755'
                                    }, {
                                        offset: 1,
                                        color: '#90f3e9'
                                    }]),
                                    opacity: 0.5,
                                }
                            },
                            data: data.yaxis.all_line.diff_degree,
                            z: 4
                        },
                        {
                            name: '班级中位数得分率',
                            type: 'bar',
                            barMaxWidth: 15,
                            areaStyle: {
                                normal: {
                                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                                        offset: 0,
                                        color: '#ce15a9'
                                    }, {
                                        offset: 1,
                                        color: '#90f3e9'
                                    }]),
                                    opacity: 0.5,
                                }
                            },
                            data: data.yaxis.all_line.class_median_percent,
                            z: 3
                        },
                        {
                            name: '年级平均得分率',
                            type: 'bar',
                            barMaxWidth: 15,
                            areaStyle: {
                                normal: {
                                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                                        offset: 0,
                                        color: '#1eb9c7'
                                    }, {
                                        offset: 1,
                                        color: '#90f3e9'
                                    }]),
                                    opacity: 0.5,
                                }
                            },
                            data: data.yaxis.all_line.grade_average_percent,
                            z: 2
                        },
                        {
                            name: '班级平均得分率',
                            type: 'bar',
                            barMaxWidth: 15,
                            areaStyle: {
                                normal: {
                                    color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{
                                        offset: 0,
                                        color: '#25e8cf'
                                    }, {
                                        offset: 1,
                                        color: '#90f3e9'
                                    }]),
                                    opacity: 0.5,
                                }
                            },
                            data: data.yaxis.all_line.class_average_percent,
                            z: 1
                        },
                    ],
                    color: ['#062755', '#ce15a9', '#04838f', '#25e8cf'],
                    animation: false,
                };
            },
            setClassDiagnoseCenter: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16
                    },
                    title: {},
                    tooltip: {
                        trigger: 'item'
                    },
                    legend: {
                        top: 0,
                        right: 10,
                        data: [
                            {
                                name: '班级与年级平均得分率差值正值',
                                icon: 'rect',
                            },
                            {
                                name: '班级与年级平均得分率差值负值',
                                icon: 'rect',
                            }
                        ],
                    },
                    grid: {
                        top: 100,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: [
                        {
                            type: 'category',
                            //boundaryGap:false,
                            splitLine: {lineStyle: {color: ['#efefef']}},
                            axisTick: {
                                //show:false
                                alignWithLabel: true
                            },
                            data: data.xaxis,
                            axisLabel: {
                                margin: 10,
                                interval: 0,
                                textStyle: {fontSize: 16}
                            }
                        }
                    ],
                    yAxis: [
                        {
                            type: 'value',
                            axisLine: {show: false},
                            axisTick: {show: false},
                            axisLabel: {formatter: '{value}'},
                            splitNumber: 5,
                            splitLine: {lineStyle: {color: ['#efefef']}},
                        }
                    ],
                    series: [
                        {
                            name: '班级与年级平均得分率差值正值',
                            type: 'bar',
                            barMaxWidth: 15,
                            stack: '百分比',
                            areaStyle: {
                                normal: {
                                    color: '#51b8c1',
                                }
                            },
                            data: data.yaxis.diff.avg.up,
                            itemStyle: {
                                normal: {color: '#51b8c1'}
                            },
                            LegendHoverLink: true,
                        },
                        {
                            name: '班级与年级平均得分率差值负值',
                            type: 'bar',
                            barMaxWidth: 15,
                            stack: '百分比',
                            areaStyle: {
                                normal: {
                                    //color: '#c90303',
                                    color: '#fa9daf'
                                }
                            },
                            data: data.yaxis.diff.avg.down,
                            itemStyle: {
                                normal: {color: '#fa9daf'}
                            },
                            LegendHoverLink: true,
                        }
                    ],
                    animation: false,
                };

            },
            setClassDiagnoseRight: function (data) {
                return option = {
                    title: {},
                    tooltip: {
                        trigger: 'item'
                    },
                    legend: {
                        top: 0,
                        right: 10,
                        data: [
                            {
                                name: '班级中位数得分率与年级平均差值正值',
                                icon: 'rect',
                            },
                            {
                                name: '班级中位数得分率与年级平均差值负值',
                                icon: 'rect',
                            }
                        ],
                        textStyle: {fontSize: 16},
                    },
                    grid: {
                        top: 100,
                        left: 10,
                        right: 10,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: [
                        {
                            type: 'category',
                            splitLine: {lineStyle: {color: ['#ededed']}},
                            axisTick: {
                                //show:false
                                alignWithLabel: true
                            },
                            data: data.xaxis,
                            axisLabel: {
                                margin: 20,
                                interval: 0,
                                textStyle: {fontSize: 16}
                            }
                        }
                    ],
                    yAxis: [
                        {
                            type: 'value',
                            axisLine: {show: false},
                            axisTick: {show: false},
                            axisLabel: {formatter: '{value}'},
                            splitNumber: 4,
                            splitLine: {lineStyle: {color: ['#efefef']}},
                        }
                    ],
                    series: [
                        {
                            name: '班级中位数得分率与年级平均差值正值',
                            type: 'bar',
                            barMaxWidth: 15,
                            data: data.yaxis.diff.mid.up,
                            itemStyle: {
                                normal: {color: '#51b8c1'}
                            },
                            LegendHoverLink: true,
                        },
                        {
                            name: '班级中位数得分率与年级平均差值负值',
                            type: 'bar',
                            barMaxWidth: 15,
                            stack: '百分比',
                            data: data.yaxis.diff.mid.down,
                            itemStyle: {
                                normal: {color: '#fa9daf'}
                            },
                            LegendHoverLink: true,
                        },
                    ],
                    animation: false,
                };
            },
            setClassScaleNumOption: function (data) {
                return option = {
                    tooltip: {
                        trigger: 'item',
                        axisPointer: {
                            type: 'shadow',
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
                        left: 90,
                        right: 90,
                        bottom: 10,
                        containLabel: true,
                    },
                    xAxis: {
                        type: 'value',
                        splitNumber: 5,
                        max: 100,
                        axisTick: {show: false},
                        axisLabel: {formatter: '{value}%', textStyle: {color: '#212121', fontSize: 16,}},
                    },
                    yAxis: {
                        type: 'category',
                        data: data.yaxis,
                        axisLine: {show: false},
                        axisTick: {show: false},
                        splitLine: {show: false},
                        axisLabel: {textStyle: {color: '#212121', fontSize: 16,}},
                    },
                    series: [
                        {
                            name: '得分率 ≥ 85',
                            type: 'bar',
                            animation: false,
                            stack: '总量',
                            label: {
                                normal: {
                                    show: true,
                                    position: 'inside',
                                    textStyle: {color: '#fff', fontSize: 16,}
                                }
                            },
                            barMaxWidth: 30,
                            data: data.data.excenllent,
                            itemStyle: {
                                normal: {
                                    barBorderRadius: [20, 0, 0, 20],
                                    color: '#086a8e',
                                }
                            },
                        },
                        {
                            name: '60 ≤ 得分率 < 85',
                            type: 'bar',
                            legendHoverLink: false,
                            animation: false,
                            stack: '总量',
                            label: {
                                normal: {
                                    show: true,
                                    position: 'inside',
                                    textStyle: {color: '#fff', fontSize: 16,}
                                }
                            },
                            barMaxWidth: 30,
                            data: data.data.good,
                            itemStyle: {
                                normal: {
                                    barBorderRadius: 0,
                                    color: '#13ab9b',
                                }
                            },
                        },
                        {
                            name: '得分率 < 60',
                            type: 'bar',
                            legendHoverLink: false,
                            animation: false,
                            stack: '总量',
                            label: {
                                normal: {
                                    show: true,
                                    position: 'inside',
                                    textStyle: {color: '#fff', fontSize: 16,}
                                }
                            },
                            barMaxWidth: 30,
                            data: data.data.faild,
                            itemStyle: {
                                normal: {
                                    barBorderRadius: [0, 20, 20, 0],
                                    color: '#fa8471'
                                }
                            },
                        }
                    ]
                };
            }
        },

        Pupil: {
            setPupilRadarOption: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16
                    },
                    color: ['#EB595A', '#15a892'],
                    title: {},
                    tooltip: {
                        trigger: 'item',
                    },
                    legend: {
                        right: 20,
                        orient: 'vertical',
                        data: ['年级平均水平', '个人得分率']
                    },
                    grid: {},
                    radar: [
                        {
                            z: 4,
                            indicator: data.radar.grade.xaxis.nullAxis,
                            center: ['50%', '55%'],
                            radius: '60%',
                            splitNumber: 2,
                            splitLine: {
                                lineStyle: {
                                    color: ['#b6b6b6']
                                }
                            },
                            splitArea: {
                                areaStyle: {
                                    opacity: 0,
                                }
                            },
                            axisLine: {
                                lineStyle: {
                                    color: '#b6b6b6'
                                }
                            },
                            startAngle: 90,
                        },
                        {
                            z: 1,
                            indicator: data.radar.grade.xaxis.xAxis,
                            center: ['50%', '55%'],
                            radius: '60%',
                            splitNumber: 2,
                            splitLine: {show: false},
                            splitArea: {
                                areaStyle: {
                                    color: ['#fff']
                                }
                            },
                            name: {
                                textStyle: {
                                    color: '#212121'
                                }
                            },
                            axisLine: {show: false},
                            startAngle: 90
                        }
                    ],
                    series: [
                        {
                            name: '',
                            type: 'radar',
                            data: [
                                {
                                    value: data.radar.grade.yaxis.yAxis,
                                    name: '年级平均水平',
                                    symbol: '',
                                    symbolSize: 8,
                                    lineStyle: {normal: {width: 0}},
                                    areaStyle: {
                                        normal: {
                                            color: '#fa9daf'
                                        }
                                    },
                                    z: 2
                                },
                                {
                                    value: data.radar.pupil.yaxis.yAxis,
                                    name: '个人得分率',
                                    symbol: '',
                                    symbolSize: 8,
                                    lineStyle: {normal: {width: 0}},
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
                                    z: 3
                                }
                            ]
                        }
                    ],
                    animation: false,
                };
            },
            setPupilDiffOption: function (data) {
                return option = {
                    textStyle: {
                        fontSize: 16
                    },
                    title: {},
                    tooltip: {
                        trigger: 'item'
                    },
                    legend: {
                        top: 10,
                        right: 10,
                        data: [
                            {
                                name: '个人与年级平均得分率差值正值',
                                icon: 'roundRect',
                            },
                            {
                                name: '个人与年级平均得分率差值负值',
                                icon: 'roundRect',
                            }
                        ],
                    },
                    grid: {
                        left: 40,
                        right: 20,
                        bottom: 170,
                    },
                    animation: false,
                    xAxis: [
                        {
                            type: 'category',
                            axisTick: {
                                alignWithLabel: true
                            },
                            splitLine: {show: false},
                            axisLabel: {
                                margin: 10,
                                interval: 0,
                                textStyle: {
                                    fontSize: 16
                                }
                            },
                            data: data.diff.xaxis
                        }
                    ],
                    yAxis: [
                        {
                            type: 'value',
                            axisLine: {
                                show: false
                            },
                            axisTick: {
                                show: false
                            },
                            axisLabel: {
                                formatter: '{value}'
                            },
                            splitLine: {
                                lineStyle: {
                                    color: '#f4f4f4'
                                }
                            },
                            min: -100,
                            max: 100,
                            splitNumber: 10,
                        }
                    ],
                    series: [
                        {
                            name: '个人与年级平均得分率差值正值',
                            type: 'bar',
                            barMaxWidth: 30,
                            stack: '百分比',
                            itemStyle: {
                                normal: {
                                    color: '#51b8c1',
                                }
                            },
                            data: data.diff.yaxis.up,
                        },
                        {
                            name: '个人与年级平均得分率差值负值',
                            type: 'bar',
                            barMaxWidth: 30,
                            stack: '百分比',
                            itemStyle: {
                                normal: {
                                    color: '#fa9daf',
                                }
                            },
                            data: data.diff.yaxis.down,
                        }
                    ]
                };
            }
        },
    }
}
