# frozen_string_literal: true

class MyAttemptsController < ApplicationController
  before_action :require_login

  PER_PAGE = 25

  def index
    @page = normalized_page
    offset = (@page - 1) * PER_PAGE

    attempts = current_user.exam_attempts
      .includes(:exam_session, :exam_room)
      .order(updated_at: :desc, id: :desc)
      .offset(offset)
      .limit(PER_PAGE + 1)

    @has_next_page = attempts.length > PER_PAGE
    @attempts = attempts.first(PER_PAGE)
    @rows = build_rows(@attempts)
  end

  private

  def normalized_page
    page = params[:page].to_i
    page < 1 ? 1 : page
  end

  def build_rows(attempts)
    attempts.map do |attempt|
      score = score_for_attempt(attempt)
      {
        attempt: attempt,
        score: score,
        submitted_at: attempt.submissions.present? ? attempt.updated_at : nil
      }
    end
  end

  def score_for_attempt(attempt)
    return nil if attempt.submissions.blank?

    attempt.exam_session.score_submissions(attempt.submissions_array)
  end
end

