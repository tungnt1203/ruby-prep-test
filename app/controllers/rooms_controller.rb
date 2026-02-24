# frozen_string_literal: true

class RoomsController < ApplicationController
  before_action :require_host, only: [ :new, :create, :destroy ]
  before_action :set_room, only: [ :show, :results, :start_now, :destroy ]

  def new
    @exam_sessions = ExamSession.order(created_at: :desc).limit(20)
    @preselected_exam_hash_id = params[:exam_hash_id].presence
  end

  def create
    exam_hash_id = [ params[:exam_hash_id_manual], params[:exam_hash_id] ].compact.find { |v| v.present? && v != "__manual__" }
    exam_session = ExamSession.find_by(hash_id: exam_hash_id)
    unless exam_session
      flash.now[:alert] = "Exam not found. Please enter a valid exam code."
      set_room_form_from_params
      render :new, status: :unprocessable_entity
      return
    end

    starts_at = parse_starts_at(params[:starts_at_date], params[:starts_at_time])
    unless starts_at && starts_at > Time.current
      flash.now[:alert] = "Start time must be in the future."
      set_room_form_from_params
      render :new, status: :unprocessable_entity
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
      require_display_name: false,
      require_candidate_identifier: false
    )

    redirect_to room_path(room.room_code), notice: "Room created. Share the link with participants."
  end

  def show
    return if performed?

    @exam_session = @room.exam_session
    if @room.expired?
      redirect_to room_results_path(@room.room_code), notice: "Room has ended. Here are the results."
    end
  end

  def start_now
    return if performed?

    unless current_user&.host? && @room.created_by_id == current_user.id
      redirect_to room_path(@room.room_code), alert: "Only the room creator can start the exam early."
      return
    end
    if @room.started?
      redirect_to room_path(@room.room_code), notice: "Exam already started."
      return
    end
    @room.update!(starts_at: Time.current)
    broadcast_room_started(@room)
    redirect_to room_path(@room.room_code), notice: "Exam started now. Candidates can begin."
  end

  def destroy
    return if performed?

    unless current_user&.host? && @room.created_by_id == current_user.id
      redirect_to room_path(@room.room_code), alert: "Only the room creator can delete this room."
      return
    end
    room_code = @room.room_code
    @room.destroy
    redirect_to dashboard_path, notice: "Room #{room_code} and all related attempts have been deleted."
  end

  def results
    return if performed?

    @exam_session = @room.exam_session
    attempts_with_submissions = @room.exam_attempts.where.not(submissions: [ nil, "" ])

    @leaderboard = attempts_with_submissions.map do |attempt|
      subs = attempt.submissions_array
      result = @exam_session.score_submissions(subs)
      { attempt: attempt, score: result[:score], total: result[:total], submitted_at: attempt.updated_at }
    end.sort_by { |e| [ -e[:score], e[:submitted_at].to_i ] }

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
    @room = ExamRoom.find_by(room_code: params[:room_code])
    unless @room
      redirect_to root_path, alert: "Room not found."
    end
  end

  def broadcast_room_started(room)
    room.reload
    html = ApplicationController.render(
      partial: "rooms/room_countdown_section",
      locals: { room: room },
      layout: false
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      ActionView::RecordIdentifier.dom_id(room),
      target: "room_countdown_section",
      html: html
    )
  end

  def set_room_form_from_params
    @exam_sessions = ExamSession.order(created_at: :desc).limit(20)
    raw = [ params[:exam_hash_id_manual], params[:exam_hash_id] ].compact.find { |v| v.present? && v != "__manual__" }
    @preselected_exam_hash_id = raw.presence
    @room_name = params[:room_name]
    @instructions = params[:instructions]
    @starts_at_date = params[:starts_at_date]
    @starts_at_time = params[:starts_at_time]
    @duration_minutes = params[:duration_minutes]
  end

  def parse_starts_at(date_str, time_str)
    return nil if date_str.blank? || time_str.blank?
    Time.zone.parse("#{date_str} #{time_str}")
  rescue ArgumentError
    nil
  end

  def build_results_csv(leaderboard)
    CSV.generate(headers: true) do |csv|
      csv << %w[Rank User Score Total Submitted\ at]
      leaderboard.each_with_index do |entry, index|
        attempt = entry[:attempt]
        csv << [
          index + 1,
          attempt.display_name.presence || attempt.candidate_identifier.presence || "",
          entry[:score],
          entry[:total],
          entry[:submitted_at]&.strftime("%Y-%m-%d %H:%M")
        ]
      end
    end
  end
end
