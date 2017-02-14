module Managers::MainsHelper
  def page_info_item
    case controller_name
    when "area_administrators"
      title = I18n.t("activerecord.models.area_administrator")
      path = "/managers/area_administrators"      
    when "analyzers"
      title = I18n.t("activerecord.models.analyzer")
      path = "/managers/analyzers"
    when "permissions"
      title = I18n.t("activerecord.models.permission")
      path = "/managers/permissions"
    when "pupils"
      title = I18n.t("activerecord.models.pupil")
      path = "/managers/pupils"
    when "project_administrators"
      title = I18n.t("activerecord.models.project_administrator")
      path = "/managers/project_administrators"
    when "roles"
      title = I18n.t("activerecord.models.role")
      path = "/managers/roles"
    when "teachers"
      title = I18n.t("activerecord.models.teacher")
      path = "/managers/teachers"
    when "tenants"
      title = I18n.t("activerecord.models.tenant")
      path = "/managers/tenants"
    when "tenant_administrators"
      title = I18n.t("activerecord.models.tenant_administrator")
      path = "/managers/tenant_administrators"
    when "node_structures"
      title = I18n.t("activerecord.models.bank_nodestructure")
      path = "/managers/node_structures"
    when "node_catalogs"
      nd = BankNodestructure.where(uid: params[:node_structure_id]).first
      arr = [
        nd.version_cn,
        nd.subject_cn,
        nd.grade_cn,
        nd.term_cn,
      ]
      title = "#{I18n.t('activerecord.models.bank_node_catalog')}(#{arr.join('/')})"
      path = "/managers/node_structures/#{params[:node_structure_id]}/node_catalogs"
    else
      title = I18n.t("dict.unknown")
      path = "/managers/"
    end
    result = {
      :title => title,
      :path => path
    }
    result
  end
end
