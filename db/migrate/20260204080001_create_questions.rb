# frozen_string_literal: true

class CreateQuestions < ActiveRecord::Migration[8.0]
  def change
    create_table :questions do |t|
      t.references :exam_session, null: false, foreign_key: true
      t.integer :external_question_id, null: false
      t.string :question_type, null: false # single_choice, multi_choice
      t.text :body, null: false
      t.text :explanation

      t.timestamps
    end

    add_index :questions, [:exam_session_id, :external_question_id], unique: true
  end
end
