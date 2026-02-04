# frozen_string_literal: true

# Persisted answer key for each question (single_choice: 1 row, multi_choice: multiple rows).
class CreateQuestionCorrectAnswers < ActiveRecord::Migration[8.0]
  def change
    create_table :question_correct_answers do |t|
      t.references :question, null: false, foreign_key: true
      t.references :question_choice, null: false, foreign_key: true

      t.timestamps
    end

    add_index :question_correct_answers, [:question_id, :question_choice_id],
              unique: true,
              name: "index_qca_on_question_and_choice"
  end
end
