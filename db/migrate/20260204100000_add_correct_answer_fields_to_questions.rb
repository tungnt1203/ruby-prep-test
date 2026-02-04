# frozen_string_literal: true

class AddCorrectAnswerFieldsToQuestions < ActiveRecord::Migration[8.0]
  def change
    add_column :questions, :correct_answer_description, :text
    add_column :questions, :correct_answers_fetched_at, :datetime
  end
end
