var IntervalUpdater = function(target_obj){
	var self = this;
	this.interval_obj = null;

	this.ajax = function(){
		var options = {
		    url: target_obj.url,
		    type: "get",
		    data: target_obj.data,
		    dataType: "json",
		    success: function(data){
		    	var is_finished = target_obj.success_callback(data);
				if(is_finished){
					target_obj.is_finished = true;
					self.destroy();
				}
		    },
		    error: function(e){
		    	//console.log(e);
		    }
		};
		$.ajax(options);
	};

    this.simple_processing = function(){
    	var result = target_obj.execute();
    	if(result){
			target_obj.is_finished = true;
			self.destroy();
			target_obj.success_callback();
    	}
    };

	this.ajax_worker = function(){
		this.interval_obj = setInterval(function(){self.ajax()}, target_obj.interval_time);
	};

	this.simple_worker = function(){
		this.interval_obj = setInterval(function(){self.simple_processing()}, target_obj.interval_time);
	};

	this.destroy = function(){
		clearInterval(this.interval_obj);
	};
}

//进度条的定时更新
var ProgressBarUpdater = function(target, task_uid, job_uid){
	this.target = target;
	this.url = "/monitors/get_task_status";
	this.data = {task_uid: task_uid};
	this.job_uid = job_uid;
	this.updater =  new IntervalUpdater(this);
	this.interval_time = 10000;
	this.is_finished = false;
	
	this.success_callback = function(data){
		var self = this;
		var items = $.grep(data.jobs, function(e){ return e.job_uid == self.job_uid; });
		self.target.style.width = items[0].progress*100+"%";
		self.target.innerHTML = (items[0].progress*100).toFixed(0)+"%";
		return (items[0].progress >= 1);
	}

	this.run = function(){
		this.updater.ajax_worker();
	}
}

//
var MonitorMultipleUpdaters = function(){
	this.updater_objs = [];
	this.updater = new IntervalUpdater(this);
	this.interval_time = 10000;
	this.is_finished = false;

	this.execute = function(){
		for(var i in this.updater_objs){
			if(!this.updater_objs[i].is_finished){
				return false
			}
		}
		return true;
	}

	this.success_callback = function(){
		location.reload();
	}

	this.run = function(){
		this.updater.simple_worker();
	}
}
