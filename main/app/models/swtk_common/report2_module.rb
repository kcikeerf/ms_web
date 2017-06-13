module Report2Module
  module Report2
    module_function
    
    module Group
      List1Arr = ["pupil", "project"]
      List2Arr = ["pupil", "klass", "grade", "project"]
      Individual = "individual"
      Pupil = "pupil" 
      Klass = "klass"
      Grade = "grade"
      Project = "project"
    end

    Config = Proc.new { 
      cfg = YAML.load_file(Rails.root.to_s + "/config/report.yml")
      cfg["report_plus2"]
    }.call

  end
end
