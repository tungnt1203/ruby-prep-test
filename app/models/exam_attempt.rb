# frozen_string_literal: true

class ExamAttempt < ApplicationRecord
  belongs_to :exam_session
  belongs_to :exam_room, optional: true

  validates :attempt_token, presence: true, uniqueness: true

  before_validation :generate_attempt_token, on: :create

  after_create_commit :broadcast_room_participants
  after_update_commit :broadcast_room_participants_if_submissions_changed

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

  def broadcast_room_participants_if_submissions_changed
    broadcast_room_participants if saved_change_to_submissions?
  end

  def broadcast_room_participants
    return unless exam_room_id?

    room = exam_room
    room.reload
    html = ApplicationController.render(
      partial: "rooms/participants",
      locals: { room: room },
      layout: false
    )
    Turbo::StreamsChannel.broadcast_update_to(
      "room:#{room.room_code}",
      target: "room_#{room.room_code}_participants",
      html: html
    )
  end
end
