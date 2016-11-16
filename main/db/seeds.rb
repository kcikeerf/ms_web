# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)


# Role.destroy_all
# User.destroy_all
# Pupil.destroy_all
# Teacher.destroy_all
# Analyzer.destroy_all
# Location.destroy_all
# Role.new({:name => "super_administrator",
#           :desc => "this role is for who has all permissions",
#           :permissions => Permission.all}).save
# User.new({:name=>"user001", 
#           :email=>"admin@swtk.com",
#           :role_name=>"super_administrator",
#           :password=>"welcome1",
#           :role => Role.where(:name => "super_administrator")[0]}).save
# ######
# Role.new({:name => "pupil",
#           :desc => "this role is for who has all permissions",
#           :permissions => Permission.all}).save
# Role.new({:name => "teacher",
#           :desc => "this role is for who has all permissions",
#           :permissions => Permission.all}).save
# Role.new({:name => "analyzer",
#           :desc => "this role is for who has all permissions",
#           :permissions => Permission.all}).save
# User.new({:name=>"user002",
#           :email=>"pupil@swtk.com",
#           :role_name=>"pupil",
#           :password=>"welcome1",
#           :role => Role.where(:name => "pupil")[0]}).save
# User.new({:name =>"user003",
#           :email=>"teacher@swtk.com",
#           :role_name=>"teacher",
#           :password=>"welcome1",
#           :role => Role.where(:name => "teacher")[0]}).save
# User.new({:name => "user004",
#           :email=>"analyzer@swtk.com",
#           :role_name=>"analyzer",
#           :password=>"welcome1",
#           :role => Role.where(:name => "analyzer")[0]}).save!
# Pupil.new({:name=>"pupil",:user_id=> User.all[1].id, :grade =>"grade7", :school=>"Beijing Middle"}).save!
# Teacher.new({:name=>"teacher",:user_id=> User.all[2].id, :subject =>"english", :school=>"Beijing Middle"}).save!
# Analyzer.new({:name=>"analyzer",:user_id=> User.all[3].id, :subject =>"english"}).save!


# # delete all mongodb
# Mongodb::BankPaperPap.destroy_all
# Mongodb::BankQuizQiz.destroy_all
# Mongodb::BankQizpointQzp.destroy_all
# Mongodb::BankQizpointScore.destroy_all
# Mongodb::BankCkpQzp.destroy_all
# Mongodb::GradeReport.destroy_all
# Mongodb::ClassReport.destroy_all
# Mongodb::PupilReport.destroy_all
# Mongodb::ReportEachLevelPupilNumberResult.destroy_all
# Mongodb::ReportStandDevDiffResult.destroy_all
# Mongodb::ReportTotalAvgResult.destroy_all
# Mongodb::ReportQuizCommentsResult.destroy_all

SwtkConfig.new(:name => "version", :value=>"1.1").save
SwtkConfig.new(:name => "sv_cpu_cores", :value=>"2").save