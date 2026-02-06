# frozen_string_literal: true

class RoomsController < ApplicationController
  before_action :require_host, only: [:new, :create]

  def new
    @exam_sessions = ExamSession.order(created_at: :desc).limit(20)
  end

  def create
    exam_session = ExamSession.find_by(hash_id: params[:exam_hash_id])
    unless exam_session
      redirect_to new_room_path, alert: "Exam not found. Please enter a valid exam code."
      return
    end

    starts_at = parse_starts_at(params[:starts_at_date], params[:starts_at_time])
    unless starts_at && starts_at > Time.current
      redirect_to new_room_path, alert: "Start time must be in the future."
      return
    end

    duration_minutes = params[:duration_minutes].presence&.to_i
    duration_minutes = nil if duration_minutes.present? && duration_minutes <= 0

    room = exam_session.exam_rooms.create!(
      starts_at: starts_at,
      duration_minutes: duration_minutes,
      name: params[:room_name].presence
    )

    redirect_to room_path(room.room_code), notice: "Room created. Share the link with participants."
  end

  def show
    @room = ExamRoom.find_by!(room_code: params[:room_code])
    @exam_session = @room.exam_session

    if @room.expired?
      redirect_to room_results_path(@room.room_code), notice: "Room has ended. Here are the results."
      return
    end
    if @room.started?
      redirect_to exams_path(exam_code: @room.exam_hash_id, room_code: @room.room_code)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Room not found."
  end

  def results
    @room = ExamRoom.find_by!(room_code: params[:room_code])
    @exam_session = @room.exam_session
    attempts_with_submissions = @room.exam_attempts.where.not(submissions: [nil, ""])

    @leaderboard = attempts_with_submissions.map do |attempt|
      subs = attempt.submissions_array
      result = @exam_session.score_submissions(subs)
      { attempt: attempt, score: result[:score], total: result[:total], submitted_at: attempt.updated_at }
    end.sort_by { |e| [-e[:score], e[:submitted_at].to_i] }

  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Room not found."
  end

  private

  def parse_starts_at(date_str, time_str)
    return nil if date_str.blank? || time_str.blank?
    Time.zone.parse("#{date_str} #{time_str}")
  rescue ArgumentError
    nil
  end
end
