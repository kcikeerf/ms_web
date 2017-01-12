class BankNodestructure < ActiveRecord::Base
  self.primary_key = "uid"

  #concerns
  include TimePatch
  include InitUid

  has_many :bank_checkpoint_ckps, foreign_key: "node_uid"#, through: :bank_tbc_ckps

  #教材目录 1:n 
  has_many :bank_node_catalogs, foreign_key: "node_uid", dependent: :destroy

  #教材与指标 n:n
  has_many :bank_nodestructure_subject_ckps, foreign_key: 'node_structure_uid', dependent: :destroy
  has_many :bank_subject_checkpoint_ckps, through: :bank_nodestructure_subject_ckps

  accepts_nested_attributes_for :bank_checkpoint_ckps, :bank_node_catalogs, :bank_nodestructure_subject_ckps

  scope :by_subject, ->(subject) { where(subject: subject) }
  scope :by_grade, ->(grade) { where(grade: grade) }

  validates :grade, :subject, :version, :xue_duan, :term, presence: true

  class << self

    def list_structures
      result = {}
      self.all.each{|bn|
        if bn.subject && !result.keys.include?(bn.subject)
          result[bn.subject] = {"label" => Common::Locale::i18n("dict.#{bn.subject}"),"items" =>{}}
  #      else
  #        return result
        end
        keys_arr = result[bn.subject]["items"].keys
        if bn.grade && !keys_arr.include?(bn.grade)
          result[bn.subject]["items"][bn.grade] = {"label" => Common::Locale::i18n("dict.#{bn.grade}"), "items" =>{}}
  #      else
  #        return result
        end
        keys_arr = result[bn.subject]["items"][bn.grade]["items"].keys
        if bn.version && bn.volume && !keys_arr.include?(bn.version+"("+bn.volume+")")
          result[bn.subject]["items"][bn.grade]["items"][bn.version+"("+bn.volume+")"] = {"label" => Common::Locale::i18n("dict.#{bn.version}") + "("+Common::Locale::i18n("dict.#{bn.volume}")+")", "node_uid" => bn.uid, "items"=>{}}
  #      else
  #        return result
        end
      }
      return result
    end

    def subject_gather
      self.all.map{|item| {label: Common::Locale::i18n("dict.#{item.subject}"), name: item.subject} }.uniq
    end

    def grade_gather(subject)
      by_subject(subject).map{ |m| {label: Common::Locale::i18n("dict.#{m.grade}"), name: m.grade} }
    end

    def version_gather(subject, grade)
      by_subject(subject).by_grade(grade).map{ |m| { label: Common::Locale::i18n('dict.' + m.version), name: m.version } }
    end

    def unit_gather(subject, grade, version)
      by_subject(subject).by_grade(grade).where(version: version).map{ |m| { label: Common::Locale::i18n('dict.' + m.volume), name: m.volume, node_uid: m.uid } }
    end

    def list
      arr = self.all.order({:version => :asc, :subject=> :asc, :grade => :asc, :term => :asc})
      arr.map{|item|
        {name: [item.version_cn,item.subject_cn,item.grade_cn,item.term_cn].join("/")}.merge(item.attributes)
      }
    end
  end

  # def add_ckps(ckps)
  #   transaction do
  #     bank_nodestructure_subject_ckps.destroy_all
  #     ckp_arr = [].tap do |arr|
  #       ckps.each {|ckp| arr << {subject_ckp_uid: ckp} }
  #     end
  #     bank_nodestructure_subject_ckps.create(ckp_arr)
  #   end
  # end

  def catalog_ztree_list
    self.bank_node_catalogs.map{|item|
      item.ztree_node_hash
    }.unshift({
      uid: "",
      rid: "",
      pid: "",
      name: Common::Locale::i18n("activerecord.models.bank_node_catalog"),
      checked: 0,
      open: true
    })
  end

  def update_node params
    self.update(node_params(params))
    self.save!
  end

  def replace_subject_checkpoints
    # 清除教材旧的绑定指标
    self.bank_nodestructure_subject_ckps.destroy_all
    # 绑定教材的所有目录的当前指标
    self.bank_subject_checkpoint_ckp_ids = self.bank_node_catalogs.map{|item| item.bank_subject_checkpoint_ckp_ids }.flatten.uniq
    self.save!
  end

  private

    def node_params params
      xue_duan = Common::Grade.judge_xue_duan(params[:grade])
      {
        version: Common::Locale::hanzi2pinyin(params[:version_cn]),
        subject: params[:subject],
        xue_duan: xue_duan,
        grade: params[:grade],
        term: params[:term],
        version_cn: params[:version_cn],
        subject_cn: Common::Subject::List[params[:subject].to_sym],
        xue_duan_cn: Common::Grade::XueDuan::List[xue_duan.to_sym],
        grade_cn: Common::Grade::List[params[:grade].to_sym],
        term_cn: Common::Term::List[params[:term].to_sym]
      }
    end
end
