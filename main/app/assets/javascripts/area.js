//= require_self

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

