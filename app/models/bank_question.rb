# frozen_string_literal: true

class BankQuestion < ApplicationRecord
  belongs_to :question_topic
  has_many :bank_question_choices, dependent: :destroy

  validates :question_type, presence: true, inclusion: { in: %w[single multiple] }
  validates :body, presence: true
end
