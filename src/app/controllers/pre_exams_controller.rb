# frozen_string_literal: true

class PreExamsController < ApplicationController
  before_action :require_host

  def index
  end

  def create_test
    exam_title = params[:exam_title].presence
    result = CreateExamFromBankService.new(exam_title: exam_title).call
    redirect_to created_pre_exams_path(exam_code: result[:hash_id]), notice: "Exam created with 50 random questions from Ruby Silver."
  rescue CreateExamFromBankService::Error => e
    redirect_to pre_exams_path, alert: e.message
  rescue StandardError => e
    Rails.logger.error("[PreExamsController#create_test] #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    redirect_to pre_exams_path, alert: "Could not create exam: #{e.message}"
  end

  def created
    @exam_code = params[:exam_code].presence
    if @exam_code.blank?
      redirect_to pre_exams_path, alert: "Missing exam code."
      nil
    end
  end
end
