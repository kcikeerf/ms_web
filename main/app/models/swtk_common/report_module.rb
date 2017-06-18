# -*- coding: utf-8 -*-
# 
require 'fileutils'

module ReportModule
  module Report
    module_function

    def get_test_report_url test_id, rpt_type, rpt_id
      target_path = "/" + "reports_warehouse/tests/" + test_id+ '/.*' + rpt_type + '/' + rpt_id + '.json(\\?ext_data_path=.*){0,}'
      re = Regexp.new target_path
      target_url = Mongodb::TestReportUrl.where(test_id: test_id, report_url: re).first
      return target_url.blank?? "" : target_url.report_url
    end

    module Thread
      NumPerTh = 50
      ThNum = 5
      ThNumMax = 20
    end

    module WareHouse
      module_function

      ReportLocation = Rails.root.to_s + "/"
      # 报告保存格式
      # /reports/测试id／类型／租户uid／类型id
      #
      # /reports/测试id／tenants／租户uid／班级uid／学生uid
      # /reports/测试id／tenants/Tenant uid／Location uid/Pupil uid

      def store_report_json path, file_name, str
        FileUtils.mkdir_p path
        File.write(path+"/#{file_name}.json", str)
      end
    end

    module Url
      Length = 6
    end

    module CheckPoints
      DefaultLevel = 2
      DefaultLevelFrom = 1
      DefaultLevelTo = 2
      DefaultLevelEnd = 3
      Levels = 2
    end

    module PaperOutlines
      DefaultLevel = 2
      DefaultLevelFrom = 1
      DefaultLevelTo = 2
      DefaultLevelEnd = 3
      Levels = 2
    end

    module ScoreLevel
      LevelNone = -1
      Level0 = 0
      Level60 = 0.6
      Level85 = 0.85

      module Label
        LevelNone = "none"
        Level0 = "failed_level"
        Level60 = "good_level"
        Level85 = "excellent_level"
      end
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

    module Group
      ListArr = ["pupil", "klass", "grade", "project"]
      Pupil = "pupil"
      Klass = "klass"
      Grade = "grade"
      Project = "project"
    end

    module Type
      Pupil = '000'
      Klass = '001'
      Grade = '002'
      Project = '003'
    end

    module Format
      #班级报告解读文字
=begin
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

<li>1. 听
<ol>

<li>1.1 记忆（听）：通过听的方式，从长期记忆取回有关知识的思维过程；
<ol>
<li>
1.1.1再认（听）：通过听的方式，对再次出现的信息能够识别的思维过程；
<div class='report_explanation_example'>
示例：从下列选项中找出你所听到的单词或短语。
</div>
</li>
<li>
1.1.2再现（听）：通过听的方式，从记忆中提取所需信息的思维过程；
<div class='report_explanation_example'>
示例：听写单词。
</div>
</li>
</ol>
</li>

<li>
1.2 理解（听）：从听的方式中建构意义的思维过程；
<ol>

<li>
1.2.1 意义建构（听）：将听到的内容转化成有意义的信息并产生相应的反应的思维过程；
<div class='report_explanation_example'>
示例：找出与所听到的句子意义相同的选项。
</div>
</li>

<li>
1.2.2 匹配（听）：找出所听到信息与所看到的信息的一致性，并将两者搭配起来的思维过程；
<div class='report_explanation_example'>
示例：听对话，从下面各题所给的图片中选择与对话内容相符的图片。
</div>
</li>

<li>
1.2.3 信息提取（听）：从长篇对话或听力材料中获取信息的思维过程
<ol>
<li>
1.2.3.1 直接提取（听）：从长篇对话或者听力材料中直接获取所需信息的思维过程；
<div class='report_explanation_example'>
示例：听短文，选出最恰当的一项。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Where does Mr. Green come from? (    )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. London&nbsp;&nbsp;&nbsp;B. China&nbsp;&nbsp;&nbsp;C. Boston<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;原文中有明确的说明：Mr. Green is from London.
</div>
</li>
<li>
1.2.3.2间接提取（听）：从长篇对话或听力材料中，经过语义转换获取所需信息的思维过程；
<div class='report_explanation_example'>
示例：听短文，选出最恰当的一项。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What does Mr. Green do every night? (    )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. Read books.&nbsp;&nbsp;&nbsp;B.&nbsp;&nbsp;&nbsp;Exercise.&nbsp;&nbsp;&nbsp;C. Learn Chinese<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;原文中的说法是：Mr. Green goes to Chinese classes every night.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;学生需要将goes to Chinese classes转换成Learn Chinese才能完成匹配。
</div>
</li>
</ol>

<li>
1.2.4 综合概括（听）：对长篇对话或听力材料的主要内容、主旨进行归纳概括的思维过程；
<div class='report_explanation_example'>
示例：What’s the dialogue about？
</div>
</li>

<li>
1.2.5 推理（听）：根据长篇对话或听力材料中的信息，做出超越文本的推测的思维过程；
<div class='report_explanation_example'>
示例：Who is the speaker? (&nbsp;&nbsp;&nbsp;)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A manager.&nbsp;&nbsp;&nbsp;B. A teacher.&nbsp;&nbsp;&nbsp;C. A guide.
</div>
</li>

</ol>
</li>

