//= require bootstrapValidator.min
//= require_directory ./cropper
//= require jquery_lib/jquery-rebox
//= require_self

$(document).on('ready page:load', function (){
	// $('#testtable').bootstrapTable('hideColumn','id');
	// 	$('#logtable').bootstrapTable('hideColumn','id');
	$('.filterControl input').attr('placeholder','请输入关键字进行搜索');

		//基本信息验证
		$('#basicinfoForm').bootstrapValidator({
				// live: 'disabled',
				locale: 'zh_CN',
				message: '此项不能为空',
				feedbackIcons: {
					valid: 'glyphicon glyphicon-ok',
					invalid: 'glyphicon glyphicon-remove',
					validating: 'glyphicon glyphicon-refresh'
				},
				fields: {
					name: {
						message: '请填写姓名',
						validators: {
							notEmpty: {
								message: '此项不能为空'
							},
							regexp: {
								regexp:  /^[\u4e00-\u9fa5]{2,20}$/,
								message: '请填写正确的姓名'
							}
						}
					},
					subject: {
						message: '请填写学科',
						validators: {
							notEmpty: {
								message: '此项不能为空'
							},
							regexp: {
								regexp:  /^[\u4e00-\u9fa5]{0,}$/,
								message: '请填写正确的学科名称'
							}
						}
					},
					mobile: {
						message: '请填写手机号',
						validators: {
							notEmpty: {
								message: '此项不能为空'
							},
							regexp: {
								regexp: /^(13[0-9]|15[012356789]|17[678]|18[0-9]|14[57])[0-9]{8}$/,
								message: ''
							}
						}
					},
					email: {
						validators: {
							emailAddress: {
								message: '请输入正确的邮箱地址'
							}
						}
					},
				}
			});

		//忘记密码第二步提交
		$(".password_step_two").on("submit", function(e){
		 	
	 	$form = $(this);
		$.post($form.attr('action'), $form.serialize(), function(data){
			console.log(data);
			if(data.status == 200){
				window.location = "/users/password/edit?reset_password_token=" + data.data;
			}
			else{
				error_show(data.data);
			}
		}).error(function(){
			error_show('出现错误信息');
		})
		 e.preventDefault();
	});

		//基本信息编辑
		$(".edit").click(function(){
			$("#basicinfo-view").hide();
			$("#basicinfo-edit").show();
		});

		$("#affirm").click(function(){
			$("#basicinfo-view").show();
			$("#basicinfo-edit").hide();
		});

		//年级、科目等筛选
		$("#data_filter select").on('change', function(data){
			var url = window.location.pathname;
			var form_params = $("#data_filter").serialize();

			url_to(url + '?' + form_params);
		});

		$("#keyword").on("keydown",function(event){      
			if(event.keyCode==13){  
				var url = window.location.pathname;
				url_to(url + '?keyword=' + this.value);
			}      
		});  

		$("#keyword_filter").on('click', function(){
			var url = window.location.pathname;
			url_to(url + '?keyword=' + $('#keyword').val());
		})

		//倒计时
		var wait=60; 
		function time(o) { 
			if (wait == 0) { 
				o.removeAttribute("disabled");	
				o.value="发送验证码"; 
				wait = 60; 
			} else { 
				o.setAttribute("disabled", true); 
				o.value="重新发送(" + wait + ")"; 
				wait--; 
				setTimeout(function() { 
					time(o) 
				}, 
				1000) 
			} 
		}

		//发送完善资料短信验证码
		$("#send_mobile_auth_number").on('click', function(){
			var mobile = $("#analyzer_user_phone").val();
			send_auth_number_sms(mobile, '/messages/send_sms_auth_number', this);
		});

		//发送绑定手机短信验证码
		$("#send_binding_mobile_auth_number").on('click', function(){
			var mobile = $("#user_phone").val();
			send_auth_number_sms(mobile, '/messages/send_sms_auth_number', this);
		});

		//发送忘记密码短信验证码
		$("#send_sms_forgot_password").on('click', function(){
			var mobile = $("#user_login_password").val();
			send_auth_number_sms(mobile, '/messages/send_sms_forgot_password', this);
		});

		function send_auth_number_sms(mobile, url, node){
			if(mobile == ''){
				alert('请输入手机号');
				return false;
			}
			time(node);
			$.post(url, {mobile: mobile}, function(data){
				if(data.status == 200){
					alert(data.data);
				}
				else{
					error_show(data.data);
					wait = 0;
					time(node);
				}
			});
		}

		//发送邮件验证码
		$("#send_email_auth_number").on('click', function(){			
			var email = $("#analyzer_user_email").val();
			send_auth_number_email(email, '/messages/send_email_auth_number', this)
		});

		//绑定邮箱发送邮件验证码
		$("#send_binding_email_auth_number").on('click', function(){			
			var email = $("#user_email").val();
			send_auth_number_email(email, '/messages/send_email_auth_number', this)
		});

		//发送忘记密码邮件验证码
		$("#send_email_forgot_password").on('click', function(){			
			var email = $("#user_login_password").val();
			send_auth_number_email(email, '/messages/send_email_forgot_password', this)
		});

		function send_auth_number_email(email, url, node){
			if(email == ''){
				alert('请输入邮箱');
				return false;
			}
			time(node);
			$.post(url, {email: email}, function(data){
				if(data.status == 200){
					alert(data.data);
				}
				else{
					error_show(data.data);
					wait = 0;
					time(node);
				}
			});
		}

		// 修改密码
		$('#passwordForm').bootstrapValidator({
				// live: 'disabled',
				message: '此项不能为空',
				feedbackIcons: {
					valid: 'glyphicon glyphicon-ok',
					invalid: 'glyphicon glyphicon-remove',
					validating: 'glyphicon glyphicon-refresh'
				},
				fields: {
					"user[current_password]": {
						validators: {
							notEmpty: {
								message: '原密码不能为空'
							},
						}
					},
					"user[password]": {
						validators: {
							notEmpty: {
								message: '新密码不能为空'
							}
						}
					},
					"user[password_confirmation]": {
						validators: {
							notEmpty: {
								message: '确认密码不能为空'
							},
							identical: {
								field: 'user[password]',
								message: '重复密码不一致'
							}							
						}
					},
				}
			});

	});
