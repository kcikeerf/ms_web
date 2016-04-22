# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160422083804) do

  create_table "active_admin_comments", force: true do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "bank_checkpoint_ckps", id: false, force: true do |t|
    t.string   "uid",        limit: 36
    t.string   "dimesion",   limit: 50
    t.string   "rid",        limit: 36
    t.string   "checkpoint", limit: 200
    t.integer  "is_entity"
    t.text     "desc"
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_ckp_comments", id: false, force: true do |t|
    t.string   "uid",       limit: 36
    t.string   "ckp_uid",   limit: 36
    t.string   "ban_uid",   limit: 36
    t.string   "target",    limit: 36
    t.text     "template"
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_ckp_cubes", primary_key: "nid", force: true do |t|
    t.string   "ckp_uid_k", limit: 36
    t.string   "ckp_uid_s", limit: 36
    t.string   "ckp_uid_a", limit: 36
    t.integer  "crosstype"
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_dic_items", id: false, force: true do |t|
    t.string   "sid",       limit: 50
    t.string   "dic_sid",   limit: 50
    t.string   "caption",   limit: 200
    t.text     "desc"
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_dics", id: false, force: true do |t|
    t.string   "sid",       limit: 50
    t.string   "caption",   limit: 200
    t.text     "desc"
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_nodestructures", id: false, force: true do |t|
    t.string   "uid",       limit: 36
    t.string   "subject",   limit: 50
    t.string   "version",   limit: 50
    t.string   "grade",     limit: 50
    t.string   "rid",       limit: 128
    t.string   "node",      limit: 200
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_papertag_ptgs", id: false, force: true do |t|
    t.string   "sid",       limit: 200
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_quiztag_qtgs", id: false, force: true do |t|
    t.string   "sid",       limit: 200
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_tbc_ckps", primary_key: "nid", force: true do |t|
    t.string   "tbs_uid",   limit: 36
    t.string   "ckp_uid3",  limit: 36
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "file_uploads", force: true do |t|
    t.string   "name"
    t.string   "file"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: true do |t|
    t.string   "name"
    t.string   "subject_class"
    t.string   "action"
    t.string   "description"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", force: true do |t|
    t.string   "name"
    t.string   "desc"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_permissions_links", force: true do |t|
    t.integer  "role_id"
    t.integer  "permission_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.integer  "role_id"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
