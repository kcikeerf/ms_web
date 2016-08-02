# -*- coding: utf-8 -*-
# 

module Common

  module SwtkConstants
    CkpDepth = 100
    CkpStep = 3
    UploadPrefix = Rails.root.to_s + "/uploads/"
  end

  module Role
    Pupil="pupil"
    Teacher="teacher"
    Analyzer="analyzer"
    NAME_ARR = %w(pupil teacher analyzer)
  end

  module Paper
    module_function

    Subject_ckp_type = 'from_subject'
    Node_ckp_type = 'from_node'

    module Constants
      OrderWidth = 5
    end

    module Status
      None = "none"
      New = "new"
      Editting = "editting"
      Editted = "editted"
      Analyzing = "analyzing" 
      Analyzed = "analyzed"
      ScoreImporting = "score_importing"
      ScoreImported = "score_imported"
      ReportGenerating = "report_generating"
      ReportCompleted = "report_completed"
    end

    def quiz_order(x,y)
      x_arr = destruct_order x
      y_arr = destruct_order y

      if x_arr[0] != y_arr[0]
        return x_arr[0] <=> y_arr[0]
      else
        return x_arr[1] <=> y_arr[1]
      end
    end

    def destruct_order orderStr
      return ["",""] if orderStr.blank?
      reg = /\(([0-9].*?)\)/
      md = reg.match(orderStr)
      quiz_order = orderStr.sub(/\(.*/,"")
      quiz_order = quiz_order.blank?? 0:quiz_order.to_i
      qizpoint_order = md.blank?? 0:md[1].to_i
      return [quiz_order,qizpoint_order]
    end
  end

  module CheckpointCkp
    module_function
    TYPE = %w{knowledge skill ability}

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
            else
              result = 1
            end
          elsif y[i] =~ /[0-9a-z]/
            result = -1
          else
            result = x[i] <=> y[i]
          end
        end
      end

      if x.length == y.length
        return result
      else
        return (x.length > y.length)? 1:-1
      end
    end
  end

  module School
    NumberLength = 4
  end

  module Score
    module Constants
      AllowUserNumber = 5000
      AllowScoreNumber = 1000
    end

    def create_empty_score file_path
      fs = ScoreUpload.new
      fs.empty_file = Pathname.new(file_path).open
      fs.save!
      return fs 
    end
    module_function :create_empty_score

    def create_usr_pwd params
      fs = ScoreUpload.where(id: params[:score_file_id]).first
      fs.usr_pwd_file = Pathname.new(params[:file_path]).open
      fs.save!
      return fs 
    end
    module_function :create_usr_pwd

    def upload_filled_score params
      fs = ScoreUpload.where(id: params[:score_file_id]).first     
      fs.filled_file = params[:filled_file]
      fs.save!
      return fs
    end
    module_function :upload_filled_score
  end

  module Subject
    Abbrev = {
      :yu_wen          => "yw",
      :shu_xue         => "sx",
      :ying_yu         => "yy",
      :li_shi          => "ls",
      :di_li           => "dl",
      :wu_li           => "wl",
      :hua_xue         => "hx",
      :sheng_wu        => "sw",
      :si_xiang_pin_de => "sd",
      :zheng_zhi       => "zz",
      :xin_xi_ji_shu   => "xs",
      :ji_shu          => "js"
    }
  end

  module Task
    module Type
      CreateReport = "create_report"
      UploadScore = "upload_score"
    end

    module Status
      InActive = "in_active"
      Active = "active"
    end
  end

  module Job
    module Type
      CreateReport = "create_report"
      CreatePupilReport = "create_pupil_report"
      CreateClassReport = "create_class_report"
    end

    module Status
      NotInQueue = "notinqueue"
      InQueue = "inqueue"
      Initialization = "initialization"
      Processing = "processing"
      Completed = "completed"
    end
  end

  module Report

    module Url
      Length = 6
    end

    module CheckPoints
      Levels = 2
    end

    module ScoreLevel
      Level0 = 0
      Level60 = 0.6
      Level85 = 0.85
    end

    module FourSection
      Level0 = 0
      Level25 = 25
      Level50 = 50
      Level75 = 75
    end

    module Charts
      PersonalKnowledgeRadar = "personal_knowledge_radar"
      PersonalKnowledgeLine = "personal_knowledge_line"
      PersonalSkillRadar = "personal_skill_radar"
      PersonalSkillLine = "personal_skill_line"
      PersonalAbilityRadar = "personal_ability_radar"
      PersonalAbilityLine = "personal_ability_line" 
    end

    module Format
      #班级报告解读文字
      KlassExplanation = {
          "three_dimesions"=>"
<div class='wrapper-md'>
<h1 class='font-thin h3'>报告解读</h1></div>
<div class='hbox hbox-auto-xs hbox-auto-sm'>
<div class='col'>
<div class='clearfix padder-lg'>
<h3>三维指标含义解释</h3>
<dl>
<dt>技能指标</dt>
<dd>
<ol>
<li>记忆：再认、回忆学过的词汇的音形义、固定词法和句法、时态及语态</li>
<li>理解：根据听觉、视觉通道所获得的信息，结合语境对单词、句子的意义进行解释和转译</li>
<li>信息提取：通过听觉、视觉通道将问题中的信息与文中相同的词或暗含的信息相匹配，来找出所要求的新信息</li>
<li>推理：通过听觉、视觉通道所提供的信息，借助思维的逻辑性、系统性，对文本内容进行推论</li>
<li>分析-区分：</li>
<li>分析-组织：将材料分解为其组成部分，并确定这些部分彼此及其与整体结构及目的之间关系</li>
<li>分析-归因：对文本隐含的观点、倾向、价值或意图的。</li>
<li>表达：综合运用英语语言知识，以记叙、议论或说明的方式记录事件、表达观点或传递信息</li>
</ol>
</dd>
</dl>
<dl>
<dt>能力指标</dt>
<dd>
<ol>
<li>词汇辨析：再认、回忆学过的词汇的音形义、固定词法和句法、时态及语态</li>
<li>语言理解：根据听觉、视觉通道所获得的信息，结合语境对单词、句子的意义进行解释和转译</li>
<li>逻辑分析：通过听觉、视觉通道将问题中的信息与文中相同的词或暗含的信息相匹配，来找出所要求的新信息</li>
<li>人际理解：通过听觉、视觉通道所提供的信息，借助思维的逻辑性、系统性，对文本内容进行推论</li>
</ol>
</dd>
</dl>
</div>
</div>
</div>
          ",
          "statistics"=> "
<div class='wrapper-md'>
<h1 class='font-thin h3'>报告解读</h1>
</div>
<div class='hbox hbox-auto-xs hbox-auto-sm'>
<div class='col'>
<div class='clearfix padder-lg'>
<dl>
<dt>统计指标解释</dt>
<dd>
<ol>
<li>班级平均得分率：班级平均得分率表明班级总体的得分情况，即班级学生在各个指标上的整体达标情况（不包括成绩为零的学生），
公式为：（全班学生某指标的平均分/该指标的满分值） × 100。</li>
<li>班级中位数得分率：将全班学生成绩从高到低排序后，恰好处于中间位置的学生的成绩情况，
公式为：（全班学生某指标得分的中位数/该指标的满分值） × 100。</li>
<li>年级平均得分率：年级全体参测学生在各个指标上的整体达标情况（不包括成绩为零的学生），
公式为：（年级参测学生某指标的平均分/该指标的满分值） × 100。</li>
<li>分化程度：本班学生在某一指标上的成绩离散情况，数值越大，表明班级成绩的不均衡性越高。
公式为：（标准差/平均数） × 100。</li>
<li>满分值：本次测试为每个指标设定的最高值。</li>
</ol>
</dd>
</dl>
</div>
</div>
</div>
          ",
          "data" => "
<div class='wrapper-md'>
<h1 class='font-thin h3'>报告解读</h1>
</div>
<div class='hbox hbox-auto-xs hbox-auto-sm'>
<div class='col'>
<div class='clearfix padder-lg'>
<h3>数据解读</h3>
<dl>
<dt>技能</dt>
<dd>
<ul>
<li>班级平均得分率越高，表明班级学生在技能方面的总体达标情况越好。理想的数值应该在90以上。当某个技能点的平均得分率低于70时，则需要引起任课老师的关注。
对于达标考试而言，这样的得分率表明本班有很多学生并未很好的掌握这部分技能。</li>
<li>认知是英语学习中所必须的基础技能。如果班级学生在此项技能上的得分率较低，表明基本功还不扎实。学生英语上所投入的时间和精力还存在不足，或者是方法不对。
需要教师对照本班的实际情况，激发学生的学习兴趣，引导学生调整学习方法。</li>
<li>理解的得分率较低则表明学生的学习并未实现有效的迁移，还停留在死记硬背的阶段。因此，需要教师帮助学生学会举一反三。</li>
<li>信息提取是阅读中对理解要求最低的一项技能。如果班级学生在此项技能上的得分率较低，教师需要关注本班学生是否掌握了最基本的阅读方法。</li>
<li>推理、分析和表达是阅读理解中较高级的理解能力。如果班级学生在这些技能项上的得分率较低，则表明学生的阅读习惯不好。
阅读的目的仅仅是为了回答问题，而没有真正想去理解文章的内容。因此，教师需要在日常教学中引导学生培养良好的阅读习惯，不是为了阅读而阅读，
而是要站在真正从文章中获取一定的信息，理解文章的基本内容，理解作者的写作目的和意图的角度去阅读。</li>
<li>班级中位数得分率越高，表明班级中50%的学生技能达标情况越好，当该数值高于班级平均得分率时，表明本班虽然有较多的高分，但因为存在极端低分值，
从而使平均得分率不能很好的代表班级的总体水平。技能中位数得分率低于平均得分率，需要结合基础技能和高级思维技能在本次考试中所占比重的情况综合考虑。
如果基础技能所占比重较大，且班级学生技能低分又较多，则表明多数学生需掌握的基础技能并没有掌握好，可能与训练较少有关；如果高级技能所占比重较大，
则表明试题难度与多数学生的水平不相匹配，任课教师需要在高级思维技能方面给学生以更多的引导和关注</li>
<li>分化程度表明分化程度越小，表明任课老师在全体学生共同进步方面所投入的精力越大。分化程度越大，表明班级学生的分化现象越严重，
需要教师针对不同群体的学生采取不同的训练策略，以防止分化进一步加剧。正常的情况应该是学生在基础技能项上的分化程度要小，在高级技能项上的分化程度要大。</li>
<li>任课教师可选取分化程度最大的技能点作为调整教学策略的最初切入点。</li>
</ul>
</dd>
</dl>
<dl>
<dt>能力</dt>
<dd>
<ul>
<li>班级平均得分率越高，表明班级能力表现越好，理想的数值应该在90以上。当某个能力点的平均得分率低于70时，则需要引起任课老师的关注。
这表明本班学生在该能力项上存在不足，某一能力项的不足会影响学生在后期接受相关知识时的速度和效率。</li>
<li>班级中位数得分率越高，表明班级中50%的学生能力表现情况越好，当该数值高于班级平均得分率时，表明本班虽然有较多的高分，但因为存在极端低分值，
从而使能力的平均得分率不能很好的代表班级的总体的能力水平。</li>
<li>分化程度越小，表明班级学生在该能力项的同质水平越高，大班制的授课方式的效果也越好。分化程度越大，表明班级学生在该能力项上的差异越大，
大班制的授课方式所能取得的整体效果越差，会导致能力强的学生的能力得不到有效的开发，而能力弱的学生则不能从现有的授课方式和训练方式中获得最大的收益。</li>
<li>任课教师可选取分化程度最大的能力点作为调整能力开发的基点。</li>
</ul>
</dd>
</dl>
</div>
</div>
</div>
          "
      }
      
      #班级测试评价模版文字
      KlassQuizComment = {
        "dimesion" => "
<div class='wrapper-md'><h1 class='font-thin h3'>测试评价</h1></div>
<div class='hbox hbox-auto-xs hbox-auto-sm'><div class='col'><div class='clearfix padder-lg'>
<dl><dt>%{head_title}</dt><dd><ul><li>
本班学生得分率最高的项是: <mark>%{pupil_highest_items}</mark><br>
本班学生得分率最低的项是: <mark>%{pupil_lowest_items}</mark><br>
表明在上一阶段的学习中，本班学生在<mark>%{pupil_highest_items}</mark>取得了较好的学习效果，
但在<mark>%{pupil_lowest_items}</mark>方面的学习却相对存在不足。
</li><li>
本班高于年级平均水平的项是: <mark>%{higher_than_grade_items}</mark><br>
本班低于年级平均水平的项是: <mark>%{lower_than_grade_items}</mark><br>
表明在这次考试中，本班学生总体的优势是<mark>%{higher_than_grade_items}</mark>，
本班学生总体的劣势是<mark>%{lower_than_grade_items}</mark>。 
</li><li>
本班的平均得分率是<mark>%{klass_average_percent}</mark>，
在本次考试中，达到了<mark>%{level}</mark>水平。
与年级平均水平相比，<mark>%{than_grade}</mark>于年级平均水平。
</li><li>
本班的得分率 ≥ 85的人数比例是<mark>%{excellent_level_percent}</mark>, 
表明在本次考试中，知识得分率在 85 以上的学生人数占本班全部考试人数的<mark>%{excellent_level_percent}</mark>，
与年级相比，<mark>%{excellent_level_percent_than_grade}</mark>于年级的比例。
</li><li>
本班的60 ≤ 得分率 < 85的人数比例是<mark>%{good_level_percent}</mark>, 
表明在本次考试中，知识得分率在 60-85之间的学生人数占本班全部考试人数的<mark>%{good_level_percent}</mark>，
与年级相比，<mark>%{good_level_percent_than_grade}</mark>于年级的比例。
</li><li>
本班的得分率 < 60的人数比例是<mark>%{failed_level_percent}</mark> , 
表明在本次考试中，知识得分率在60以下的学生人数占本班全部考试人数的<mark>%{failed_level_percent}</mark>，
与年级相比，<mark>%{failed_level_percent_than_grade}</mark>于年级的比例。
</li></ul></dd></dl></div></div></div>
",
        "total" => "
<div class='wrapper-md'><h1 class='font-thin h3'>测试评价</h1></div>
<div class='hbox hbox-auto-xs hbox-auto-sm'><div class='col'>
<div class='clearfix padder-lg'><dl><dt>总体情况</dt><dd><ul><li>
知识、技能、能力中得分率最高的项是：<mark>%{pupil_highest_dimesions}</mark><br>
知识、技能、能力中得分率最低的项是：<mark>%{pupil_lowest_dimesions}</mark><br>
表明在本次测试总，本班学生总体展示出的长板是<mark>%{pupil_highest_dimesions}</mark>，短板是<mark>%{pupil_lowest_dimesions}</mark>。
</li><li>
同年级平均水平相比，本班学生高于年级平均水平的是：<mark>%{higher_than_grade_dimesions}</mark><br>
同年级平均水平相比，本班学生低于年级平均水平的是：<mark>%{lower_than_grade_dimesions}</mark><br>
表明在这次考试中，本班学生总体的优势是 %{higher_than_grade_dimesions}，
本班学生总体的劣势是<mark>%{lower_than_grade_dimesions}</mark>。
</li><li>
在总成绩方面，本班的平均得分率是<mark>%{klass_average_percent}</mark>，在本次考试中，达到了<mark>%{level}</mark>水平。
与年级平均水平相比，<mark>%{than_grade}</mark>于年级平均水平。
</li><li>
在总成绩方面，本班的得分率 ≥ 85的人数比例是<mark>%{excellent_level_percent}</mark>，
表明在本次考试中，总成绩得分率在 85 以上的学生人数占本班全部考试人数的<mark>%{excellent_level_percent}</mark>，
与年级相比，<mark>%{excellent_level_percent_than_grade}</mark>于年级的人数比例。
</li><li>
在总成绩方面，本班的60 ≤ 得分率 < 85的人数比例是<mark>%{good_level_percent}</mark>，
表明在本次考试中，总成绩得分率在 60-85 之间的学生人数占本班全部考试人数的<mark>%{good_level_percent}</mark>，
与年级相比，<mark>%{good_level_percent_than_grade}</mark>于年级的人数比例。
</li><li>
在总成绩方面，本班的得分率 < 60的人数比例是<mark>%{failed_level_percent}</mark>，
表明在本次考试中，总成绩得分率在 60 以下的学生人数占本班全部考试人数的<mark>%{failed_level_percent}</mark>，
与年级相比，<mark>%{failed_level_percent_than_grade}</mark>于年级的人数比例。
</li></ul></dd></dl></div></div></div>
"
      }

      #个人测试评价模版文字
      PupilQuizComment = "
<div class='wrapper-md'><h1 class='font-thin h3'>诊断及改进建议</h1>
</div><div class='hbox hbox-auto-xs hbox-auto-sm'>
<div class='col'><div class='clearfix padder-lg'><div id='diagnosis'>
<h3>诊断 <small>（本次测试总体表现如下）</small></h3><div class='wrap'>
<h4>最佳表现</h4><p class='text-muted'><b>与自身相比，表现最佳的方面有：</b>
知识：%{self_best_knowledge}<br>
技能：%{self_best_skill}<br>
能力：%{self_best_ability}
</p><p class='text-muted'><b>与群体相比，表现最佳的方面有：</b>
知识：%{inclass_best_knowledge}<br>
技能：%{inclass_best_skill}<br>
能力：%{inclass_best_ability}
</p><h4>问题发现</h4><p class='text-muted'><b>低于年级平均水平较多的方面是：</b>
知识：%{ingrade_worse_knowledge}<br>
技能：%{ingrade_worse_skill}<br>
能力：%{ingrade_worse_ability}
</p><h4>原因分析</h4><ol>
%{ingrade_worse_cause}
</ol></div></div><div id='proposal'><h3>改进建议</h3><div class='wrap'><ol>
%{ingrade_worse_advice}
</ol></div></div></div></div></div>
"
      DisplayLimit = {
        "default" => 15
      }
      Grade = {
        #basic information
        "basic" => {
          "subject" => "",
          "area" => "",
          "school" => "",
          "grade" => "",
          "klass_count" => "",
          "quiz_type" => "",
          "quiz_date" => "",
          "levelword2" => ""
        },
        "display_limit" => {
          #诊断图
          "charts" => {
            "knowledge_3lines" => Common::Report::Format::DisplayLimit["default"],
            "knowledge_med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
            "skill_3lines" => Common::Report::Format::DisplayLimit["default"],
            "skill_med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
            "ability_3lines" => Common::Report::Format::DisplayLimit["default"],
            "ability_med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
            "dimesion_disperse" => -1
          },
          #各分数段人数比例
          "each_level_number" => {
            "grade_knowledge"=> Common::Report::Format::DisplayLimit["default"],
            "grade_skill"=> Common::Report::Format::DisplayLimit["default"],
            "grade_ability"=> Common::Report::Format::DisplayLimit["default"]
          },
          #四分位区间表现情况
          "four_sections" => {
            "level75"=> {
              "knowledge" => Common::Report::Format::DisplayLimit["default"],
              "skill" => Common::Report::Format::DisplayLimit["default"],
              "ability" => Common::Report::Format::DisplayLimit["default"]
            },
            "level50"=> {
              "knowledge" => Common::Report::Format::DisplayLimit["default"],
              "skill" => Common::Report::Format::DisplayLimit["default"],
              "ability" => Common::Report::Format::DisplayLimit["default"]
            },
            "level25"=> {
              "knowledge" => Common::Report::Format::DisplayLimit["default"],
              "skill" => Common::Report::Format::DisplayLimit["default"],
              "ability" => Common::Report::Format::DisplayLimit["default"]
            },
            "level0"=> {
              "knowledge" => Common::Report::Format::DisplayLimit["default"],
              "skill" => Common::Report::Format::DisplayLimit["default"],
              "ability" => Common::Report::Format::DisplayLimit["default"]
            }
          },
          #各指标水平图
          "each_checkpoint_horizon" => {
            "knowledge" => {
              "average_percent" => Common::Report::Format::DisplayLimit["default"],
              "median_percent" => Common::Report::Format::DisplayLimit["default"],
              "med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
              "diff_degree" => Common::Report::Format::DisplayLimit["default"]
            },
            "skill" => {
              "average_percent" => Common::Report::Format::DisplayLimit["default"],
              "median_percent" => Common::Report::Format::DisplayLimit["default"],
              "med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
              "diff_degree" => Common::Report::Format::DisplayLimit["default"]
            },
            "ability" => {
              "average_percent" => Common::Report::Format::DisplayLimit["default"],
              "median_percent" => Common::Report::Format::DisplayLimit["default"],
              "med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
              "diff_degree" => Common::Report::Format::DisplayLimit["default"]
            },
            "total" => {
              "average_percent" => Common::Report::Format::DisplayLimit["default"],
              "median_percent" => Common::Report::Format::DisplayLimit["default"],
              "med_avg_diff" => Common::Report::Format::DisplayLimit["default"],
              "diff_degree" => Common::Report::Format::DisplayLimit["default"]
            },

          },
          #各班分数段人数比例
          "each_class_pupil_number_chart" => {
            "knowledge" => {
              "excellent_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "good_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "failed_pupil_percent" => Common::Report::Format::DisplayLimit["default"]
            },
            "skill" => {
              "excellent_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "good_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "failed_pupil_percent" => Common::Report::Format::DisplayLimit["default"]
            },
            "ability" => {
              "excellent_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "good_pupil_percent" => Common::Report::Format::DisplayLimit["default"],
              "failed_pupil_percent" => Common::Report::Format::DisplayLimit["default"]
            }
          },
        },
        #诊断图
        "charts" => {
          "knowledge_3lines" => {
            "grade_median_percent" => {},
            "grade_average_percent" => {},
            "grade_diff_degree" => {}
          },
          "knowledge_med_avg_diff" => {},
          "skill_3lines" => {
            "grade_median_percent" => {},
            "grade_average_percent" => {},
            "grade_diff_degree" => {}
          },
          "skill_med_avg_diff" => {},
          "ability_3lines" => {
            "grade_median_percent" => {},
            "grade_average_percent" => {},
            "grade_diff_degree" => {}
          },
          "ability_med_avg_diff" => {},
          "dimesion_disperse" => {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          }
        },
        #各分数段人数比例
        "each_level_number" => {
          "grade_knowledge"=>{
          },
          "grade_skill"=>{
          },
          "grade_ability"=>{
          }
        },
        #四分位区间表现情况
        "four_sections" => {
          "level75"=> {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          },
          "level50"=> {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          },
          "level25"=> {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          },
          "level0"=> {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          }
        },
        #各指标水平图
        "each_checkpoint_horizon" => {
          "knowledge" => {
            "average_percent" => {},
            "median_percent" => {},
            "med_avg_diff" => {},
            "diff_degree" => {}
          },
          "skill" => {
            "average_percent" => {},
            "median_percent" => {},
            "med_avg_diff" => {},
            "diff_degree" => {}
          },
          "ability" => {
            "average_percent" => {},
            "median_percent" => {},
            "med_avg_diff" => {},
            "diff_degree" => {}
          },
          "total" => {
            "average_percent" => {},
            "median_percent" => {},
            "med_avg_diff" => {},
            "diff_degree" => {}
          } 
        },
        #各班分数段人数比例
        "each_class_pupil_number_chart" => {
          "knowledge" => {
            "excellent_pupil_percent" =>{},
            "good_pupil_percent" => {},
            "failed_pupil_percent" => {}
          },
          "skill" => {
            "excellent_pupil_percent" =>{},
            "good_pupil_percent" => {},
            "failed_pupil_percent" => {}
          },
          "ability" => {
            "excellent_pupil_percent" =>{},
            "good_pupil_percent" => {},
            "failed_pupil_percent" => {}
          }
        },
        #各题答对率
        "average_percent" => {
          "failed" => [],
          "good" => [],
          "excellent" => []
        },
        #报告解读
        "report_explanation" =>{
          "three_dimesions"=> Common::Report::Format::KlassExplanation["three_dimesions"],
          "statistics"=> Common::Report::Format::KlassExplanation["statistics"],
          "data" => Common::Report::Format::KlassExplanation["data"]
        }
      }

      Klass = {
        #basic information
        "basic" => {
          "subject" => "",
          "area" => "",
          "school" => "",
          "grade" => "",
          "classroom" => "",
          "head_teacher" => "",
          "subject_teacher" => "",
          "quiz_type" => "",
          "quiz_date" => "",
          "levelword2" => ""
        },
        "display_limit" => {
          "charts" => {
            "knowledge_all_lines" => Common::Report::Format::DisplayLimit["default"],
            "knowledge_gra_cls_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "knowledge_cls_mid_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "skill_all_lines" => Common::Report::Format::DisplayLimit["default"],
            "skill_gra_cls_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "skill_cls_mid_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "ability_all_lines" => Common::Report::Format::DisplayLimit["default"],
            "ability_gra_cls_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "ability_cls_mid_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"]
          }
        },
        "dimesion_values" => {
          "knowledge" => {
            "average" => 0.0,
            "average_percent" => 0.0,
            "gra_average" => 0.0,
            "gra_average_percent" => 0.0
          },
          "skill" => {
            "average" => 0.0,
            "average_percent" => 0.0,
            "gra_average" => 0.0,
            "gra_average_percent" => 0.0
          },
          "ability" => {
            "average" => 0.0,
            "average_percent" => 0.0,
            "gra_average" => 0.0,
            "gra_average_percent" => 0.0
          }
        },
        #诊断图
        "charts" => {
          "knowledge_all_lines" => {
            "grade_average_percent" => {},
            "class_average_percent" => {},
            "class_median_percent" => {},
            "diff_degree" => {}
          },
          "knowledge_gra_cls_avg_diff_line" =>{},
          "knowledge_cls_mid_gra_avg_diff_line" => {},
          "skill_all_lines" => {
            "grade_average_percent" => {},
            "class_average_percent" => {},
            "class_median_percent" => {},
            "diff_degree" => {}
          },
          "skill_gra_cls_avg_diff_line" =>{},
          "skill_cls_mid_gra_avg_diff_line" => {},
          "ability_all_lines" => {
            "grade_average_percent" => {},
            "class_average_percent" => {},
            "class_median_percent" => {},
            "diff_degree" => {}
          },
          "ability_gra_cls_avg_diff_line" =>{},
          "ability_cls_mid_gra_avg_diff_line" => {}
        },
        #各分数段人数比例
        "each_level_number" => {
          "class_three_dimesions"=>{
            "class_knowledge"=>{},
            "class_skill"=>{},
            "class_ability"=>{}
          },
          "class_grade_knowledge"=>{
            "class_knowledge"=>{},
            "grade_knowledge"=>{}
          },
          "class_grade_skill"=>{
            "class_skill"=>{},
            "grade_skill"=>{}
          },
          "class_grade_ability"=>{
            "class_ability"=>{},
            "grade_ability"=>{}
          },
          "total"=>{
            "class"=>{},
            "grade"=>{}
          }
        },
        #数据表
        "data_table" => {
          "knowledge"=>{},
          "skill"=>{},
          "ability"=>{}
        },
        #各题答对率
        "average_percent" => {
          "failed" => [],
          "good" => [],
          "excellent" => []
        },
        #报告解读
        "report_explanation" =>{
          "three_dimesions"=> Common::Report::Format::KlassExplanation["three_dimesions"],
          "statistics"=> Common::Report::Format::KlassExplanation["statistics"],
          "data" => Common::Report::Format::KlassExplanation["data"]
        },
        #测试评价
        "quiz_comment" => {
          "knowledge" => Common::Report::Format::KlassQuizComment["dimesion"],
          "skill" => Common::Report::Format::KlassQuizComment["dimesion"],
          "ability" => Common::Report::Format::KlassQuizComment["dimesion"],
          "total" => Common::Report::Format::KlassQuizComment["total"]
        }
      }

      Pupil = {
        #基本信息
        "basic" => {
          "area" => "",
          "school" => "",
          "grade" => "",
          "classroom" =>"",
          "subject" => "",
          "name" => "",
          "sex" => "",          
          "levelword2" => "",
          "quiz_date" => ""
        },
        "display_limit" => {
          "charts" => {
            "knowledge_radar" => Common::Report::Format::DisplayLimit["default"],
            "knowledge_pup_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "skill_radar" => Common::Report::Format::DisplayLimit["default"],
            "skill_pup_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"],
            "ability_radar" => Common::Report::Format::DisplayLimit["default"],
            "ability_pup_gra_avg_diff_line" => Common::Report::Format::DisplayLimit["default"]
          }
        },
        #诊断图
        "charts" => {
          "knowledge_radar" => {
            "pupil_average" => {},
            "grade_average" => {}
          },
          "knowledge_pup_gra_avg_diff_line" =>{
          },
          "skill_radar" => {
            "pupil_average" => {},
            "grade_average" => {}
          },
          "skill_pup_gra_avg_diff_line" =>{
          },
          "ability_radar" => {
            "pupil_average" => {},
            "grade_average" => {}
          },
          "ability_pup_gra_avg_diff_line" =>{
          }
        },
        #诊断及改进建议
        "quiz_comment" => Common::Report::Format::PupilQuizComment,
        #数据表
        "data_table" => {
          "knowledge"=>{},
          "skill"=>{},
          "ability"=>{}
        }
      }

      PupilMobile = {
        #基本信息
        "basic" => {
          "area" => "",
          "school" => "",
          "grade" => "",
          "classroom" =>"",
          "subject" => "",
          "name" => "",
          "sex" => "",          
          "levelword2" => "",
          "quiz_date" => "",
          "score" =>"",
          "full_score" =>""
        },
        "rank" => {
          "my_position" => 0,
          "total_testers" => 0
        },
        "charts" => {
          "knowledge" => {
          },
          "skill" => {
          },
          "ability" => {
          }
        },
        "weak_fields" => {
          "knowledge" => {
          },
          "skill" => {
          },
          "ability" => {
          }
        },
        "wrong_quizs"=>{
          "knowledge" => {
          },
          "skill" => {
          },
          "ability" => {
          }
        }
      }
    end
  end

  module Image
 
    def file_upload(user, file, crop)
      fu = user.image_upload || user.build_image_upload
      fu.crop_x = crop["x"]
      fu.crop_y = crop["y"]
      fu.crop_w = crop["width"]
      fu.crop_h = crop["height"]
      fu.crop_r = crop["rotate"]
      fu.file = file
      fu.save
      return fu 
    end
    module_function :file_upload

  end

  module PaperFile
    module_function
    # Upload one file 
    def single_upload params
