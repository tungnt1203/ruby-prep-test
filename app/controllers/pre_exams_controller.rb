# frozen_string_literal: true

require "net/http"
require "uri"

class PreExamsController < ApplicationController
  def index
  end

  def create_test
    uri = URI("https://learn.viblo.asia")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.get(uri.request_uri)
    cookies = response.get_fields("set-cookie")

    csrf = cookies
      .find { |c| c.start_with?("XSRF-TOKEN=") }
      .split(";").first.split("=").last

    cookie_header = cookies.map { |c| c.split(";").first }.join("; ")
    cookie_header += "; viblo_session_nonce=#{Rails.application.credentials.viblo_session_nonce}"
    cookie_header += "; viblo_learning_auth=#{Rails.application.credentials.viblo_learning_auth}"

    exam_id = params[:exam_id].presence || 76
    language = params[:language].presence || "en"

    raw = Viblo::Exams.new(
      url: "https://learn.viblo.asia/api/exams/#{exam_id}/tests/create?language=#{language}",
      cookies: cookie_header,
      x_xsrf_token: csrf
    ).create_test

    parsed = JSON.parse(raw)
    api_data = parsed["data"]

    unless api_data&.key?("hashId")
      redirect_to pre_exams_path, alert: "Could not create an exam. Please verify the Viblo API and cookies."
      return
    end

    ExamSession.find_by(hash_id: api_data["hashId"])&.destroy
    exam_session = ExamSession.create_from_api_data(api_data)

    unless exam_session
      redirect_to pre_exams_path, alert: "Failed to persist the exam session."
      return
    end

    open_router_key = Rails.application.credentials.open_router_api_key.presence || ENV["OPENROUTER_API_KEY"]
    gemini_key = Rails.application.credentials.gemini_api_key.presence || ENV["GEMINI_API_KEY"]

    if open_router_key.present? || gemini_key.present?
      result = exam_session.fetch_correct_answers!
      api_name = open_router_key.present? ? "OpenRouter" : "Gemini"
      flash[:ai_answer_key_result] = "#{result[:success]}/#{result[:total]} questions (#{api_name})"
      flash[:ai_answer_key_has_errors] = result[:errors].any?
      if result[:errors].any?
        err = result[:errors].first[:error].to_s
        flash[:ai_answer_key_first_error] = err.length > 500 ? "#{err[0, 500]}..." : err
      end
    else
      flash[:ai_answer_key_result] = "AI answer key is not configured (missing OPENROUTER_API_KEY / GEMINI_API_KEY)."
    end

    redirect_to created_pre_exams_path(exam_code: api_data["hashId"])
  rescue JSON::ParserError
    redirect_to pre_exams_path, alert: "Invalid API response."
  rescue StandardError => e
    redirect_to pre_exams_path, alert: "Error: #{e.message}"
  end

  def created
    @exam_code = params[:exam_code].presence
    if @exam_code.blank?
      redirect_to pre_exams_path, alert: "Missing exam code."
      return
    end
  end

  def fetch_correct_answers
    exam_session = ExamSession.find_by(hash_id: session[:exam_hash_id])

    unless exam_session
      redirect_to pre_exams_path, alert: "No exam session found. Please create an exam first."
      return
    end

    result = exam_session.fetch_correct_answers!
    open_router_key = Rails.application.credentials.open_router_api_key.presence || ENV["OPENROUTER_API_KEY"]
    api_name = open_router_key.present? ? "OpenRouter" : "Gemini"

    if result[:errors].any?
      redirect_to exams_path(exam_code: session[:exam_hash_id]),
        notice: "Answer key fetched for #{result[:success]}/#{result[:total]} questions (#{api_name}). Some questions failed."
    else
      redirect_to exams_path(exam_code: session[:exam_hash_id]),
        notice: "Answer key fetched for #{result[:success]}/#{result[:total]} questions (#{api_name})."
    end
  rescue Gemini::CorrectAnswerFetcher::MissingApiKey, OpenRouter::CorrectAnswerFetcher::MissingApiKey
    redirect_to pre_exams_path, alert: "AI answer key is not configured (missing OPENROUTER_API_KEY / GEMINI_API_KEY)."
  end
end
