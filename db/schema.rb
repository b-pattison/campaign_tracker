# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_29_032615) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.integer "session_id", null: false
    t.integer "character_id", null: false
    t.boolean "present", default: true, null: false
    t.integer "xp_earned", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["character_id"], name: "index_attendances_on_character_id"
    t.index ["session_id"], name: "index_attendances_on_session_id"
  end

  create_table "campaigns", force: :cascade do |t|
    t.string "name"
    t.string "system"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "description"
  end

  create_table "characters", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.string "name", null: false
    t.string "class_name", null: false
    t.integer "level", null: false
    t.string "ancestry"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "subclass_name"
    t.boolean "pc", default: true, null: false
    t.integer "xp", default: 0, null: false
    t.index ["campaign_id"], name: "index_characters_on_campaign_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "campaign_id", null: false
    t.datetime "scheduled_at", null: false
    t.text "recap"
    t.string "location"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "xp_mode"
    t.integer "total_xp"
    t.datetime "played_at"
    t.string "title"
    t.index ["campaign_id"], name: "index_sessions_on_campaign_id"
  end

  add_foreign_key "attendances", "characters"
  add_foreign_key "attendances", "sessions"
  add_foreign_key "characters", "campaigns"
  add_foreign_key "sessions", "campaigns"
end
