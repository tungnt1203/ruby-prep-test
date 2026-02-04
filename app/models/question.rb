# frozen_string_literal: true

class Question < ApplicationRecord
  belongs_to :exam_session
  has_many :question_choices, dependent: :destroy
  has_many :question_correct_answers, dependent: :destroy
  has_many :correct_choices, through: :question_correct_answers, source: :question_choice

  validates :external_question_id, presence: true
  validates :question_type, presence: true, inclusion: { in: %w[single_choice multi_choice] }
  validates :body, presence: true

  scope :single_choice, -> { where(question_type: "single_choice") }
  scope :multi_choice, -> { where(question_type: "multi_choice") }

  # Returns external_choice_ids for the persisted correct answers.
  def correct_external_choice_ids
    correct_choices.pluck(:external_choice_id).sort
  end

  # Checks if the user's external_choice_ids match the persisted correct answers.
  def correct?(user_external_choice_ids)
    return false if user_external_choice_ids.blank?

    Array.wrap(user_external_choice_ids).map(&:to_i).sort == correct_external_choice_ids
  end
end
