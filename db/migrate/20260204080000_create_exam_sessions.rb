# frozen_string_literal: true

class CreateExamSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :exam_sessions do |t|
      t.string :hash_id, null: false, index: { unique: true }
      t.integer :external_exam_id, null: false
      t.string :language, default: "en"
      t.integer :start_time
      t.string :exam_title
      t.text :exam_description
      t.integer :time_limit_seconds
      t.integer :total_questions
      t.integer :number_pass

      t.timestamps
    end
  end
end
