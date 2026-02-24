# frozen_string_literal: true

class QuestionTopic < ApplicationRecord
  has_many :bank_questions, dependent: :destroy

  validates :key, presence: true, uniqueness: true
  validates :name, presence: true
end
