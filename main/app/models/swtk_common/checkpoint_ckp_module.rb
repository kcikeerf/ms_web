module CheckpointCkpModule
  module CheckpointCkp
    module_function
    TYPE = %w{knowledge skill ability}
    Dimesions = Proc.new {
      {
        :xy_default => TYPE,
        :zh_dyzn => %W{other},
        :zh_fzqn => %W{other},
        :zh_rwdy => %W{other},
        :zh_kxjs => %W{other},
        :zh_xhxx => %W{other},
        :zh_jksh => %W{other},
        :zh_zrdd => %W{other},
        :zh_sjcx => %W{other}
      }
    }.call

    Order = {
      :knowledge => '1',
      :skill => '2',
      :ability => '3'
    }

    LevelArr = [[1], [2], [3], [4], [5], [6], [7], [8], [9], [10,100]]

    ReservedCkpRid = {
      :knowledge => {
          :total => { :label => Common::Locale::i18n("checkpoints.label.knowledge.total"), :rid => "-1"}
      },
      :skill => {
          :total => { :label => Common::Locale::i18n("checkpoints.label.skill.total"), :rid => "-2"}
      },
      :ability => {
          :total => { :label => Common::Locale::i18n("checkpoints.label.ability.total"), :rid => "-3"}
      }
    }

    DifficultyModifierCommon = {
      :default =>1,
      :knowledge => {
        :rong_yi => 1,
        :jiao_yi => 1,
        :zhong_deng => 1,
        :jiao_nan => 1,
        :kun_nan => 1
      },
      :skill => {
        :rong_yi => 1,
        :jiao_yi => 1,
        :zhong_deng => 1,
        :jiao_nan => 1,
        :kun_nan => 1
      }
    }

    DifficultyModifier = DifficultyModifierCommon.merge({
      :ability => {
        :rong_yi => 0.4,
        :jiao_yi => 0.6,
        :zhong_deng => 0.7,
        :jiao_nan => 0.8,
        :kun_nan => 1
      }
    })

    DifficultyModifierShuXue = DifficultyModifierCommon.merge({
      :ability => {
        :rong_yi => 1,
        :jiao_yi => 1,
        :zhong_deng => 1,
        :jiao_nan => 1,
        :kun_nan => 1
      }
    })

    module CkpSource
      Default = "BankCheckpointCkp"
      SubjectCkp = "BankSubjectCheckpointCkp"
    end

    module Dimesion
      Knowledge = "knowledge"
      Skill = "skill"
      Ability = "ability"
    end


    DimesionRatio = {
      Dimesion::Knowledge.to_sym => 0.5,
      Dimesion::Skill.to_sym => 0.4,
      Dimesion::Ability.to_sym => 0.1
    }

    # module SubjectCkpCategory
    #   XiaoXue = "xiao_xue"
    #   ChuZhong = "chu_zhong"
    #   GaoZhong = "gao_zhong"
    # end

    def ckp_types_loop(dimesion_arr=[],&block)
      nodes = {}
      dimesion_arr = TYPE.clone if dimesion_arr.blank?
      dimesion_arr.each do |t|
        nodes[t.to_sym] = proc.call(t)
      end
      nodes
    end

    def compare_rid(x,y)
      return compare_rid_stand(x, y) {|r,b,c|
        if r == 0
          (b.length > c.length)? 1:-1
        else
          r
        end
      }
    end

    def compare_rid_plus(x,y)
      return compare_rid_stand(x, y) {|r,b,c|
        if r == 0
          if b.length > c.length 
            1
          elsif b.length < c.length 
            -1
          else
            0
          end
        else
          r
        end
      }
    end

    def compare_rid_stand(x,y,&block)
      result = 0
      x = x || ""
      y = y || ""
      length = (x.length < y.length) ? x.length : y.length

      0.upto(length-1) do |i|
        if x[i] == y[i]
          next
        else
          if x[i] =~ /[0-9a-z]/
            if y[i] =~ /[0-9a-z]/
              result = x[i] <=> y[i]
              break
            else
              result = 1
              break
            end
          elsif y[i] =~ /[0-9a-z]/
            result = -1
            break
          else
            result = x[i] <=> y[i]
            break
          end
        end
      end
      result = yield(result, x, y) if block_given?
      return result
    end

    def get_ckps_json ckps
        result = {
          Common::CheckpointCkp::Dimesion::Knowledge => [], 
          Common::CheckpointCkp::Dimesion::Skill => [],
          Common::CheckpointCkp::Dimesion::Ability => []
        }
      ckps.each{|ckp|
        next unless ckp

        unless ckp.subject
          logger.debug ">>>#{ckp}: no subject information<<<"
        end

        ckp_ancestors = BankRid.get_all_higher_nodes(ckp.families,ckp)
        ckp_ancestors.sort!{|a,b| Common::CheckpointCkp.compare_rid_plus(a.rid, b.rid) }
        ckps_arr = ckp_ancestors.push(ckp)

        ckp_uid_path = "/#{ckps_arr.map(&:uid).join('/')}"
        ckp_rid_path = "/#{ckps_arr.map(&:rid).join('/')}"
        weights_arr = ckps_arr.map{|ckp|
            Mongodb::BankPaperPap.ckp_weights_modification({
              :subject => ckp.subject,
              :dimesion=> ckp.dimesion, 
              :weights => ckp.weights, 
              :difficulty=> nil
            })
        }
        ckp_weights_path = "/#{weights_arr.join('/')}"
        result[ckp.dimesion] << { 
          ckp_uid_path => {
            "weights" => ckp_weights_path, 
            "rid" => ckp_rid_path
          } 
        }
      }
      return result.to_json      
    end

  end
end