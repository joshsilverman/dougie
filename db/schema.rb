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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110106193056) do

  create_table "documents", :force => true do |t|
    t.string   "name"
    t.text     "html"
    t.integer  "tag_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "documents", ["tag_id"], :name => "index_documents_on_tag_id"
  add_index "documents", ["user_id"], :name => "index_documents_on_user_id"

  create_table "lines", :force => true do |t|
    t.text     "text"
    t.string   "domid"
    t.integer  "document_id"
    t.integer  "parent_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "lines", ["document_id"], :name => "index_lines_on_document_id"
  add_index "lines", ["parent_id"], :name => "index_lines_on_parent_id"

  create_table "mems", :force => true do |t|
    t.float    "strength"
    t.boolean  "status"
    t.integer  "line_id"
    t.integer  "user_id"
    t.datetime "review_after"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "mems", ["line_id"], :name => "index_mems_on_line_id"

  create_table "tags", :force => true do |t|
    t.string   "name"
    t.boolean  "misc"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "tags", ["user_id"], :name => "index_tags_on_user_id"

  create_table "users", :force => true do |t|
    t.string   "email",                               :default => "", :null => false
    t.string   "encrypted_password",   :limit => 128, :default => "", :null => false
    t.string   "password_salt",                       :default => "", :null => false
    t.string   "reset_password_token"
    t.string   "remember_token"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",                       :default => 0
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.string   "first_name"
    t.string   "last_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["first_name"], :name => "index_users_on_first_name"
  add_index "users", ["last_name"], :name => "index_users_on_last_name"
  add_index "users", ["reset_password_token"], :name => "index_users_on_reset_password_token", :unique => true

end
