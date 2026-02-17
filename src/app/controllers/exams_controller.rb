# frozen_string_literal: true

class ExamsController < ApplicationController
  before_action :require_login, only: [ :index, :create, :show ]

  def index
    hash_id = params[:exam_code].presence
    room_code = params[:room_code].presence
    @exam_room = room_code.present? ? ExamRoom.find_by(room_code: room_code) : nil

    if hash_id.present?
      @exam_session = ExamSession.find_by(hash_id: hash_id)
      if @exam_session.nil?
        redirect_to root_path, alert: "Exam not found. Please use a valid exam or room link."
        return
      end
      if @exam_room && @exam_session && !@exam_room.started?
        redirect_to room_path(@exam_room.room_code), alert: "Exam has not started yet. Please wait until the start time."
        return
      end
      if @exam_session
        @exam_attempt = find_or_create_attempt
        if @exam_room&.started? && @exam_attempt&.submissions.present?
          redirect_to exam_path(hash_id, room_code: room_code), notice: "You already submitted. Here is your result."
          return
        end
        if @exam_room&.expired?
          redirect_to room_results_path(@exam_room.room_code), notice: "Room has ended. View results below."
          return
        end
      end
    else
      @exam_session = nil
      @exam_attempt = nil
    end

    if @exam_session
      @exam = build_exam_hash(@exam_session)
      @questions = build_questions_array(@exam_session, @exam_attempt, @exam_room)
      raw_ends_at = @exam_room&.started? && @exam_room.ends_at.present? ? @exam_room.ends_at : nil
      @room_ends_at = raw_ends_at.respond_to?(:iso8601) ? raw_ends_at : (raw_ends_at.respond_to?(:to_time) ? raw_ends_at.to_time : nil)
    else
      @exam = {}
      @questions = []
      @room_ends_at = nil
    end
  end

  def create
    hash_id = params[:exam_code].presence
    unless hash_id.present?
      redirect_to pre_exams_path, alert: "Invalid request. Please start from an exam or room link."
      return
    end

    exam_session = ExamSession.find_by(hash_id: hash_id)
    attempt = find_attempt_for_submit(exam_session)
    unless attempt
      redirect_to exams_path(exam_code: hash_id, room_code: params[:room_code].presence), alert: "Could not find your attempt. Please start the exam again."
      return
    end

    answers_hash = params[:answers].present? ? params[:answers].to_unsafe_h : {}
    submissions = build_submissions_from_params(answers_hash)
    payload = submissions.map { |s| { "question_id" => s[:question_id], "answers" => s[:answers] } }
    attempt.update!(submissions: payload.to_json)

    redirect_to exam_path(hash_id, room_code: params[:room_code].presence), notice: "Submission saved."
  end

  def show
    @hash_id = params[:id]
    @room_code = params[:room_code].presence
    @exam_session = ExamSession.find_by(hash_id: @hash_id)
    @exam_attempt = find_attempt_for_result
    last_submissions = @exam_attempt&.submissions_array

    @score_from_db = if @exam_session && last_submissions.present?
      @exam_session.score_submissions(last_submissions)
    end
    @details_by_qid = @score_from_db[:details].index_by { |d| d[:question_id].to_i } if @score_from_db.present?

    if @exam_session
      @questions_for_result = build_questions_array(@exam_session, @exam_attempt, @exam_attempt&.exam_room)
      @exam_title = @exam_session.exam_title
      @total_questions = @exam_session.total_questions
    end
  end

  private

  def build_exam_hash(exam_session)
    {
      "title" => exam_session.exam_title,
      "time" => exam_session.time_limit_seconds,
      "totalQuestions" => exam_session.total_questions,
      "numberPass" => exam_session.number_pass
    }
  end

  def build_questions_array(exam_session, attempt = nil, exam_room = nil)
    questions = exam_session.questions.order(:id).to_a
    # Cùng phòng thi → cùng seed → đề và thứ tự đáp án giống nhau cho mọi thí sinh
    seed = questions_seed_for(exam_room, attempt)
    if seed
      questions = questions.shuffle(random: Random.new(seed))
    end
    questions.map do |q|
      choices = q.question_choices.order(:choice_key).map { |c| { "id" => c.choice_key, "label" => c.label } }
      {
        "id" => q.id,
        "type" => q.question_type,
        "question" => q.body,
        "choices" => choices,
        "topic_key" => q.topic_key,
        "topic_name" => q.topic_name
      }
    end
  end

  # Seed cho thứ tự câu/đáp án: theo room nếu có phòng (đề giống nhau trong room), không thì theo attempt
  def questions_seed_for(exam_room, attempt)
    if exam_room.present?
      exam_room.id.to_i
    elsif attempt.present? && attempt.attempt_token.present?
      attempt.attempt_token.bytes.sum
    end
  end

  def find_or_create_attempt
    scope = @exam_session.exam_attempts.where(user_id: current_user.id)
    scope = scope.where(exam_room_id: @exam_room ? @exam_room.id : nil)
    attempt = scope.first
    unless attempt
      attrs = {
        user_id: current_user.id,
        exam_room: @exam_room || nil,
        display_name: current_user.email.presence,
        candidate_identifier: current_user.email.presence
      }
      attempt = @exam_session.exam_attempts.create!(attrs)
    end
    attempt
  end

  def find_attempt_for_submit(exam_session)
    return nil unless exam_session && current_user
    scope = exam_session.exam_attempts.where(user_id: current_user.id)
    room_code = params[:room_code].presence
    if room_code.present?
      room = ExamRoom.find_by(room_code: room_code)
      return nil unless room # invalid room_code => don't submit to wrong attempt
      scope = scope.where(exam_room_id: room.id)
    else
      scope = scope.where(exam_room_id: nil)
    end
    scope.first
  end

  def find_attempt_for_result
    if params[:attempt_id].present?
      ExamAttempt.find_by(attempt_token: params[:attempt_id], exam_session: @exam_session)
    elsif @exam_session && current_user
      scope = @exam_session.exam_attempts.where(user_id: current_user.id)
      if @room_code.present?
        room = ExamRoom.find_by(room_code: @room_code)
        return nil unless room # invalid room_code => don't show wrong attempt
        scope = scope.where(exam_room_id: room.id)
      else
        scope = scope.where(exam_room_id: nil)
      end
      scope.first
    end
  end

  def build_submissions_from_params(answers_params)
    return [] if answers_params.blank?

    answers_params.map do |question_id_str, value|
      qid = question_id_str.to_i
      answers = Array.wrap(value).map { |v| v.to_s.upcase }.compact
      next if answers.empty?

      item = { question_id: qid }
      item[:answers] = answers.size == 1 ? answers.first : answers
      item
    end.compact
  end
end
