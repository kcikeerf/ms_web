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

ActiveRecord::Schema.define(version: 20170212130213) do

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace",     limit: 255
    t.text     "body",          limit: 65535
    t.string   "resource_id",   limit: 255,   null: false
    t.string   "resource_type", limit: 255,   null: false
    t.integer  "author_id",     limit: 4
    t.string   "author_type",   limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "analyzers", primary_key: "uid", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.string   "name",       limit: 255
    t.string   "subject",    limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "tenant_uid", limit: 255
  end

  create_table "area_administrators", primary_key: "uid", force: :cascade do |t|
    t.string   "user_id",   limit: 255
    t.string   "name",      limit: 255
    t.string   "desc",      limit: 255
    t.string   "area_uid",  limit: 255
    t.string   "area_rid",  limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "areas", primary_key: "uid", force: :cascade do |t|
    t.string   "rid",       limit: 255
    t.string   "area_type", limit: 255
    t.string   "name",      limit: 255
    t.string   "name_cn",   limit: 255
    t.string   "comment",   limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_checkpoint_ckps", id: false, force: :cascade do |t|
    t.string   "uid",        limit: 36
    t.string   "dimesion",   limit: 50
    t.string   "rid",        limit: 36
    t.string   "node_uid",   limit: 36
    t.text     "advice",     limit: 65535
    t.string   "checkpoint", limit: 200
    t.integer  "is_entity",  limit: 4
    t.text     "desc",       limit: 65535
    t.float    "weights",    limit: 24
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "sort",       limit: 255
  end

  create_table "bank_checkpoint_rids", force: :cascade do |t|
    t.string   "nid",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_ckp_cats", primary_key: "nid", force: :cascade do |t|
    t.string   "cat_uid",    limit: 36
    t.string   "ckp_uid",    limit: 36
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_ckp_comments", id: false, force: :cascade do |t|
    t.string   "uid",       limit: 36
    t.string   "ckp_uid",   limit: 36
    t.string   "ban_uid",   limit: 36
    t.string   "target",    limit: 36
    t.text     "template",  limit: 65535
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_ckp_cubes", primary_key: "nid", force: :cascade do |t|
    t.string   "ckp_uid_k", limit: 36
    t.string   "ckp_uid_s", limit: 36
    t.string   "ckp_uid_a", limit: 36
    t.integer  "crosstype", limit: 4
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_dic_items", id: false, force: :cascade do |t|
    t.string   "sid",       limit: 50
    t.string   "dic_sid",   limit: 50
    t.string   "caption",   limit: 200
    t.text     "desc",      limit: 65535
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_dic_quiz_subjects", primary_key: "nid", force: :cascade do |t|
    t.string   "subject",    limit: 50
    t.string   "caption",    limit: 200
    t.string   "desc",       limit: 500
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_dic_quiztypes", id: false, force: :cascade do |t|
    t.string   "sid",        limit: 50
    t.string   "caption",    limit: 200
    t.string   "desc",       limit: 500
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_dics", id: false, force: :cascade do |t|
    t.string   "sid",       limit: 50
    t.string   "caption",   limit: 200
    t.text     "desc",      limit: 65535
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_node_catalog_subject_ckps", force: :cascade do |t|
    t.string   "node_catalog_uid", limit: 50, null: false
    t.string   "subject_ckp_uid",  limit: 50, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  create_table "bank_node_catalogs", id: false, force: :cascade do |t|
    t.string   "uid",       limit: 36
    t.string   "node",      limit: 200
    t.string   "node_uid",  limit: 36
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "rid",       limit: 255
  end

  create_table "bank_nodestructure_subject_ckps", force: :cascade do |t|
    t.string   "node_structure_uid", limit: 50, null: false
    t.string   "subject_ckp_uid",    limit: 50, null: false
    t.datetime "created_at",                    null: false
    t.datetime "updated_at",                    null: false
  end

  create_table "bank_nodestructures", id: false, force: :cascade do |t|
    t.string   "uid",         limit: 36
    t.string   "subject",     limit: 50
    t.string   "version",     limit: 50
    t.string   "grade",       limit: 50
    t.string   "rid",         limit: 128
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "grade_cn",    limit: 255
    t.string   "subject_cn",  limit: 255
    t.string   "term",        limit: 255
    t.string   "term_cn",     limit: 255
    t.string   "version_cn",  limit: 255
    t.string   "xue_duan",    limit: 255
    t.string   "xue_duan_cn", limit: 255
  end

  create_table "bank_papertag_ptgs", id: false, force: :cascade do |t|
    t.string   "sid",       limit: 200
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_quiztag_qtgs", id: false, force: :cascade do |t|
    t.string   "sid",       limit: 200
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "bank_rids", force: :cascade do |t|
    t.string   "rid",        limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_subject_checkpoint_ckps", primary_key: "uid", force: :cascade do |t|
    t.string   "dimesion",   limit: 50
    t.string   "rid",        limit: 36,                   null: false
    t.string   "checkpoint", limit: 200
    t.string   "subject",    limit: 36,                   null: false
    t.boolean  "is_entity",  limit: 1,     default: true
    t.text     "advice",     limit: 65535
    t.text     "desc",       limit: 65535
    t.float    "weights",    limit: 24
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "sort",       limit: 255
    t.string   "category",   limit: 255
  end

  add_index "bank_subject_checkpoint_ckps", ["subject"], name: "ckp_subject", using: :btree

  create_table "bank_subject_qiztype_links", force: :cascade do |t|
    t.string   "subj_nid",    limit: 50
    t.string   "qiztype_sid", limit: 50
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bank_tbc_ckps", primary_key: "nid", force: :cascade do |t|
    t.string   "tbs_uid",   limit: 36
    t.string   "ckp_uid3",  limit: 36
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "class_teacher_mappings", primary_key: "uid", force: :cascade do |t|
    t.string   "tea_uid",      limit: 255
    t.string   "loc_uid",      limit: 255
    t.string   "subject",      limit: 255
    t.boolean  "head_teacher", limit: 1,   default: false
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "tenant_uid",   limit: 255
  end

  add_index "class_teacher_mappings", ["loc_uid"], name: "index_class_teacher_mappings_on_loc_uid", using: :btree
  add_index "class_teacher_mappings", ["tea_uid"], name: "index_class_teacher_mappings_on_tea_uid", using: :btree
  add_index "class_teacher_mappings", ["tenant_uid"], name: "index_class_teacher_mappings_on_tenant_uid", using: :btree

  create_table "file_uploads", force: :cascade do |t|
    t.string   "paper",         limit: 255
    t.string   "answer",        limit: 255
    t.string   "analysis",      limit: 255
    t.string   "single",        limit: 255
    t.string   "revise_paper",  limit: 255
    t.string   "revise_answer", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "empty_result",  limit: 255
  end

  create_table "image_uploads", force: :cascade do |t|
    t.string   "file",       limit: 255
    t.string   "user_id",    limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "job_lists", primary_key: "uid", force: :cascade do |t|
    t.string   "name",      limit: 255
    t.string   "job_id",    limit: 255
    t.string   "status",    limit: 255
    t.float    "process",   limit: 24
    t.string   "task_uid",  limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "job_type",  limit: 255
  end

  create_table "locations", primary_key: "uid", force: :cascade do |t|
    t.string   "province",      limit: 255
    t.string   "city",          limit: 255
    t.string   "district",      limit: 255
    t.string   "school",        limit: 255
    t.string   "school_number", limit: 255
    t.string   "grade",         limit: 255
    t.string   "classroom",     limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "tenant_uid",    limit: 255
    t.string   "area_uid",      limit: 255
    t.string   "area_rid",      limit: 255
  end

  add_index "locations", ["tenant_uid"], name: "index_locations_on_tenant_uid", using: :btree

  create_table "managers", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "", null: false
    t.string   "encrypted_password",     limit: 255, default: "", null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.string   "name",                   limit: 255
  end

  add_index "managers", ["email"], name: "index_managers_on_email", unique: true, using: :btree
  add_index "managers", ["reset_password_token"], name: "index_managers_on_reset_password_token", unique: true, using: :btree

  create_table "messages", force: :cascade do |t|
    t.string   "mobile",     limit: 11,                  null: false
    t.string   "content",    limit: 255,                 null: false
    t.string   "channel",    limit: 20
    t.boolean  "status",     limit: 1,   default: false
    t.string   "kinds",      limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "permissions", force: :cascade do |t|
    t.string   "name",          limit: 255
    t.string   "subject_class", limit: 255
    t.string   "action",        limit: 255
    t.string   "description",   limit: 255
    t.integer  "role_id",       limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_administrator_tenant_links", primary_key: "uid", force: :cascade do |t|
    t.string   "project_administrator_uid", limit: 255
    t.string   "tenant_uid",                limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "project_administrators", primary_key: "uid", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.string   "name",       limit: 255
    t.string   "desc",       limit: 255
    t.string   "tenant_uid", limit: 255
    t.string   "area_uid",   limit: 255
    t.string   "area_rid",   limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "pupil_teacher_links", primary_key: "uid", force: :cascade do |t|
    t.string   "tea_uid",   limit: 255
    t.string   "pup_uid",   limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "pupils", primary_key: "uid", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.string   "loc_uid",    limit: 255
    t.string   "stu_number", limit: 255
    t.string   "sex",        limit: 10
    t.string   "name",       limit: 255
    t.string   "grade",      limit: 255
    t.string   "classroom",  limit: 255
    t.string   "school",     limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "tenant_uid", limit: 255
  end

  add_index "pupils", ["loc_uid"], name: "index_pupils_on_loc_uid", using: :btree
  add_index "pupils", ["stu_number"], name: "index_pupils_on_stu_number", using: :btree
  add_index "pupils", ["tenant_uid"], name: "index_pupils_on_tenant_uid", using: :btree
  add_index "pupils", ["user_id"], name: "index_pupils_on_user_id", using: :btree

  create_table "report_url_mappings", primary_key: "codes", force: :cascade do |t|
    t.string   "params_json", limit: 255
    t.boolean  "first_login", limit: 1,   default: true
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "roles", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "desc",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles_permissions_links", force: :cascade do |t|
    t.integer  "role_id",       limit: 4
    t.integer  "permission_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "score_uploads", force: :cascade do |t|
    t.string   "filled_file",  limit: 255
    t.string   "empty_file",   limit: 255
    t.string   "usr_pwd_file", limit: 255
    t.string   "ana_uid",      limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "test_id",      limit: 255
    t.string   "tenant_uid",   limit: 255
  end

  create_table "swtk_configs", primary_key: "uid", force: :cascade do |t|
    t.string   "name",      limit: 255
    t.string   "value",     limit: 255
    t.string   "desc",      limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "task_lists", primary_key: "uid", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "type",       limit: 255
    t.string   "pap_uid",    limit: 255
    t.string   "status",     limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "user_id",    limit: 255
    t.string   "task_type",  limit: 255
    t.boolean  "monitoring", limit: 1
    t.string   "wx_user_id", limit: 255
  end

  create_table "teachers", primary_key: "uid", force: :cascade do |t|
    t.string   "user_id",    limit: 255
    t.string   "loc_uid",    limit: 255
    t.string   "name",       limit: 255
    t.string   "subject",    limit: 255
    t.string   "school",     limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
    t.string   "tenant_uid", limit: 255
  end

  add_index "teachers", ["loc_uid"], name: "index_teachers_on_loc_uid", using: :btree
  add_index "teachers", ["tenant_uid"], name: "index_teachers_on_tenant_uid", using: :btree
  add_index "teachers", ["user_id"], name: "index_teachers_on_user_id", using: :btree

  create_table "tenant_administrators", primary_key: "uid", force: :cascade do |t|
    t.integer  "user_id",    limit: 4,   null: false
    t.string   "name",       limit: 255
    t.string   "tenant_uid", limit: 255
    t.string   "comment",    limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  create_table "tenants", primary_key: "uid", force: :cascade do |t|
    t.string   "number",         limit: 255, null: false
    t.string   "name",           limit: 255, null: false
    t.string   "name_en",        limit: 255
    t.string   "name_cn",        limit: 255, null: false
    t.string   "name_abbrev",    limit: 255
    t.string   "watchword",      limit: 255
    t.string   "tenant_type",    limit: 255
    t.string   "tenant_type_cn", limit: 255
    t.string   "k12_type",       limit: 255
    t.string   "school_type",    limit: 255
    t.string   "address",        limit: 255
    t.string   "email",          limit: 255
    t.string   "phone",          limit: 255
    t.string   "web",            limit: 255
    t.string   "build_at",       limit: 255
    t.string   "comment",        limit: 255
    t.string   "area_uid",       limit: 255
    t.string   "area_rid",       limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  add_index "tenants", ["number", "name"], name: "index_tenants_on_number_and_name", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  limit: 255, default: "",    null: false
    t.string   "name",                   limit: 50
    t.string   "phone",                  limit: 11
    t.string   "qq",                     limit: 30
    t.string   "wechat",                 limit: 50
    t.string   "encrypted_password",     limit: 255, default: "",    null: false
    t.boolean  "phone_validate",         limit: 1,   default: false
    t.boolean  "email_validate",         limit: 1,   default: false
    t.boolean  "init_profile",           limit: 1,   default: false, null: false
    t.string   "reset_password_token",   limit: 255
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          limit: 4,   default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip",     limit: 255
    t.string   "last_sign_in_ip",        limit: 255
    t.datetime "created_at",                                         null: false
    t.datetime "updated_at",                                         null: false
    t.integer  "role_id",                limit: 4
    t.string   "wx_openid",              limit: 255
    t.string   "wx_token",               limit: 255
    t.string   "initial_password",       limit: 255
    t.boolean  "locked",                 limit: 1,   default: true
    t.datetime "expired_at"
  end

  add_index "users", ["name"], name: "index_users_on_name", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["wx_openid"], name: "index_users_on_wx_openid", unique: true, using: :btree

  create_table "wx_user_mappings", force: :cascade do |t|
    t.string   "user_id",   limit: 255
    t.string   "wx_uid",    limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  add_index "wx_user_mappings", ["user_id"], name: "index_wx_user_mappings_on_user_id", using: :btree
  add_index "wx_user_mappings", ["wx_uid"], name: "index_wx_user_mappings_on_wx_uid", using: :btree

  create_table "wx_users", primary_key: "uid", force: :cascade do |t|
    t.string   "name",      limit: 255
    t.string   "wx_openid", limit: 255
    t.string   "wx_token",  limit: 255
    t.string   "comment",   limit: 255
    t.datetime "dt_add"
    t.datetime "dt_update"
  end

  add_index "wx_users", ["wx_openid"], name: "index_wx_users_on_wx_openid", using: :btree

end
