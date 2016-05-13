$(function(){
	var myCkeditor = {};

	myCkeditor.init = function(){
		//配置编辑器参数
		CKEDITOR.editorConfig = function( config ) {
			//工具栏配置
			config.toolbar_Mine =[
                { name: 'document', items: ['Source'] },
                { name: 'clipboard', items: ['Cut', 'Copy', 'Paste', 'PasteText', '-', 'Undo', 'Redo'] },
                { name: 'editing', items: ['Find', 'Replace', '-', 'SelectAll', '-', 'SpellChecker', 'Scayt'] },
                { name: 'basicstyles', items: ['Bold', 'Italic', 'Underline', 'Strike', 'Subscript', 'Superscript', 'SpecialChar', 'RemoveFormat'] },'/',
                { name: 'paragraph', items: ['NumberedList', 'BulletedList', '-', 'Outdent', 'Indent', '-', 'JustifyLeft', 'JustifyCenter', 'JustifyRight', 'JustifyBlock'] },
                { name: 'insert', items: ['Table', 'HorizontalRule', 'Smiley'] },
                { name: 'styles', items: ['Font', 'FontSize'] },
                { name: 'colors', items: ['TextColor', 'BGColor'] },
                { name: 'tools', items: ['Maximize', 'base64image', 'wordUpload'] }
            ];
		    config.toolbar = 'Mine';
		    //初始化高度
		    config.height = 300;
		    //初始化宽度
		    //config.width = 1000;
		    //禁止拖拽
		    config.resize_enabled = false;
		    //图片属性预览区域显示内容
		    config.image_previewText=' ';
		    //添加中文字体
		    config.font_names='微软雅黑/微软雅黑;宋体/宋体;黑体/黑体;仿宋/仿宋_GB2312;楷体/楷体_GB2312;隶书/隶书;幼圆/幼圆;'+ config.font_names;
		    //添加word上传模块
		    config.extraPlugins += (config.extraPlugins ? ',wordUpload' : 'wordUpload');

		    //过滤
		    config.disallowedContent = '*[id]; *[class]; *[href]; *[on*]; script; link; ';
		    //word文件上传地址
                   config.wordUploadUrl = "/quizs/single_quiz_file_upload";
                   //图片转码的固定地址
                   config.replaceImgcrc = "/ckeditors/urlimage?src=";
		};

		//初始化编辑器
		if($("#TextArea1").length) this.editor1 = CKEDITOR.replace('TextArea1');
		if($("#TextArea2").length) this.editor2 = CKEDITOR.replace('TextArea2');
		//绑定事件
		this.bindEvent();
		//初始化加进去的测试数据，正式使用可删除
		//this.editor1.setData('<div class="container clearfix"><a href="http://www.wqdian.com" class="pull-left n-logo"><img src="http://static.cfzb.org/upload/zhongcaixie_cms/article/20150925/1443151851184440793.jpg"><img src="http://www.wqdian.com/images/pc/n-logo.png"></a><nav class="pull-right"><ul class="menu"><li class="menu-list active"><a href="http://www.wqdian.com/index.html">首页</a></li><li class="menu-list "><a href="http://www.wqdian.com/advantage.html">产品优势</a></li><li class="menu-list "><a href="http://www.wqdian.com/theme/overall.html">模板主题</a></li><li class="menu-list "><a href="http://www.wqdian.com/casesite/overall.html">案例中心</a></li><li class="menu-list "><a href="http://www.wqdian.com/news/1.html">新闻公告</a></li><li class="menu-list"><a href="http://bbs.wqdian.com/forum-37-1.html" target="_blank">新手指南</a></li></ul><a href="http://passport.wqdian.com/register.html" class="btn btn-primary">注册</a><a href="http://member.wqdian.com/passport/login.html" class="btn btn-default">登录</a></nav></div>');
		
	};
	myCkeditor.bindEvent = function(){
		this.editor1 && this.editor1.on('change', function( event ) {myCkeditor.editorChange(this);}); 
		this.editor2 && this.editor2.on('change', function( event ) {myCkeditor.editorChange(this);}); 

		$(".saveBtn").on("click",myCkeditor.saveData);
	}
	//内容改变自动检测图片
	myCkeditor.editorChange = function(thatEditor){
		var id = "#cke_" + thatEditor.name,
			domImg = $(id).find(".cke_inner iframe").eq(0).contents().find("body img");
        domImg = domImg.filter(function(i){
            return ($(this).attr("src")||"").substring(0,5)!="data:";
        });
        if(!domImg.length) return;
        domImg.each(function(){
        	var that = $(this),
                src = that.attr("src") || "",
                imgFormat = src.match(/\.png/g) ? 'image/png' : 'image/jpeg',
                canvas = document.createElement("canvas"),
                img = new Image(),
                ctx = canvas.getContext('2d');
            img.src = thatEditor.config.replaceImgcrc + src + "&time=" + new Date().getTime();
            img.onload = function() {
            	// var htmlString = thatEditor.getData();
            	// if(htmlString.indexOf('src="http:')==-1) return;
                canvas.height = that.height(); 
                canvas.width = that.width();
                ctx.drawImage(img,0,0); 
                var dataURL = canvas.toDataURL(imgFormat);
                that.attr({"src":dataURL,"data-cke-saved-src":dataURL});
            }                 
        });
	}
	//保存操作
	myCkeditor.saveData = function(){
		var confirm = $('<div class="confirmMask" style="font-family:微软雅黑;font-size:16px;position: fixed;z-index:9998;width: 100%;height: 100%;left: 0;top: 0;background-color: rgba(0,0,0,0.4);"><div class="confirmWarp" style="position:absolute;top: 50%;left: 50%;width: 260px;height: 150px;margin:-75px 0 0 -130px; background-color: #fff;border-radius: 4px;"><p style="font-size:14px;padding:50px 0 0 40px;margin:0;">数据保存中，请稍等...</p></div></div>');
		$("body").append(confirm);
		myCkeditor.saveAjax();
	};
	//保存数据请求接口
	myCkeditor.saveAjax = function(){
		var editorDate1 = "",
			editorDate2 = "";
		if(myCkeditor.editor1) editorDate1 = myCkeditor.editor1.getData();
		if(myCkeditor.editor2) editorDate2 = myCkeditor.editor2.getData();
		$.ajax({
            url: "-----------",		//保存接口地址
            data: {html1:editorDate1, html2:editorDate2},		//参数html:编辑器返回的字符串
            type: "post",
            dataType: "json",
            success: function(data) {
                $(".confirmMask").remove();
            }
        });
	};
	
	myCkeditor.init();
});







