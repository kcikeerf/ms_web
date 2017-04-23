// JavaScript Document
$(function(){
    var paper_interval;
    var ckeditor_common_params = {
            toolbar : [
                { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Subscript', 'Superscript', 'SpecialChar', 'RemoveFormat'] },
                { name: 'paragraph', items: ['JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'Undo', 'Redo'] },
                { name: 'styles', items: ['Font', 'FontSize', 'lineheight', 'TextColor', 'BGColor', 'Source'] }
            ],
            resize_enabled : false,
            allowedContent: true,
            removePlugins : "elementspath,magicline,link,anchor",
            height : 500
    };
    var paper = {
        id: null,
        paperData : {information: {}},     //数据保存时的参数对象
        changeState : false,
        currentQuiz: {},
        currentQuizOrder: null,
        modalLastUrl: "",
        ckeditor_params: {
            quiz_split: Object.assign({}, ckeditor_common_params, {contentsCss : "/assets/zhengjuan/css/paper.css"}),
            quiz_edit: ckeditor_common_params,
            qzp_edit: Object.assign({}, ckeditor_common_params, {height : 100 })
        },
        // getSubject : "/node_structures/get_subjects",        //请求科目
        // getGrade : "/node_structures/get_grades",        //请求年级
        // getTextbook : "/node_structures/get_versions",        //请求教材
        // getTerm : "/node_structures/get_units",        //请求学期
        // getPaperUnit : "/node_structures/get_catalogs_and_tree_data",        //请求知识点范围
        fileUploadSrc : "/papers/paper_answer_upload",  //试卷答案word上传接口
        getPaperInfo : "/papers/get_saved_paper",       //请求试卷信息接口
        analysisSaveUrl : "/papers/save_analyze",   //解析保存接口
        analysisSubmitUrl : "/papers/submit_analyze",   //解析提交接口
        paperSaveUrl : "/papers/save_paper",    //整卷保存接口
        paperSubmitUrl : "/papers/submit_paper",    //整卷提交接口
        createReport : "/reports/generate_all_reports",  //生成报告接口
        generateReports : "/reports/generate_reports",  //生成报告接口        
        get_task_status : "/monitors/get_task_status",  //查询报告进度接口
        paperUrl : "/papers/get_paper",  //访问已生成试卷路径
        paper_outline_list: "/papers/outline_list",
        init : function(){
            //截取url里的id参数，存在的画根据id取数据，不存在的话，跳到上传模块
            paper.bindEvent();
            var paperId = this.getQueryString(location.href,"pap_uid");
            paper.id = paperId;

            if(paperId){
                $.ajax({
                    url: paper.getPaperInfo,
                    type: "GET",
                    data: {pap_uid:paperId},
                    dataType: "json",
                    success: function(data){
                        if(data.status == 200){
                            paper.paperData = typeof data.data=="string" ? JSON.parse(data.data) : data.data;
                            // 初始状态禁止编辑试卷大纲；
                            paper.paperData.information.paper_outline_edittable = false;                            
                            paper.judge(paper.paperData);
                        }else{
                           alert(data.data.mesg);
                        }
                    },
                    error: function(){
                        alert("网络错误，请求失败");
                    } 
                });
            }else{
                $(".zhengjuang .container").show();
                var template = $(".template_part1").html();
                $(".contentBody").html(template);
                //word文件校验
                $(".part1 .formList input").on("change",function(){
                    var format = paper.fileVerify($(this)),
                        size = paper.sizeVerify($(this));
                    if(format && size){
                        $(this).siblings(".fileName").text($(this).val());
                    }else{
                        $(this).val("").siblings(".fileName").text("");
                        alert("您上传的文件不是word文件或者文件大于5M!");
                    }
                });
                //上传试卷
                $(".submitWarp .submitBtn").on("click",function(){
                    if($(".part1 [name=doc_path]").val() && $(".part1 [name=answer_path]").val()){
                        paper.createLoading();
                        var options={
                            url : paper.fileUploadSrc,
                            type : "POST",
                            dataType : "json",
                            success : paper.uploadCallback
                        };
                        $(".paperForm").ajaxSubmit(options);
                    }else{
                        alert("您需要同时选择试卷文件和答案文件！");
                        /*
                        $.ajax({
                            url: "json/paper2.json",
                            type: "GET",
                            dataType: "json",
                            success: paper.uploadCallback   
                        });
                        */
                    }
                });
            } 
        },
        baseFn : {
            calQizpointFullScore: function(obj){
                var target_obj = $(".analyze .textLabelWarp");
                if(target_obj.length==1){
                    var that = obj,
                        values = that.val(),
                        other = $(".selectFullscore, .scorePart").not(that.parents(".selectWarp"));
                    other.find(".selectVal input").val(values);
                    other.find(".optionList li").removeClass("active").map(function(i,item){
                        if($(item).text()==values) $(item).addClass("active");
                    });
                } else if(target_obj.length > 1) {
                    var fullscore = 0;
                    $(".analyze .textLabelWarp").each(function(){
                        fullscore += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
                    });
                    $(".selectFullscore").find(".selectVal input").val(fullscore.toFixed(2));
                    $(".selectFullscore").find(".optionList li").removeClass("active").map(function(i,item){
                        if(parseFloat($(item).text())==fullscore) $(item).addClass("active");
                    });
                }
            },
            update_quiz_type_list: function(){
                //update quiz type list
                
                var html_str = "";
                var quiz_types = quiz_type_list[paper.paperData.information.subject.name];
                for(k in quiz_types){
                    html_str += "<li values=" + k + ">" + quiz_types[k] + "</li>";
                }
                $(".selectCategory .optionList").html("");
                $(".selectCategory .optionList").html(html_str);
            },
            update_paper_outline_list: function(selector, callback){
                var html_str = "";
                $.ajax({
                    url: paper.paper_outline_list,
                    type: "post",
                    data: { pap_uid: paper.id },
                    dataType: "json",
                    success: function(data){
                        for(index in data){
                            var item = data[index];
                            disable_str = (item.is_end_point == "true") ? "" : "disabled"
                            html_str += "<option value='" + item.id + "'" + disable_str + ">" + item.path + "</option>";
                            $(selector).html("");
                            $(selector).html(html_str);
                            callback();
                        }
                    },
                    error: function(){
                        
                    }   
                });                
            },
            preview_paper_outline: function(){
                var outline_text = $(".paper_outline").val();
                var outline_arr = ["\n"].concat(outline_text.split("\n"));
                var zNodes = [];
                var outline_ids_arr = [];

                for(index in outline_arr){
                    var item = outline_arr[index];
                    var level_arr = item.match(/(\+{4})/g);
                    var level = level_arr ? level_arr.length + 1 : 1;

                    outline_ids_arr[level] = outline_ids_arr[level]? outline_ids_arr[level] + 1 : Math.pow(10, level);
                    var parent_level = (level-1 > 0) ? level-1 : 0;
                    outline_ids_arr[parent_level] = outline_ids_arr[parent_level]? outline_ids_arr[parent_level] : Math.pow(10, parent_level);
                    zNodes.push({
                        id: outline_ids_arr[level],
                        pId: outline_ids_arr[parent_level],
                        name: item.substring(4*(parent_level)),
                        open: true
                    });

                }
                var setting = {
                    data: {
                        simpleData: {
                            enable: true
                        }
                    }
                };
                $.fn.zTree.init($("#paper_outline_tree"), setting, zNodes);
            },
            toggle_paper_outline_edit: function(){
                var btn = $(".paper_outline_edit_lock");
                var flag = (btn.attr("locked") == "true");
                var btn_label = flag ? "未锁定" : "锁定中";
                var locked_message = flag ? " " : "锁定中大纲不会被更新";

                if(!flag){
                    btn.removeClass("btn-danger");
                    btn.addClass("btn-success");
                } else {
                    btn.removeClass("btn-success");
                    btn.addClass("btn-danger");
                }
                btn.attr("locked", !flag);
                btn.html(btn_label);
                $(".paper_outline").attr("disabled", !flag);
                $(".paper_outline_edit_lock_message").html(locked_message);
                paper.paperData.information.paper_outline_edittable = flag;
            },
            check_all_tenants: function(){
                $(".tenant_range_item_checkbox").addClass("active");
            },
            clear_check_all_tenants: function(){
                $(".tenant_range_item_checkbox").removeClass("active");
            }

        },
        judge : function(data){
            $(".zhengjuang .container").hide().after($(".template_detail").html());
            var type = null, tempDom = $("<div></div>").html(data.paper_html);
            if(data.bank_quiz_qizs && data.bank_quiz_qizs.length){
                type = 4;
            }else if(data.information){
                type = 3;
            }else{
                type = 2;
            }
            if(data.information){
                var typeObj = {
                    quiz_type: "测试类型",
                    qi_chu_ce_shi: "期初测试",
                    qi_zhong_ce_shi: "期中测试",
                    qi_mo_ce_shi: " 期末测试",
                    mo_ni_ce_shi: "模拟测试",
                    yue_kao: "月考",
                    dan_yuan_ce_shi: "单元测试",
                    xiao_sheng_chu_ce_shi: "小升初测试",
                    xue_ke_neng_li_ce_ping: "学科能力测评"
                },
                levelObj = {rong_yi:"容易",jiao_yi:"较易",zhong_deng:"中等",jiao_nan:"较难",kun_nan:"困难"};
                $(".top_title").text(data.information.heading||"");
                $(".sub_title").text(data.information.subheading||"");
                var city = (data.information.province||"")+" "+(data.information.city||"")+" "+(data.information.district||"");
                $(".info_city p").text(city);
                $(".info_school p").text(data.information.school);
                $(".info_type p").text(typeObj[data.information.quiz_type]);
                $(".info_subject p").text(data.information.subject ? data.information.subject.label : "");
                $(".info_grade p").text(data.information.grade ? data.information.grade.label : "");
                $(".info_term p").text(data.information.term ? data.information.term.label : "");
                $(".info_time p").text(data.information.quiz_duration);
                $(".info_version p").text(data.information.text_version ? data.information.text_version.label : "");
                $(".info_difficulty p").text(levelObj[data.information.levelword]);
                $(".info_testTime p").text(data.information.quiz_date);
                $(".info_score p").text(data.information.score);
                // 保留，暂时未发现可用场景
                // update tenant list
                // var tenant_list_html = "";
                // data.information.tenants.forEach(function(v,i){ 
                //     tenant_list_html += ""
                //     +"<tr><td>"+(i+1)+"</td><td>"
                //     +v.tenant_name+"</td><td>"
                //     +v.tenant_status_label+'</td><td><button type="button" class="btn btn-default" disabled>成绩上传</button></td></tr>';
                // });
                // $(".tenant_range_display_list").html(tenant_list_html);
                
            }

            var html1 = "", html2 = '<ul class="rangeAll">';
            if(data.bank_node_catalogs && data.bank_node_catalogs.length){
                for (var i=0; i<data.bank_node_catalogs.length; i++) {
                    if(i<3){
                        html1 += '<p>'+data.bank_node_catalogs[i].node+'<p>';
                        html2 += '<li>'+data.bank_node_catalogs[i].node+'<li>';
                    }else{
                        html2 += '<li>'+data.bank_node_catalogs[i].node+'<li>';
                    }
                    
                };
                html2 += '</ul>'
                $(".info_range .table_celle").html(html1);
                data.bank_node_catalogs.length > 2 && $(".info_range .table_celle").after(html2);
            }
            $(".paper_editor").attr("parttype",type);
            //试卷状态判断
            switch(data.information.paper_status){
                case "editted":
                case "analyzing":
                    $(".lookPaperInfo").show().find(".lookPaper_sanwei").hide();
                    $(".paper_about").show().find(".load_list").hide();
                    //project administrator tenant action
                    //$(".tenant_result_list").hide();
                    //
                    $(".link_paper").css("display","block");
                    break;
                case "analyzed":
                    $(".lookPaperInfo, .paper_about").show().find(".edit_sanwei").hide();
                    $(".link_paper").css("display","block");
                    // if($(".tenant_result_list")){
                        //$(".tenant_result_list .progress").show();
                    // }
                    break;
                case "score_importing":
                    $(".lookPaperInfo, .paper_about").show().find(".edit_sanwei").hide();
                    $(".link_paper").css("display","block");
                    if($(".tenant_result_list")){
                        $(".tenant_result_list .score_importing").show();

                        var monitoring_all_tenants = new MonitorMultipleUpdaters();
                        $.each($(".tenant_result_list .score_importing .progress-bar"),function(i,item){
                            var target_task_uid = data.information.tasks.import_result;
                            var target_job_uid = item.getAttribute("job-uid");
                            window["job_updater"+target_job_uid] = new ProgressBarUpdater(item, target_task_uid, target_job_uid);
                            monitoring_all_tenants.updater_objs.push(window["job_updater"+target_job_uid]);
                            $.Topic("tenant_score_importing").subscribe(window["job_updater"+target_job_uid].run());
                            $.Topic("tenant_score_importing").publish();
                        });
                        if($(".tenant_result_list .score_importing .progress-bar").length > 0 ){
                            monitoring_all_tenants.run(); 
                        }
                    }
                    else{
                        $(".paperDetails > .progress").show();
                        paper.setInterVal();
                    }

                    break;
                case "score_imported":
                    $.Topic("tenant_score_importing").destroy();
                    $(".link_paper, .link_form, .link_grade, .link_user").css("display","block");
                    $(".lookPaperInfo, .createReport:first").show();
                    //project administrator tenant action
                    if($(".tenant_result_list")){
                        $(".tenant_result_list .score_importing").show();
                    }
                    //
                    break
                case "report_generating":
                    $(".link_paper, .link_form, .link_grade, .link_user").css("display","block");
                    $(".lookPaperInfo, .createReport").show();
                    $(".paperDetails > .progress.createReport").show();
                    $(".createReport a").removeClass("active");
                    $(".createReport a").html("报告生成中...");
                    //project administrator tenant action
                    if($(".tenant_result_list")){
                        $(".tenant_result_list .score_importing").show();
                    }
                    //
                    //paper.setInterVal();
                    var monitoring_all_tenants = new MonitorMultipleUpdaters();
                     $.each($(".progress.createReport > .progress-bar"),function(i,item){
                        var target_task_uid = data.information.tasks.create_report;
                        var target_job_uid = item.getAttribute("job-uid");
                        window["job_updater"+target_job_uid] = new ProgressBarUpdater(item, target_task_uid, target_job_uid);
                        monitoring_all_tenants.updater_objs.push(window["job_updater"+target_job_uid]);
                        $.Topic("paper_report_generating").subscribe(window["job_updater"+target_job_uid].run());
                        $.Topic("paper_report_generating").publish();
                    });
                    monitoring_all_tenants.run();

                    break;
                case "report_completed":
                    $.Topic("paper_report_generating").destroy();
                    $(".download_link").css("display","block");
                    $(".lookPaperInfo, .lookReport").show();
                    //project administrator tenant action
                    if($(".tenant_result_list")){
                        $(".tenant_result_list .score_importing").show();
                    }
                    //
                    var pap_uid = paper.getQueryString(location.href,"pap_uid");
                        pap_uid && $(".lookReport a").attr("href",$(".lookReport a").attr("href")+"?pap_uid="+pap_uid);
                    break;
                default:
                    $(".paper_editor").css("display","block");
                    break;
            }
            //修订试卷
            $(".paper_editor").on("click",function(){
                var type = $(this).attr("parttype") || "2";
                $(".paperDetails").remove();
                $(".zhengjuang .container").show();
                $(".paperDetails").remove();
                switch(type){
                    case "2":
                        paper.gotoPaperInfo();
                        break;
                    case "3":
                        paper.gotoPaperChange();
                        break;
                    case "4": 
                        paper.gotoPaperAnalysis();
                        break;
                    default:
                        break;
                }
            });
            //编辑解析
            $(".paper_about .edit_sanwei").on("click",function(){
                $(".zhengjuang .container").show();
                $(".paperDetails").remove();
                paper.gotoAnalysisDetail();
            });
            //查看试卷问题答案
            $(".lookPaper_q_a").on("click",function(){
                $(".zhengjuang .container").show();
                $(".paperDetails").remove();
                paper.status = "editted";
                paper.gotoAnalysisDetail();

            });
            //查看解析详情
            $(".lookPaper_sanwei").on("click",function(){
                $(".zhengjuang .container").show();
                $(".paperDetails").remove();
                paper.status = "analyzed";
                paper.gotoAnalysisDetail();
            });
            //生成报告
            $(".createReport a").on("click",function(){
                var that = $(this);
                if(!that.hasClass("active")) return;
                that.removeClass("active");
                var dataObj = {
                    pap_uid : paper.paperData.pap_uid,
                    // province : paper.paperData.information.province,
                    // city : paper.paperData.information.city,
                    // district : paper.paperData.information.district,
                    school : paper.paperData.information.school
                };
                $.ajax({
                    url: paper.generateReports,
                    type: "post",
                    data: dataObj,
                    dataType: "json",
                    success: function(data){
                        if(data && data.task_uid){
                            location.reload();
                            // console.log( $(".paperDetails > .progress"));
                            // $(".paperDetails > .progress").show();
                            // paper.paperData.task_uid = data.task_uid;
                            // paper.setInterVal();
                        }
                    },
                    error: function(){
                        that.addClass("active");
                        alert("网络错误，请求失败");
                    }   
                });
            });
            //打开模态框
            $(".download_link, .load_list, .download_list, .tenant_result_list button").on("click",function(){
                var getUrl = $(this).attr("geturl") || "",
                    pap_uid = paper.paperData.pap_uid,
                    parame = getUrl.indexOf("?") < 0 ? "?pap_uid="+pap_uid : "&pap_uid="+pap_uid;
                if(paper.modalLastUrl != (getUrl+parame) ){
                  $("#commonDialog").removeData('bs.modal');
                }
                paper.modalLastUrl = getUrl+parame;
                $("#commonDialog").modal({remote:paper.modalLastUrl},"show");
            });
        },
        getQueryString : function(url, name) {
            url = String(url);
            url = url.substring(String(url).indexOf("?"));
            var reg = new RegExp("(^|&)" + name + "=([^&]*)(&|$)", "i");
            var r = url.substring(1).match(reg);
            if (r != null) return decodeURIComponent(r[2]); return null;
        }
    };
    paper.bindEvent = function(){
        var doc = $(document);
        //弹出、收起下拉选项
        doc.on("click",".selectVal",function(){
            if($(this).find("input").length) return;
            $(".optionWarp").not($(this).parent()).removeClass("active");
            $(this).parent().toggleClass("active");
        });
        //得分弹出、收起下拉选项
        doc.on("click",".selectFullscore .selectVal .icon, .scorePart .selectVal .icon, .selectScore .selectVal .icon",function(){
            $(".optionWarp").not($(this).parents(".optionWarp")).removeClass("active");
            $(this).parents(".optionWarp").toggleClass("active");
        });
        //科目下拉选择
        doc.on("click",".selectSubject .optionList li",function(){
            //if($(this).hasClass("active")) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
            // $(".selecGrade, .selectVersion, .selecTerm, .selectKnowledge").find(".optionList").html("");
            // $(".selecGrade, .selectVersion, .selecTerm, .selectKnowledge").find(".selectVal span").text("请选择").removeAttr("values");
            // var dataObj = {
            //     subject : $(this).attr("nameid")
            // }
            // paper.getInformation(paper.getGrade,dataObj,function(data){
            //     var html = "";
            //     for(var i=0; i<data.data.length; i++){
            //         html += '<li nameid="'+data.data[i].name+'">'+data.data[i].label+'</li>';
            //     }
            //     $(".selecGrade .optionList").html(html);
            // });
        });
        //年级下拉选择
        doc.on("click",".selecGrade .optionList li",function(){
            //if($(this).hasClass("active")) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
            // $(".selectVersion, .selecTerm, .selectKnowledge").find(".optionList").html("");
            // $(".selectVersion, .selecTerm, .selectKnowledge").find(".selectVal span").text("请选择").removeAttr("values");
            // var dataObj = {
            //     subject : $(".selectSubject li.active").attr("nameid"),
            //     grade : $(this).attr("nameid")
            // }
            // paper.getInformation(paper.getTextbook,dataObj,function(data){
            //     var html = "";
            //     for(var i=0; i<data.data.length; i++){
            //         html += '<li nameid="'+data.data[i].name+'">'+data.data[i].label+'</li>';
            //     }
            //     $(".selectVersion .optionList").html(html);
            // });
        });
        //教材版本下拉选择
        doc.on("click",".selectVersion .optionList li",function(){
            //if($(this).hasClass("active")) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
            // $(".selecTerm, .selectKnowledge").find(".optionList").html("");
            // $(".selecTerm, .selectKnowledge").find(".selectVal span").text("请选择").removeAttr("values");
            // var dataObj = {
            //     subject : $(".selectSubject li.active").attr("nameid"),
            //     grade : $(".selecGrade li.active").attr("nameid"),
            //     version : $(this).attr("nameid")
            // }
            // paper.getInformation(paper.getTerm,dataObj,function(data){
            //     var html = "";
            //     for(var i=0; i<data.data.length; i++){
            //         html += '<li nameid="'+data.data[i].name+'" uid="'+data.data[i].node_uid+'">'+data.data[i].label+'</li>';
            //     }
            //     $(".selecTerm .optionList").html(html);
            // });
        });
        //学期下拉选择
        doc.on("click",".selecTerm .optionList li",function(){
            //if($(this).hasClass("active")) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
            // $(".selectKnowledge").find(".optionList").html("");
            // $(".selectKnowledge").find(".selectVal span").text("请选择").removeAttr("values");
            // var dataObj = {
            //     node_uid:$(".selecTerm .optionList li.active").attr("uid")
            // }
            // paper.getInformation(paper.getPaperUnit,dataObj,function(data){
            //     var html = "";
            //     for(var i=0; i<data.catalogs.length; i++){
            //         html += '<li nameid="'+data.catalogs[i].uid+'">'+data.catalogs[i].node+'</li>';
            //     }
            //     $(".selectKnowledge .optionList").html(html);
            // });
        });
        //知识点范围下拉选择
        // doc.on("click",".selectKnowledge .optionList li",function(){
        //     var arr = [], that = $(this), text;
        //     that.toggleClass("active");
        //     that.parent().find("li.active").each(function(){
        //         arr.push($(this).text());
        //     });
        //     text = arr.length ? arr.join(",") : "请选择";
        //     that.parents(".optionWarp").find(".selectVal span").text(text);
        // });
        //得分下拉选择
        doc.on("click",".selectFullscore .optionList li, .scorePart .optionList li, .selectScore .optionList li",function(){
            //if($(this).hasClass("active")) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal input").val($(this).text());
            if(!$(this).parents(".selectScore").length && $(".analyze .textLabelWarp").length==1){
                var that = $(this),
                    other = $(".selectFullscore, .scorePart").not(that.parents(".selectWarp"));
                other.find(".selectVal input").val($(this).text());
                other.find(".optionList li").removeClass("active").map(function(i,item){
                    if($(item).text()==that.text()) $(item).addClass("active");
                });
            }else if($(this).parents(".scorePart").length && $(".analyze .textLabelWarp").length>1){
                var fullscore = 0;
                $(".analyze .textLabelWarp").each(function(){
                    fullscore += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
                });
                $(".selectFullscore").find(".selectVal input").val(fullscore);
                $(".selectFullscore").find(".optionList li").removeClass("active").map(function(i,item){
                    if(parseFloat($(item).text())==fullscore) $(item).addClass("active");
                });
            }
            $(".saveWarp .saveBtn").addClass("active");
            paper.changeState = true;
        });
        //得分点input on keyup
        doc.on("keyup",".selectFullscore .selectVal input, .scorePart .selectVal input",function(){
            paper.baseFn.calQizpointFullScore($(this));
        });
        //测试类型、难度、题型下拉选择
        doc.on("click",".selectCommon .optionList li",function(){
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("values"));
            if($(this).parents(".part4").length){
                $(".saveWarp .saveBtn").addClass("active");
                paper.changeState = true;
            }
        });
        //普通下拉选择
        doc.on("click",".optionList li",function(){
            //科目学期等单独绑定
            if($(this).parents(".different").length) return;
            $(this).addClass("active").siblings().removeClass("active");
            $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).text());
            if($(this).parents(".part4").length){
                $(".saveWarp .saveBtn").addClass("active");
                paper.changeState = true;
            }
            var html = "", index = $(this).index();
            // //选择的省
            // if($(this).parents(".selectProvince").length){
            //     for(var k=0; k<china_city["0_"+index].length; k++){
            //         html += '<li>' + china_city["0_"+index][k] + '</li>';
            //     }
            //     $(".selectCity, .selectCounty").find(".selectVal span").text("请选择").removeAttr("values");
            //     $(".selectCounty .optionList").html("");
            //     $(".selectCity .optionList").html(html);
            // //选择市
            // }else if($(this).parents(".selectCity").length){
            //     var provinceIndex = $(".selectProvince .optionList li.active").index(),
            //         key = "0_" + provinceIndex + "_" + index;
            //     for(var k=0; k<china_city[key].length; k++){
            //         html += '<li>' + china_city[key][k] + '</li>';
            //     }
            //     $(".selectCounty").find(".selectVal span").text("请选择").removeAttr("values");
            //     $(".selectCounty .optionList").html(html);
            // }
        });
        //自定义题顺
        doc.on("keyup",".customQuizOrder > input, .customScoreOrder > input",function(){
           if($(this).val().length){
                $(".saveWarp .saveBtn").addClass("active");
                paper.changeState = true;
            }
        });
        //试卷大纲
        //doc.on("click",".selectQuizPaperOutline, .selectScorePaperOutline",function(){
        doc.on("click",".selectQuizPaperOutline",function(){
            $(".saveWarp .saveBtn").addClass("active");
            paper.changeState = true;
        });        
        //提交试卷基本信息
        doc.on("click",".infoBtn",function(){
            var errors = [];
            var allowSubmit = true; //允许提交
            //paper.createLoading();
            paper.paperData.information = {
                heading : $(".paperTitle1 input").val(),    //主标题
                subheading : $(".paperTitle2 input").val(), //副标题
                school : $(".source .school input").val(),  //学校
                quiz_date : $(".selectTestdate input").val(),   //考试时间
                // province : $(".selectProvince .selectVal span").attr("values") || "",   //省
                // city : $(".selectCity .selectVal span").attr("values") || "",   //市
                // district : $(".selectCounty .selectVal span").attr("values") || "", //县
                node_uid : $(".selecTerm  li.active").attr("uid") || "",

                subject : $(".selectSubject .selectVal span").attr("values") ? {
                    label : $(".selectSubject .selectVal span").text(),
                    name : $(".selectSubject li.active").attr("nameid")
                } : "", //科目

                grade : $(".selecGrade .selectVal span").attr("values") ? {
                    label : $(".selecGrade  .selectVal span").text(),
                    name : $(".selecGrade  li.active").attr("nameid")
                } : "", //年级

                text_version : $(".selectVersion  .selectVal span").attr("values") ? {
                    label : $(".selectVersion  .selectVal span").text(),
                    name : $(".selectVersion  li.active").attr("nameid")
                } : "", //教材版本

                term : $(".selecTerm .selectVal span").attr("values") ? {
                    label : $(".selecTerm  .selectVal span").text(),
                    name : $(".selecTerm  li.active").attr("nameid")
                } : "", //适用学期

                quiz_type : $(".selecType .selectVal span").attr("values") || "",   //考试类型
                levelword : $(".selectDifficulty .selectVal span").attr("values") || "",    //难度
                quiz_duration : $(".selectTime .selectVal span").attr("values") || "",  //考试时长
                score : $(".selectScore .selectVal input").val() || "0",  //满分值
                tenants: $.map($(".tenant_range_item_checkbox.active"), function(v,i){ 
                    return {tenant_uid: v.getAttribute("tenant_uid"), 
                            tenant_name: v.getAttribute("tenant_name"),
                            tenant_status: "",
                            tenant_status_label: ""}
                }),
                paper_outline: $(".paper_outline").val() || "",
                paper_outline_edittable: paper.paperData.information.paper_outline_edittable
            };

            paper.paperData.test = {
                ext_data_path: $(".test_config .report_ext_data_path").val() || ""
            };

            $(".selecTerm li.active").length && (paper.paperData.information.node_uid=$(".selecTerm li.active").attr("uid"));
            paper.paperData.bank_node_catalogs = [];

            $(".selectKnowledge .optionList li.active").each(function(){
                var tempObj = {
                    node : $(this).text(),
                    uid : $(this).attr("nameid")    
                };
                paper.paperData.bank_node_catalogs.push(tempObj);
            });
            
            //基本信息项目检查
            var must_item_arr = [
                "heading",
                "school",
                "subject",
                "grade",
                "text_version",
                "term",
                "quiz_duration",
                "quiz_type",
                "quiz_date",
                "score",
                "levelword"
            ];
            for(var k in paper.paperData.information){
                if( (must_item_arr.indexOf(k) > -1 && !paper.paperData.information[k]) || ( k == "tenants" && paper.paperData.information[k].length == 0) ){
                    allowSubmit = false;
                    errors.push("除了副标题，所有选项都必填！(错误项：" + k +")")
                    break;
                }
            }
            //!paper.paperData.bank_node_catalogs.length && (allowSubmit = false);

            if(allowSubmit){
                paper.createLoading();
                paper.dataSave(paper.paperSaveUrl, paper.paperData, paper.gotoPaperChange);
            } else {
                alert(errors.join("\n"));
            }

            // if($(".paper_outline_edit_lock").attr("locked") == "true"){
            //     allowSubmit = false;
            //     errors.push("试卷大纲锁定中!")
            // }
        });
        //保存试题和答案的html
        doc.on("click",".change .saveHtml",function(){
            paper.createLoading();
            paper.paperData.paper_html = paper.questionEditor.getData();
            paper.paperData.answer_html = paper.answerEditor.getData();
            paper.dataValidation();
            paper.dataSave(paper.paperSaveUrl, paper.paperData);
        });
        //返回试卷基本信息
        doc.on("click",".change .prevBtn",function(){
            if($(".statistics").hasClass("error") || $(".statistics .questionNum").text()=="0"){
                alert("题目与答案数量不相符，请先完成切题！");
            }else{
                paper.createLoading();
                paper.paperData.paper_html = paper.questionEditor.getData();
                paper.paperData.answer_html = paper.answerEditor.getData();
                //校验html体与单题数组的内容，以保持对应
                paper.dataValidation();
                //题目html的目录结构，现在不需要了
                //paper.paperData.structure = paper.updateStructure();
                paper.dataSave(paper.paperSaveUrl, paper.paperData, paper.gotoPaperInfo);
            }   
        });
        doc.on("click",".change .nextBtn",function(){
            if($(".statistics").hasClass("error") || $(".statistics .questionNum").text()=="0"){
                alert("题目与答案数量不相符，请先完成切题！");
            }else{
                paper.createLoading();
                var temp = $('<div><div class="temp_question"></div><div class="temp_answer"></div></div>'),
                    question = paper.questionEditor.getData(),
                    answer = paper.answerEditor.getData();
                temp.find(".temp_question").html(question);
                temp.find(".temp_answer").html(answer);
                temp.children().each(function(){
                    $(this).children().each(function(){
                        var that = $(this);
                        (that.get(0).tagName != "DIV" || (!that.hasClass("my-timu")&&!that.hasClass("my-group")&&!that.hasClass("my-category"))) && that.remove();
                    });
                });
                paper.paperData.paper_html = temp.find(".temp_question").html();
                paper.paperData.answer_html = temp.find(".temp_answer").html();
                //校验html体与单题数组的内容，以保持对应
                paper.dataValidation();
                //题目html的目录结构，现在不需要了
                //paper.paperData.structure = paper.updateStructure();
                
                paper.dataSave(paper.paperSaveUrl, paper.paperData, paper.gotoPaperAnalysis);
            }
        });
        doc.on("click",".analysis .prevBtn",function(){
            if(paper.changeState){
                var fullScore =  $(".selectFullscore .selectVal input").val() || 0,
                    scores = 0;
                fullScore = fullScore - 0;
                $(".analyze .textLabelWarp").each(function(){
                    scores += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
                });
                if(fullScore == 0 || fullScore != scores){
                    alert("您当前未选择满分值或者得分点总值不等于满分值！");
                    return;
                }
                var target = $(this);
                paper.needSave(paper.paperSaveUrl,paper.paperData,function(){target.trigger("click")});
            }else{
                paper.gotoPaperChange(true);
            }
        });
        //树目录动画
        doc.on("click",".topNav > li > p",function(){
            var sibling = $(this).siblings("ol");
            if(sibling.is(":visible")) sibling.slideUp();
            else sibling.slideDown();
        });
        //单题得分选择题目
        doc.on("click",".subNav li.li_describe",function(){
            var that = $(this);
            if(that.hasClass("active")) return;
            if(paper.changeState){
                var fullScore =  $(".selectFullscore .selectVal input").val() || 0,
                    scores = 0;
                fullScore = fullScore - 0;
                $(".analyze .textLabelWarp").each(function(){
                    scores += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
                });
                if(fullScore == 0 || fullScore != scores){
                    alert("您当前未选择满分值或者得分点总值不等于满分值！");
                    return;
                }
                var target = $(this);
                paper.needSave(paper.paperSaveUrl,paper.paperData,function(){target.trigger("click")});
            }else{
                $(".questionType").text(that.parent().siblings("p").text());
                var html = "",
                    num = that.attr("num"),
                    part4_html = $($(".template_part4").html()),
                    question = $(".hide_question").find("[timuindex="+num+"]").clone(false),
                    answer = $(".hide_answer").find("[timuindex="+num+"]").clone(false);
                $(".remarks").val("");

                $(".part4 .information").html(part4_html.find(".information").html());
                //更新列表
                paper.baseFn.update_quiz_type_list();
                

                $(".part4 .analyze ").html(part4_html.find(".analyze ").html());
                paper.min_question.setData(question.addClass("analysis").get(0).outerHTML);
                paper.min_answer.setData(answer.addClass("analysis").get(0).outerHTML);
                $(".systemQuizOrderDisplay").text(num);

                paper.currentQuizOrder = num;
                paper.baseFn.update_paper_outline_list(".selectQuizPaperOutline", function(){});
                // paper.baseFn.update_paper_outline_list(".selectScorePaperOutline", function(){});
                $(".systemScoreOrderDisplay").text( num + "(1)");
                //显示已设置过的信息
                if(paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs.length && paper.paperData.bank_quiz_qizs[num-1]){
                    paper.currentQuiz = paper.paperData.bank_quiz_qizs[num-1];
                    var tempObj = {
                        'selectCategory' : paper.currentQuiz.cat,
                        'selectFullscore' : paper.currentQuiz.score,
                        'selectDegree' : paper.currentQuiz.levelword2
                    };
                    for(var k in tempObj){
                        $("." + k + " .optionList li").each(function(){
                            if(k == "selectFullscore") $(this).parents(".optionWarp").find(".selectVal input").val(tempObj[k]||0);
                            if($(this).text() == tempObj[k]){
                                $(this).addClass("active").siblings().removeClass("active").parents(".optionWarp").find(".selectVal span").text($(this).text()).attr("values",$(this).text());
                                $(this).parents(".optionWarp").find(".selectVal input").val($(this).text());
                                return false;
                            }
                            if($(this).attr("values") == tempObj[k]){
                                $(this).addClass("active").siblings().removeClass("active").parents(".optionWarp").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("values"));
                                $(this).parents(".optionWarp").find(".selectVal input").val($(this).text());
                                return false;
                            }
                        });
                    }
                    $(".customQuizOrder > input").val(paper.currentQuiz.custom_order || "");
                    paper.baseFn.update_paper_outline_list(".selectQuizPaperOutline", function(){
                        $(".selectQuizPaperOutline").val(paper.currentQuiz.paper_outline_id || "");
                    });
                    //是否可选
                    (paper.currentQuiz.optional)? $(".isOptional .textCheckbox").addClass("active") : $(".isOptional .textCheckbox").removeClass("active");
                    //试题是否图片
                    (paper.currentQuiz.text_is_image)? $(".text_is_image.textCheckbox").addClass("active") : $(".text_is_image.textCheckbox").removeClass("active"); 
                    //答案是否图片
                    (paper.currentQuiz.answer_is_image)? $(".answer_is_image.textCheckbox").addClass("active") : $(".answer_is_image.textCheckbox").removeClass("active");

                    $(".remarks").val(paper.currentQuiz.desc || "");
                    var template = $(".analyze .textLabelWarp").eq(0);
                    var cloneNode = template.clone(false);
                    $(".analyze .textLabelWarp").remove();
                    for(var k=0; k<paper.currentQuiz.bank_qizpoint_qzps.length; k++){
                        var thisNode = cloneNode.clone(true);
                        thisNode.find(".systemScoreOrderDisplay").text( paper.currentQuiz.order + "(" + (k+1) + ")");
                        thisNode.find(".scoreAnswer").val(paper.currentQuiz.bank_qizpoint_qzps[k].answer||"");

                        //是否主观题
                        paper.currentQuiz.bank_qizpoint_qzps[k].type=="主观" &&  thisNode.find(".is_subjective .textCheckbox").addClass("active");
                        //答案是否图片
                        paper.currentQuiz.bank_qizpoint_qzps[k].answer_is_image && thisNode.find(".score_answer_is_image .textCheckbox").addClass("active");

                        thisNode.find(".scorePart .optionList li").each(function(){
                            $(this).parents(".optionWarp").find(".selectVal input").val(paper.currentQuiz.bank_qizpoint_qzps[k].score||0);
                            if($(this).text() == paper.currentQuiz.bank_qizpoint_qzps[k].score){
                                $(this).addClass("active").siblings().removeClass("active").parents(".selectWarp").find(".selectVal span").text($(this).text());
                                $(this).parents(".optionWarp").find(".selectVal input").val($(this).text());
                                return false;
                            }
                        });
                        thisNode.find(".customScoreOrder > input").val(paper.currentQuiz.bank_qizpoint_qzps[k].custom_order || "");

                        // 页面添加得分点HTML
                        $(".analyze").append(thisNode);
                        // 修改得分点区块ID，并更新
                        var qzp_ckeditor_id = "scoreAnswerText" + k;
                        thisNode.find(".scoreAnswerText").attr("id", qzp_ckeditor_id);                        
                        var qzp_editor = CKEDITOR.replace(qzp_ckeditor_id, paper.ckeditor_params.qzp_edit);
                        qzp_editor.setData(paper.currentQuiz.bank_qizpoint_qzps[k].answer);
                    }

                    // paper.baseFn.update_paper_outline_list(".selectScorePaperOutline", function(){
                    //     for(var index in paper.currentQuiz.bank_qizpoint_qzps){
                    //         $(".selectScorePaperOutline")[index].value = paper.currentQuiz.bank_qizpoint_qzps[index].paper_outline_id;
                    //     }
                    // });
                }
                $(".subNav li").removeClass("active");
                that.addClass("active");
                $(".saveWarp .saveBtn").removeClass("active");
                paper.changeState = false;
            }
        });
        //单题解析选择题目
        doc.on("click",".subNav li.li_analysis",function(){
            var that = $(this);
            if(that.hasClass("active")) return;
            if(paper.changeState){
                var target = $(this);
                paper.needSave(paper.analysisSaveUrl,{
                    pap_uid : paper.paperData.pap_uid,
                    bank_quiz_qizs : paper.paperData.bank_quiz_qizs
                },function(){$(".subNav li.active").addClass("dispose");target.trigger("click")});
            }else{
                //显示已设置过的信息
                $(".questionType").text(that.parent().siblings("p").text());
                var num = $(this).attr("num");
                if(paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs.length && paper.paperData.bank_quiz_qizs[num-1]){
                    var html = "",
                        quiz = paper.paperData.bank_quiz_qizs[num-1],
                        typeObj = quiz_type_list,//{ting_li_li_jie:"听力理解",dan_xiang_xuan_ze:"单项选择",wan_xing_tian_kong:"完形填空",yue_du_li_jie:"阅读理解",ci_yu_yun_yong:"词语运用",bu_quan_dui_hua:"补全对话",shu_mian_biao_da:"书面表达"},
                        levelObj = {rong_yi:"容易",jiao_yi:"较易",zhong_deng:"中等",jiao_nan:"较难",kun_nan:"困难"};

                    $(".analysis_info .info_quiz_system_order span").text(quiz.order || "");
                    $(".analysis_info .info_quiz_custom_order span").text(quiz.custom_order || "");
                    $(".analysis_info .info_quiz_paper_outline span").text(quiz.paper_outline_name || "");
                    $(".analysis_info .info_type span").text(typeObj[paper.paperData.information.subject.name][quiz.cat] || "");
                    $(".analysis_info .info_difficulty span").text(levelObj[quiz.levelword2] || "");
                    $(".analysis_info .info_score span").text(quiz.score ? quiz.score+"分" : "");
                    $(".analysis_info .info_optional span").text(quiz.optional ? "是" : "否");
                    $(".analysis_q .info_right").html(quiz.text || "");
                    $(".analysis_a .info_right").html(quiz.answer || "");
                    $(".analysis_describe .info_right").html(quiz.desc || "");
                    for(var k=0; k<quiz.bank_qizpoint_qzps.length; k++){
                        html += '<div class="score_list clearfix" style="margin-bottom: 15px;"><div class="score_data analysis_score clearfix"><div class="info_left">得分点'+(k+1)+'：</div><div class="info_right"><ul>';
                        html += '<li class="info_score_system_order"><label>系统顺序：</label><span>' + quiz.bank_qizpoint_qzps[k].order + '</span></li>';
                        html += '<li class="info_score_custom_order"><label>自定义顺序：</label><span>' + quiz.bank_qizpoint_qzps[k].custom_order + '</span></li>';
                        html += '<li class="info_score_answer"><label>答案：</label><span>' + quiz.bank_qizpoint_qzps[k].answer + '</span></li>';
                        html += '<li class="info_score_point"><label>分数：</label><span>' + (quiz.bank_qizpoint_qzps[k].score ? quiz.bank_qizpoint_qzps[k].score+"分" : "") + '</span></li>';
                        html += '<li class="info_score_zhu_ke_guan"><label>主客观：</label><span>' + quiz.bank_qizpoint_qzps[k].type + '</span></li>';
                        html += '</ul></div></div>';

                        html += '<div class="score_data analysis_sanwei clearfix"><div class="info_left">三维解析：</div><div class="info_right"><ul>';
                        html += '<li class="info_knowledge"><label>知识：</label><input type="text" readonly="readonly"></li>';
                        html += '<li class="info_skill"><label>技能：</label><input type="text" readonly="readonly"></li>';
                        html += '<li class="info_ability"><label>能力：</label><input type="text" readonly="readonly"></li></ul></div></div></div>';
                    }
                    $(".score_part").html(html);

                    for(var m=0; m<quiz.bank_qizpoint_qzps.length; m++){
                        if(quiz.bank_qizpoint_qzps[m].bank_checkpoints_ckps && quiz.bank_qizpoint_qzps[m].bank_checkpoints_ckps.length){
                            var arr1 = [], arr2 = [], arr3 = [],
                                ckps = quiz.bank_qizpoint_qzps[m].bank_checkpoints_ckps;
                            for(var n=0; n<ckps.length; n++){
                                if(ckps[n].dimesion == "knowledge"){
                                    arr1.push(ckps[n].checkpoint);
                                }else if(ckps[n].dimesion == "skill"){
                                    arr2.push(ckps[n].checkpoint);
                                }else if(ckps[n].dimesion == "ability"){
                                    arr3.push(ckps[n].checkpoint);
                                }
                            }
                            arr1.length && $(".score_part .score_list").eq(m).find(".info_knowledge input").val(arr1.join("、")).attr("title",arr1.join("、"));
                            arr2.length && $(".score_part .score_list").eq(m).find(".info_skill input").val(arr2.join("、")).attr("title",arr2.join("、"));
                            arr3.length && $(".score_part .score_list").eq(m).find(".info_ability input").val(arr3.join("、")).attr("title",arr3.join("、"));
                        }
                        
                    }
                }
                $(".subNav li").removeClass("active");
                $(this).addClass("active");
                paper.changeState = false;
                if(paper.status == "editted"){
                    $(".analysis_sanwei, .sanweiSave, .detection").hide();
                }else if(paper.status == "analyzed"){
                    $(".analysis_sanwei").addClass("disabled_");
                    $(".sanweiSave, .detection").hide();
                }
            }
        });

        //是否选做题, 是否主观题, 是否图片
        doc.on("click",".textCheckbox",function(){
            paper.changeState = true;
            $(".saveWarp .saveBtn").addClass("active");
            $(this).toggleClass("active");
        });

        //Tenant范围各项
        doc.on("click",".tenant_range_item_checkbox",function(){
            $(this).toggleClass("active");
        });

        doc.on("input propertychange",".attribute input, .attribute textarea",function(){
            $(".saveWarp .saveBtn").addClass("active");
            paper.changeState = true;
        });
        //添加得分点
        doc.on("click",".addWarp .addScore",function(){
            var scroll_top = $(document).scrollTop()+200;
            var qzp_order = $(".analyze .textLabelWarp").length + 1;
            var qzp_ckeditor_id = "scoreAnswerText" + qzp_order;
            cloneNode = $(".analyze .textLabelWarp").eq(0).clone(false);
            cloneNode.find(".systemScoreOrderDisplay").text( paper.currentQuizOrder + "(" + qzp_order + ")");
            cloneNode.find(".selectVal span").text("请选择");
            cloneNode.find(".optionList li").removeClass("active");
            cloneNode.find("textarea").val("");
            cloneNode.find("input").val("0");
            cloneNode.find(".is_subjective .textCheckbox").removeClass("active");
            cloneNode.find(".scoreAnswerText").attr("id", qzp_ckeditor_id);
            $(".analyze").append(cloneNode);

            CKEDITOR.replace(qzp_ckeditor_id, paper.ckeditor_params.qzp_edit);
            window.scrollTo(0, scroll_top);
        });
        //删除得分点
        doc.on("click",".analyze .deleteIcon",function(){
            $(this).parents(".textLabelWarp").remove();
            $(".saveWarp .saveBtn").addClass("active");
            paper.changeState = true;
        });
        //点击保存按钮
        doc.on("click",".saveWarp .saveBtn",function(){
            if(!$(this).hasClass("active")) return;
            var fullScore =  $(".selectFullscore .selectVal input").val() || 0,
                scores = 0;
            fullScore = fullScore - 0;
            $(".analyze .textLabelWarp").each(function(){
                scores += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
            });
            if(fullScore == 0 || fullScore != scores){
                alert("您当前未选择满分值或者得分点总值不等于满分值！");
                return;
            }
            var index = $(".subNav li").index($(".subNav li.active")),
                target = $(".subNav li").eq(index+1);
            paper.savePaperItem();  //保存单题信息
            paper.createLoading();
            paper.dataSave(paper.paperSaveUrl,paper.paperData,function(){target.length && target.trigger("click") && window.scrollTo(0, 0)});
        });
        //整卷提交
        doc.on("click",".analysis .nextBtn",function(){
            if(paper.changeState){
                var fullScore =  $(".selectFullscore .selectVal input").val() || 0,
                    scores = 0;
                fullScore = fullScore - 0;
                $(".analyze .textLabelWarp").each(function(){
                    scores += parseFloat($(this).find(".scorePart .selectVal input").val() || 0);
                });
                if(fullScore == 0 || fullScore != scores){
                    alert("您当前未选择满分值或者得分点总值不等于满分值！");
                    return;
                }
                var target = $(this);
                paper.needSave(paper.paperSaveUrl,paper.paperData,function(){target.trigger("click")});
            }else{
                if($(".subNav li").length == $(".subNav li.dispose").length){
                    var fullScore =  paper.paperData.information.score || 0,
                        scores = 0,
                        optional_scores = 0;
                    fullScore = fullScore - 0;
                    for(var i=0; i<paper.paperData.bank_quiz_qizs.length; i++){
                        var target_qiz = paper.paperData.bank_quiz_qizs[i]; 
                        if(target_qiz.optional){
                            optional_scores = target_qiz.score;
                        } else {
                            scores += parseFloat(paper.paperData.bank_quiz_qizs[i].score || 0);
                        }
                    };
                    scores += parseFloat(optional_scores || 0 );
                    if(fullScore == 0 || fullScore != scores){
                        alert("当前的题目分数总和不等于试卷总分值，请重新修改！");
                        return;
                    }
                    paper.createLoading();
                    paper.dataSave(paper.paperSubmitUrl, paper.paperData, function(){
                        if(paper.paperData.pap_uid){
                            $.ajax({
                                url: paper.getPaperInfo,
                                type: "GET",
                                data: {pap_uid:paper.paperData.pap_uid},
                                dataType: "json",
                                success: function(data){
                                    if(data.status == 200){
                                        paper.paperData = typeof data.data=="string" ? JSON.parse(data.data) : data.data;
                                        paper.gotoAnalysisDetail();
                                    }
                                }
                            });
                        }
                    });     
                }else{
                    alert("您还有单题未编辑！");
                } 
            }
        });
        //解析保存
        doc.on("click",".sanweiSave .prevBtn",function(){
            var status = false;
            $(".info_knowledge input").each(function(){
                if($(this).val() == ""){
                    status = true;
                    return false;
                }
            });
            if(status){
                alert("您有知识点未选择！");
                return;
            }
            var index = $(".subNav li").index($(".subNav li.active")),
                target = $(".subNav li").eq(index+1);
            paper.createLoading();
            paper.dataSave(paper.analysisSaveUrl,{
                pap_uid : paper.paperData.pap_uid,
                bank_quiz_qizs : paper.paperData.bank_quiz_qizs
            },function(){$(".subNav li.active").addClass("dispose");target.length && target.trigger("click") && window.scrollTo(0, 0)});
        });
        //解析提交
        doc.on("click",".sanweiSave .nextBtn",function(){
            if(paper.changeState){
                var target = $(this);
                paper.needSave(paper.analysisSubmitUrl,{
                    pap_uid : paper.paperData.pap_uid,
                    bank_quiz_qizs : paper.paperData.bank_quiz_qizs
                },function(){$(".subNav li.active").addClass("dispose");target.trigger("click")});
            }else{
                if($(".subNav li").length == $(".subNav li.dispose").length){
                    paper.createLoading();
                    paper.dataSave(paper.analysisSubmitUrl,{
                        pap_uid : paper.paperData.pap_uid,
                        bank_quiz_qizs : paper.paperData.bank_quiz_qizs
                    }, function(){
                        var pap_uid = paper.getQueryString(location.href,"pap_uid");
                        if(pap_uid){
                            location.reload();
                        }else{
                            $(".contentBody").html("");
                            location.href = paper.paperUrl+"?pap_uid="+paper.paperData.pap_uid;
                        }
                    });
                }else{
                    alert("您还有单题未解析！");
                } 
            }
        });
        //弹出三维选择模块
        doc.on("click",".analysis_sanwei input",function(){
            var tabIndex = $(this).parent().index();
            if($(this).parents(".analysis_sanwei").hasClass("disabled_")) return;
            var num = $(".subNav li.active").attr("num") || 1,
                index = $(this).parents(".score_list").index(),
                data = paper.paperData.bank_quiz_qizs[num-1].bank_qizpoint_qzps[index].bank_checkpoints_ckps || undefined;
            $(this).parents(".score_list").addClass("open").siblings().removeClass("open");
            $("#commonDialog").modal({remote:"/checkpoints/dimesion_tree"},"show");
            $(document).trigger("modal:open",{dataArr:data,tabIndex:tabIndex});
        });
        doc.on("modal:close",function(e,obj){
            $(".analysis_sanwei input").val();
            var arr1 = [], arr2 = [], arr3 = [],
                num = $(".subNav li.active").attr("num") || 1,
                index = $(".score_part .score_list.open").index();
            paper.changeState = true;
            var dataArr = (obj && obj.dataArr) ? obj.dataArr : "";
            if(dataArr && dataArr.length){
                paper.paperData.bank_quiz_qizs[num-1].bank_qizpoint_qzps[index].bank_checkpoints_ckps = dataArr;
                for(var k=0; k<dataArr.length; k++){
                    if(dataArr[k].dimesion == "knowledge"){
                        arr1.push(dataArr[k].checkpoint);
                    }else if(dataArr[k].dimesion == "skill"){
                        arr2.push(dataArr[k].checkpoint);
                    }else if(dataArr[k].dimesion == "ability"){
                        arr3.push(dataArr[k].checkpoint);
                    }
                }
                arr1.length ? $(".score_part .score_list.open .info_knowledge input").val(arr1.join("、")).attr("title",arr1.join("、")):$(".score_part .score_list.open .info_knowledge input").val("").removeAttr("title");
                arr2.length ? $(".score_part .score_list.open .info_skill input").val(arr2.join("、")).attr("title",arr2.join("、")) : $(".score_part .score_list.open .info_skill input").val("").removeAttr("title");
                arr3.length ? $(".score_part .score_list.open .info_ability input").val(arr3.join("、")).attr("title",arr3.join("、")) : $(".score_part .score_list.open .info_ability input").val("").removeAttr("title");
            }else{
                paper.paperData.bank_quiz_qizs[num-1].bank_qizpoint_qzps[index].bank_checkpoints_ckps = undefined;
                $(".score_part .score_list.open .analysis_sanwei input").val("").removeAttr("title");
            }
            $(".score_part .score_list.open").removeClass("open");
            $('#commonDialog').modal('hide');
        });

        $("#commonDialog").on("hidden.bs.modal",function(e){
            var task_uid = $("input#task_uid").val();
            if(task_uid){
                paper.paperData.task_uid = task_uid;
            }
        });

        doc.on("click", ".preview_paper_outline", function(e){
            paper.baseFn.preview_paper_outline();
        });

        doc.on("click", ".paper_outline_edit_lock", function(e){
            paper.baseFn.toggle_paper_outline_edit();
        });

        doc.on("click", ".check_all_tenants", function(e){
            paper.baseFn.check_all_tenants();
        });

        doc.on("click", ".clear_check_all_tenants", function(e){
            paper.baseFn.clear_check_all_tenants();
        });    
    }
    //生成loading
    paper.createLoading = function(){
        var loading = $('<div class="loadingWarp"><img src="/images/zhengjuan/loading.gif" alt=""></div>');
        $("body").append(loading);
    }
    //删除loading
    paper.removeLoading = function(){
        $("body .loadingWarp").remove();
    }
    //校验格式
    paper.fileVerify = function(elem){
        var bool = false,
        str = elem.val();
        if(str.length!=0){
            var reg = ".*\.(doc|docx|DOC|DOCX)";
            if(str.match(reg)) bool = true;
        }
        return bool;
    }
    //校验文件大小
    paper.sizeVerify = function(elem){
        var bool = false,
            fileSize = 0,
            isIE = /msie/i.test(navigator.userAgent) && !window.opera;
        if (isIE && !elem.get(0).files) {
            var filePath = elem.get(0).value;      
            var fileSystem = new ActiveXObject("Scripting.FileSystemObject");         
            var file = fileSystem.GetFile (filePath);      
            fileSize = file.Size;     
        }else{
            fileSize = elem.get(0).files[0].size;
        }
        fileSize = fileSize /5120;
        if(fileSize > 0 && fileSize < 1000){
            bool = true;
        }
        return bool;
    }
    //文件上传后的回调
    paper.uploadCallback = function(data){
        if(!data) return;
        $(".loadingWarp").remove();
        data.pap_uid && (paper.paperData.pap_uid = data.pap_uid);
        paper.paperData.orig_file_id = data.orig_file_id;
        paper.paperData.paper_html = paper.editorControl.adjustHtml(data.paper_html);
        paper.paperData.answer_html = paper.editorControl.adjustHtml(data.answer_html);
        paper.gotoPaperInfo();
    }
    //数据提交
    paper.dataSave = function(src,data,callback){
        $.ajax({
            url: src,
            type: "post",
            data: JSON.stringify(data),
            dataType: "json",
            contentType : "application/json",
            success: function(data){
                data.data && data.data.pap_uid && (paper.paperData.pap_uid = data.data.pap_uid);
                $(".loadingWarp, .mask").remove();
                paper.changeState = false;
                typeof callback == "function" && callback(paper.paperData);
            },
            error: function(data){
                paper.removeLoading();
                var resp_data = JSON.parse(data.responseText);
                var message = resp_data.messages ? resp_data.messages : "发生异常！"; 
                alert(message);
            }   
        });
    }
    //检测是否更改数据后未保存
    paper.needSave = function(saveUrl,paperData,callback){
        var mask = $('<div class="mask"><div class="prompt"><h5>您还未保存，请先保存！</h5><a class="toSave" href="javascript:void(0);">保存</a><a class="cancle" href="javascript:void(0);">不保存</a></div></div>');
        $("body").append(mask);
        mask.find(".toSave").on("click",function(){
            var status = paper.paperData.information.paper_status;
            if(status != "editted" && status != "analyzing"){
                paper.savePaperItem();
            }else{
                var statu = false;
                $(".info_knowledge input").each(function(){
                    if($(this).val() == ""){
                        statu = true;
                        return false;
                    }
                });
                if(statu){
                    mask.remove();
                    alert("您有知识点未选择！");
                    return;
                }
            }
            var backFunc = callback || undefined;
            paper.dataSave(saveUrl, paperData,backFunc);
        });
        mask.find(".cancle").on("click",function(){
            mask.remove();
            paper.changeState = false;
            typeof callback == "function" && callback(paper.paperData);
        });
    }
    //校验html体与单题数组的内容
    paper.dataValidation = function(){
        if(paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs.length){
            var newArr = [],
                dataArr = paper.paperData.bank_quiz_qizs,
                dom = $("<div></div>").html(paper.paperData.paper_html),
                dom2 = $("<div></div>").html(paper.paperData.answer_html);
            dom.find("div.my-timu").each(function(i){
                var timuindex = $(this).attr("timuindex") || "";
                if(timuindex && dataArr[timuindex-1]){
                    newArr[i] = dataArr[timuindex-1];
                    newArr[i].text = $(this).html();
                    newArr[i].answer = dom2.children("div.my-timu").eq(i).html();
                }
            });
            if(newArr.length){
                for(var n=0; n<newArr.length; n++){
                    if(newArr[n]){
                        newArr[n].order = n+1;
                        for(var m=0; m<newArr[n].bank_qizpoint_qzps.length; m++){
                            newArr[n].bank_qizpoint_qzps[m].order = (n+1)+"("+(m+1)+")";
                        }
                        
                    }
                }
                //更新题号及得分点序号
                paper.paperData.bank_quiz_qizs = newArr;
            }   
        }  
    }
    //读取试卷信息摘要
    paper.abstract = function(){
        $(".paperModify .paper_title").text(paper.paperData.information.heading || "");
        $(".paperModify .paper_subtitle").text(paper.paperData.information.subheading || "");
        var grade = paper.paperData.information.grade ? '<span class="grade">'+paper.paperData.information.grade.label+'</span>' : "",
            term = paper.paperData.information.term ? '<span class="term">'+paper.paperData.information.term.label+'</span>' : "",
            version = paper.paperData.information.text_version ? '<span class="version">'+paper.paperData.information.text_version.label+'</span>' : "",
            subject = paper.paperData.information.subject ? '<span class="subject">'+paper.paperData.information.subject.label+'</span>' : "",
            type = paper.paperData.information.type ? '<span class="time">'+paper.paperData.information.type+'</span>' : "",
            stringInfo = grade + term + version + subject + type;
        stringInfo && $(".paperModify .description").html(stringInfo);
    }
    //保存单题解析信息
    paper.savePaperItem = function(){
        $(".saveWarp .saveBtn").removeClass("active");
        var itemObj = {}, index = $(".subNav li.active").attr("num")-1, q_html, a_html;
        q_html = paper.itemFilter(paper.min_question.getData());
        a_html = paper.itemFilter(paper.min_answer.getData());
        itemObj.cat = $(".selectCategory .selectVal span").attr("values") || "";
        itemObj.levelword2 = $(".selectDegree .selectVal span").attr("values") || "";
        itemObj.optional = $(".isOptional .textCheckbox").hasClass("active") || false;
        itemObj.score = $(".selectFullscore .selectVal input").val() || 0;
        itemObj.text = q_html;
        itemObj.text_is_image = $(".text_is_image.textCheckbox").hasClass("active") || false;;
        itemObj.answer = a_html;
        itemObj.answer_is_image = $(".answer_is_image.textCheckbox").hasClass("active") || false;;
        itemObj.order = $(".subNav li").index($(".subNav li.active"))+1;
        itemObj.custom_order = $(".customQuizOrder > input").val() || "";
        itemObj.paper_outline_id = $(".selectQuizPaperOutline").val() || "";
        itemObj.paper_outline_name = $(".selectQuizPaperOutline option:selected").text() || "";
        itemObj.desc = $(".testAnswer .remarks").val();
        itemObj.bank_qizpoint_qzps = [];
        $(".analyze .textLabelWarp").each(function(i){
            // var cate = $(this).find(".is_subjective .textCheckbox").hasClass("active") ? "主观" : "客观";
            tempObj = {
                type : $(this).find(".is_subjective .textCheckbox").hasClass("active") ? "主观" : "客观",
                order : itemObj.order+"("+(i+1)+")",
                custom_order: $(".customScoreOrder > input")[i].value || "",
                //paper_outline_id: $(".selectScorePaperOutline")[i].value || "",
                paper_outline_id: $(".selectQuizPaperOutline").val() || "",
                paper_outline_name: $(".selectQuizPaperOutline option:selected").text() || "",
                score : $(this).find(".scorePart .selectVal input").val() || 0,

                //answer : $(this).find(".scoreAnswer").val(),
                answer: CKEDITOR.instances["scoreAnswerText" + i].getData(),
                answer_is_image: $(this).find(".score_answer_is_image .textCheckbox").hasClass("active")
            };
            itemObj.bank_qizpoint_qzps.push(tempObj);
        });
        typeof paper.paperData.bank_quiz_qizs == "undefined" && (paper.paperData.bank_quiz_qizs = []);
        paper.paperData.bank_quiz_qizs[index] = itemObj;
        $(".hide_question").find("[timuindex="+(index+1)+"]").html($(q_html).html());
        $(".hide_answer").find("[timuindex="+(index+1)+"]").html($(a_html).html());
        paper.paperData.paper_html = $(".hide_question").html();
        paper.paperData.answer_html = $(".hide_answer").html();
        $(".subNav li.active").addClass("dispose");
    }
    //单题 题目和答案的html确保div套p
    paper.itemFilter = function(html){
        var dom = $("<div></div>").html(html);
        if(!dom.children("div.my-timu").length){
            dom.html('<div class="my-block my-timu" my-typetext="题"></div>');
            dom.find(".my-timu").html(html);
        }else{
            dom.children("div.my-timu").removeClass("analysis");
        }
        return dom.html();
    }
    //更新试卷结构
    paper.updateStructure = function(){
        var StrucArr = [],
            divDom = $("<div></div>").html(paper.paperData.paper_html);
        divDom.children(function(){
            var that = $(this), tempObj = {};
            if(that.hasClass("my-category")){
                tempObj.type = "juan";
                tempObj.caption = that.find("p").text();
            }else if(that.hasClass("my-group")){
                tempObj.type = "tixing";
                tempObj.caption = that.find("p").text();
            }else if(that.hasClass("my-timu")){
                tempObj.type = "timu";
                tempObj.index = divDom.children(".my-timu").index(that);
            }
            !$.isEmptyObject(tempObj) && StrucArr.push(tempObj);
            return StrucArr;
        });
    }
    //查询报告进度
    paper.getProgress = function(){
        $.ajax({
            url: paper.get_task_status,
            type: "get",
            data: {task_uid:paper.paperData.task_uid},
            dataType: "json",
            success: function(data){
                if(data){
                    if(data.status == "success"){
                        var percent = data.process*100+"%";
                        var display_label = data.name + "(" +(data.process * 100).toFixed(2) + "%" +")";
                        $(".paperDetails > .progress_label").html(display_label);
                        $(".paperDetails > .progress .finish").css("width",percent);
                        if(data.process == 1){
                            //location.reload();
                        }/*else{
                            var percent = data.process*100+"%";
                            $(".progress .finish").css("width",percent);
                        }*/
                    }else{
                        $(".createReport a").addClass("active");
                        $(".createReport p.error").text(data.message);
                        clearInterval(paper_interVal);
                    }
                }
            },
            error: function(){
                $(".createReport a").addClass("active");
                $(".createReport p.error").text("");
                clearInterval(paper_interVal);
                alert("查询报告进度失败！");
            }
        });
    }
    //轮询请求报告进度
    paper.setInterVal = function(){
        if(!paper.paperData.task_uid) return;
        paper.getProgress();
        paper_interVal = setInterval(paper.getProgress,6000);
    }
    //从后台获取试卷年级学期等信息
    paper.getInformation = function(url,data,callback){
        $.ajax({
            url: url,
            type: "get",   
            data: data,
            dataType: "json",
            success: function(data){
                var json = {"data" : data};
                typeof callback == "function" && callback(json);
            },
            error: function(){
                alert("网络错误，请求失败");
            }   
        });
    }
    //跳转到试卷信息模块
    paper.gotoPaperInfo = function(){
        $(".zhengjuang .container").removeClass("auto");
        /*$(".navColumn .navList li").each(function(){
            if($(this).index() < 2) $(this).addClass("active");
            else $(this).removeClass("active"); 
        });*/
        $(".contentBody").html($(".template_part2").html());
        $("input.date_input").date_input();

        if(paper.paperData.information){
            if(paper.paperData.information.subject){
                var subject = paper.paperData.information.subject.name,
                s_active = $(".selectSubject .optionList li[nameid="+subject+"]");
                s_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",subject).text(s_active.text());
            }
            if(paper.paperData.information.grade){
                var grade = paper.paperData.information.grade.name,
                g_active = $(".selecGrade .optionList li[nameid="+grade+"]");
                g_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",grade).text(g_active.text());
            }
            if(paper.paperData.information.text_version){
                var version = paper.paperData.information.text_version.name,
                v_active = $(".selectVersion .optionList li[nameid="+version+"]");
                v_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",version).text(v_active.text());
            }
            if(paper.paperData.information.term){
                var term = paper.paperData.information.term.name,
                t_active = $(".selecTerm .optionList li[nameid="+term+"]");
                t_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",term).text(t_active.text());
            }
        }

        // var html = "";
        // for(var k=0; k<china_city["0"].length;k++){
        //     html += '<li>' + china_city["0"][k] + '</li>';
        // }
        // $(".selectProvince .optionList").html(html);
        //获取科目
        // paper.getInformation(paper.getSubject,{},function(data){
        //     if(data.data && data.data.length){
        //         var htm = "";
        //         for(var i=0; i<data.data.length; i++){
        //             htm += '<li nameid="'+data.data[i].name+'">'+data.data[i].label+'</li>';
        //         }
        //         $(".selectSubject .optionList").html(htm);
        //         //已选科目
        //         if(paper.paperData.information && paper.paperData.information.subject){
        //             var subject = paper.paperData.information.subject.name,
        //             s_active = $(".selectSubject .optionList li[nameid="+subject+"]");
        //             s_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",subject).text(s_active.text());
        //             paper.getInformation(paper.getGrade,{subject:$(".selectSubject .optionList li.active").attr("nameid")},function(data){
        //                 htm = "";
        //                 for(var i=0; i<data.data.length; i++){
        //                     htm += '<li nameid="'+data.data[i].name+'">'+data.data[i].label+'</li>';
        //                 }
        //                 $(".selecGrade .optionList").html(htm);
        //                 //已选年级
        //                 if(paper.paperData.information.grade){
        //                     var grade = paper.paperData.information.grade.name,
        //                     g_active = $(".selecGrade .optionList li[nameid="+grade+"]");
        //                     g_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",grade).text(g_active.text());
        //                     paper.getInformation(paper.getTextbook,{
        //                             subject:$(".selectSubject .optionList li.active").attr("nameid"),
        //                             grade:$(".selecGrade .optionList li.active").attr("nameid")
        //                         },
        //                         function(data){
        //                             htm = "";
        //                             for(var i=0; i<data.data.length; i++){
        //                                 htm += '<li nameid="'+data.data[i].name+'">'+data.data[i].label+'</li>';
        //                             }
        //                             $(".selectVersion .optionList").html(htm);
        //                             //已选教材
        //                             if(paper.paperData.information.text_version){
        //                                 var version = paper.paperData.information.text_version.name,
        //                                 v_active = $(".selectVersion .optionList li[nameid="+version+"]");
        //                                 v_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",version).text(v_active.text());
        //                                 paper.getInformation(paper.getTerm,{
        //                                         subject:$(".selectSubject .optionList li.active").attr("nameid"),
        //                                         grade:$(".selecGrade .optionList li.active").attr("nameid"),
        //                                         version:$(".selectVersion .optionList li.active").attr("nameid")
        //                                     },
        //                                     function(data){
        //                                         htm = "";
        //                                         for(var i=0; i<data.data.length; i++){
        //                                             htm += '<li nameid="'+data.data[i].name+'" uid="'+data.data[i].node_uid+'">'+data.data[i].label+'</li>';
        //                                         }
        //                                         $(".selecTerm .optionList").html(htm);
        //                                         //已选学期
        //                                         if(paper.paperData.information.term){
        //                                             var term = paper.paperData.information.term.name,
        //                                             t_active = $(".selecTerm .optionList li[nameid="+term+"]");
        //                                             t_active.addClass("active").parents(".selectWarp").find(".selectVal span").attr("values",term).text(t_active.text());
        //                                             paper.getInformation(paper.getPaperUnit,{node_uid:$(".selecTerm .optionList li.active").attr("uid")}, function(data){
        //                                                 htm = "";
        //                                                 for(var i=0; i<data.catalogs.length; i++){
        //                                                     htm += '<li nameid="'+data.catalogs[i].uid+'">'+data.catalogs[i].node+'</li>';
        //                                                 }
        //                                                 $(".selectKnowledge .optionList").html(htm);
        //                                                 //已选单元
        //                                                 if(paper.paperData.bank_node_catalogs && paper.paperData.bank_node_catalogs.length){
        //                                                     var sArr = [], tempArr = paper.paperData.bank_node_catalogs;
        //                                                     for(var i=0; i<tempArr.length; i++){
        //                                                         $(".selectKnowledge .optionList li[nameid="+tempArr[i].name+"]").addClass("active");
        //                                                         sArr.push($(".selectKnowledge .optionList li[nameid="+tempArr[i].name+"]").text());
        //                                                     }
        //                                                     $(".selectKnowledge .selectVal span").text(sArr.join(","));
        //                                                 }
        //                                             });
        //                                         }
        //                                     }
        //                                 );
        //                             }
        //                         }
        //                     );
        //                 }
        //             });
        //         }
        //     }
        // });
        if(paper.paperData.information){
            $(".paperTitle1 input").val(paper.paperData.information.heading);
            $(".paperTitle2 input").val(paper.paperData.information.subheading);
            $(".source .school label.school_name").html(paper.paperData.information.school);
            $(".selectTestdate input").val(paper.paperData.information.quiz_date);
            var tempObj = {
                // 'selectProvince' : paper.paperData.information.province,
                'selecType' : paper.paperData.information.quiz_type,
                'selectDifficulty' : paper.paperData.information.levelword,
                'selectTime' : paper.paperData.information.quiz_duration,
                'selectScore' : paper.paperData.information.score
            };
            for(var k in tempObj){
                $("." + k + " .optionList li").each(function(){
                    if(k == "selectScore") $(this).parents(".optionWarp").find(".selectVal input").val(tempObj[k]||0);
                    if($(this).text() == tempObj[k]){
                        $(this).addClass("active").siblings().removeClass("active").parents(".optionWarp").find(".selectVal span").text($(this).text()).attr("values",$(this).text());
                        return false;
                    }
                    if($(this).attr("values") == tempObj[k]){
                        $(this).addClass("active").siblings().removeClass("active").parents(".optionWarp").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("values"));
                        return false;
                    }
                });
            }
            // //存在“省”
            // if(paper.paperData.information.province){
            //     var html1 = "",
            //         pIndex = $(".selectProvince .optionList li.active").index(),
            //         key = "0_" + pIndex;
            //     for(var k=0; k<china_city[key].length; k++){
            //         if(paper.paperData.information.city == china_city[key][k]){
            //             html1 += '<li class="active">' + china_city[key][k] + '</li>';
            //         }else{
            //             html1 += '<li>' + china_city[key][k] + '</li>';
            //         }
            //     }
            //     $(".selectCity .optionList").html(html1);
            //     var active_city = $(".selectCity .optionList li.active");
            //     active_city.length && $(".selectCity .selectVal span").attr("values",active_city.text()).text(active_city.text());
            // }
            // //存在“市”
            // if(paper.paperData.information.city){
            //     var html2 = "",
            //         pIndex = $(".selectProvince .optionList li.active").index(),
            //         cIndex = $(".selectCity .optionList li.active").index();
            //         key = "0_" + pIndex + "_" + cIndex;
            //     for(var k=0; k<china_city[key].length; k++){
            //         if(paper.paperData.information.district == china_city[key][k]){
            //             html2 += '<li class="active">' + china_city[key][k] + '</li>';
            //         }else{
            //             html2 += '<li>' + china_city[key][k] + '</li>';
            //         }
            //     }
            //     $(".selectCounty .optionList").html(html2);
            //     var active_county = $(".selectCounty .optionList li.active");
            //     active_county.length && $(".selectCounty .selectVal span").attr("values",active_county.text()).text(active_county.text());
            // }
        }

        if(paper.paperData.information && paper.paperData.information.tenants){
            var target_tenant_uids = $.map(paper.paperData.information.tenants, function(v){ return v.tenant_uid});
            $(".tenant_range_check_list .tenant_range_item_checkbox").each(function(){
                if(target_tenant_uids.includes($(this)[0].getAttribute("tenant_uid"))){
                    $(this).addClass("active");
                }
            });
        }
        if(paper.paperData.information && paper.paperData.information.paper_outline){
            $(".paper_outline").text(paper.paperData.information.paper_outline);
        }

        if(paper.paperData.test && paper.paperData.test.ext_data_path){
            $(".test_config .report_ext_data_path").val(paper.paperData.test.ext_data_path);
        }        
    }
    //跳转到单题切分模块
    paper.gotoPaperChange = function(){
        $(".zhengjuang .container").addClass("auto");
        $(".hide_question, .hide_answer").remove();
        /*$(".navColumn .navList li").each(function(){
            if($(this).index() < 3) $(this).addClass("active");
            else $(this).removeClass("active"); 
        });*/
        $(".contentBody").html($(".template_part3").html());
        paper.abstract();
        // var parameter = {
        //     toolbar : [
        //         { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Subscript', 'Superscript', 'SpecialChar', 'RemoveFormat'] },
        //         { name: 'paragraph', items: ['JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock', '-', 'Undo', 'Redo'] },
        //         { name: 'styles', items: ['Font', 'FontSize', 'lineheight', 'TextColor', 'BGColor'] }
        //     ],
        //     contentsCss : "/assets/zhengjuan/css/paper.css",
        //     resize_enabled : false,
        //     allowedContent: true,
        //     removePlugins : "elementspath,magicline,link,anchor",
        //     height : 500
        // };
        paper.questionEditor = CKEDITOR.replace('questionEditor',paper.ckeditor_params.quiz_split);
        paper.answerEditor = CKEDITOR.replace('answerEditor',paper.ckeditor_params.quiz_split);
        paper.questionEditor.on("change",function(){paper.editorControl.caculatequestionCount();});
        paper.answerEditor.on("change",function(){paper.editorControl.caculatequestionCount();});
        //绑定事件
        CKEDITOR.instances["questionEditor"].on("instanceReady", function(){   
            $(this.document.$.body).on("click mousemove mouseout dblclick contextmenu keyup", function(e){
                paper.editorControl.editor_event_handler(e.type, e.target, e, paper.answerEditor);
                paper.editorControl.editor_update_handler(e.type, e.target, paper.answerEditor);
            });  
        });
        CKEDITOR.instances["answerEditor"].on("instanceReady", function(){   
            $(this.document.$.body).on("click mousemove mouseout dblclick contextmenu keyup", function(e){
                paper.editorControl.editor_event_handler(e.type, e.target, e, paper.questionEditor);
                paper.editorControl.editor_update_handler(e.type, e.target, paper.questionEditor);
            });  
        });
        var divDom = $("<div></div>").html(paper.paperData.paper_html);
        if(divDom.find("div.my-timu").length){
            paper.questionEditor.setData(paper.paperData.paper_html);
            paper.answerEditor.setData(paper.paperData.answer_html);
            paper.editorControl.caculatequestionCount();
        }else{
            paper.editorControl.init();
        }
    }
    //跳转到单题解析模块
    paper.gotoPaperAnalysis = function(){
        // paper.baseFn.update_paper_outline_list();
        $(".zhengjuang .container").removeClass("auto");
        /*$(".navColumn .navList li").each(function(){
            if($(this).index() < 4) $(this).addClass("active");
            else $(this).removeClass("active"); 
        });*/
        $(".contentBody").html($(".template_part4").html());
        paper.abstract();
        // var parameter = {
        //     toolbar : [
        //         { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Subscript', 'Superscript', 'SpecialChar', 'RemoveFormat'] },
        //         { name: 'paragraph', items: ['JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock'] },
        //         { name: 'styles', items: ['Font', 'FontSize', 'TextColor', 'BGColor'] }
        //     ],
        //     resize_enabled : false,
        //     allowedContent: true,
        //     removePlugins : "elementspath,magicline,link,anchor",
        //     height : 130
        // };
        paper.min_question = CKEDITOR.replace('min_question', paper.ckeditor_params.quiz_edit);
        paper.min_answer = CKEDITOR.replace('min_answer', paper.ckeditor_params.quiz_edit);
        CKEDITOR.instances["min_question"].on("instanceReady", function(){   
            $(this.document).on("keyup", function(e){
                paper.changeState = true;
                $(".saveWarp .saveBtn").addClass("active");
            });  
        });
        CKEDITOR.instances["min_answer"].on("instanceReady", function(){   
            $(this.document).on("keyup", function(e){
                paper.changeState = true;
                $(".saveWarp .saveBtn").addClass("active");
            });  
        });
        var hide_question = $('<div class="hide_question" style="display:none;"></div>'),
            hide_answer = $('<div class="hide_answer" style="display:none;"></div>');
        $("body").append(hide_question.html(paper.paperData.paper_html));
        $("body").append(hide_answer.html(paper.paperData.answer_html));
        var menu1 = "", menu2 = "", count = 0;
        hide_question.find(".my-group").each(function(i){
            var that = $(this);
            menu1 += '<li><p>'+that.find("p").text()+'</p><ol class="subNav"></ol></li>';
        });
        $(".sideMenu .topNav").html(menu1);
        hide_question.children("div").each(function(i){
            if($(this).hasClass("my-timu")){
                count++;
                var groupNum = $(this).prevAll(".my-group").length-1;
                groupNum < 0 && (groupNum = 0);
                $(this).attr("timuindex",count);
                $(".sideMenu .topNav > li").eq(groupNum).find("ol").append('<li class="li_describe" num="'+count+'">'+count+'.</li>');
            }
        });
        hide_answer.find(".my-timu").each(function(i){
            $(this).attr("timuindex",(i+1));
        });
        if(paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs.length){
            for(var i=0; i<paper.paperData.bank_quiz_qizs.length; i++){
                paper.paperData.bank_quiz_qizs[i] && $(".subNav li").eq(i).addClass("dispose");
            }
        }
        $(".sideMenu .topNav > li:first-child").find("ol li:first-child").trigger("click");

        paper.baseFn.update_quiz_type_list();
    }

    //跳转到解析详情模块
    paper.gotoAnalysisDetail = function(){
        $(".contentBody").html($(".template_analysis").html());
        paper.abstract();
        $("input#node_uid").val(paper.paperData.information.node_uid || "");
        $("input#pap_uid").val(paper.paperData.pap_uid || "");
        var menu1 = "", count = 0,
            tempObj = $("<div></div>").html(paper.paperData.paper_html);
        tempObj.find(".my-group").each(function(i){
            var that = $(this);
            menu1 += '<li><p>'+that.find("p").text()+'</p><ol class="subNav"></ol></li>';
        });
        $(".sideMenu .topNav").html(menu1);
        tempObj.children("div").each(function(i){
            if($(this).hasClass("my-timu")){
                count++;
                var index = 1,
                    groupNum = $(this).prevAll(".my-group").length-1;
                groupNum < 0 && (groupNum = 0);
                $(this).attr("timuindex",count);
                paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs[count-1] && paper.paperData.bank_quiz_qizs[count-1].bank_qizpoint_qzps &&  paper.paperData.bank_quiz_qizs[count-1].bank_qizpoint_qzps.length>1 && (index=paper.paperData.bank_quiz_qizs[count-1].bank_qizpoint_qzps.length);
                $(".sideMenu .topNav > li").eq(groupNum).find("ol").append('<li class="li_analysis" num="'+count+'"><span>'+count+'</span><em>('+index+'个得分点)</em></li>');
            }
        });
        
        if(paper.paperData.bank_quiz_qizs && paper.paperData.bank_quiz_qizs.length){
            for(var i=0; i<paper.paperData.bank_quiz_qizs.length; i++){
                paper.paperData.bank_quiz_qizs[i].bank_qizpoint_qzps[0].bank_checkpoints_ckps && paper.paperData.bank_quiz_qizs[i].bank_qizpoint_qzps[0].bank_checkpoints_ckps.length && $(".subNav li").eq(i).addClass("dispose");
            }
        }
        $(".sideMenu .topNav > li:first-child").find("ol li:first-child").trigger("click");
    }
    //ckeditor处理对象
    paper.editorControl = {
        // 鼠标所在特殊Dom节点的顺序号
        _index:-1,
        // 该节点的内部html数据需要保留
        _sb : "<div class='my-block my-timu' my-typetext='题'>",
        // 该节点的内部text数据需要保留
        _sb2 : "<div class='my-block my-group' my-typetext='题型'>",
        // 该节点的内部text数据需要保留
         _sb3 : "<div class='my-block my-category' my-typetext='卷'>",
        // 该节点的数据不要保留
        _sbignore : "<div class='my-block my-other' my-typetext='其他'>",
        _se : "</div>",

        init : function(){
            paper.editorControl.setPaper(paper.paperData.paper_html,paper.questionEditor,true);
            paper.editorControl.setPaper(paper.paperData.answer_html,paper.answerEditor,true);
            paper.editorControl.caculatequestionCount();
        },
        // 调配一下word转过来的html
        adjustHtml:function(editorData, bool){
            var domObj = $(editorData);
            // 去掉多余的左右互搏
            domObj.find("p").each(function(){
                var indent=0, o=$(this).get(0), need;
                if(o.style.marginLeft){
                    indent += parseInt($(o).css("marginLeft"),10);
                    need=1;
                }
                if(o.style.textIndent){
                    indent += parseInt($(o).css("textIndent"),10);
                    need=1;
                }
                if(need && indent>0){
                    $(o).prepend("<span style='display:inline-block;width:"+indent+"pt'></span>");
                }

                o.style.marginLeft = o.style.textIndent = "";
                o.style.fontFamily = "";
                if(o.style.fontSize=="12pt") o.style.fontSize = "";
            });
            domObj.find("span").each(function(o){
                var o=$(this).get(0);
                o.style.fontFamily = "";
                if(o.style.fontSize=="12pt") o.style.fontSize = "";
            });

            // 去掉多余的 div 层
            domObj.find("div > div:not([class~='my-block'])").each(function(o){
                var o=$(this).get(0);
                if(o.childElementCount==1 && o.firstElementChild.tagName=="DIV" && /my-block/.test(o.firstElementChild.className)){
                    $(o).before(o.firstElementChild);
                    $(o).remove();
                }
            });
            bool && paper.editorControl.adjustTables(domObj);
//            return domObj.html();
            //convert to html
            var tempdiv=document.createElement("div");
            for(var i=0; i <domObj.length; i++){
               tempdiv.appendChild(domObj.get(i));
            };
            return tempdiv.innerHTML;
        },
        // 从答案中找到表格式答案，提供分拆按钮
        adjustTables:function(domObj){
            domObj.find("table").each(function(){
                if($(this).hasClass("table-answer")) return true;
                var table = $(this).get(0);
                if(table.rows.length % 2 ===0){
                    if(/题/.test(table.rows[0].cells[0].innerText || table.rows[0].cells[0].textContent) &&
                       /答案/.test(table.rows[1].cells[0].innerText || table.rows[1].cells[0].textContent)
                      ){
                        table.className += "table-answer";
                    }
                }
            });
            return domObj.html();
        },
        // 计算切分出来的题目数
        caculatequestionCount : function(){
            var question_count = $('<div></div>').html(paper.questionEditor.getData()).find("div.my-timu").length,
                answer_count = $('<div></div>').html(paper.answerEditor.getData()).find("div.my-timu").length;
            $(".statistics .questionNum").text(question_count).siblings(".answerNum").text(answer_count);
            question_count != answer_count && $(".statistics").addClass("error");
            question_count == answer_count && $(".statistics").removeClass("error");
        },
        // 设置试题html到编辑器
        setPaper:function(paperHtml, editor, format){
            var ns = paper.editorControl;
            var text = paperHtml;
            if(format){
                var needmatch=0;
                text = ns.advReplace(
                    text, 
                    [["\\<p[\\s\\S]*?\\<\\/p\\>",
                      function(a,b){
                          // 卷
                          if(a[1].match(/\\s*(Ⅰ|Ⅱ|Ⅲ|Ⅳ|Ⅴ|Ⅵ|Ⅶ|Ⅷ|Ⅸ|Ⅹ)(\<[^>]+\>\s*)*[．、.]/)){
                              var r=(needmatch?(ns._se):"") + ns._sb3 + a[1];
                              needmatch = 1;
                              return r;
                          }
                          // 题型
                          else if(a[1].match(/(一|二|三|四|五|六|七|八|九|十|Ⅰ|Ⅱ|Ⅲ|Ⅳ|Ⅴ|Ⅵ|Ⅶ|Ⅷ|Ⅸ|Ⅹ|Ⅺ)(\<[^>]+\>\s*)*[．、.]/)){
                              var r=(needmatch?(ns._se):"") + ns._sb2 + a[1];
                              needmatch = 1;
                              return r;
                          }
                          // 题目
                          else if(a[1].match(/\<p[^>]*\>[^<]*(\<span[^>]*\>[()（）\s]+\<\/span\>)?(\<[^>]+\>\s*)*([1-9][\d]*)\s*(\<[^>]+\>\s*)*[．、.]/)){
                              var r=(needmatch?(ns._se):"") + ns._sb + a[1];
                              needmatch = 1;
                              return r;
                          }
                          // 其他
                          else{
                              if(needmatch){
                                  return a[1];
                              }else{
                                  var r = ns._sbignore + a[1] +  (ns._se);
                                  return r;
                              }
                          }
                      }]
                     ,
                     ["\\<table[\\s\\S]*?\\<\\/table\\>",function(a,b){
                         if(needmatch){
                             return a[2] + "<p>&nbsp;<\/p>";
                         }else{
                             needmatch = 1;
                             return ns._sbignore + "<p>" + a[2] + "</p>";
                         }
                     }]
                    ]);

                if(needmatch)text+=(ns._se);
            }
            var domObj = $("<div></div>").html(text);
            text = ns.adjustTables(domObj);
            editor.setData(text);
        },
        // 高级正则替换函数
        advReplace:function(str, reg, replace, ignore_case){
            if(!str)return "";

            var i, len,_t, m,n, flag, a1 = [], a2 = [],
                me=arguments.callee,
                reg1=me.reg1 || (me.reg1=/\\./g),
                reg2=me.reg2 || (me.reg2=/\(/g),
                reg3=me.reg3 || (me.reg3=/\$\d/),
                reg4=me.reg4 || (me.reg4=/^\$\d+$/),
                reg5=me.reg5 || (me.reg5=/'/),
                reg6=me.reg6 || (me.reg6=/\\./g),
                reg11=me.reg11 || (me.reg11=/(['"])\1\+(.*)\+\1\1$/)
            ;

            if(!$.isArray(reg)){reg=[reg,replace];}else{ignore_case=replace;}
            if(!$.isArray(reg[0])){reg=[reg];}
            for(var k=0; k<reg.length; k++){
                m= typeof reg[k][0]=='string'?reg[k][0]:reg[k][0].source;
                n= reg[k][1]||"";
                len = ((m).replace(reg1, "").match(reg2) || "").length;
                if(typeof n !='function'){
                    if (reg3.test(n)) {
                        //if only one paras and valid
                        if (reg4.test(n)) {
                            _t = parseInt(n.slice(1),10);
                            if(_t<=len)n=_t;
                        }else{
                            flag = reg5.test(n.replace(reg6, "")) ? '"' : "'";
                            i = len;
                            while(i + 1)
                                n = n.split("$" + i).join(flag + "+a[o+"+ i-- +"]+" + flag);

                            n = new Function("a,o", "return" + flag + n.replace(reg11, "$1") + flag);
                        }
                    }
                }
                a1.push(m || "^$");
                a2.push([n, len, typeof n]);
            }


            return str.replace(new RegExp("("+a1.join(")|(")+")", ignore_case ? "gim" : "gm"), function(){
                var i=1,j=0,args=arguments,p,t;
                if (!args[0]) return "";
                while ((p = a2[j++])) {
                    if ((t = args[i])) {
                        switch(p[2]) {
                            case 'function':
                                //arguments:
                                //1: array, all arguments; 
                                //2: the data position index,  args[i] is $0;
                                //3: the regexp index
                                return p[0](args, i, j-1);
                            case 'number':
                                return args[p[0] + i];
                            default:
                                return p[0];
                        }
                    }else{i += p[1]+1;}
                }
            });
        },
        // 注意：用editor删除，争取能够 undo
        deleteNode:function(node){
            // all browsers, except IE before version 9
            if (document.createRange) {
                var rangeObj = document.createRange ();
                rangeObj.selectNode (node);
                rangeObj.deleteContents ();
            }
        },
        // 富文本编辑器的自动标红匹配
        editor_update_handler:function(type, target, other){
            var ns=paper.editorControl, body=$(target).parents("body").get(0);

            if(type=="mousemove" && type=="mouseout")return;

            var selection;
            if (window.getSelection)
                selection = window.getSelection();
            else if (document.selection && document.selection.type != "Control")
                selection =document.selection;

            //current node on which cursor is positioned
            var node = target; 
            if(!node){
                return;
            }          

            do{
                node = node.parentNode;
            }while(node && node !==body && !(node.tagName=="DIV" && /my-timu/.test(node.className)));

            if(node == body){
                return;
            }
            if(!node || !(node.tagName=="DIV" && /my-timu/.test(node.className))){
                return;
            }

            // 标红
            var index=-1, top=0;
            $(body).find("div.my-timu").each(function(i){
                if($(this).get(0) == node){
                    index = i;
                    top = $(this).get(0).offsetTop - body.scrollTop;
                }
            });

            if(ns._index === index){
                return;
            }
            ns._index = index;

            // 先掉高亮
            var editorName = "#" + other.name;
            $(body).find(".my-active").removeClass("my-active");
            $(editorName).siblings(".cke").find("iframe").eq(0).contents().find(".my-active").removeClass("my-active");
            // 本区高亮
            $(node).addClass("my-active");
            // 对应的高亮
            if(index!=-1){
                var body2=$(editorName).siblings(".cke").find("iframe").eq(0).contents();
                body2.find("div.my-timu").each(function(i){
                    if(i == index){
                        //n.scrollIntoView();
                        $(body2).scrollTop($(this).get(0).offsetTop - top);
                        $(this).addClass("my-active");
                    }
                });
            }

        },
        // 富文本编辑器的鼠标事件处理
        editor_event_handler:function(type, node, e, other){
            var parent_body = $(node).parents("body"), ns = paper.editorControl;

            if(node && node.parentNode && node.tagName=="P" && node.parentNode.tagName=="DIV" /*&& /my-block/.test( node.parentNode.className)*/){
                if(type=="click"){
                    var rect = node.getBoundingClientRect(),
                        body = node.ownerDocument.body,
                        x = e.pageX - body.scrollLeft,
                        y = e.pageY - body.scrollTop;

                    if(x <= rect.left  + 12){
                        var p=node.parentNode, curCNodes;
                        if(p.tagName=="DIV" && /my-block/.test( p.className)){
                            curCNodes = p.children;
                        }

                        if(y >= rect.top -6 && y <= rect.top + 6 ){
                            // （点击上部的 ∧）尝试连接本行到上一个区块
                            if( node.parentNode.tagName=="DIV" && /my-block/.test( node.parentNode.className) && !node.previousElementSibling){
                                var preP=p.previousElementSibling;
                                // 如果上一个是区块，加入其内部后
                                if(preP && preP.tagName=="DIV" && /my-block/.test( preP.className)){
                                    $(preP).append(curCNodes);
                                }
                                //  如果上一个不是区块，脱本区块的dom壳即可
                                else{
                                    if(preP)
                                        $(preP).after(curCNodes);
                                    else{
                                        if(p.parentNode){
                                            $(p.parentNode).prepend(curCNodes);
                                        }
                                    }
                                }
                                if(curCNodes)
                                    $(p).remove();
                            }
                            // （点击 ✂）尝试分离上一个区块，并开始新的区块
                            else{
                                // 生成一个区块
                                var nP=$(ns._sb),tail,arr=[];

                                // 如果node原来是在区块中，分离到一个新区块
                                if(curCNodes){
                                    $(p).after(nP);
                                    for(var i=0,l=curCNodes.length;i<l;i++){
                                        if(tail || curCNodes[i]===node){
                                            tail=true;
                                            arr.push(curCNodes[i]);
                                        }
                                    }
                                    nP.append(arr);
                                }
                                // 如果node原来不是在区块中，加区块的dom壳即可
                                else{
                                    // 抛弃掉没有用的dom包
                                    var pp = node;
                                    while(pp.parentNode && pp.parentNode.firstElementChild ===pp.parentNode.lastElementChild ){
                                        pp = pp.parentNode;
                                    }
                                    if(pp.parentNode==body){
                                        pp = node;
                                    }
                                    $(pp).after(nP);
                                    nP.append(node);
                                    if(pp !== node){
                                        $(pp).remove();
                                    }
                                }
                            }

                            ns.caculatequestionCount();
                        }
                        else if(y >= rect.bottom - 8 && y <= rect.bottom + 4 ){
                            // （点击下部的 ∨）尝试连接本行到下一个区块
                            if(node.parentNode.tagName=="DIV" && /my-block/.test( node.parentNode.className) && !node.nextElementSibling){
                                var nextP=p.nextElementSibling;
                                // 如果下一个是区块，加到其内部前
                                if(nextP && nextP.tagName=="DIV" && /my-block/.test( nextP.className)){
                                    $(nextP).prepend(curCNodes);
                                }
                                //  如果下一个不是区块，脱本区块的dom壳即可
                                else{
                                    if(nextP)
                                        $(nextP).after(curCNodes);
                                    else{
                                        if(p.parentNode){
                                            $(p.parentNode).append(curCNodes);
                                        }
                                    }
                                }
                                if(curCNodes)
                                   $(p).remove();
                            }
                            // （点击 ✂）尝试分离下一个区块
                            else{
                                // 生成一个区块
                                var nP=$(ns._sb),tail, arr=[];

                                // 如果node原来是在区块中，分离到一个新区块
                                if(curCNodes){
                                    $(p).after(nP);
                                    for(var i=0,l=curCNodes.length;i<l;i++){
                                        if(tail){
                                            arr.push(curCNodes[i]);
                                        }
                                        if(curCNodes[i]===node){
                                            tail=true;
                                        }
                                    }
                                    nP.append(arr);
                                }
                                // 如果node原来不是在区块中，加区块的dom壳即可
                                else{
                                    // 抛弃掉没有用的dom包
                                    var pp = node;
                                    while(pp.parentNode && pp.parentNode.firstElementChild ===pp.parentNode.lastElementChild ){
                                        pp = pp.parentNode;
                                    }
                                    if(pp.parentNode==body){
                                        pp = node;
                                    }
                                    $(pp).after(nP);
                                    nP.append(node);
                                    if(pp !== node){
                                       $(pp).remove();
                                    }
                                }
                            }
                            ns.caculatequestionCount();
                        }
                    }                    
                }
                // 鼠标hover提示
                else if (type=="mousemove"){
                    var rect = node.getBoundingClientRect(),
                        body = node.ownerDocument.body,
                        x = e.pageX - body.scrollLeft,
                        y = e.pageY - body.scrollTop;

                    if(x <= rect.left + 12){
                        if(y >= rect.top -6 && y <= rect.top + 6 ){
                            if(node.parentNode.tagName=="DIV" && /my-block/.test( node.parentNode.className) && !node.previousElementSibling)
                                node.title = "链接本行到上一区块";
                            else 
                                node.title = "将本行作为区块开始行";
                        }else if(y >= rect.bottom - 8 && y <= rect.bottom + 4 ){
                            if(node.parentNode.tagName=="DIV" && /my-block/.test( node.parentNode.className) && !node.nextElementSibling)
                                node.title = "链接本行到下一区块";
                            else 
                                node.title = "将本行作为区块结束行";
                        }else{
                            node.title = "";
                        }
                    }else{
                        node.title = "";
                    }

                }
                else if (type=="mouseout"){
                    node.title = "";
                }
            }
            // 标识成题目或非题目
            else if(node.tagName=="DIV" && /my-block/.test(node.className)){
                if(type=="click"){
                    var rect = node.getBoundingClientRect(),
                        body = node.ownerDocument.body,
                        x = e.pageX - body.scrollLeft,
                        y = e.pageY - body.scrollTop,
                        totype;

                    if(x <= rect.left  + 32){
                        var n=$(node);

                        if(n.hasClass("my-timu")){
                            n.removeClass("my-timu my-category my-group my-other");
                            n.attr("my-typetext","题型");
                            n.addClass("my-group");
                            totype = "noquestion";
                        }else if(n.hasClass("my-group")){
                            n.removeClass("my-timu my-category my-group my-other");
                            n.attr("my-typetext","卷");
                            n.addClass("my-category");
                            totype = "noquestion";                        
                        }else if(n.hasClass("my-category")){
                            n.removeClass("my-timu my-category my-group my-other");
                            n.attr("my-typetext","其他");
                            n.addClass("my-other");
                            totype = "noquestion";                        
                        }else{
                            n.removeClass("my-timu my-category my-group my-other");
                            n.attr("my-typetext","题");
                            n.addClass("my-timu");                                      
                            totype = "question";
                        }   

                        ns.caculatequestionCount();
                    }else if(x >= rect.right - 16){
                        if(y >= rect.top && y <= rect.top + 16 ){
                            // 用editor删除一个区块
                            //xui(node).remove();
                            ns.deleteNode(node);
                        }
                    }

                    if(totype && ns._index!=-1){
                        if(totype=="noquestion"){
                            var editorName = "#" + other.name;
                            parent_body.find(".my-active").removeClass("my-active");
                            $(editorName).siblings(".cke").find("iframe").eq(0).contents().find(".my-active").removeClass("my-active");
                        }
                        ns._index=-1;
                    }
                    ns.caculatequestionCount();
                }
                // 标识成题目或非题目
                else if(type=="mousemove"){
                    var rect = node.getBoundingClientRect(),
                        body = node.ownerDocument.body,
                        x = e.pageX - body.scrollLeft,
                        y = e.pageY - body.scrollTop;

                    if(x >= rect.right - 16){
                        if(y >= rect.top && y <= rect.top + 16 ){
                            node.title = "本区块是冗余信息，删除！";
                        }else{
                            node.title = "";
                        }
                    }else{
                        node.title = "";
                    }
                }
                else if (type=="mouseout"){
                    node.title = "";
                }
            }
            // 答案拆解
            else if(node.tagName=="TABLE" && /table-answer/.test(node.className)){
                if(type=="click"){
                    var rect = node.getBoundingClientRect(),
                        body = node.ownerDocument.body,
                        y = e.pageY - body.scrollTop;

                    if(y <= rect.top + 1 ){
                        var l = node.rows.length,ll = l / 2, k=node.rows[0].cells.length;
                        var cell1,cell2, arr=[];
                        for(var i=0;i<ll;i++){
                            for(var j=1;j<k;j++){
                                cell1 = node.rows[i*2].cells[j];
                                cell2 = node.rows[i*2+1].cells[j];                            
                                var numb = (cell1.innerText||cell1.textContent).replace(/\s/g,"");
                                if(numb){
                                    arr.push(numb+". " + (cell2.innerText||cell2.textContent));
                                }
                            }   
                        }

                        var html = ns._sb + "<p>" + arr.join( "</p>" + ns._se + ns._sb + "<p>" ) + "</p>" + ns._se;

                        $(node.parentNode).after(html);
                        $(node).remove();
                    }
                    ns.caculatequestionCount();
                }
            }
        },
    }

    paper.init();
});
