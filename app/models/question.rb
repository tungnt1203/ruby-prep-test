# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :exam_session
  has_many :question_choices, dependent: :destroy
  has_many :question_correct_answers, dependent: :destroy
  has_many :correct_choices, through: :question_correct_answers, source: :question_choice

  validates :question_type, presence: true, inclusion: { in: %w[single multiple] }
  validates :body, presence: true

  scope :single, -> { where(question_type: "single") }
  scope :multiple, -> { where(question_type: "multiple") }

  # Returns choice_keys (A, B, C, D) for the correct answers.
  def correct_choice_keys
    correct_choices.pluck(:choice_key).sort
  end

  # Checks if the user's choice_keys match the persisted correct answers.
  def correct?(user_choice_keys)
    return false if user_choice_keys.blank?

    Array.wrap(user_choice_keys).map(&:to_s).map(&:upcase).sort == correct_choice_keys
  end
end
