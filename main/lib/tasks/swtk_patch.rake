# -*- coding: UTF-8 -*-

require 'ox'
require 'roo'
require 'axlsx'
require 'find'

namespace :swtk do
  namespace :patch do
    desc "update unionid with openid"
    task :update_unionid_with_openid, [:file_path] => :environment do
      if args[:file_path].nil?
        puts "Command format not correct, Usage: #rake swtk:patch:update_unionid_with_openid[file_path]"
        exit 
      end
      wx_xlsx = Roo::Excelx.new(args[:file_path])
      wx_xlsx.sheet(0).each_with_index do |row, index|
        if index < 1
        else
          WxUser.where(wx_openid: row[0]).first.update(wx_openid: row[0], wx_unionid: row[1])
        end
      end
    end
  end
end