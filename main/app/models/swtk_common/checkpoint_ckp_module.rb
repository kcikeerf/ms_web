module CheckpointCkpModule
  module CheckpointCkp
    module_function
    TYPE = %w{knowledge skill ability}

    LevelArr = [[1], [2], [3], [4], [5], [6], [7], [8], [9], [10,100]]

    ReservedCkpRid = {
      :knowledge => {
          :total => { :label => I18n.t("checkpoints.label.knowledge.total"), :rid => "-1"}
      },
      :skill => {
          :total => { :label => I18n.t("checkpoints.label.skill.total"), :rid => "-2"}
      },
      :ability => {
          :total => { :label => I18n.t("checkpoints.label.ability.total"), :rid => "-3"}
      }
    }

    DifficultyModifier = {
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
      },
      :ability => {
        :rong_yi => 0.4,
        :jiao_yi => 0.6,
        :zhong_deng => 0.7,
        :jiao_nan => 0.8,
        :kun_nan => 1
      }
    }

    module CkpSource
      Default = "BankCheckpointCkp"
      SubjectCkp = "BankSubjectCheckpointCkp"
    end

    module SubjectCkpCategory
      XiaoXue = "xiao_xue"
      ChuZhong = "chu_zhong"
      GaoZhong = "gao_zhong"
    end

    def ckp_types_loop(&block)
      nodes = {}
      TYPE.each do |t|
        nodes[t.to_sym] = proc.call(t)
      end
      nodes
    end

    def compare_rid(x,y)
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
      if result == 0
        return (x.length > y.length)? 1:-1
      else
        return result
      end
    end
  end
end