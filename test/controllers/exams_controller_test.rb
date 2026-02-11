# frozen_string_literal: true

require "test_helper"

class ExamsControllerTest < ActionDispatch::IntegrationTest
  def exam_session
    exam_sessions(:one)
  end

  def exam_room
    exam_rooms(:one)
  end

  def candidate
    users(:one)
  end

  test "get index without login redirects to login and stores return_to" do
    get exams_path(exam_code: exam_session.hash_id, room_code: exam_room.room_code, display_name: "Test")
    assert_redirected_to login_path
    assert_equal "/exams?display_name=Test&exam_code=#{exam_session.hash_id}&room_code=#{exam_room.room_code}", session[:return_to]
    assert_match(/sign in to take the exam/i, flash[:alert].to_s)
  end

  test "get index with login succeeds when exam and room exist" do
    post login_path, params: { email: candidate.email, password: "password" }
    assert_redirected_to root_path

    get exams_path(exam_code: exam_session.hash_id, room_code: exam_room.room_code, display_name: "Test User")
    assert_response :success
    assert_nil session[:return_to]
  end

  test "post create without login redirects to login" do
    post login_path, params: { email: candidate.email, password: "password" }
    get exams_path(exam_code: exam_session.hash_id, room_code: exam_room.room_code, display_name: "Test")
    assert_response :success
    attempt_token = session[:exam_attempt_token]
    assert attempt_token.present?

    delete logout_path
    post exams_path, params: { attempt_id: attempt_token, answers: { "1" => "A" } }
    assert_redirected_to login_path
    assert_match(/sign in to take the exam/i, flash[:alert].to_s)
  end

  test "get show without login redirects to login" do
    post login_path, params: { email: candidate.email, password: "password" }
    get exams_path(exam_code: exam_session.hash_id, room_code: exam_room.room_code, display_name: "Test")
    attempt_token = session[:exam_attempt_token]
    delete logout_path

    get exam_path(exam_session.hash_id, attempt_id: attempt_token)
    assert_redirected_to login_path
    assert_equal "/exams/#{exam_session.hash_id}?attempt_id=#{attempt_token}", session[:return_to]
  end

  test "after login redirects back to return_to when set" do
    get exams_path(exam_code: exam_session.hash_id, room_code: exam_room.room_code)
    assert_redirected_to login_path
    return_to = session[:return_to]

    post login_path, params: { email: candidate.email, password: "password" }
    assert_redirected_to return_to
    assert_nil session[:return_to]
  end
end
