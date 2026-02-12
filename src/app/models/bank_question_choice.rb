# frozen_string_literal: true

class BankQuestionChoice < ApplicationRecord
  belongs_to :bank_question

  validates :choice_key, presence: true
  validates :label, presence: true
end
