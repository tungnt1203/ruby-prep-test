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

ActiveRecord::Schema[8.1].define(version: 2026_02_06_110000) do
  create_table "exam_attempts", force: :cascade do |t|
    t.string "attempt_token", null: false
    t.datetime "created_at", null: false
    t.string "display_name"
    t.integer "exam_room_id"
    t.integer "exam_session_id", null: false
    t.text "submissions"
    t.datetime "updated_at", null: false
    t.index ["attempt_token"], name: "index_exam_attempts_on_attempt_token", unique: true
    t.index ["exam_room_id"], name: "index_exam_attempts_on_exam_room_id"
    t.index ["exam_session_id"], name: "index_exam_attempts_on_exam_session_id"
  end

  create_table "exam_rooms", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_minutes"
    t.integer "exam_session_id", null: false
    t.string "name"
    t.string "room_code", null: false
    t.datetime "starts_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_session_id"], name: "index_exam_rooms_on_exam_session_id"
    t.index ["room_code"], name: "index_exam_rooms_on_room_code", unique: true
  end

  create_table "exam_sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "exam_description"
    t.string "exam_title"
    t.integer "external_exam_id", null: false
    t.string "hash_id", null: false
    t.string "language", default: "en"
    t.integer "number_pass"
    t.integer "start_time"
    t.integer "time_limit_seconds"
    t.integer "total_questions"
    t.datetime "updated_at", null: false
    t.index ["hash_id"], name: "index_exam_sessions_on_hash_id", unique: true
  end

  create_table "question_choices", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "external_choice_id", null: false
    t.text "label", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id", "external_choice_id"], name: "index_question_choices_on_question_id_and_external_choice_id", unique: true
    t.index ["question_id"], name: "index_question_choices_on_question_id"
  end

  create_table "question_correct_answers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "question_choice_id", null: false
    t.integer "question_id", null: false
    t.datetime "updated_at", null: false
    t.index ["question_choice_id"], name: "index_question_correct_answers_on_question_choice_id"
    t.index ["question_id", "question_choice_id"], name: "index_qca_on_question_and_choice", unique: true
    t.index ["question_id"], name: "index_question_correct_answers_on_question_id"
  end

  create_table "questions", force: :cascade do |t|
    t.text "body", null: false
    t.text "correct_answer_description"
    t.datetime "correct_answers_fetched_at"
    t.datetime "created_at", null: false
    t.integer "exam_session_id", null: false
    t.text "explanation"
    t.integer "external_question_id", null: false
    t.string "question_type", null: false
    t.datetime "updated_at", null: false
    t.index ["exam_session_id", "external_question_id"], name: "index_questions_on_exam_session_id_and_external_question_id", unique: true
    t.index ["exam_session_id"], name: "index_questions_on_exam_session_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "role", default: "user", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "exam_attempts", "exam_rooms"
  add_foreign_key "exam_attempts", "exam_sessions"
  add_foreign_key "exam_rooms", "exam_sessions"
  add_foreign_key "question_choices", "questions"
  add_foreign_key "question_correct_answers", "question_choices"
  add_foreign_key "question_correct_answers", "questions"
  add_foreign_key "questions", "exam_sessions"
end
