# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'

namespace :swtk do
  namespace :export do

    # #添加所有controller和action到permission表
    # require 'find'
    desc 'find conform or similar checkpoint'
    task :find_similar_checkpoint, [:paper_uid_first,:paper_uid_second] => :environment do |t, args|
      #rake export:find_similar_checkpoint[58771e4bfa33187439c937b5,587749d5fa33187423b1b612]
      if args[:paper_uid_first].nil? || args[:paper_uid_second].nil?
        puts "Command format not correct, Usage: #rake export:find_similar_checkpoint[:paper_uid_first,:paper_uid_second]"
        exit 
      end
      p "begin"
      paper1 = Mongodb::BankPaperPap.where(_id: args[:paper_uid_first]).first
      paper2 = Mongodb::BankPaperPap.where(_id: args[:paper_uid_second]).first
      out_excel = Axlsx::Package.new
      wb = out_excel.workbook
      all_conform_sheet = wb.add_worksheet(:name => "知识_技能_能力")
      skill_ability_sheet = wb.add_worksheet(:name => "技能_能力")
      knowledge_similar_sheet = wb.add_worksheet(:name => "知识相近")
      knowledge_skill_sheet = wb.add_worksheet(:name => "知识_技能")
      knowledge_ability_sheet = wb.add_worksheet(:name => "知识_能力")

      paper1_qiz = paper1.bank_quiz_qizs.map {|quiz| quiz.bank_qizpoint_qzps}.flatten
      paper2_qiz = paper2.bank_quiz_qizs.map {|quiz| quiz.bank_qizpoint_qzps}.flatten
      paper1_ckp_sort = paper1_qiz.map {|qiz| qiz.bank_checkpoint_ckps.map(&:uid).sort}.uniq!
      paper2_ckp_sort = paper2_qiz.map {|qiz| qiz.bank_checkpoint_ckps.map(&:uid).sort}.uniq!
      base_ckp_sort = []
      p "#{paper1_ckp_sort.size}-#{paper2_ckp_sort.size}"
      if paper1_ckp_sort.size < paper2_ckp_sort.size
        paper1, paper2 = paper2, paper1
        base_ckp_sort = paper2_ckp_sort
      else
        base_ckp_sort = paper1_ckp_sort
      end

      title_arr = ["知识","技能","技能","能力","能力", "#{paper1.heading},#{paper1._id.to_s}","题顺" ,"题数", "#{paper2.heading},#{paper2._id.to_s}", "题顺","题数" ]
      all_conform_sheet.add_row(title_arr)
      skill_ability_sheet.add_row(title_arr)
      knowledge_similar_sheet.add_row(title_arr)
      knowledge_skill_sheet.add_row(title_arr)
      knowledge_ability_sheet.add_row(title_arr)

      base_ckp_sort.each do |ckp_arr|
        ckps = BankSubjectCheckpointCkp.where(uid: ckp_arr).to_a
        base_hash = JSON.parse(Common::CheckpointCkp.get_ckps_json(ckps))

        bash_hash_know_lv3 = base_hash["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[-1]}}.flatten
        bash_hash_know_lv2 = base_hash["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[1]}}.flatten
        bash_hash_skill_lv3 = base_hash["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-1]}}.flatten
        bash_hash_skill_lv2 = base_hash["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-2]}}.flatten
        bash_hash_ability_lv3 = base_hash["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-1]}}.flatten
        bash_hash_ability_lv2 = base_hash["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-2]}}.flatten
        bash_k_s_a_arr = bash_hash_know_lv3 + bash_hash_skill_lv3 + bash_hash_ability_lv3
        bash_s_a_arr = bash_hash_skill_lv3 + bash_hash_ability_lv3
        bash_k_lv2_arr = bash_hash_know_lv2
        bash_k_s_arr =  bash_hash_know_lv3 + bash_hash_skill_lv3
        bash_k_a_arr =  bash_hash_know_lv3 + bash_hash_ability_lv3
        sheet1_paper1_arr = []
        sheet2_paper1_arr = []
        sheet3_paper1_arr = []
        sheet4_paper1_arr = []
        sheet5_paper1_arr = []
        sheet1_paper1_qiz_arr = []
        sheet2_paper1_qiz_arr = []
        sheet3_paper1_qiz_arr = []
        sheet4_paper1_qiz_arr = []
        sheet5_paper1_qiz_arr = []
        paper1_qiz.each {|qiz|
          unless qiz.ckps_json 
            qiz = qiz.format_ckps_json
          end
          p1_ckps_json = JSON.parse(qiz.ckps_json)
          p1_hash_know_lv3 = p1_ckps_json["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[-1]}}.flatten
          p1_hash_know_lv2 = p1_ckps_json["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[1]}}.flatten
          p1_hash_skill_lv3 = p1_ckps_json["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-1]}}.flatten
          p1_hash_skill_lv2 = p1_ckps_json["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-2]}}.flatten
          p1_hash_ability_lv3 = p1_ckps_json["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-1]}}.flatten
          p1_hash_ability_lv2 = p1_ckps_json["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-2]}}.flatten
          p1_k_s_a_arr = p1_hash_know_lv3 + p1_hash_skill_lv3 + p1_hash_ability_lv3
          p1_s_a_arr = p1_hash_skill_lv3 + p1_hash_ability_lv3
          p1_k_lv2_arr = p1_hash_know_lv2
          p1_k_s_arr =  p1_hash_know_lv3 + p1_hash_skill_lv3
          p1_k_a_arr =  p1_hash_know_lv3 + p1_hash_ability_lv3
          if p1_k_s_a_arr.flatten.sort == bash_k_s_a_arr.flatten.sort
            sheet1_paper1_arr << qiz._id.to_s
            sheet1_paper1_qiz_arr << qiz.order
          end
          if p1_s_a_arr.flatten.sort == bash_s_a_arr.flatten.sort
            sheet2_paper1_arr << qiz._id.to_s
            sheet2_paper1_qiz_arr << qiz.order

          end
          if p1_k_lv2_arr.flatten.sort == bash_k_lv2_arr.flatten.sort
            sheet3_paper1_arr << qiz._id.to_s
            sheet3_paper1_qiz_arr << qiz.order

          end
          if p1_k_s_arr.flatten.sort == bash_k_s_arr.flatten.sort
            sheet4_paper1_arr << qiz._id.to_s
            sheet4_paper1_qiz_arr << qiz.order

          end
          if p1_k_a_arr.flatten.sort == bash_k_a_arr.flatten.sort
            sheet5_paper1_arr << qiz._id.to_s
            sheet5_paper1_qiz_arr << qiz.order
          end 
        }
        sheet1_paper2_arr = []
        sheet2_paper2_arr = []
        sheet3_paper2_arr = []
        sheet4_paper2_arr = []
        sheet5_paper2_arr = []
        sheet1_paper2_qiz_arr = []
        sheet2_paper2_qiz_arr = []
        sheet3_paper2_qiz_arr = []
        sheet4_paper2_qiz_arr = []
        sheet5_paper2_qiz_arr = []      
        paper2_qiz.each {|qiz|
          unless qiz.ckps_json 
            qiz = qiz.format_ckps_json
          end 
          p2_ckps_json = JSON.parse(qiz.ckps_json)
          p2_hash_know_lv3 = p2_ckps_json["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[-1]}}.flatten
          p2_hash_know_lv2 = p2_ckps_json["knowledge"].map{|kn| kn.keys.map{|key| key.split('/')[1]}}.flatten
          p2_hash_skill_lv3 = p2_ckps_json["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-1]}}.flatten
          p2_hash_skill_lv2 = p2_ckps_json["skill"].map{|sk| sk.keys.map{|key| key.split('/')[-2]}}.flatten
          p2_hash_ability_lv3 = p2_ckps_json["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-1]}}.flatten
          p2_hash_ability_lv2 = p2_ckps_json["ability"].map{|ab| ab.keys.map{|key| key.split('/')[-2]}}.flatten
          p2_k_s_a_arr = p2_hash_know_lv3 + p2_hash_skill_lv3 + p2_hash_ability_lv3
          p2_s_a_arr = p2_hash_skill_lv3 + p2_hash_ability_lv3
          p2_k_lv2_arr = p2_hash_know_lv2
          p2_k_s_arr =  p2_hash_know_lv3 + p2_hash_skill_lv3
          p2_k_a_arr =  p2_hash_know_lv3 + p2_hash_ability_lv3
          if p2_k_s_a_arr.flatten.sort == bash_k_s_a_arr.flatten.sort
            sheet1_paper2_arr << qiz._id.to_s
            sheet1_paper2_qiz_arr << qiz.order
          end
          if p2_s_a_arr.flatten.sort == bash_s_a_arr.flatten.sort
            sheet2_paper2_arr << qiz._id.to_s
            sheet2_paper2_qiz_arr << qiz.order
          end
          if p2_k_lv2_arr.flatten.sort == bash_k_lv2_arr.flatten.sort
            sheet3_paper2_arr << qiz._id.to_s
            sheet3_paper2_qiz_arr << qiz.order
          end
          if p2_k_s_arr.flatten.sort == bash_k_s_arr.flatten.sort
            sheet4_paper2_arr << qiz._id.to_s
            sheet4_paper2_qiz_arr << qiz.order
          end
          if p2_k_a_arr.flatten.sort == bash_k_a_arr.flatten.sort
            sheet5_paper2_arr << qiz._id.to_s
            sheet5_paper2_qiz_arr << qiz.order
          end
        }
        ckp_title = [nil,nil,nil,nil,nil] 
        ckps.each {|ckp| 
          # ckp_info = "#{ckp.checkpoint}"
          ckp_ancestors = BankRid.get_all_higher_nodes(ckp.families,ckp)
          ckp_ancestors.sort!{|a,b| Common::CheckpointCkp.compare_rid_plus(a.rid, b.rid) }
          ckps_arr = ckp_ancestors.push(ckp)

          ckp_info = "/#{ckps_arr.map(&:checkpoint).join('/')}"
          if ckp.dimesion == "knowledge"
            ckp_title[0] = ckp_info
          elsif ckp.dimesion == "skill"
            if ckp_title[1] == nil
              ckp_title[1] = ckp_info
            else
              ckp_title[2] = ckp_info
            end
          elsif ckp.dimesion == "ability"
            if ckp_title[3] == nil
              ckp_title[3] = ckp_info
            else
              ckp_title[4] = ckp_info
            end
          end
        }
        p ckp_title
        if sheet1_paper1_arr.size > 0 && sheet1_paper2_arr.size > 0
          row_data = []
          row_data << sheet1_paper1_arr
          row_data << sheet1_paper1_qiz_arr
          row_data << sheet1_paper1_qiz_arr.size
          row_data << sheet1_paper2_arr
          row_data << sheet1_paper2_qiz_arr
          row_data << sheet1_paper2_qiz_arr.size
          row_data = ckp_title + row_data
          all_conform_sheet.add_row(row_data)
        end
        if sheet2_paper1_arr.size > 0 && sheet2_paper2_arr.size > 0
          row_data = []
          row_data << sheet2_paper1_arr
          row_data << sheet2_paper1_qiz_arr
          row_data << sheet2_paper1_qiz_arr.size
          row_data << sheet2_paper2_arr
          row_data << sheet2_paper2_qiz_arr
          row_data << sheet2_paper2_qiz_arr.size
          row_data = ckp_title + row_data
          skill_ability_sheet.add_row(row_data)
        end
        if sheet3_paper1_arr.size > 0 && sheet3_paper2_arr.size > 0
          row_data = []
          row_data << sheet3_paper1_arr
          row_data << sheet3_paper1_qiz_arr
          row_data << sheet3_paper1_qiz_arr.size
          row_data << sheet3_paper2_arr
          row_data << sheet3_paper2_qiz_arr
          row_data << sheet3_paper2_qiz_arr.size
          row_data = ckp_title + row_data
          knowledge_similar_sheet.add_row(row_data)
        end
        if sheet4_paper1_arr.size > 0 && sheet4_paper2_arr.size > 0
          row_data = []
          row_data << sheet4_paper1_arr
          row_data << sheet4_paper1_qiz_arr
          row_data << sheet4_paper1_qiz_arr.size
          row_data << sheet4_paper2_arr
          row_data << sheet4_paper2_qiz_arr
          row_data << sheet4_paper2_qiz_arr.size
          row_data = ckp_title + row_data
          knowledge_skill_sheet.add_row(row_data)
        end
        if sheet5_paper1_arr.size > 0 && sheet5_paper2_arr.size > 0
          row_data = []
          row_data << sheet5_paper1_arr
          row_data << sheet5_paper1_qiz_arr
          row_data << sheet5_paper1_qiz_arr.size
          row_data << sheet5_paper2_arr
          row_data << sheet5_paper2_qiz_arr
          row_data << sheet5_paper2_qiz_arr.size
          row_data = ckp_title + row_data
          knowledge_ability_sheet.add_row(row_data)
        end
      end
      file_path = Rails.root.to_s + "/tmp/similar_checkpoint_file.xlsx"

      out_excel.serialize(file_path)



      
      p 'end'
    end
    
  end
end