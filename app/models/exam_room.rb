# frozen_string_literal: true

class ExamRoom < ApplicationRecord
  belongs_to :exam_session
  belongs_to :created_by, class_name: "User", optional: true
  has_many :exam_attempts, dependent: :destroy

  validates :starts_at, presence: true
  validates :room_code, presence: true, uniqueness: true

  before_validation :generate_room_code, on: :create

  scope :upcoming, -> { where("starts_at > ?", Time.current) }
  scope :started, -> { where("starts_at <= ?", Time.current) }

  def started?
    t = starts_at.respond_to?(:to_time) ? starts_at.to_time : starts_at
    t <= Time.current
  end

  def ends_at
    return nil if duration_minutes.blank? || duration_minutes <= 0
    t = starts_at.respond_to?(:to_time) ? starts_at.to_time : starts_at
    t + duration_minutes.minutes
  end

  def expired?
    return false if ends_at.nil?
    Time.current >= ends_at
  end

  def exam_hash_id
    exam_session&.hash_id
  end

  # Same structure as RoomsController#results @leaderboard, for partial/stream
  def leaderboard_entries
    es = exam_session
    attempts = exam_attempts.where.not(submissions: [ nil, "" ])
    attempts.map do |attempt|
      subs = attempt.submissions_array
      result = es.score_submissions(subs)
      { attempt: attempt, score: result[:score], total: result[:total], submitted_at: attempt.updated_at }
    end.sort_by { |e| [ -e[:score], e[:submitted_at].to_i ] }
  end

  private

  def generate_room_code
    return if room_code.present?
    self.room_code = SecureRandom.alphanumeric(8)
    self.room_code = SecureRandom.alphanumeric(8) while ExamRoom.exists?(room_code: room_code)
  end
end
