# frozen_string_literal: true

class CreateExamFromBankService
  class Error < StandardError; end

  EXAM_QUESTIONS_COUNT = 50
  DEFAULT_TITLE = "Ruby 3.1.x Silver Exam"
  DEFAULT_TIME_LIMIT = 60 * 60 # 1 hour
  DEFAULT_NUMBER_PASS = 40

  def initialize(questions_count: EXAM_QUESTIONS_COUNT, exam_title: nil)
    @questions_count = questions_count
    @exam_title = exam_title
  end

  def call
    bank_questions = BankQuestion.joins(:question_topic)
                                 .includes(:question_topic, :bank_question_choices)
                                 .order("RANDOM()")
                                 .limit(@questions_count)

    raise Error, "Question bank has fewer than #{@questions_count} questions. Run: rails db:seed_question_bank" if bank_questions.size < @questions_count

    hash_id = SecureRandom.hex(8)

    ExamSession.transaction do
      session = ExamSession.create!(
        hash_id: hash_id,
        exam_title: @exam_title.presence || DEFAULT_TITLE,
        exam_description: "50 random questions from Ruby Silver question bank",
        total_questions: @questions_count,
        number_pass: DEFAULT_NUMBER_PASS,
        time_limit_seconds: DEFAULT_TIME_LIMIT
      )

      bank_questions.each do |bq|
        copy_to_exam(session, bq)
      end

      { exam_session: session, hash_id: hash_id }
    end
  end

  private

  def copy_to_exam(exam_session, bank_question)
    topic = bank_question.question_topic
    question = exam_session.questions.create!(
      question_type: bank_question.question_type,
      body: bank_question.body,
      explanation: bank_question.explanation,
      topic_key: topic.key,
      topic_name: topic.name
    )

    choice_map = {}
    bank_question.bank_question_choices.each do |bc|
      qc = question.question_choices.create!(
        choice_key: bc.choice_key,
        label: bc.label
      )
      choice_map[bc] = qc
    end

    bank_question.bank_question_choices.where(is_correct: true).each do |bc|
      QuestionCorrectAnswer.create!(
        question: question,
        question_choice: choice_map[bc]
      )
    end
  end
end