<li>
1.3 分析（听）：将长篇对话或听力材料分解成各个部分，并确定各部分彼此和与整体结构或目的关系；
<ol>
<li>
1.3.1 区分（听）：对听力材料中高度相似的信息加以分辨，找出符合条件的信息的思维过程；
<div class='report_explanation_example'>
示例：According to the speaker, what time will be the shop open at?<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. 8:15.&nbsp;&nbsp;&nbsp;B. 8:50.&nbsp;&nbsp;&nbsp;C. 8:45.<br>
</div>
</li>
<li>
1.3.2 归因（听）：确定听力材料隐含的观点、偏见、价值观或意图的思维过程；
<div class='report_explanation_example'>
示例：What’s the speaker’s attitude to the news?
</div>
</li>

</ol>
</li>

</ol>
</li>


<li>2. 读
<ol>

<li>
2.1记忆（读）：通过读的方式，从长期记忆取回有关知识的思维过程；
<ol>
<li>
2.1.1再认（读）：通过读的方式，对再次出现的信息能够识别的思维过程；
<div class='report_explanation_example'>
示例：为下列单词选出正确的释义
</div>
</li>
<li>
2.1.2再现（读）：通过读的方式，从记忆中提取所需信息的思维过程；
<div class='report_explanation_example'>
示例：
</div>
</li>
</ol>
</li>

<li>
2.2 理解（读）：从读的方式中建构意义的思维过程
<ol>
<li>
2.2.1 意义建构（读）：将读到的内容转化成有意义的信息并产生相应的反应的思维过程；
<div class='report_explanation_example'>
示例：将下列英文句子翻译成汉语。
</div>
</li>
<li>
2.2.2 匹配（读）：将信息一致或近似的单词、句子搭配起来的思维过程；
<div class='report_explanation_example'>
示例：读句子，从下面各题所给的图片中选择与句子意义相符的图片。
</div>
</li>
<li>
2.2.3 信息提取（读）：从长篇对话或阅读材料中获取信息的思维过程
<ol>
<li>
2.2.3.1 直接提取（读）：从长篇对话或者阅读材料中直接获取所需信息的思维过程；
<div class='report_explanation_example'>
示例：读短文，选出最恰当的一项。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Where does Mr. Green come from? (&nbsp;&nbsp;&nbsp;)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. London&nbsp;&nbsp;&nbsp;B. China&nbsp;&nbsp;&nbsp;C. Boston<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;原文中有明确的说明：Mr. Green is from London.
</div>
</li>
<li>
2.2.3.2间接提取（读）：从长篇对话或阅读材料中，经过语义转换获取所需信息的思维过程；
<div class='report_explanation_example'>
示例：读短文，选出最恰当的一项。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;What does Mr. Green do every night? (&nbsp;&nbsp;&nbsp;)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. Read books.&nbsp;&nbsp;&nbsp;B. Exercise.&nbsp;&nbsp;&nbsp;C. Learn Chinese<br>
<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;原文中的说法是：Mr. Green goes to Chinese classes every night.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;学生需要将goes to Chinese classes转换成Learn Chinese才能完成匹配。<br>
</div>
</li>
</ol>
</li>
<li>
2.2.4 综合概括（读）：对长篇对话或阅读材料的主要内容、主旨进行归纳概括的思维过程；
<div class='report_explanation_example'>
示例：What’s the main idea of the article？
</div>
</li>
<li>
2.2.5 推理（读）：根据长篇对话或阅读材料中的信息，做出超越文本的推测的思维过程；
<div class='report_explanation_example'>
示例：What can you infer from paragraph 2? (&nbsp;&nbsp;&nbsp;)
</div>
</li>
</ol>
</li>

<li>
2.3 分析（读）：将长篇对话或阅读材料分解成各个部分，并确定各部分彼此和与整体结构或目的关系；
<ol>
<li>
2.3.1 区分（读）：对高度相似的信息加以分辨，找出符合条件的信息的思维过程；
<div class='report_explanation_example'>
示例：I a very interesting film last night.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. watched&nbsp;&nbsp;&nbsp;B. saw&nbsp;&nbsp;&nbsp;C. looked at.
</div>
</li>
<li>
2.3.2 归因（读）：确定阅读材料隐含的观点、偏见、价值观或意图的思维过程；
<div class='report_explanation_example'>
示例：The writer wants to tell us to.
</div>
</li>
<li>
2.3.3 结构剖析（读）：确定词序、句子的成分、文章的结构、写作手法或风格的恰当性等的思维过程；
<div class='report_explanation_example'>
示例：E-book ________by more and more people in our daily life now. <br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. uses&nbsp;&nbsp;&nbsp;B. used&nbsp;&nbsp;&nbsp;C. is used&nbsp;&nbsp;&nbsp;D. was used
</div>
</li>
</ol>
</li>

</ol>
</li>


<li>3. 写
<ol>

<li>
3.1 记忆（写）
<ol>
<li>
3.1.1 抄写：按照给出的原文写下来。
<div class='report_explanation_example'>
示例：抄写下面的单词，注意书写美观。
</div>
</li>
<li>
3.1.2 默写：从长时记忆中提取信息并写下来的过程。
<div class='report_explanation_example'>
示例：看图写单词。
</div>
</li>
</ol>
</li>

<li>
3.2 应用
<ol>
<li>
3.2.1 模仿：在相似度较高的情境下将学习过的知识，通过书写的方式呈现出来的过程。
<div class='report_explanation_example'>
示例：根据要求修改句子：<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;（1）He is a good student.(改成否定句)<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;（2）It’s a nice picture. (对划线部分提问)
</div>
</li>
<li>
3.2.2 迁移：将学习过的知识在新的情景中以恰当的形式重组，并通过书写的方式呈现出来的过程。
<div class='report_explanation_example'>
示例：阅读下面短文，回答问题<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;（短文略）<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. Where does Mary live now?  ( In 4 words )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. Who does she often try to speak Chinese to? ( In 10 words )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. Where is Mary going on Saturday morning? ( In 5 or 6 words )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;4. What is she going to do there? ( In 7 or 8 words )<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;5. How does she ask the way? ( In 8 words )
</div>
</li>
</ol>
</li>