#      if params[:str_tempid].blank?
        fu = FileUpload.new
#      else
#        fu = FileUpload.where("id = ?", params[:str_tempid]).first
#      end 
      
#      case params[:type]
#      when "question"
#        fu.paper = params[:file]
#      when "answer"
#        fu.answer = params[:file]
#      end
      fu.single = params[:file]
      fu.save!
      return fu
    end
    module_function :single_upload
 
    # Upload files 
    def multiple_upload files_h
      fu = FileUpload.new
      fu.paper = files_h[:paper]
      fu.answer = files_h[:answer]
      fu.analysis = files_h[:analysis]
      fu.save!
      return fu
    end    
    module_function :multiple_upload

    def paper_or_answer_upload(file, file_hash)      
      file.revise_paper = Pathname.new(file_hash[:revise_paper]).open unless file_hash[:revise_paper].blank?
      file.revise_answer = Pathname.new(file_hash[:revise_answer]).open unless file_hash[:revise_answer].blank?
      file.save!
      file
    end

    def generate_docx_by_html(file, html, file_name, file_column)
      doc_str = PandocRuby.html(html).to_docx
      file_path = File.join(Rails.root, "/tmp/#{file_name}.docx")
      File.open(file_path, 'wb') { |f| f.write(doc_str) }

      file = paper_or_answer_upload(file, {file_column.to_sym => file_path})
      File.delete(file_path)
      file
    end

    # Get excel file content
    def get_excel_file_content file_path
      result = []
      file = nil
      return result if file_path.blank?
      case file_path.split('.').last.downcase
      when 'xlsx', 'xlsm'
        file = Roo::Excelx.new(file_path)
      when 'xls'
        file = Roo::Excel.new(file_path)
