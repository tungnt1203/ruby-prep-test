class ExamsController < ApplicationController
  def index
    hash_id = params[:exam_code].presence || session[:exam_hash_id]
    if hash_id.present?
      session[:exam_hash_id] = hash_id
      @exam_session = ExamSession.find_by(hash_id: hash_id)
      @exam_attempt = find_or_create_attempt if @exam_session
    else
      @exam_session = nil
      @exam_attempt = nil
    end

    if @exam_session
      @exam = build_exam_hash(@exam_session)
      @questions = build_questions_array(@exam_session)
    else
      @exam = {}
      @questions = []
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

  def build_questions_array(exam_session)
    exam_session.questions.order(:id).map do |q|
      {
        "id" => q.external_question_id,
        "type" => q.question_type,
        "question" => q.body,
        "choices" => q.question_choices.map { |c| { "id" => c.external_choice_id, "label" => c.label } }
      }
    end
  end

  def find_or_create_attempt
    token = session[:exam_attempt_token]
    attempt = ExamAttempt.find_by(attempt_token: token, exam_session_id: @exam_session.id) if token.present?
    unless attempt
      attempt = @exam_session.exam_attempts.create!
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