<li>
3.3 表达
<ol>
<li>
3.3.1 记叙性表达：以记人、叙事、写景、状物为主，对社会生活中的人、串、景、物的情态变化和发展进行叙述和描写的表达。
<div class='report_explanation_example'>
示例：以“My Friend”为题，写80词的短文。
</div>
</li>
<li>
3.3.2 说明性表达：对事物的形状、性质、特征、成因、关系、功用等进行解说的表达。
<div class='report_explanation_example'>
示例：Write a paragraph to describe your bedroom。
</div>
</li>
<li>
3.3.3 议论性表达：对事件发表意见、主张和看法的表达。
<div class='report_explanation_example'>
示例：许多中学不允许学生带手机到学校，对此要求你有什么看法？写120左右的短文。
</div>
</li>
<li>
3.3.4 应用性表达：为处理生活、学习、工作中的实际事物而进行的表达。
<div class='report_explanation_example'>
示例：时值圣诞节，班级要召开一次联欢会，请针对这一活动，写一个通知。
</div>
</li>
</ol>
</li>

</ol>
</li>


</ol>
</dd>


<dt>能力指标</dt>
<dd>
<ol>

<li>
1. 语言-言语：有效地运用口头语言及文字的能力;
<ol>

<li>
1.1 词汇辨析：对词音、词型、词义、词法进行区分，找出最符合条件的能力。
<ol>
<li>
1.1.1 词音辨析：对单词的发音进行区分，找出最符合条件的能力。
<div class='report_explanation_example'>
示例：下列各组单词中有一个单词的划线部分读音与其他两个不同，请把它选出来。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. A. clothes&nbsp;&nbsp;&nbsp;B. potato&nbsp;&nbsp;&nbsp;C. office<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. A. river&nbsp;&nbsp;&nbsp;&nbsp;B. nice&nbsp;&nbsp;&nbsp;C. size
</div>
</li>
<li>
1.1.2 词型辨析：对单词的拼写形式进行区分，找出最符合条件的能力。
<div class='report_explanation_example'>
示例：I can see animals. They’re （&nbsp;&nbsp;&nbsp;）.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. boats&nbsp;&nbsp;&nbsp;B. coats&nbsp;&nbsp;&nbsp;C. goats<br>
</div>
</li>
<li>
1.1.3 词义辨析：对单词或短语的意义进行区分，找出最符合条件的能力。
<div class='report_explanation_example'>
示例：The teacher’s desk is （&nbsp;&nbsp;&nbsp;）classroom.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. in the front of&nbsp;&nbsp;&nbsp;B. in front of&nbsp;&nbsp;&nbsp;C. in front<br>  
</div>
</li>
<li>
1.1.4 词法辨析：对单词或短语的用法进行区分，找出最符合条件的能力。
<div class='report_explanation_example'>
示例：The English novel is quite easy for you. There are （&nbsp;&nbsp;&nbsp;）new words in it.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. a little&nbsp;&nbsp;&nbsp;B. little&nbsp;&nbsp;&nbsp;C. a few&nbsp;&nbsp;&nbsp;D. few
</div>
</li>
</ol>
</li>
<li>

<li>
1.2 语言理解：通过口头语言或文字建构意义，表达思想，实现交流与沟通目的的能力。
<ol>
<li>
1.2.1 建构性理解：将口头语言、文字、图形、符号转化成有意义的信息，并做出相应反应的能力。
<div class='report_explanation_example'>
示例：根据图片写句子。
<img src='/images/report_explanation_ability1.png'>
</div>
</li>
<li>
1.2.2 匹配性理解：将具有一致性或相关联系的两个事物、观点或其他类似物匹配起来的能力。
<div class='report_explanation_example'>
示例：<br>
Come and see the Indian elephants and tigers from America. The koalas are waiting to meet you, and the monkeys from Thailand are waiting to throw things at you. The cute dogs from Australia are waiting to laugh at you, and the giraffes from Zambia are waiting to look down on you. <br>
&nbsp;&nbsp;&nbsp;Come and enjoy your special day! Kids!<br>
<img src='/images/report_explanation_ability2.png' width='60%'>
<br>
How many kinds of animals are talked about in the poster(海报)?<br>
&nbsp;&nbsp;&nbsp;A. 4&nbsp;&nbsp;&nbsp;B. 5&nbsp;&nbsp;&nbsp;C. 6&nbsp;&nbsp;&nbsp;D. 7<br>
</div>
</li>
<li>
1.2.3 概括性理解：综合各种信息，得出概括性结论的能力。
<div class='report_explanation_example'>
示例：The passage is mainly about（&nbsp;&nbsp;&nbsp;）.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. the car in the future&nbsp;&nbsp;&nbsp;B. pollution in the car<br>    
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;C. gasoline the car needed&nbsp;&nbsp;&nbsp;D. the road in the future
</div>
</li>
<li>
1.2.4 推理性理解：综合各种信息，得出符合逻辑的推论的能力。
<div class='report_explanation_example'>
示例：<br>
<img src='/images/report_explanation_ability3.png' width='60%'><br>
根据短文内容，判断正（T）误（F）。<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Janna is thirteen. She has no money, but she can go into the zoo. （&nbsp;&nbsp;&nbsp;）
</div>
</li>
</ol>
</li>

