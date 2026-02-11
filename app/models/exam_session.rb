# frozen_string_literal: true

class ExamSession < ApplicationRecord
  has_many :questions, dependent: :destroy
  has_many :exam_attempts, dependent: :destroy
  has_many :exam_rooms, dependent: :destroy

  validates :hash_id, presence: true, uniqueness: true

  # Scores user submissions against the persisted answer key.
  # @param submissions [Array<Hash>] each entry { question_id: id, answers: "A" or ["A","B"] }
  # @return [Hash] { score:, total:, details: [{ question_id, correct, user_answers, correct_answers, description }] }
  def score_submissions(submissions)
    return { score: 0, total: questions.count, details: [] } if submissions.blank?

    by_id = questions.index_by(&:id)
    details = []
    score = 0

    submissions.each do |sub|
      qid = (sub["question_id"] || sub[:question_id]).to_i
      question = by_id[qid]
      next unless question

      user_keys = Array.wrap(sub["answers"] || sub[:answers]).map(&:to_s)
      correct = question.correct_choice_keys.any? && question.correct?(user_keys)
      score += 1 if correct

      details << {
        question_id: qid,
        correct: correct,
        user_answers: user_keys,
        correct_answers: question.correct_choice_keys,
        description: question.explanation,
        topic_key: question.topic_key,
        topic_name: question.topic_name
      }
    end

    { score: score, total: by_id.size, details: details }
  end
end
