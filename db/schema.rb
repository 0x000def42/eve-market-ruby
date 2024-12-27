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

ActiveRecord::Schema[8.0].define(version: 2024_12_27_111109) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "constellations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "eve_id"
    t.bigint "region_id"
    t.string "name"
    t.index ["eve_id"], name: "index_constellations_on_eve_id"
    t.index ["region_id"], name: "index_constellations_on_region_id"
  end

  create_table "regions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.integer "eve_id"
    t.index ["eve_id"], name: "index_regions_on_eve_id"
  end

  create_table "stations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "system_id"
    t.integer "eve_id"
    t.string "name"
    t.index ["eve_id"], name: "index_stations_on_eve_id"
    t.index ["system_id"], name: "index_stations_on_system_id"
  end

  create_table "systems", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "eve_id"
    t.bigint "constellation_id"
    t.bigint "star_id"
    t.string "name"
    t.string "security_class"
    t.decimal "security_status"
    t.index ["constellation_id"], name: "index_systems_on_constellation_id"
    t.index ["eve_id"], name: "index_systems_on_eve_id"
    t.index ["star_id"], name: "index_systems_on_star_id"
  end
end
