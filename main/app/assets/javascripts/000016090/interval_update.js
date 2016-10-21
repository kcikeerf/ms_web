var IntervalUpdater = function(updater){
	this.interval_obj = null;
	this.url = updater.url;
	this.data = updater.data;
	this.updater = updater;
	this.success_callback = updater.success_func;
	this.error_callback = updater.error_func;
	this.interval_time = updater.interval_time;
}

IntervalUpdater.prototype.ajax = function(){
	var self = this;
	var options = {
	    url: this.url,
	    type: "get",
	    data: this.data,
	    dataType: "json",
	    success: function(data){
	    	self.success_callback(data);
	    },
	    error: function(e){
	    	//console.log(e);
	    }
	};
	$.ajax(options);
}

IntervalUpdater.prototype.worker = function(){
	var self = this;
	this.interval_obj = setInterval(function(){self.ajax()}, this.interval_time);
}

IntervalUpdater.prototype.destroy = function(){
	clearInterval(this.interval_obj);
} 


//进度条的定时更新
var ProgressBarUpdater = function(target, task_uid, job_uid){
	this.target = target;
	this.url = "/monitors/get_task_status";
	this.data = {task_uid: task_uid};
	this.job_uid = job_uid;
	this.updater = null;
	this.interval_time = 10000;
}

ProgressBarUpdater.prototype.success_func = function(data){
	var self = this;
	var items = $.grep(data.jobs, function(e){ return e.job_uid == self.updater.job_uid; });
	self.updater.target.style.width = items[0].progress*100+"%";
	self.updater.target.innerHTML = (items[0].progress*100).toFixed(0)+"%";
	if(items[0].progress >= 1){
		self.destroy();
		//location.reload();
	}
}

ProgressBarUpdater.prototype.error_func = function(){
	//this.target.className = "progress-bar  progress-bar-danger";
	console.log("error");
}

ProgressBarUpdater.prototype.execute = function(){
	var self = this;
	this.updater = new IntervalUpdater(self);
	this.updater.worker();
}


