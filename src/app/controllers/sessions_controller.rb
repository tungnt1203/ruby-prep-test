# frozen_string_literal: true

class SessionsController < ApplicationController
  def new
    @user = User.new
  end

  def create
    user = User.find_by(email: params[:email]&.downcase&.strip)
    if user&.authenticate(params[:password])
      session[:user_id] = user.id
      return_to = session.delete(:return_to).presence
      return_to = validate_exam_return_to(return_to)
      redirect_to return_to || root_path, notice: "Signed in."
    else
      flash.now[:alert] = "Invalid email or password."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path, notice: "Signed out."
  end

  private

  def validate_exam_return_to(path)
    return path if path.blank?
    return path unless path.start_with?("/exams")

    exam_code = URI.parse(path).query.to_s.split("&").find { |p| p.start_with?("exam_code=") }&.split("=", 2)&.last
    return path if exam_code.blank?
    return path if ExamSession.exists?(hash_id: exam_code)

    nil
  end
end
