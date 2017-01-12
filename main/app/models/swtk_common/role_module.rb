module RoleModule
  module Role
  	module_function
  	
    Pupil="pupil"
    Teacher="teacher"
    Analyzer="analyzer"
    TenantAdministrator="tenant_administrator"
    ProjectAdministrator="project_administrator"
    NAME_ARR = %w(
    	pupil 
    	teacher 
    	analyzer 
    	tenant_administrator 
    	project_administrator
    )
  end
end