</li>
</ol>
</li>

<li>
2 数理-逻辑：有效运用数字和推理的能力
<ol>
<li>
2.1 逻辑分析：发现句子、文章内在逻辑结构或逻辑关系或以有逻辑的结构或关系表述事物的能力。
<ol>
<li>
2.1.1 关系分析：发现句子、文章内在逻辑关系或以符合逻辑的关系表述事物的能力。
<div class='report_explanation_example'>
示例：你如何看待“中学生不能带手机到学校”的校规？<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;要求：观点明确，论述合理，文章具有逻辑性。
</div>
</li>
<li>
2.1.2 结构分析：发现句子、文章逻辑结构或以恰当的结构表述事物的能力。
<div class='report_explanation_example'>
示例：<br>
&nbsp;&nbsp;&nbsp;（1） happy life the old live!<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. What a&nbsp;&nbsp;&nbsp;B. What&nbsp;&nbsp;&nbsp;C. How<br>
&nbsp;&nbsp;&nbsp;（2）The structure of the article is（&nbsp;&nbsp;&nbsp;）.<br>
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;A. time-ordered&nbsp;&nbsp;&nbsp;B. space-ordered&nbsp;&nbsp;&nbsp;C. event-ordered.
</div>
</li>
</ol>
</li>
</ol>
</li>

<li>
3 交流-交际：领会和体验他人的情绪、情感、意图、目的能力
<ol>
<li>
3.1 人际理解：通过文本领会和体验他人的情绪、情感、意图、目的的能力。
<ol>
<li>
3.1.1 作者理解：领会和体验作者透过文本表达的情绪、情感、意图、目的等的能力。
<div class='report_explanation_example'>
示例：What’s the purpose of the author?
</div>
</li>
<li>
3.1.2 作品理解：领会和体验文本中人物情绪、情感、意图、目的等的能力。
<div class='report_explanation_example'>
示例：According to the article, why did Andy say those words?
</div>
</li>
</ol>
</li>
</ol>
</li>

<li>
4 自知-自省：自我反思、自我省察、自我表达的能力。
<ol>
<li>
4.1 自我情感认识：对自己情绪反思、觉察及表达的能力。
</li>
<li>
4.2 自我态度认识：对自己对事物的态度的反思、觉察及表达的能力。
</li>
<li>
4.3 自我价值观认识：对自己的价值观的反思、觉察及表达的能力。
<div class='report_explanation_example'>
示例：How do you think of “Chinese crossing street”?
</div>
</li>
</ol>
</li>

</ol>
</dd>



</dl>
</div>
</div>
</div>
          ",
