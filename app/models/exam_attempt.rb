# frozen_string_literal: true

class ExamAttempt < ApplicationRecord
  belongs_to :exam_session

  validates :attempt_token, presence: true, uniqueness: true

  before_validation :generate_attempt_token, on: :create

  def submissions_array
    return [] if submissions.blank?
    JSON.parse(submissions)
  rescue JSON::ParserError
    []
  end

  private

  def generate_attempt_token
    self.attempt_token ||= SecureRandom.urlsafe_base64(16)
  end
end
