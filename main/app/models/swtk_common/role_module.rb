module RoleModule
  module Role
  	module_function
  	
    Pupil="pupil"
    Teacher="teacher"
    Analyzer="analyzer"
    TenantAdministrator="tenant_administrator"
    ProjectAdministrator="project_administrator"
    AreaAdministrator="area_administrator"
    Guest="guest"

    NAME_ARR = %w(
      guest
    	pupil 
    	teacher 
    	analyzer 
    	tenant_administrator 
    	project_administrator
      area_administrator
    )

  end
end
