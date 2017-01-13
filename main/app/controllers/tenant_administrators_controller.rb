class TenantAdministratorsController < ApplicationController
  layout 'user'
   
  before_action :get_tenant_uid
  before_action :filter_papers, only: [:my_home, :my_paper]

  def my_home
  end

  def my_analyzer
  	@analyzers =Analyzer.by_tenant(@tenant_uid)
      .by_keyword(params[:keyword])
      .get_list params
  end

  def my_teacher
  	@teachers =Teacher.by_tenant(@tenant_uid)
      .by_keyword(params[:keyword])
      .get_list params
  end

  def my_paper
  	@subjects = []
  	@grades = []
  	@status = []
    return if @papers_data.blank?

    subject_arr = @papers_data.map(&:subject).uniq.sort{|a,b| Common::Locale.mysort(Common::Subject::Order[a.nil?? "":a.to_sym],Common::Subject::Order[b.nil?? "":b.to_sym]) }
    @subjects = deal_label('dict', subject_arr)

    grade_arr = @papers_data.map(&:grade).uniq.sort{|a,b| Common::Locale.mysort(Common::Grade::Order[a.nil?? "":a.to_sym],Common::Grade::Order[b.nil?? "":b.to_sym]) }
    @grades = deal_label('dict', grade_arr)
 
    status_arr = @papers_data.map(&:paper_status).uniq.sort{|a,b| Common::Locale.mysort(Common::Locale::StatusOrder[a.nil?? "":a.to_sym],Common::Locale::StatusOrder[b.nil?? "":b.to_sym]) }
    @status = deal_label('papers.status', status_arr)
 
    @papers = @papers_data.by_grade(params[:grade])
      .by_subject(params[:subject])
      .by_status(params[:paper_status])
      .by_keyword(params[:keyword])
      .page(params[:page])
      .per(Common::SwtkConstants::DefaultRows)
      .only([:_id, :heading, :subheading, :dt_update])
  end

  private

  def get_tenant_uid
    current_tenant = current_user.role_obj.tenant
    @tenant_uid = current_tenant.nil?? nil:current_tenant.uid
    @tenant_uid
  end

  def filter_papers
    @papers_data = Mongodb::BankPaperPap.by_tenant(@tenant_uid).order({dt_update: :desc})
  end
end
