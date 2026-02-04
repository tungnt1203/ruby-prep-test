# frozen_string_literal: true

class QuestionChoice < ApplicationRecord
  belongs_to :question
  has_many :question_correct_answers, dependent: :destroy

  validates :external_choice_id, presence: true
  validates :label, presence: true
end
