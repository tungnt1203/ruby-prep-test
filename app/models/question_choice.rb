# frozen_string_literal: true

class QuestionChoice < ApplicationRecord
  belongs_to :question
  has_many :question_correct_answers, dependent: :destroy

  validates :choice_key, presence: true
  validates :label, presence: true
  validates :choice_key, format: { with: /\A[A-Za-z]\z/, message: "must be a single letter A–Z" }
end
