var areaObj = {
	province: null,
	city: null,
	district: null,
	tenant_uid: null,
	
	init: function(){
		areaObj.province = $('#province_rid');
		areaObj.city = $("#city_rid");
		areaObj.district = $("#district_rid");
		areaObj.tenant_uid = $("#tenant_uid");

		areaObj.province.on('change',function(){
	    	areaObj.reset_city_list();
		});

/*		areaObj.city.on('DOMNodeInserted',function(){
			reset_district_list($(this).find(':selected'));
		})*/

		areaObj.city.on('change',function(){
			areaObj.reset_district_list(areaObj.city);
		});
        if(areaObj.tenant_uid.length > 0){
			areaObj.district.on('change',function(){
				areaObj.reset_tenant_list(areaObj.city);
			});
		}
    },

    reset_city_list: function(){
    	var current_province = areaObj.province;
		if(current_province.val() != ''){
			areaObj.city.find('option').remove();
			areaObj.district.find('option:gt(0)').remove();
			$.get('/managers/areas/get_city',{province_rid:current_province.val()},function(data){
				var len = data.length;
				var str = '';
				str += '<option value="'+data[0].rid+'" selected="selected">'+data[0].name_cn+'</option>';
				for(var i=1;i<len;i++){
					str += '<option value="'+data[i].rid+'">'+data[i].name_cn+'</option>';
				}
				areaObj.city.append(str);
			});
		}else{
			areaObj.city.find('option:gt(0)').remove();
			areaObj.district.find('option:gt(0)').remove();
		}
	},

	reset_district_list: function(){
		var current_city = areaObj.city;
		if(current_city.val() != ''){
			areaObj.district.find('option').remove();
			$.get('/managers/areas/get_district',{city_rid:current_city.val()},function(data){
				var len = data.length;
				var str = '';
				for(var i=0;i<len;i++){
					str += '<option value="'+data[i].rid+'">'+data[i].name_cn+'</option>';
				}
				areaObj.district.append(str);
			})
		}else{
			areaObj.district.find('option:gt(0)').remove();
		}	
	},

	reset_tenant_list: function(){
		var current_province = areaObj.province;
		var current_city = areaObj.city;
		var current_district = areaObj.district;
		var current_tenant_uid = areaObj.tenant_uid;
		var area_rid = "";
		if(current_district.val() != ''){
          area_rid = current_district.val();
		} else if (current_city.val() != ''){
          area_rid = current_city.val();
		} else if (current_province.val() != ''){
          area_rid = current_province.val();
		}
		$('#fm')[0]["tenant_uid"].value = "";
		$("#tenant_uid").find('option').remove();
		if(area_rid != ""){
			$.get('/managers/areas/get_tenants',{area_rid: area_rid},function(data){
				var len = data.length;
				var str = '';
				for(var i=0;i<len;i++){
					str += '<option value="'+data[i].uid+'">'+data[i].name_cn+'</option>';
				}
				current_tenant_uid.append(str);
			})
		}
	}
}

$(document).ready(function(){
	areaObj.init();
});
