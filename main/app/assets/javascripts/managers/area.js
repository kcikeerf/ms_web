var areaObj = {
	province: null,
	city: null,
	district: null,
	tenant: null,
	
	init: function(){
		areaObj.province = $('#province_rid');
		areaObj.city = $("#city_rid");
		areaObj.district = $("#district_rid");
		areaObj.tenant = $("#tenant_uids");

		areaObj.province.combobox({
			onChange: function(){
				areaObj.reset_city_list();
			}
		});


		areaObj.city.combobox({
			onChange: function(){
				areaObj.reset_district_list();
				areaObj.reset_tenant_list();
			}
		});


		areaObj.district.combobox({
			onChange: function(){
				areaObj.reset_tenant_list();
			}
		});
    },

    reset_city_list: function(){
		areaObj.city.combobox("clear");
		$.get('/managers/areas/get_city',{province_rid:areaObj.province.combobox("getValue")},function(data){
			areaObj.city.combobox("loadData", data)
		});
	},

	reset_district_list: function(){
		areaObj.district.combobox("clear");
		$.get('/managers/areas/get_district',{city_rid:areaObj.city.combobox("getValue")},function(data){
			areaObj.district.combobox("loadData", data)
		})
	},

	reset_tenant_list: function(){
		var area_rid = "";
		//only city, district changed will get tenants
		//area_rid = "areaObj.district.combobox("getValue") ||  areaObj.city.combobox("getValue") || areaObj.province.combobox("getValue")";
		area_rid = areaObj.district.combobox("getValue") || areaObj.city.combobox("getValue") || "";
		areaObj.tenant.combobox("clear");
		$.get('/managers/areas/get_tenants',{area_rid: area_rid},function(data){
			areaObj.tenant.combobox("loadData", data)
		})
	}
}

$(document).ready(function(){
	areaObj.init();
});
