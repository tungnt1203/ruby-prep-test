# frozen_string_literal: true

class RoomsController < ApplicationController
  before_action :require_host, only: [:new, :create]
  before_action :set_room, only: [:show, :results, :participants, :start_now]

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
      name: params[:room_name].presence,
      created_by: current_user,
      instructions: params[:instructions].presence,
      require_display_name: params[:require_display_name] != "0",
      require_candidate_identifier: params[:require_candidate_identifier] == "1"
    )

    redirect_to room_path(room.room_code), notice: "Room created. Share the link with participants."
  end

  def show
    @exam_session = @room.exam_session
    @participants_count = @room.exam_attempts.count
    @submitted_count = @room.exam_attempts.where.not(submissions: [nil, ""]).count
    @participants = @room.exam_attempts.order(created_at: :asc).pluck(:display_name, :candidate_identifier, :submissions)

    if @room.expired?
      redirect_to room_results_path(@room.room_code), notice: "Room has ended. Here are the results."
      return
    end
    # When room is started, do not redirect to exams here — user may not have entered name yet.
    # They see the "Start exam" form (countdown shows "Started!") and submit with display_name/candidate_identifier,
    # then exams#index accepts them. Redirecting without name would cause a redirect loop with require_display_name.
  end

  def start_now
    unless current_user&.host? && @room.created_by_id == current_user.id
      redirect_to room_path(@room.room_code), alert: "Only the room creator can start the exam early."
      return
    end
    if @room.started?
      redirect_to room_path(@room.room_code), notice: "Exam already started."
      return
    end
    @room.update!(starts_at: Time.current)
    redirect_to room_path(@room.room_code), notice: "Exam started now. Candidates can begin."
  end

  def participants
    render json: {
      participants_count: @room.exam_attempts.count,
      submitted_count: @room.exam_attempts.where.not(submissions: [nil, ""]).count,
      participants: @room.exam_attempts.order(created_at: :asc).map { |a| { display_name: a.display_name.presence || "—", submitted: a.submissions.present? } }
    }
  end

  def results
    @exam_session = @room.exam_session
    attempts_with_submissions = @room.exam_attempts.where.not(submissions: [nil, ""])

    @leaderboard = attempts_with_submissions.map do |attempt|
      subs = attempt.submissions_array
      result = @exam_session.score_submissions(subs)
      { attempt: attempt, score: result[:score], total: result[:total], submitted_at: attempt.updated_at }
    end.sort_by { |e| [-e[:score], e[:submitted_at].to_i] }

    respond_to do |format|
      format.html
      format.csv do
        require "csv"
        csv = build_results_csv(@leaderboard)
        send_data csv, filename: "room-#{@room.room_code}-results-#{Time.current.strftime('%Y%m%d-%H%M')}.csv", type: "text/csv", disposition: "attachment"
      end
    end
  end

  private

  def set_room
    @room = ExamRoom.find_by!(room_code: params[:room_code])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Room not found."
    throw :abort
  end

  def parse_starts_at(date_str, time_str)
    return nil if date_str.blank? || time_str.blank?
    Time.zone.parse("#{date_str} #{time_str}")
  rescue ArgumentError
    nil
  end

  def build_results_csv(leaderboard)
    CSV.generate(headers: true) do |csv|
      csv << %w[Rank Name Candidate\ ID Score Total Submitted\ at]
      leaderboard.each_with_index do |entry, index|
        attempt = entry[:attempt]
        csv << [
          index + 1,
          attempt.display_name.presence || "",
          attempt.candidate_identifier.presence || "",
          entry[:score],
          entry[:total],
          entry[:submitted_at]&.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end
end
