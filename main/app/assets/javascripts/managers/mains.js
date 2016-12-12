// require jquery
// require jquery_ujs
//= require jquery-min
//= require easyui/jquery.easyui.min.js
//= require managers/area

$(function(){
  InitLeftMenu();
  tabClose();
  tabCloseEven();
})

//初始化左侧
function InitLeftMenu() {

    // $(".easyui-accordion").empty();
    // var menulist = "";

    // $.each(_menus.menus, function(i, n) {
    //     menulist += '<div title="'+n.menuname+'"  icon="'+n.icon+'" style="overflow:auto;">';
    //     menulist += '<ul>';
    //     $.each(n.menus, function(j, o) {
    //         menulist += '<li><div><a target="mainFrame" href="' + o.url + '" ><span class="icon '+o.icon+'" ></span>' + o.menuname + '</a></div></li> ';
    //     })
    //     menulist += '</ul></div>';
    // })

    // $(".easyui-accordion").append(menulist);
    
    $('.easyui-accordion li a').click(function(){
      var tabTitle = $(this).text();
      var url = $(this).attr("ref");
      addTab($('#tabs'), tabTitle,url);
      $('.easyui-accordion li div').removeClass("selected");
      $(this).parent().addClass("selected");
    }).hover(function(){
      $(this).parent().addClass("hover");
    },function(){
      $(this).parent().removeClass("hover");
    });

    $(".easyui-accordion").accordion();
  }

  function reopen(tab_container, subtitle, url){
    if(tab_container.tabs('exists',subtitle)){
      tab_container.tabs('close', subtitle);
    }
    addTab(tab_container,subtitle,url);
  }

  function addTab(tab_container,subtitle,url){
    if(!tab_container.tabs('exists',subtitle)){
      tab_container.tabs('add',{
        title:subtitle,
        content:createFrame(url),
        closable:true,
        width:$('#mainPanle').width()-10,
        height:$('#mainPanle').height()-26
      });
    }else{
      tab_container.tabs('select',subtitle);
      $('#mm-tabupdate').click();
    }
    tabClose();
  }

  function createFrame(url)
  {
    var s = '<iframe name="mainFrame" scrolling="auto" frameborder="0"  src="'+url+'" style="width:100%;height:100%;"></iframe>';
    return s;
  }

  function tabClose()
  {
    /*双击关闭TAB选项卡*/
    $(".tabs-inner").dblclick(function(){
      var subtitle = $(this).children("span").text();
      $('#tabs').tabs('close',subtitle);
    })

    $(".tabs-inner").bind('contextmenu',function(e){
      $('#mm').menu('show', {
        left: e.pageX,
        top: e.pageY,
      });

      var subtitle =$(this).children("span").text();
      $('#mm').data("currtab",subtitle);

      return false;
    });
  }
//绑定右键菜单事件
function tabCloseEven()
{
    //关闭当前
    $('#mm-tabclose').click(function(){
      var currtab_title = $('#mm').data("currtab");
      $('#tabs').tabs('close',currtab_title);
    })
    //全部关闭
    $('#mm-tabcloseall').click(function(){
      $('.tabs-inner span').each(function(i,n){
        var t = $(n).text();
        $('#tabs').tabs('close',t);
      }); 
    });
    //关闭除当前之外的TAB
    $('#mm-tabcloseother').click(function(){
      var currtab_title = $('#mm').data("currtab");
      $('.tabs-inner span').each(function(i,n){
        var t = $(n).text();
        if(t!=currtab_title)
          $('#tabs').tabs('close',t);
      }); 
    });
    //关闭当前右侧的TAB
    $('#mm-tabcloseright').click(function(){
      var nextall = $('.tabs-selected').nextAll();
      if(nextall.length==0){
            //msgShow('系统提示','后边没有啦~~','error');
            alert('后边没有啦~~');
            return false;
          }
          nextall.each(function(i,n){
            var t=$('a:eq(0) span',$(n)).text();
            $('#tabs').tabs('close',t);
          });
          return false;
        });
    //关闭当前左侧的TAB
    $('#mm-tabcloseleft').click(function(){
      var prevall = $('.tabs-selected').prevAll();
      if(prevall.length==0){
        alert('到头了，前边没有啦~~');
        return false;
      }
      prevall.each(function(i,n){
        var t=$('a:eq(0) span',$(n)).text();
        $('#tabs').tabs('close',t);
      });
      return false;
    });

    //退出
    $("#mm-exit").click(function(){
      $('#mm').menu('hide');
    })
  }

