# frozen_string_literal: true

class ExamSession < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :exam_attempts, dependent: :destroy

  validates :hash_id, presence: true, uniqueness: true
  validates :external_exam_id, presence: true

  def self.create_from_api_data(api_data)
    return nil if api_data.blank?

    exam = api_data["exam"] || {}
    questions_data = api_data["questions"] || []

    transaction do
      session = create!(
        hash_id: api_data["hashId"],
        external_exam_id: exam["id"],
        language: api_data["language"] || "en",
        start_time: api_data["startTime"],
        exam_title: exam["title"],
        exam_description: exam["description"],
        time_limit_seconds: exam["time"],
        total_questions: exam["totalQuestions"],
        number_pass: exam["numberPass"]
      )

      questions_data.each do |q|
        session.questions.create!(
          external_question_id: q["id"],
          question_type: q["type"],
          body: q["question"],
          explanation: q["explanation"]
        ).tap do |question|
          (q["choices"] || []).each do |c|
            question.question_choices.create!(
              external_choice_id: c["id"],
              label: c["label"]
            )
          end
        end
      end

      session
    end
  end

  # Fetches and persists an AI answer key for every question in this session.
  # @return [Hash] { total: N, success: n, errors: [...] }
  def fetch_correct_answers!(api_key: nil)
    total = questions.count
    success = 0
    errors = []

    questions.find_each do |q|
      result = Gemini::FetchAndSaveCorrectAnswers.new(q, api_key: api_key).call
      if result[:success]
        success += 1
      else
        errors << { question_id: q.external_question_id, error: result[:error] }
      end
    end

    { total: total, success: success, errors: errors }
  end

  # Scores user submissions against the persisted answer key.
  # @param submissions [Array<Hash>] each entry { question_id: external_question_id, answers: id or [ids] }
  # @return [Hash] { score: correct_count, total: question_count, details: [{ question_id, correct, user_answers, correct_answers }] }
  def score_submissions(submissions)
    return { score: 0, total: questions.count, details: [] } if submissions.blank?

    by_external_id = questions.index_by(&:external_question_id)
    details = []
    score = 0

    submissions.each do |sub|
      qid = sub["question_id"] || sub[:question_id]
      question = by_external_id[qid.to_i]
      next unless question

      user_ids = Array.wrap(sub["answers"] || sub[:answers]).map(&:to_i)
      correct = question.correct_external_choice_ids.any? && question.correct?(user_ids)
      score += 1 if correct

      details << {
        question_id: qid,
        external_question_id: qid,
        correct: correct,
        user_answers: user_ids,
        correct_answers: question.correct_external_choice_ids,
        description: question.correct_answer_description
      }
    end

    { score: score, total: by_external_id.size, details: details }
  end
end
