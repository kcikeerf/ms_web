# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'

namespace :swtk_patch do
  namespace :v1_2 do

    desc "get wechat openid excel"
    task get_wechat_openid_excel: :environment do      
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(:name => "获取微信信息") do |sheet|
          sheet.add_row(["openid"])
          WxUser.pluck(:wx_openid).each {|wx_openid|            
            sheet.add_row([wx_openid])
          }
        end
        p.serialize("./wx_openid_list.xlsx")
      end    
    end

    desc "update unionid with openid"
    task :update_unionid_with_openid, [:file_path] => :environment do
      if args[:file_path].nil?
        puts "Command format not correct, Usage: #rake swtk:patch:update_unionid_with_openid[file_path]"
        exit 
      end
      wx_xlsx = Roo::Excelx.new(args[:file_path])
      wx_unionid_arr = []
      wx_xlsx.sheet(0).each_with_index do |row, index|
        if index < 1
        else
          wx = WxUser.where(wx_openid: row[0]).first
          if wx && wx_unionid_arr.include?(row[1])
            master_wx = WxUser.where(wx_unionid: row[1]).first
            master_wx.migrate_other_wx_user_binded_user(wx)
            wx.destroy if wx
          else
            wx.update(wx_openid: row[0], wx_unionid: row[1])
            wx_unionid_arr << row[1]
          end 
        end
      end
    end

    desc "update wx_user is_master merge users"
    task update_wx_user_is_master: :environment do
      puts "开始迁移身份用户"
      WxUser.all.each do |wx|
        master_user = nil
        master_user = wx.users.by_master(true).first if wx.users
        unless master_user
          wx.default_user!
          master_user = wx.users.by_master(true).first if wx.users
        end
        slave_user = wx.users.by_master(false)
        slave_user.each do |slave|
          unless master_user.children.include?(slave)
            master_user.children.push(slave)
          end
          wx.users.delete(slave)
        end
        puts "#{wx.wx_openid}已迁移"
      end
      puts "迁移完成"
    end
  end
end