#      else:
#        file = Roo::Excelx.new(file_path)
      end
      sheet = file.sheet('试题分析') if file
      sheet.each{|row|
        result << row
      } if sheet
      return result
    end
    module_function :get_excel_file_content

    # Convert doc file content
    def get_doc_file_content_as_html file_path
      return "" if file_path.blank?
      result = ""
      location = file_path.split('/')[0..-2].join('/')
      html_name = file_path.split('/').last.split('.')[0] + '_converted.html' 

      begin
        word_cleaner_folder = Rails.root.to_s.split('/')[0..-2].join('/') + "/tools/WordCleaner7ComponentMono"
        #cmd_str = "mono #{word_cleaner_folder}/WordCleaner7ComponentMono.exe /t '#{word_cleaner_folder}/Templates/Convert\ to\ HTML\ embed\ images.wc' /f #{file_path} /o #{location} /of #{html_name}"
        cmd_str = "mono #{word_cleaner_folder}/WordCleaner7ComponentMono.exe /t '#{word_cleaner_folder}/Templates/swtk.wc' /f #{file_path} /o #{location} /of #{html_name}"
        #exec cmd_str
        #if not use popen, rails app will be interrupted
        p cmd_str
        IO.popen(cmd_str){|f| f.gets}
      rescue Exception => ex
        p ex.message
      end
      arr = IO.readlines(location + '/' + html_name)
      result = arr.join('')
      return result
    end
    module_function :get_doc_file_content_as_html

  end

  module Response

    # Analyze the params to check callback type
    def get_callback_type params
      params[:callback].blank? ? "3,,no" : ((params[:callback]=='window.name')? "1,,#{params[:callback]}" : "2,,#{params[:callback]}")
    end
    module_function :get_callback_type

    # Used for format the response data if have callback parameter    
    def format_response_json json_target,callback_type
      arr = callback_type.split(',,')
      data_str = ""

      case json_target.class.to_s
      when 'Hash','Array'#Array maybe no this type
        data_str = json_target.to_json
      when 'String'
        data_str = json_target
      end 

      case arr[0].to_i
      #如果request中带有callback参数，并且callback等于"window.name"
      when 1
        '<script type="text" id="json">
           {"data":' + data_str + '}
        </script>
        <script type="text/javascript">window.name=document.getElementById("json").innerHTML;</script>'
      #如果request中带有callback参数，并且callback不等于"window.name"（例如是"xui.SAjax.No._1"）
      when 2
        arr[1] + '({"data":' + data_str + '}});'
      #如果request中没有callback
      when 3
        '{"data":' + data_str  + '}'
      end
    end
    module_function :format_response_json

    # Used to change the bson id name to normal id name
    def exchange_record_id bson_id
      bson_id.gsub!(/(\"_id\":{\"\$oid\":)(\"[0-9a-z]{1,}\")(})/) do |m|      # do not know why the $2 cannot work
        '"id":' + m.scan(/(\"[0-9a-z]{1,}\")/)[0][0]
      end
      return bson_id
    end
    module_function :exchange_record_id

  end

  module Locale
    module_function

    KlassMapping ={
      "yi_ban" => "1",
      "er_ban" => "2",
      "san_ban" => "3",
      "si_ban" => "4",
      "wu_ban" => "5",
      "liu_ban" => "6",
      "qi_ban" => "7",
      "ba_ban" => "8",
      "jiu_ban" => "9",
      "shi_ban" => "10",
      "shi_yi_ban" => "11",
      "shi_er_ban" => "12",
      "shi_san_ban" => "13",
      "shi_si_ban" => "14",
      "shi_wu_ban" => "15",
      "shi_liu_ban" => "16",
      "shi_qi_ban" => "17",
      "shi_ba_ban" => "18",
      "shi_jiu_ban" => "19",
      "er_shi_ban" => "20",
      "er_shi_yi_ban" => "21",
      "er_shi_er_ban" => "22",
      "er_shi_san_ban" => "23",
      "er_shi_si_ban" => "24",
      "er_shi_wu_ban" => "25",
      "er_shi_liu_ban" => "26",
      "er_shi_qi_ban" => "27",
      "er_shi_ba_ban" => "28",
      "er_shi_jiu_ban" => "29",
      "san_shi_ban" => "30"
    }

    StatusOrder = {
      :new => "1",
      :editting => "2",
      :editted => "3",
      :analyzing => "4",
      :analyzed => "5",
      :score_importing => "6",
      :score_imported => "7",
      :report_generating => "8",
      :report_completed => "9",
      :none => "10000"
    }

    SubjectOrder = {
      :yu_wen => "1",
      :shu_xue => "2",
      :ying_yu => "3",
      :li_shi => "4",
      :di_li => "5",
      :wu_li => "6",
      :hua_xue => "7",
      :sheng_wu => "8",
      :si_xiang_pin_de => "9",
      :zheng_zhi => "10",
      :xin_xi_ji_shu => "11",
      :ji_shu => "12",
      :none => "10000"
    }

    GradeOrder = {
      :yi_nian_ji => "1",
      :er_nian_ji => "2",
      :san_nian_ji => "3",
      :si_nian_ji => "4",
      :wu_nian_ji => "5",
      :liu_nian_ji => "6",
      :qi_nian_ji => "7",
      :ba_nian_ji => "8",
      :jiu_nian_ji => "9",
      :gao_yi_nian_ji => "10",
      :gao_er_nian_ji => "11",
      :gao_san_nian_ji => "12",
      :none => "10000"
    }

    SubjectList = {
      :yu_wen => I18n.t("dict.yu_wen"),
      :shu_xue => I18n.t("dict.shu_xue"),
      :ying_yu => I18n.t("dict.ying_yu"),
      :li_shi => I18n.t("dict.li_shi"),
      :di_li => I18n.t("dict.di_li"),
      :wu_li => I18n.t("dict.wu_li"),
      :hua_xue => I18n.t("dict.hua_xue"),
      :sheng_wu => I18n.t("dict.sheng_wu"),
      :si_xiang_pin_de => I18n.t("dict.si_xiang_pin_de"),
      :zheng_zhi => I18n.t("dict.zheng_zhi"),
      :xin_xi_ji_shu => I18n.t("dict.xin_xi_ji_shu"),
      :ji_shu => I18n.t("dict.ji_shu")
    }

    GradeList = {
      :yi_nian_ji => I18n.t("dict.yi_nian_ji"),
      :er_nian_ji => I18n.t("dict.er_nian_ji"),
      :san_nian_ji => I18n.t("dict.san_nian_ji"),
      :si_nian_ji => I18n.t("dict.si_nian_ji"),
      :wu_nian_ji => I18n.t("dict.wu_nian_ji"),
      :liu_nian_ji => I18n.t("dict.liu_nian_ji"),
      :qi_nian_ji => I18n.t("dict.qi_nian_ji"),
      :ba_nian_ji => I18n.t("dict.ba_nian_ji"),
      :jiu_nian_ji => I18n.t("dict.jiu_nian_ji"),
      :gao_yi_nian_ji => I18n.t("dict.gao_yi_nian_ji"),
      :gao_er_nian_ji => I18n.t("dict.gao_er_nian_ji"),
      :gao_san_nian_ji => I18n.t("dict.gao_san_nian_ji")
    }

    KlassList = {
      :yi_ban => I18n.t("dict.yi_ban"),
      :er_ban => I18n.t("dict.er_ban"),
      :san_ban => I18n.t("dict.san_ban"),
      :si_ban => I18n.t("dict.si_ban"),
      :wu_ban => I18n.t("dict.wu_ban"),
      :liu_ban => I18n.t("dict.liu_ban"),
      :qi_ban => I18n.t("dict.qi_ban"),
      :ba_ban => I18n.t("dict.ba_ban"),
      :jiu_ban => I18n.t("dict.jiu_ban"),
      :shi_ban => I18n.t("dict.shi_ban"),
      :shi_yi_ban => I18n.t("dict.shi_yi_ban"),
      :shi_er_ban => I18n.t("dict.shi_er_ban"),
      :shi_san_ban => I18n.t("dict.shi_san_ban"),
      :shi_si_ban => I18n.t("dict.shi_si_ban"),
      :shi_wu_ban => I18n.t("dict.shi_wu_ban"),
      :shi_liu_ban => I18n.t("dict.shi_liu_ban"),
      :shi_qi_ban => I18n.t("dict.shi_qi_ban"),
      :shi_ba_ban => I18n.t("dict.shi_ba_ban"),
      :shi_jiu_ban => I18n.t("dict.shi_jiu_ban"),
      :er_shi_ban => I18n.t("dict.er_shi_ban"),
      :er_shi_yi_ban => I18n.t("dict.er_shi_yi_ban"),
      :er_shi_er_ban => I18n.t("dict.er_shi_er_ban"),
      :er_shi_san_ban => I18n.t("dict.er_shi_san_ban"),
      :er_shi_si_ban => I18n.t("dict.er_shi_si_ban"),
      :er_shi_wu_ban => I18n.t("dict.er_shi_wu_ban"),
      :er_shi_liu_ban => I18n.t("dict.er_shi_liu_ban"),
      :er_shi_qi_ban => I18n.t("dict.er_shi_qi_ban"),
      :er_shi_ba_ban => I18n.t("dict.er_shi_ba_ban"),
      :er_shi_jiu_ban => I18n.t("dict.er_shi_jiu_ban"),
      :san_shi_ban => I18n.t("dict.san_shi_ban")
    }

    def hanzi2pinyin hanzi_str
      PinYin.backend = PinYin::Backend::Simple.new
      PinYin.of_string(hanzi_str).join("_")
    end

    def hanzi2abbrev shanzi_str
      PinYin.backend = PinYin::Backend::Simple.new
      PinYin.abbr(shanzi_str) 
    end

    def mysort(x,y)
      x = x || ""
      y = y || ""
      length = (x.length > y.length) ? x.length : y.length
      x = x.rjust(length, '0')
      y = y.rjust(length, '0')
      0.upto(length-1) do |i|
        if x[i] == y[i]
          next
        else
          if x[i] =~ /[0-9]/
            if y[i] =~ /[0-9]/
              return x[i] <=> y[i]
            else
              return 1
            end
          elsif y[i] =~ /[0-9]/
            return  -1
          else
            return x[i] <=> y[i]
          end
        end
      end
    end
  end
end
