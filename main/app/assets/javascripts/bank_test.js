//= require application
//= require interval_update
//= require topic
//= require zhengjuan/js/area

$(document).on('ready page:load', function (){

  if(data){
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
    
    if(data.information.paper_status=='analyzed'||
      data.information.paper_status=='score_importing'||
      data.information.paper_status=='score_imported'||
      data.information.paper_status=='report_generating'||
      data.information.paper_status=='report_completed'){
      //初始化试卷详情
      switch(data.information.test_status){
      // switch("score_imported"){
        //测试开始状态为已经解析完成
        // case "editted":
        // case "analyzing":
        //     $(".lookPaperInfo").show().find(".lookPaper_sanwei").hide();
        //     $(".paper_about").show()//.find(".load_list").hide();
        //     //project administrator tenant action
        //     //$(".tenant_result_list").hide();
        //     //
        //     $(".link_paper").css("display","block");
        //     break;
        case null:
        case "new":
        case "editted":
        case "analyzing":
        case "analyzed":
            $(".lookPaperInfo, .paper_about").show()//.find(".edit_sanwei").hide();
            // if($(".tenant_result_list")){
                //$(".tenant_result_list .progress").show();
            // }
            break;
        case "score_importing":
            $(".lookPaperInfo, .paper_about").show()//.find(".edit_sanwei").hide();
            if($(".tenant_result_list")){
                $(".tenant_result_list .score_importing").show();

                var monitoring_all_tenants = new MonitorMultipleUpdaters();
                $.each($(".tenant_result_list .score_importing .progress-bar"),function(i,item){
                    var target_task_uid = data.information.import_result_task;
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
                var target_task_uid = data.information.create_report_task;
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
            // var pap_uid = paper.getQueryString(location.href,"pap_uid");
                test_uid && $(".lookReport a").attr("href",$(".lookReport a").attr("href")+"?test_uid="+test_uid);
            break;
        default:
            $(".paper_editor").css("display","block");
            break;
      }
    }
  }

  $("input.date_input").date_input();
  //下拉选择试卷列表
  $(document).on("click","#select_paper",function(){
    $(".paper_list").html('');
    $.ajax({
      url: '/api/v1.2/tests/get_pap',
      type: 'get',
      data: {
        access_token: getCookie('access_token'),
      },
      success: function(rs){
        var paper_html = "";
        $.map(rs,function(v){
          paper_html += ("<tr><td><div class='paper_item_checkbox' paper_uid='"+v.uid+"'><span></span></div></td><td>"+
            v.heading+ "</td><td>"+
            v.school+ "</td><td>"+
            v.status_label+ "</td><td>"+
            v.subject_label+ "</td></tr>")
        })
        $(".paper_list").html(paper_html);
      },
      error: function(rs){
        error(rs)
      }
    })
    $("#paper_list").modal("show")
  })

  //单选控制
  $(document).on("click",".paper_item_checkbox",function(){
    if($(this).hasClass('active')){
      $(this).removeClass('active')
    }else{
      $(".paper_item_checkbox").removeClass("active")
      $(this).addClass("active")
    }
  });

  //选择试卷
  $("#paper_selected").click(function(){
    var paper_uid = $(".paper_item_checkbox.active").attr("paper_uid")
    var html = $(".paper_item_checkbox.active").parent('td').parent('tr').children('td:eq(1)').text()
    $('#select_paper').attr('paper_uid',paper_uid)    
    $('#select_paper').find('span').html(html)
  })

  //默认选中学校,且不可更改
  $(".tenant_range_check_list .tenant_range_item_checkbox").each(function(){
      if(target_tenant_uids.includes($(this)[0].getAttribute("tenant_uid"))){
          $(this).addClass("active");
      }
  });
  $(".hint").empty()

  var doc = $(document);

  doc.on("click",".selectVal",function(){
    if($(this).find("input").length) return;
    $(".optionWarp").not($(this).parent()).removeClass("active");
    $(this).parent().toggleClass("active");
  });

  doc.on("click"," .optionList li",function(){
    //if($(this).hasClass("active")) return;
    $(this).addClass("active").siblings().removeClass("active");
    $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
  });


  //下载链接点击
  var modalLastUrl = ""
  $(".download_link, .load_list, .download_list, .tenant_result_list .download_button button").on("click",function(){
      var getUrl = $(this).attr("geturl") || "",
        parame = getUrl.indexOf("?") < 0 ? "?test_uid="+test_uid : "&test_uid="+test_uid;
      if(modalLastUrl != (getUrl+parame)&& modalLastUrl != "" ){
        $("#commonDialog").removeData('bs.modal');
      }
      modalLastUrl = getUrl+parame;
      $("#commonDialog").modal({remote: modalLastUrl},"show");
      // console.log(modalLastUrl)
  });

  //学校状态更改：状态回退，忽略学校
  $(".tenant_state_update button").on("click",function(){
    var url = $(this).attr("geturl")
    if(url){
      $.ajax({
        url: url,
        type: 'get',
        data: {
          access_token: getCookie('access_token'),
        },
        success: function(rs){
          setTimeout(function(){
            location.reload();
          },1000);
        },
        error: function(rs){
          error(rs)
        }
      })
    }
  });

  //生成报告
  $(".createReport a").on("click",function(){
    var that = $(this);
    if(!that.hasClass("active")) return;
    that.removeClass("active");
    var dataObj = {
      test_uid : test_uid,
      // province : paper.paperData.information.province,
      // city : paper.paperData.information.city,
      // district : paper.paperData.information.district,
      school : data.information.school
    };
    $.ajax({
      url: "/reports/generate_reports",
      type: "post",
      data: dataObj,
      dataType: "json",
      success: function(data){
          if(data && data.task_uid){
              setTimeout(function(){
                  location.reload();
              },3000);
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
});

function error(rs){
  switch(rs.status){
    case 401:
    case 403:
      alert('token无效，请重新登录')
      break;
    case 404:
      break;
    case 500:
      alert(rs.error_message)
      break;
  }
}