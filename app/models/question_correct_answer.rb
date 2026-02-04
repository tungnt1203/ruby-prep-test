# frozen_string_literal: true

class QuestionCorrectAnswer < ApplicationRecord
  belongs_to :question
  belongs_to :question_choice

  validates :question_id, uniqueness: { scope: :question_choice_id }
end
