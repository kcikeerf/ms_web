class UsersController < ApplicationController
	layout 'new_user'
  before_action :authenticate_user!
  before_action :set_tenant, only: [:my_analyzer, :my_teacher]
  before_action :read_papers, only: [:my_paper, :region]

	def my_home
		if current_user.is_analyzer?
			@analyzer = current_user.analyzer
	    @papers_status_to_count = {}
	    #@papers_data.group_by {|p| p.paper_status }.each do |k, v|
	    #  @papers_status_to_count[k] = v.count
	    #end
	    filter = {
	      :user_id => current_user.id
	    }
	    results = Mongodb::BankPaperPap.get_paper_status_count(filter)
	    @papers_status_to_count = results
	  end
	end

  def region
    region = Mongodb::BankPaperPap.region(@papers_data)
    render json: region.to_json
  end

  def my_paper
    user = current_user
    redirect_to my_home_users_path unless user.is_tenant_administrator? || user.is_project_administrator? || user.is_analyzer?
    subject_arr = Mongodb::BankPaperPap.get_column_arr(@papers_filter, "subject").sort{|a,b| Common::Locale.mysort(Common::Subject::Order[a.nil?? "":a.to_sym],Common::Subject::Order[b.nil?? "":b.to_sym]) }
    @subjects = deal_label('dict', subject_arr)

    grade_arr = Mongodb::BankPaperPap.get_column_arr(@papers_filter, "grade").sort{|a,b| Common::Locale.mysort(Common::Grade::Order[a.nil?? "":a.to_sym],Common::Grade::Order[b.nil?? "":b.to_sym]) }
    @grades = deal_label('dict', grade_arr)
 
    status_arr = Mongodb::BankPaperPap.get_column_arr(@papers_filter,"paper_status").sort{|a,b| Common::Locale.mysort(Common::Locale::StatusOrder[a.nil?? "":a.to_sym],Common::Locale::StatusOrder[b.nil?? "":b.to_sym]) }
    @status = deal_label('papers.status', status_arr)
 
    province, city, district = params[:region].split('/') unless params[:region].blank?
    @region = params[:region]#deal_label('area', params[:region].split('/')).join('/') unless params[:region].blank?

    @papers = @papers_data.by_grade(params[:grade])
      .by_subject(params[:subject])
      .by_status(params[:paper_status])
      .by_keyword(params[:keyword])
      .by_province(province)
      .by_city(city)
      .by_district(district)
      .page(params[:page])
      .per(10)
      .only(Common::Page::PaperListLeastAttributes)

  end

  def my_test
    if current_user.is_project_administrator?
      @tests_data = Mongodb::BankTest.where(user_id: current_user.id)
    else
      bank_test_ids = Mongodb::BankTestUserLink.where(user_id: current_user.id).pluck(:bank_test_id)
      @tests_data = Mongodb::BankTest.where(id: bank_test_ids)
    end
    @bank_tests = @tests_data.by_name(params[:keyword])
      .order("dt_update desc")
      .page(params[:page])
      .per(10)
  end

  def my_pupil
    if current_user.is_teacher?
    pupils = current_user.teacher.pupils
    grade_arr = pupils.all.map(&:grade).uniq.sort{|a,b| 
      Common::Locale.mysort(Common::Grade::Order[a.nil?? "":a.to_sym],Common::Grade::Order[b.nil?? "":b.to_sym]) 
    }
    @grades = deal_label('dict', grade_arr)

    klass_arr = pupils.all.map(&:classroom).uniq.sort{|a,b|
      Common::Locale.mysort(Common::Klass::Order[a.nil?? "":a.to_sym],Common::Klass::Order[b.nil?? "":b.to_sym])
    }
    klass_arr.compact!
    @classrooms = klass_arr.map{|k| [Common::Klass::klass_label(k), k]}

    @pupils = pupils.by_grade(params[:grade])
      .by_classroom(params[:classroom])
      .by_keyword(params[:keyword])
      .page(params[:page])
      .per(Common::Page::PerPage)
    else
      redirect_to my_home_users_path 
    end
  end

  def my_analyzer
    redirect_to my_home_users_path unless current_user.is_tenant_administrator?
  	@analyzers =Analyzer.by_tenant(@tenant.uid)
      .by_keyword(params[:keyword])
      .get_list params
    # render :layout => "user"
  end

  def my_teacher
    redirect_to my_home_users_path unless current_user.is_tenant_administrator?
  	@teachers =Teacher.by_tenant(@tenant.uid)
      .by_keyword(params[:keyword])
      .get_list params
    # render :layout => "user"
  end

  def test_report
    if current_user.is_teacher?
      @papers = current_user.teacher.papers.page(params[:page]).per(Common::Page::PerPage).only(Common::Page::PaperListLeastAttributes)
    else
      redirect_to my_home_users_path 
    end
  end

  def my_report
    if current_user.is_pupil?
      @papers = current_user.pupil.papers
      	.page(params[:page])
      	.per(Common::Page::PerPage)
      	.only(Common::Page::PaperListLeastAttributes)
    else
      redirect_to my_home_users_path 
    end
  end

  def union_test
    if current_user.is_project_administrator?
      # union_test_ids = Mongodb::UnionTestUserLink.only(:union_test_id).where(user_id: current_user.id).map{ |li| li.union_test_id.to_s}
      union_tests = Mongodb::UnionTest.where({user_id: current_user.id })
      grade_arr = union_tests.map {|t| t.grade if t.grade}.uniq.compact.sort{|a,b| Common::Locale.mysort(Common::Grade::Order[a.nil?? "":a.to_sym],Common::Grade::Order[b.nil?? "":b.to_sym]) }
      @grades = deal_label('dict', grade_arr)
      @union_tests = union_tests.by_grade(params[:grade])
      .by_keyword(params[:keyword])
      .page(params[:page])
      .per(10)
    else
      redirect_to my_home_users_path 
    end
  end

  private

  def set_tenant
    @tenant = current_user.role_obj.tenant
  end


  def read_papers
    if current_user.is_analyzer?
      @papers_data = Mongodb::BankPaperPap.by_user(current_user.id).order({dt_update: :desc})
    else
      # #查询关联测试列表
      # tests = Mongodb::BankTest.by_user(current_user.id)
      # #查看相关试卷id
      # pap_ids = tests.map{|t| t.bank_paper_pap.id.to_s if (t && t.bank_paper_pap) }.compact
      # #初步过滤试卷范围
      # @papers_filter = { 
      #   id: {'$in'=>pap_ids} 
      # }
      # @papers_data = Mongodb::BankPaperPap.where(@papers_filter).order({dt_update: :desc})
      @papers_data = Mongodb::BankPaperPap.where(user_id: current_user.id).order({dt_update: :desc})
    end
  end

end