=end

      KlassExplanation = {
          "three_dimesions"=> "",
=begin
          "
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

<li>1. 听
<ol>

<li>1.1 记忆（听）：通过听的方式，从长期记忆取回有关知识的思维过程；
<ol>
<li>
1.1.1再认（听）：通过听的方式，对再次出现的信息能够识别的思维过程；
</li>
<li>
1.1.2再现（听）：通过听的方式，从记忆中提取所需信息的思维过程；
</li>
</ol>
</li>

<li>
1.2 理解（听）：从听的方式中建构意义的思维过程；
<ol>

<li>
1.2.1 意义建构（听）：将听到的内容转化成有意义的信息并产生相应的反应的思维过程；
</li>

<li>
1.2.2 匹配（听）：找出所听到信息与所看到的信息的一致性，并将两者搭配起来的思维过程；
</li>

<li>
1.2.3 信息提取（听）：从长篇对话或听力材料中获取信息的思维过程
<ol>
<li>
1.2.3.1 直接提取（听）：从长篇对话或者听力材料中直接获取所需信息的思维过程；
</li>
<li>
1.2.3.2间接提取（听）：从长篇对话或听力材料中，经过语义转换获取所需信息的思维过程；
</li>
</ol>

<li>
1.2.4 综合概括（听）：对长篇对话或听力材料的主要内容、主旨进行归纳概括的思维过程；
</li>

<li>
1.2.5 推理（听）：根据长篇对话或听力材料中的信息，做出超越文本的推测的思维过程；
</li>

</ol>
</li>

<li>
1.3 分析（听）：将长篇对话或听力材料分解成各个部分，并确定各部分彼此和与整体结构或目的关系；
<ol>
<li>
1.3.1 区分（听）：对听力材料中高度相似的信息加以分辨，找出符合条件的信息的思维过程；
</li>
<li>
1.3.2 归因（听）：确定听力材料隐含的观点、偏见、价值观或意图的思维过程；
</li>

</ol>
</li>

</ol>
</li>


<li>2. 读
<ol>

<li>
2.1记忆（读）：通过读的方式，从长期记忆取回有关知识的思维过程；
<ol>
<li>
2.1.1再认（读）：通过读的方式，对再次出现的信息能够识别的思维过程；
</li>
<li>
2.1.2再现（读）：通过读的方式，从记忆中提取所需信息的思维过程；
</li>
</ol>
</li>

<li>
2.2 理解（读）：从读的方式中建构意义的思维过程
<ol>
<li>
2.2.1 意义建构（读）：将读到的内容转化成有意义的信息并产生相应的反应的思维过程；
</li>
<li>
2.2.2 匹配（读）：将信息一致或近似的单词、句子搭配起来的思维过程；
</li>
<li>
2.2.3 信息提取（读）：从长篇对话或阅读材料中获取信息的思维过程
<ol>
<li>
2.2.3.1 直接提取（读）：从长篇对话或者阅读材料中直接获取所需信息的思维过程；
</li>
<li>
2.2.3.2间接提取（读）：从长篇对话或阅读材料中，经过语义转换获取所需信息的思维过程；
</li>
</ol>
</li>
<li>
2.2.4 综合概括（读）：对长篇对话或阅读材料的主要内容、主旨进行归纳概括的思维过程；
</li>
<li>
2.2.5 推理（读）：根据长篇对话或阅读材料中的信息，做出超越文本的推测的思维过程；
</li>
</ol>
</li>

<li>
2.3 分析（读）：将长篇对话或阅读材料分解成各个部分，并确定各部分彼此和与整体结构或目的关系；
<ol>
<li>
2.3.1 区分（读）：对高度相似的信息加以分辨，找出符合条件的信息的思维过程；
</li>
<li>
2.3.2 归因（读）：确定阅读材料隐含的观点、偏见、价值观或意图的思维过程；
</li>
<li>
2.3.3 结构剖析（读）：确定词序、句子的成分、文章的结构、写作手法或风格的恰当性等的思维过程；
</li>
</ol>
</li>

</ol>
</li>


<li>3. 写
<ol>

<li>
3.1 记忆（写）
<ol>
<li>
3.1.1 抄写：按照给出的原文写下来。
</li>
<li>
3.1.2 默写：从长时记忆中提取信息并写下来的过程。
</li>
</ol>
</li>

<li>
3.2 应用
<ol>
<li>
3.2.1 模仿：在相似度较高的情境下将学习过的知识，通过书写的方式呈现出来的过程。
</li>
<li>
3.2.2 迁移：将学习过的知识在新的情景中以恰当的形式重组，并通过书写的方式呈现出来的过程。
</li>
</ol>
</li>

<li>
3.3 表达
<ol>
<li>
3.3.1 记叙性表达：以记人、叙事、写景、状物为主，对社会生活中的人、串、景、物的情态变化和发展进行叙述和描写的表达。
</li>
<li>
3.3.2 说明性表达：对事物的形状、性质、特征、成因、关系、功用等进行解说的表达。
</li>
<li>
3.3.3 议论性表达：对事件发表意见、主张和看法的表达。
</li>
<li>
3.3.4 应用性表达：为处理生活、学习、工作中的实际事物而进行的表达。
</li>
</ol>
</li>

</ol>
</li>


</ol>
</dd>


<dt>能力指标</dt>
<dd>
<ol>

<li>
1. 语言-言语：有效地运用口头语言及文字的能力;
<ol>

<li>
1.1 词汇辨析：对词音、词型、词义、词法进行区分，找出最符合条件的能力。
<ol>
<li>
1.1.1 词音辨析：对单词的发音进行区分，找出最符合条件的能力。
</li>
<li>
1.1.2 词型辨析：对单词的拼写形式进行区分，找出最符合条件的能力。
</li>
<li>
1.1.3 词义辨析：对单词或短语的意义进行区分，找出最符合条件的能力。
</li>
<li>
1.1.4 词法辨析：对单词或短语的用法进行区分，找出最符合条件的能力。
</li>
</ol>
</li>
<li>

<li>
1.2 语言理解：通过口头语言或文字建构意义，表达思想，实现交流与沟通目的的能力。
<ol>
<li>
1.2.1 建构性理解：将口头语言、文字、图形、符号转化成有意义的信息，并做出相应反应的能力。
</li>
<li>
1.2.2 匹配性理解：将具有一致性或相关联系的两个事物、观点或其他类似物匹配起来的能力。
</li>
<li>
1.2.3 概括性理解：综合各种信息，得出概括性结论的能力。
</li>
<li>
1.2.4 推理性理解：综合各种信息，得出符合逻辑的推论的能力。
</li>
</ol>
</li>

</li>
</ol>
</li>

<li>
2 数理-逻辑：有效运用数字和推理的能力
<ol>
<li>
2.1 逻辑分析：发现句子、文章内在逻辑结构或逻辑关系或以有逻辑的结构或关系表述事物的能力。
<ol>
<li>
2.1.1 关系分析：发现句子、文章内在逻辑关系或以符合逻辑的关系表述事物的能力。
</li>
<li>
2.1.2 结构分析：发现句子、文章逻辑结构或以恰当的结构表述事物的能力。
</li>
</ol>
</li>
</ol>
</li>

<li>
3 交流-交际：领会和体验他人的情绪、情感、意图、目的能力
<ol>
<li>
3.1 人际理解：通过文本领会和体验他人的情绪、情感、意图、目的的能力。
<ol>
<li>
3.1.1 作者理解：领会和体验作者透过文本表达的情绪、情感、意图、目的等的能力。
</li>
<li>
3.1.2 作品理解：领会和体验文本中人物情绪、情感、意图、目的等的能力。
</li>
</ol>
</li>
</ol>
</li>

<li>
4 自知-自省：自我反思、自我省察、自我表达的能力。
<ol>
<li>
4.1 自我情感认识：对自己情绪反思、觉察及表达的能力。
</li>
<li>
4.2 自我态度认识：对自己对事物的态度的反思、觉察及表达的能力。
</li>
<li>
4.3 自我价值观认识：对自己的价值观的反思、觉察及表达的能力。
</li>
</ol>
</li>

</ol>
</dd>



</dl>
</div>
</div>
</div>",
=end
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
<li>
班级平均得分率：班级平均得分率表明班级总体的得分情况，
即班级学生在各个指标上的整体达标情况（不包括成绩为零的学生），
公式为：（全班学生某指标的平均分/该指标的满分值） × 100。
</li>
<li>
班级中位数得分率：将全班学生成绩从高到低排序后，
恰好处于中间位置的学生的成绩情况，
公式为：（全班学生某指标得分的中位数/该指标的满分值） × 100。
</li>
<li>
年级平均得分率：年级全体参测学生在各个指标上的整体达标情况（不包括成绩为零的学生），
公式为：（年级参测学生某指标的平均分/该指标的满分值） × 100。
</li>
<li>
分化程度：本班学生在某一指标上的成绩离散情况，数值越大，表明班级成绩的不均衡性越高。
公式为：（标准差/平均数） × 100。
</li>
<li>
百分等级：一个测验分数的百分等级是指在常模样本中低于这个分数的人数百分比。
比如一个测验分数百分等级是85，则表示在常模样本中有85%的人比这个分数要低。
换句话说，百分等级指出的是个体在常模团体中所处的位置，百分等级越低，个体所处的位置越低。
公式为：Pr=100-{(100×R-50)÷N}
</li>
<li>
四分位区间：将一组数据从大到小排列，计算每个数据对应的百分等级，百分等级100和75之间是上四分位区间；
75和50之间为中上四分位区间；50和25之间为中下四分位区间；小于25%区间为下四分位区间。
[ ]代表该区间包含临近的数值，（ ）代表该区间不包含临近的数值。
</li>
<li>
满分值：本次测试为每个指标设定的最高值。
</li>
</ol>
</dd>
</dl>
</div>
</div>
</div>
          ",

          "data" => ""
=begin
          "
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
<li>年级平均得分率越高，表明年级学生在技能方面的总体达标情况越好。理想的数值应该在90以上。当某个技能点的平均得分率低于70时，则需要引起任课老师的关注。
对于达标考试而言，这样的得分率表明本班有很多学生并未很好的掌握这部分技能。</li>
<li>认知是学习中所必须的基础技能。如果年级学生在此项技能上的得分率较低，表明基本功还不扎实。学生在学习上所投入的时间和精力还存在不足，或者是方法不对。
需要教师对照本班的实际情况，激发学生的学习兴趣，引导学生调整学习方法。</li>
<li>理解的得分率较低则表明学生的学习并未实现有效的迁移，还停留在死记硬背的阶段。因此，需要教师帮助学生学会举一反三。</li>
<li>信息提取是阅读中对理解要求最低的一项技能。如果年级学生在此项技能上的得分率较低，教师需要关注本班学生是否掌握了最基本的阅读方法。</li>
<li>推理、分析和表达是阅读理解中较高级的理解能力。如果年级学生在这些技能项上的得分率较低，则表明学生的阅读习惯不好。
阅读的目的仅仅是为了回答问题，而没有真正想去理解文章的内容。因此，教师需要在日常教学中引导学生培养良好的阅读习惯，不是为了阅读而阅读，
而是要站在真正从文章中获取一定的信息，理解文章的基本内容，理解作者的写作目的和意图的角度去阅读。</li>
<li>年级中位数得分率越高，表明年级中50%的学生技能达标情况越好，当该数值高于年级平均得分率时，表明本班虽然有较多的高分，但因为存在极端低分值，
从而使平均得分率不能很好的代表年级的总体水平。技能中位数得分率低于平均得分率，需要结合基础技能和高级思维技能在本次考试中所占比重的情况综合考虑。
如果基础技能所占比重较大，且年级学生技能低分又较多，则表明多数学生需掌握的基础技能并没有掌握好，可能与训练较少有关；如果高级技能所占比重较大，
则表明试题难度与多数学生的水平不相匹配，任课教师需要在高级思维技能方面给学生以更多的引导和关注</li>
<li>分化程度越小，表明任课老师在全体学生共同进步方面所投入的精力越大。分化程度越大，表明年级学生的分化现象越严重，
需要教师针对不同群体的学生采取不同的训练策略，以防止分化进一步加剧。正常的情况应该是学生在基础技能项上的分化程度要小，在高级技能项上的分化程度要大。</li>
<li>任课教师可选取分化程度最大的技能点作为调整教学策略的最初切入点。</li>
</ul>
</dd>
</dl>
<dl>
<dt>能力</dt>
<dd>
<ul>
<li>年级平均得分率越高，表明年级能力表现越好，理想的数值应该在90以上。当某个能力点的平均得分率低于70时，则需要引起任课老师的关注。
这表明本班学生在该能力项上存在不足，某一能力项的不足会影响学生在后期接受相关知识时的速度和效率。</li>
<li>年级中位数得分率越高，表明年级中50%的学生能力表现情况越好，当该数值高于年级平均得分率时，表明本班虽然有较多的高分，但因为存在极端低分值，
从而使能力的平均得分率不能很好的代表年级的总体的能力水平。</li>
<li>分化程度越小，表明年级学生在该能力项的同质水平越高，大班制的授课方式的效果也越好。分化程度越大，表明年级学生在该能力项上的差异越大，
大班制的授课方式所能取得的整体效果越差，会导致能力强的学生的能力得不到有效的开发，而能力弱的学生则不能从现有的授课方式和训练方式中获得最大的收益。</li>
<li>任课教师可选取分化程度最大的能力点作为调整能力开发的基点。</li>
</ul>
</dd>
</dl>
</div>
</div>
</div>
          "
=end
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
          "term" => "",
          "klass_count" => "",
          "pupil_number" => "",
          "quiz_type" => "",
          "quiz_date" => "",
          "levelword2" => "",
          "value_ratio" => 1
        },
        "display_limit" => {
          #诊断图
          "charts" => {
            "knowledge_3lines" => Format::DisplayLimit["default"],
            "knowledge_med_avg_diff" => Format::DisplayLimit["default"],
            "skill_3lines" => Format::DisplayLimit["default"],
            "skill_med_avg_diff" => Format::DisplayLimit["default"],
            "ability_3lines" => Format::DisplayLimit["default"],
            "ability_med_avg_diff" => Format::DisplayLimit["default"],
            "dimesion_disperse" => -1
          },
          #各分数段人数比例
          "each_level_number" => {
            "grade_knowledge"=> Format::DisplayLimit["default"],
            "grade_skill"=> Format::DisplayLimit["default"],
            "grade_ability"=> Format::DisplayLimit["default"]
          },
          #四分位区间表现情况
          "four_sections" => {
            "level75"=> {
              "knowledge" => Format::DisplayLimit["default"],
              "skill" => Format::DisplayLimit["default"],
              "ability" => Format::DisplayLimit["default"]
            },
            "level50"=> {
              "knowledge" => Format::DisplayLimit["default"],
              "skill" => Format::DisplayLimit["default"],
              "ability" => Format::DisplayLimit["default"]
            },
            "level25"=> {
              "knowledge" => Format::DisplayLimit["default"],
              "skill" => Format::DisplayLimit["default"],
              "ability" => Format::DisplayLimit["default"]
            },
            "level0"=> {
              "knowledge" => Format::DisplayLimit["default"],
              "skill" => Format::DisplayLimit["default"],
              "ability" => Format::DisplayLimit["default"]
            }
          },
          #各指标水平图
          "each_checkpoint_horizon" => {
            "knowledge" => {
              "average_percent" => Format::DisplayLimit["default"],
              "median_percent" => Format::DisplayLimit["default"],
              "med_avg_diff" => Format::DisplayLimit["default"],
              "diff_degree" => Format::DisplayLimit["default"]
            },
            "skill" => {
              "average_percent" => Format::DisplayLimit["default"],
              "median_percent" => Format::DisplayLimit["default"],
              "med_avg_diff" => Format::DisplayLimit["default"],
              "diff_degree" => Format::DisplayLimit["default"]
            },
            "ability" => {
              "average_percent" => Format::DisplayLimit["default"],
              "median_percent" => Format::DisplayLimit["default"],
              "med_avg_diff" => Format::DisplayLimit["default"],
              "diff_degree" => Format::DisplayLimit["default"]
            },
            "total" => {
              "average_percent" => Format::DisplayLimit["default"],
              "median_percent" => Format::DisplayLimit["default"],
              "med_avg_diff" => Format::DisplayLimit["default"],
              "diff_degree" => Format::DisplayLimit["default"]
            },

          },
          #各班分数段人数比例
          "each_class_pupil_number_chart" => {
            "knowledge" => {
              "excellent_pupil_percent" => Format::DisplayLimit["default"],
              "good_pupil_percent" => Format::DisplayLimit["default"],
              "failed_pupil_percent" => Format::DisplayLimit["default"]
            },
            "skill" => {
              "excellent_pupil_percent" => Format::DisplayLimit["default"],
              "good_pupil_percent" => Format::DisplayLimit["default"],
              "failed_pupil_percent" => Format::DisplayLimit["default"]
            },
            "ability" => {
              "excellent_pupil_percent" => Format::DisplayLimit["default"],
              "good_pupil_percent" => Format::DisplayLimit["default"],
              "failed_pupil_percent" => Format::DisplayLimit["default"]
            }
          },
        },
        #诊断图
        "charts" => {
          "knowledge_3lines" => {
            "grade_median_percent" => [],
            "grade_average_percent" => [],
            "grade_diff_degree" => []
          },
          "knowledge_med_avg_diff" => [],
          "skill_3lines" => {
            "grade_median_percent" => [],
            "grade_average_percent" => [],
            "grade_diff_degree" => []
          },
          "skill_med_avg_diff" => [],
          "ability_3lines" => {
            "grade_median_percent" => [],
            "grade_average_percent" => [],
            "grade_diff_degree" => []
          },
          "ability_med_avg_diff" => [],
          "dimesion_disperse" => {
            "knowledge" => {},
            "skill" => {},
            "ability" => {}
          }
        },
        #各分数段人数比例
        "each_level_number" => {
          "grade_knowledge"=>[],
          "grade_skill"=>[],
          "grade_ability"=>[]
        },
        #四分位区间表现情况
        "four_sections" => {
          "level75"=> {
            "knowledge" => [],
            "skill" => [],
            "ability" => []
          },
          "level50"=> {
            "knowledge" => [],
            "skill" => [],
            "ability" => []
          },
          "level25"=> {
            "knowledge" => [],
            "skill" => [],
            "ability" => []
          },
          "level0"=> {
            "knowledge" => [],
            "skill" => [],
            "ability" => []
          }
        },
        #各指标水平图
        "each_checkpoint_horizon" => {
          "knowledge" => {
            "average_percent" => [],
            "median_percent" => [],
            "med_avg_diff" => [],
            "diff_degree" => []
          },
          "skill" => {
            "average_percent" => [],
            "median_percent" => [],
            "med_avg_diff" => [],
            "diff_degree" => []
          },
          "ability" => {
            "average_percent" => [],
            "median_percent" => [],
            "med_avg_diff" => [],
            "diff_degree" => []
          },
          "total" => {
            "average_percent" => [],
            "median_percent" => [],
            "med_avg_diff" => [],
            "diff_degree" => []
          } 
        },
        #各班分数段人数比例
        "each_class_pupil_number_chart" => {
          "knowledge" => {
            "excellent_pupil_percent" =>[],
            "good_pupil_percent" => [],
            "failed_pupil_percent" => []
          },
          "skill" => {
            "excellent_pupil_percent" =>[],
            "good_pupil_percent" => [],
            "failed_pupil_percent" => []
          },
          "ability" => {
            "excellent_pupil_percent" =>[],
            "good_pupil_percent" => [],
            "failed_pupil_percent" => []
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
          "three_dimesions"=> Format::KlassExplanation["three_dimesions"],
          "statistics"=> Format::KlassExplanation["statistics"],
          "data" => Format::KlassExplanation["data"]
        }
      }

      Klass = {
        #basic information
        "basic" => {
          "subject" => "",
          "area" => "",
          "school" => "",
          "grade" => "",
          "term" => "",
          "classroom" => "",
          "pupil_number" => "",
          "head_teacher" => "",
          "subject_teacher" => "",
          "quiz_type" => "",
          "quiz_date" => "",
          "levelword2" => "",
          "value_ratio" => {
            "knowledge" => 1,
            "skill" => 1,
            "ability" => 1
          }
        },
        "display_limit" => {
          "charts" => {
            "knowledge_all_lines" => Format::DisplayLimit["default"],
            "knowledge_gra_cls_avg_diff_line" => Format::DisplayLimit["default"],
            "knowledge_cls_mid_gra_avg_diff_line" => Format::DisplayLimit["default"],
            "skill_all_lines" => Format::DisplayLimit["default"],
            "skill_gra_cls_avg_diff_line" => Format::DisplayLimit["default"],
            "skill_cls_mid_gra_avg_diff_line" => Format::DisplayLimit["default"],
            "ability_all_lines" => Format::DisplayLimit["default"],
            "ability_gra_cls_avg_diff_line" => Format::DisplayLimit["default"],
            "ability_cls_mid_gra_avg_diff_line" => Format::DisplayLimit["default"]
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
            "grade_average_percent" => [],
            "class_average_percent" => [],
            "class_median_percent" => [],
            "diff_degree" => []
          },
          "knowledge_gra_cls_avg_diff_line" =>[],
          "knowledge_cls_mid_gra_avg_diff_line" => [],
          "skill_all_lines" => {
            "grade_average_percent" => [],
            "class_average_percent" => [],
            "class_median_percent" => [],
            "diff_degree" => []
          },
          "skill_gra_cls_avg_diff_line" =>[],
          "skill_cls_mid_gra_avg_diff_line" => [],
          "ability_all_lines" => {
            "grade_average_percent" => [],
            "class_average_percent" => [],
            "class_median_percent" => [],
            "diff_degree" => []
          },
          "ability_gra_cls_avg_diff_line" =>[],
          "ability_cls_mid_gra_avg_diff_line" => []
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
          "knowledge"=>[],
          "skill"=>[],
          "ability"=>[]
        },
        #各题答对率
        "average_percent" => {
          "failed" => [],
          "good" => [],
          "excellent" => []
        },
        #报告解读
        "report_explanation" =>{
          "three_dimesions"=> Format::KlassExplanation["three_dimesions"],
          "statistics"=> Format::KlassExplanation["statistics"],
          "data" => Format::KlassExplanation["data"]
        },
        #测试评价
        "quiz_comment" => {
          "knowledge" => Format::KlassQuizComment["dimesion"],
          "skill" => Format::KlassQuizComment["dimesion"],
          "ability" => Format::KlassQuizComment["dimesion"],
          "total" => Format::KlassQuizComment["total"]
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
          "quiz_date" => "",
          "score" => 0,
          "class_rank" => 0,
          "class_pupil_number" => 0,
          "grade_rank" => 0,
          "grade_pupil_number" => 0,
          "value_ratio" => {
            "knowledge" => 1,
            "skill" => 1,
            "ability" => 1
          }
        },
        "display_limit" => {
          "charts" => {
            "knowledge_radar" => Format::DisplayLimit["default"],
            "knowledge_pup_gra_avg_diff_line" => Format::DisplayLimit["default"],
            "skill_radar" => Format::DisplayLimit["default"],
            "skill_pup_gra_avg_diff_line" => Format::DisplayLimit["default"],
            "ability_radar" => Format::DisplayLimit["default"],
            "ability_pup_gra_avg_diff_line" => Format::DisplayLimit["default"]
          }
        },
        #诊断图
        "charts" => {
          "knowledge_radar" => {
            "pupil_average" => [],
            "grade_average" => []
          },
          "knowledge_pup_gra_avg_diff_line" => [],
          "skill_radar" => {
            "pupil_average" => [],
            "grade_average" => []
          },
          "skill_pup_gra_avg_diff_line" => [],
          "ability_radar" => {
            "pupil_average" => [],
            "grade_average" => []
          },
          "ability_pup_gra_avg_diff_line" => []
        },
        #诊断及改进建议
        "quiz_comment" => Format::PupilQuizComment,
        #数据表
        "data_table" => {
          "knowledge"=>[],
          "skill"=>[],
          "ability"=>[]
        },
        "percentile" =>{
          "knowledge"=> 0,
          "skill"=> 0,
          "ability"=>0
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
          "knowledge" => {},
          "skill" => {},
          "ability" => {}
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
end