# frozen_string_literal: true

class ExamsController < ApplicationController
  before_action :require_login, only: [:index, :create, :show]

  def index
    hash_id = params[:exam_code].presence || session[:exam_hash_id]
    room_code = params[:room_code].presence || session[:exam_room_code]
    if room_code.present?
      session[:exam_room_code] = room_code
      @exam_room = ExamRoom.find_by(room_code: room_code)
    else
      @exam_room = nil
      session.delete(:exam_room_code)
      session.delete(:exam_display_name)
    end

    if hash_id.present?
      session[:exam_hash_id] = hash_id
      session[:exam_display_name] = params[:display_name].presence || session[:exam_display_name]
      session[:exam_candidate_identifier] = params[:candidate_identifier].presence || session[:exam_candidate_identifier]
      @exam_session = ExamSession.find_by(hash_id: hash_id)
      if hash_id.present? && @exam_session.nil?
        redirect_to root_path, alert: "Exam not found. Please use a valid exam or room link."
        return
      end
      if @exam_room && @exam_session
        if @exam_room.require_display_name && session[:exam_display_name].blank?
          redirect_to room_path(@exam_room.room_code), alert: "Please enter your name to start the exam."
          return
        end
        if @exam_room.require_candidate_identifier && session[:exam_candidate_identifier].blank?
          redirect_to room_path(@exam_room.room_code), alert: "Please enter your email or candidate ID to start the exam."
          return
        end
      end
      if @exam_session
        @exam_attempt = find_or_create_attempt
        if @exam_room&.started? && @exam_attempt&.submissions.present?
          redirect_to exam_path(hash_id, attempt_id: @exam_attempt.attempt_token)
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
      @questions = build_questions_array(@exam_session, @exam_attempt)
      @room_ends_at = @exam_room&.started? && @exam_room.ends_at.present? ? @exam_room.ends_at : nil
    else
      @exam = {}
      @questions = []
      @room_ends_at = nil
    end
  end

  def create
    hash_id = session[:exam_hash_id]
    unless hash_id.present?
      redirect_to pre_exams_path, alert: "Invalid session. Please create an exam first."
      return
    end

    answers_hash = params[:answers].present? ? params[:answers].to_unsafe_h : {}
    submissions = build_submissions_from_params(answers_hash)

    payload = submissions.map { |s| { "question_id" => s[:question_id], "answers" => s[:answers] } }
    exam_session = ExamSession.find_by(hash_id: hash_id)
    attempt_token = params[:attempt_id].presence || session[:exam_attempt_token]
    attempt = ExamAttempt.find_by(attempt_token: attempt_token, exam_session: exam_session) if attempt_token && exam_session
    attempt&.update!(submissions: payload.to_json)

    redirect_to exam_path(hash_id, attempt_id: attempt&.attempt_token), notice: "Submission saved."
  end

  def show
    @hash_id = params[:id]
    @room_code = session[:exam_room_code]
    @exam_session = ExamSession.find_by(hash_id: @hash_id)
    @exam_attempt = find_attempt_for_result
    last_submissions = @exam_attempt&.submissions_array

    @score_from_db = if @exam_session && last_submissions.present?
      @exam_session.score_submissions(last_submissions)
    end
    @details_by_qid = @score_from_db[:details].index_by { |d| d[:external_question_id].to_i } if @score_from_db.present?

    if @exam_session
      @questions_for_result = build_questions_array(@exam_session)
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

  def build_questions_array(exam_session, attempt = nil)
    questions = exam_session.questions.order(:id).to_a
    seed = attempt.present? && attempt.attempt_token.present? ? attempt.attempt_token.bytes.sum : nil
    if seed
      questions = questions.shuffle(random: Random.new(seed))
    end
    questions.map do |q|
      choices = q.question_choices.to_a.map { |c| { "id" => c.external_choice_id, "label" => c.label } }
      if seed
        choices = choices.shuffle(random: Random.new(seed + q.external_question_id))
      end
      {
        "id" => q.external_question_id,
        "type" => q.question_type,
        "question" => q.body,
        "choices" => choices
      }
    end
  end

  def find_or_create_attempt
    token = session[:exam_attempt_token]
    scope = @exam_session.exam_attempts
    scope = scope.where(exam_room_id: @exam_room.id) if @exam_room&.started?
    attempt = scope.find_by(attempt_token: token) if token.present?
    unless attempt
      attrs = { exam_room: @exam_room&.started? ? @exam_room : nil }
      attrs[:display_name] = session[:exam_display_name].presence if session[:exam_display_name].present?
      attrs[:candidate_identifier] = session[:exam_candidate_identifier].presence if session[:exam_candidate_identifier].present?
      attempt = @exam_session.exam_attempts.create!(attrs)
      session[:exam_attempt_token] = attempt.attempt_token
    end
    attempt
  end

  def find_attempt_for_result
    if params[:attempt_id].present?
      ExamAttempt.find_by(attempt_token: params[:attempt_id], exam_session: @exam_session)
    elsif session[:exam_attempt_token].present? && @exam_session
      ExamAttempt.find_by(attempt_token: session[:exam_attempt_token], exam_session: @exam_session)
    end
  end

  def build_submissions_from_params(answers_params)
    return [] if answers_params.blank?

    answers_params.map do |question_id_str, value|
      qid = question_id_str.to_i
      answers = Array.wrap(value).map { |v| v.to_s.to_i }.compact
      next if answers.empty?

      item = { question_id: qid }
      item[:answers] = answers.size == 1 ? answers.first : answers
      item
    end.compact
  end
end
