//= require application
$(document).on('ready page:load', function (){
  if(union_test_info)  {
    $(".unionTitle1 input").val(union_test_info.heading);
    $(".unionTitle2 input").val(union_test_info.subheading);
    var tempObj = {
      'selecTerm' : union_test_info.term,
      'selecType' : union_test_info.quiz_type,
      'selecGrade' : union_test_info.grade
      };
    for(var k in tempObj){
      $("." + k + " .optionList li").each(function(){
        if($(this).attr("nameid") == tempObj[k]){
          $(this).addClass("active").siblings().removeClass("active").parents(".optionWarp").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
          return false;
        }
      });
    }
    if(union_test_info.tenants){
      var target_tenant_uids = $.map(union_test_info.tenants, function(v){ return v.uid});
      $(".tenant_range_check_list .tenant_range_item_checkbox").each(function(){
          if(target_tenant_uids.includes($(this)[0].getAttribute("tenant_uid"))){
              $(this).addClass("active");
          }
      });
    }
    var template = $(".bank_paper_list").html();
    var union_config_test = union_test_info.union_config
    console.log(union_test_info.union_config)
    $(".form-group .union_config").val(union_config_test);
    $(".union_test_list_paper").html(template);
    new_paper_url = "/papers/new?union_test_id=" + union_test_info.id
    $(".paper_new").attr("href", new_paper_url);
    var paper_html = "";
    if (union_test_info.bank_paper_paps){
      $.map(union_test_info.bank_paper_paps, function(v){ paper_html += ("<tr><td>" + v.subject_cn  + "</td><td>"+ v.status + "</td><td>"+ v.quiz_date + "</td><td><a href='/papers/get_paper?pap_uid=" + v.pap_uid + "'>进入试卷控制</a></td>") });
    }
    $(".paper_list").html(paper_html);
    if (union_test_info.paper_report_completed){
      if(union_test_info.union_stauts != "report_generating"  && union_test_info.union_stauts != "report_completed" ) {
        $(".createReport").show();
      }
      else if(union_test_info.union_stauts == "report_generating"){
        var that = $(this);
        $(".createReport").show();
        if(!that.hasClass("active")) return;
        that.removeClass("active");
      }
    }
    // $(".createReport").show();

  }
  else{

  }


  var doc = $(document);


  doc.on("click",".selectVal",function(){
    if($(this).find("input").length) return;
    $(".optionWarp").not($(this).parent()).removeClass("active");
    $(this).parent().toggleClass("active");
  });
  //学期下拉选择
  doc.on("click"," .optionList li",function(){
      //if($(this).hasClass("active")) return;
      $(this).addClass("active").siblings().removeClass("active");
      $(this).parents(".optionWarp").removeClass("active").find(".selectVal span").text($(this).text()).attr("values",$(this).attr("nameid"));
  });
  //全选Tenant
  doc.on("click", ".check_all_tenants", function(e){
    $(".tenant_range_item_checkbox").addClass("active");
  });
  //重置Tenant
  doc.on("click", ".clear_check_all_tenants", function(e){
    $(".tenant_range_item_checkbox").removeClass("active");
  });
  //Tenant范围各项
  doc.on("click",".tenant_range_item_checkbox",function(){
      $(this).toggleClass("active");
  });

  doc.on("click",".infoBtn",function(){
    var errors = [];
    var allowSubmit = true; //允许提交
    var union_test = {
      school : $(".source .school input").val(),  //学校
      heading : $(".unionTitle1 input").val(),
      subheading: $(".unionTitle2 input").val(),
      term : $(".selecTerm .selectVal span").attr("values") ? $(".selecTerm  .selectVal span").attr("values") : "", //适用学期
      quiz_type : $(".selecType .selectVal span").attr("values") ? $(".selecType  .selectVal span").attr("values") : "", //测试类型
      grade : $(".selecGrade .selectVal span").attr("values") ? $(".selecGrade  .selectVal span").attr("values") : "", //年级
      union_config: $(".form-group .union_config").val(),
      tenants: $.map($(".tenant_range_item_checkbox.active"), function(v,i){ 
          return {tenant_uid: v.getAttribute("tenant_uid"), 
                  tenant_name: v.getAttribute("tenant_name"),
                  tenant_status: "",
                  tenant_status_label: ""}
      }),
    }
    //基本信息项目检查
    var must_item_arr = [
      "school",
      "heading",
      "grade",
      "term",
      "quiz_type"
    ];
    for(var k in union_test){
      if( (must_item_arr.indexOf(k) > -1 && !union_test[k]) || ( k == "tenants" && union_test[k].length == 0)){
          allowSubmit = false;
          errors.push("除了副标题，所有选项都必填！(错误项：" + k +")")
          break;
      }
    }
    if(union_test_info) {
      union_test["id"] = union_test_info.id
      union_test["union_stauts"] = union_test_info.union_stauts

    }
    if(allowSubmit){
        $.ajax({
            url: "/union_tests/save_union",
            type: "post",
            data: union_test,
            // data: JSON.stringify(union_test),
            // dataType: "json",
            // // contentType : "application/json",
            success: function(data){
              window.location.href="/users/my_exam"; 
            },
            error: function(data){
                var resp_data = JSON.parse(data.responseText);
                var message = resp_data.messages ? resp_data.messages : "发生异常！"; 
                alert(message);
            }   
        });
    } else {
        alert(errors.join("\n"));
    }
  });



  doc.on("click",".createReport a",function(){
    if (union_test_info.paper_report_completed) {
      var that = $(this);
      if(!that.hasClass("active")) return;
      that.removeClass("active");
      $.ajax({
          url: "/reports/generate_union_reports",
          type: "post",
          data: { union_test_id: union_test_info.id },
          dataType: "json",
          success: function(data){
              if(data && data.task_uid){
                  setTimeout(function(){
                      location.reload();
                  },3000);
              }
          },
          error: function(){
              that.addClass("active");
              alert("网络错误，请求失败");
          }   
      });
    }else{
      alert("还有试卷未生成报告，不能生成整体报告")
    }
  });

});