//弹出信息窗口 title:标题 msgString:提示信息 msgType:信息类型 [error,info,question,warning]
function msgShow(title, msgString, msgType) {
  $.messager.alert(title, msgString, msgType);
}

//创建对象
function newObj(title, url){
  $('#dlg').dialog('open').dialog('setTitle',title);
  $('#fm')[0].reset();
  $('#fm').attr('action', url);
  $('#fm')[0]["authenticity_token"].value = $('meta[name="csrf-token"]')[0].content;
  $.parser.parse($("#fm"));
  $('#manager_method').val('post');
  // var $resource_add = $("#resource_add"); //没懂啥用先保留
  // if($resource_add.length){//没懂啥用先保留
  //   // $resource_add.show();
  //   // $("#resource_edit").hide();
  //   var $html = $resource_add.clone();
  //   $html.find('div:first').attr('id', 'first')
  //   $html.attr('id', '').show();
  //   $("#other").html($html);
  //   $.parser.parse($("#fm"));
  // }//没懂啥用先保留
}

//编辑
function editObj(url){
  var row = $('#dg').datagrid('getSelected');
  if (row){
    // var $resource_edit = $("#resource_edit");//没懂啥用先保留
    // if($resource_edit.length){//没懂啥用先保留
    //   var $html = $resource_edit.clone();
    //   $html.show();
    //   $("#other").html($html);
    //   $.parser.parse($("#fm"));
    // }//没懂啥用先保留
    $('#dlg').dialog('open').dialog('setTitle','编辑');
    $('#fm').form('clear').attr('action', url);
    $('#fm')[0]["authenticity_token"].value = $('meta[name="csrf-token"]')[0].content;
    $('#fm').form('load',row).attr('action', url + (row.id == undefined ? row.uid : row.id));
    $('#manager_method').val('put');
  }
}

function editObjWithArea(url){
  var row = $('#dg').datagrid('getSelected');
  console.log(row);
  if (row){
    $('#dlg').dialog('open').dialog('setTitle','编辑');
    $('#fm').form('clear').attr('action', url);
    $('#fm')[0]["authenticity_token"].value = $('meta[name="csrf-token"]')[0].content;

    $('#fm').form('load',row).attr('action', url + (row.id == undefined ? row.uid : row.id));
    $('#fm').form('load',row);
    areaObj.reset_city_list();
    setTimeout(function(){
        $('#fm').form('load',row);
        areaObj.reset_district_list();
        setTimeout(function(){
            $('#fm').form('load',row);
            areaObj.reset_tenant_list();
            setTimeout(function(){
              $('#fm').form('load',row);
            },100);
        },100);
    }, 100);
    
    if(row.subject_classrooms){
      row.subject_classrooms = row.subject_classrooms.replace(/<br ?\/?>/g, "\n");
    }
    $('#fm').form('load',row);
    $('#manager_method').val('put');
  }
}

//保存
function saveObj(){
  $('#fm').form('submit',{

    onSubmit: function(){
      return $(this).form('validate');
    },
    success: function(result){
      result = JSON.parse(result);
      if (result.status == 200){
        $('#dlg').dialog('close');      // close the dialog
        $('#dg').datagrid('reload');    // reload the user data
      } else{
        $.messager.alert({
          title: 'Error',
          msg: result.message
        });
      }
    }
  });
}


//删除
function destroy(url){
  var rows = $('#dg').datagrid('getSelections');
  var ids_arr = [];
  $.each(rows, function(i, row){
    ids_arr.push(row.id == undefined ? row.uid : row.id)
  });
  var authenticity_token = $('meta[name="csrf-token"]')[0].content;
  if (ids_arr.length > 0){
    var url = url + 'destroy_all';
    $.messager.confirm('Confirm','你确定要删除么',function(r){
      if (r){
        $.ajax({
          type: 'delete',
          url: url, 
          data: {id: ids_arr, authenticity_token: authenticity_token},
          dataType: 'json',
          success: function(){                                
            $('#dg').datagrid('reload');    // reload the user data                             
          },
          error: function(){
            $.messager.alert({   // show error message
              title: 'Error',
              msg: '删除出现错误'
            });
          }
        });
      }
    });
  } else {
    $.messager.alert({   // show error message
              title: '提示',
              msg: '请选择要删除的行'
            });
  }
}

//指标体系
function set_ckp_dialog(url_params){
  $('#checkpoint_dialog').dialog({
    title: '指标体系',
    width: 800,
    height: 600,
    closed: false,
    cache: false,
    modal: true
  });

  $('#checkpoint_dialog').dialog('refresh', '/managers/subject_checkpoints/list?' + url_params);

  }