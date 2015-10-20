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

ActiveRecord::Schema.define(version: 20151020103025) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
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

  create_table "activities", force: :cascade do |t|
    t.integer  "trackable_id"
    t.string   "trackable_type"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.string   "key"
    t.text     "parameters"
    t.integer  "recipient_id"
    t.string   "recipient_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "read",           default: false
  end

  add_index "activities", ["owner_id", "owner_type"], name: "index_activities_on_owner_id_and_owner_type", using: :btree
  add_index "activities", ["recipient_id", "recipient_type"], name: "index_activities_on_recipient_id_and_recipient_type", using: :btree
  add_index "activities", ["trackable_id", "trackable_type"], name: "index_activities_on_trackable_id_and_trackable_type", using: :btree

  create_table "experts", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
  end

  create_table "followerships", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "expert_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "followerships", ["expert_id"], name: "index_followerships_on_expert_id", using: :btree
  add_index "followerships", ["user_id"], name: "index_followerships_on_user_id", using: :btree

  create_table "foods", force: :cascade do |t|
    t.string   "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "friendships", force: :cascade do |t|
    t.boolean  "accepted"
    t.integer  "receiver_id"
    t.integer  "sender_id"
    t.datetime "created_at",                         null: false
    t.datetime "updated_at",                         null: false
    t.boolean  "sender_invisible",   default: false
    t.boolean  "receiver_invisible", default: false
  end

  create_table "not_interested_relations", force: :cascade do |t|
    t.integer  "member_one_id"
    t.integer  "member_two_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "recommendations", force: :cascade do |t|
    t.string   "review"
    t.string   "strengths",                  array: true
    t.string   "ambiences",                  array: true
    t.integer  "user_id"
    t.integer  "restaurant_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
    t.string   "price_ranges",               array: true
    t.integer  "expert_id"
  end

  add_index "recommendations", ["expert_id"], name: "index_recommendations_on_expert_id", using: :btree
  add_index "recommendations", ["restaurant_id"], name: "index_recommendations_on_restaurant_id", using: :btree
  add_index "recommendations", ["user_id"], name: "index_recommendations_on_user_id", using: :btree

  create_table "restaurant_pictures", force: :cascade do |t|
    t.integer  "restaurant_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
  end

  add_index "restaurant_pictures", ["restaurant_id"], name: "index_restaurant_pictures_on_restaurant_id", using: :btree

  create_table "restaurant_subways", force: :cascade do |t|
    t.integer  "subway_id"
    t.integer  "restaurant_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "restaurant_subways", ["restaurant_id"], name: "index_restaurant_subways_on_restaurant_id", using: :btree
  add_index "restaurant_subways", ["subway_id"], name: "index_restaurant_subways_on_subway_id", using: :btree

  create_table "restaurants", force: :cascade do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at",               null: false
    t.datetime "updated_at",               null: false
    t.integer  "food_id"
    t.float    "latitude"
    t.float    "longitude"
    t.string   "phone_number"
    t.string   "picture_url"
    t.integer  "price_range"
    t.string   "city"
    t.string   "postal_code"
    t.string   "full_address"
    t.string   "starter1"
    t.string   "starter2"
    t.float    "price_starter1"
    t.float    "price_starter2"
    t.string   "main_course1"
    t.string   "main_course2"
    t.string   "main_course3"
    t.float    "price_main_course1"
    t.float    "price_main_course2"
    t.float    "price_main_course3"
    t.string   "dessert1"
    t.string   "dessert2"
    t.float    "price_dessert1"
    t.float    "price_dessert2"
    t.string   "description_starter1"
    t.string   "description_starter2"
    t.string   "description_main_course1"
    t.string   "description_main_course2"
    t.string   "description_main_course3"
    t.string   "description_dessert1"
    t.string   "description_dessert2"
    t.string   "food_name"
    t.integer  "subway_id"
    t.string   "subway_name"
    t.string   "subways_near",                          array: true
  end

  add_index "restaurants", ["food_id"], name: "index_restaurants_on_food_id", using: :btree

  create_table "subways", force: :cascade do |t|
    t.string   "name"
    t.string   "city"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_wishlist_pictures", force: :cascade do |t|
    t.integer  "user_id"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
  end

  add_index "user_wishlist_pictures", ["user_id"], name: "index_user_wishlist_pictures_on_user_id", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "provider"
    t.string   "uid"
    t.string   "picture"
    t.string   "name"
    t.string   "token"
    t.datetime "token_expiry"
    t.boolean  "admin",                  default: false, null: false
    t.string   "picture_file_name"
    t.string   "picture_content_type"
    t.integer  "picture_file_size"
    t.datetime "picture_updated_at"
    t.string   "gender"
    t.string   "age_range"
    t.string   "authentication_token"
    t.string   "code"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  create_table "wishes", force: :cascade do |t|
    t.integer  "user_id"
    t.integer  "restaurant_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  add_index "wishes", ["restaurant_id"], name: "index_wishes_on_restaurant_id", using: :btree
  add_index "wishes", ["user_id"], name: "index_wishes_on_user_id", using: :btree

  add_foreign_key "followerships", "experts"
  add_foreign_key "followerships", "users"
  add_foreign_key "recommendations", "restaurants"
  add_foreign_key "recommendations", "users"
  add_foreign_key "restaurant_pictures", "restaurants"
  add_foreign_key "restaurants", "foods"
  add_foreign_key "user_wishlist_pictures", "users"
  add_foreign_key "wishes", "restaurants"
  add_foreign_key "wishes", "users"
end