function mobilebind(){
	if(mobilebinding.value=="绑定")
		mobilebinding.value = "不绑定";
	else
		mobilebinding.value ="绑定";
}

function emailbind(){
	if(emailbinding.value=="绑定")
		emailbinding.value = "不绑定";
	else
		emailbinding.value ="绑定";
}

//省市县三级;

	function setAreaSelect(data){
		var $region_field = $('#region'), $region_text = $('#area-text');
				//插入省;
				insetLabel(data,$('.province-box'));
				$('.province-box li').on('click',function(){
					if(!triggerEvent($(this), $region_field, $region_text)) return false;
					var cityArr = data[$(this).index() - 1].city;
					bindEvent($(this));
					//插入市
					insetLabel(cityArr,$('.city-box'));
					$('.city-box li').on('click',function(){
						if(!triggerEvent($(this), $region_field, $region_text)) return false;
						var areaArr = cityArr[$(this).index() - 1].area;
						bindEvent($(this));
						//插入县区;
						insetLabel(areaArr,$('.area-box'));
						$('.area-box li').on('click',function(){
							if(!triggerEvent($(this), $region_field, $region_text)) return false;
							var $node = $('#top-btn-list a:eq('+$(this).parent().index()+')');
							$node.html($(this).text());
							$node.attr('name',$(this).attr('name'));

							var region = {name: [], label: []};
							$('#top-btn-list a').map(function(){
								if($(this).attr('name') && $(this).attr('name') != ''){
									region.label.push($(this).text());
									region.name.push($(this).attr('name'));
								}		
							})

							$('#area-text').text(region.label.join('/'));
							$('#region').val(region.name.join('/'));
							$('.section-box').hide();
							$("#data_filter select").trigger('change');
						})
					})
				});
				$('#top-btn-list a').on('click',function(){
					var $index = $(this).index();
					$('#top-btn-list a').eq($index).addClass('active').text('请选择').siblings('a').removeClass('active');
					$('#top-btn-list a').each(function(){
						if($(this).index() > $index){
							$(this).hide();
						}
					})
					$('#section-page ul').eq($index).show().siblings('ul').hide();
				})
			}
			//插入标签;
			function insetLabel(arr,Node){
				var str = '<li name="">全部</li>';
				$.each(arr, function() {
					str += '<li name="'+this.name+'">'+this.label+'</li>';
				});
				Node.html(str);
			}
			//给标签绑定事件处理;
			function bindEvent(Node){
				var $index = Node.parent().index();
				var $parent = Node.parent();
				$('#top-btn-list a:eq('+$index+')').html(Node.text());
				$('#top-btn-list a:eq('+$index+')').attr('name',Node.attr('name'));
				$('#top-btn-list a:eq('+$index+')').show().next().show().addClass('active').siblings('a').removeClass('active');
				$parent.hide().next().show();
				
			}

			//判断是否跳转，否则插入数据
			function triggerEvent(node, region_field, region_text){
				if(node.attr('name') == ''){
					var region = {name: [], label: []};
					$('#top-btn-list a').map(function(){
						if($(this).attr('name') && $(this).attr('name') != ''){
							region.label.push($(this).text());
							region.name.push($(this).attr('name'));
						}						
					})
					region_field.val(region.name.join('/'));
					region_text.text(region.label.join('/'));

					$("#data_filter select").trigger('change');
					return false;
				}
				
				return true;

			}

