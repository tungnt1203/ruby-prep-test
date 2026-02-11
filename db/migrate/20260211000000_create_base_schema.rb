# frozen_string_literal: true

class CreateBaseSchema < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest, null: false
      t.string :role, default: "user", null: false

      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :exam_sessions do |t|
      t.string :hash_id, null: false
      t.string :language, default: "en"
      t.string :exam_title
      t.text :exam_description
      t.integer :time_limit_seconds
      t.integer :total_questions
      t.integer :number_pass
      t.integer :start_time
      t.integer :external_exam_id

      t.timestamps
    end
    add_index :exam_sessions, :hash_id, unique: true

    create_table :questions do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.string :question_type, null: false
      t.text :body, null: false
      t.text :explanation

      t.timestamps
    end
    add_index :questions, :exam_session_id

    create_table :question_choices do |t|
      t.references :question, null: false, foreign_key: true
      t.string :choice_key, null: false
      t.text :label, null: false

      t.timestamps
    end
    add_index :question_choices, [:question_id, :choice_key], unique: true

    create_table :question_correct_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.references :question_choice, null: false, foreign_key: true

      t.timestamps
    end
    add_index :question_correct_answers, [:question_id, :question_choice_id],
              unique: true, name: "index_qca_on_question_and_choice"

    create_table :exam_rooms do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.references :user, column: :created_by_id, foreign_key: true
      t.string :room_code, null: false
      t.datetime :starts_at, null: false
      t.integer :duration_minutes
      t.text :instructions
      t.string :name
      t.boolean :require_display_name, default: true, null: false
      t.boolean :require_candidate_identifier, default: false, null: false

      t.timestamps
    end
    add_index :exam_rooms, :room_code, unique: true
    add_index :exam_rooms, :created_by_id

    create_table :exam_attempts do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.references :exam_room, foreign_key: true
      t.string :attempt_token, null: false
      t.text :submissions
      t.string :display_name
      t.string :candidate_identifier

      t.timestamps
    end
    add_index :exam_attempts, :attempt_token, unique: true
    add_index :exam_attempts, :exam_room_id
    add_index :exam_attempts, :exam_session_id
  end
end
