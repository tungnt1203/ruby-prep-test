# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  def candidate
    users(:one)
  end

  test "successful login redirects to return_to when set" do
    get exams_path(exam_code: "TestHash01", room_code: "RoomCode01")
    assert_redirected_to login_path
    return_to = session[:return_to]

    post login_path, params: { email: candidate.email, password: "password" }
    assert_redirected_to return_to
    assert_nil session[:return_to]
  end

  test "successful login redirects to root when return_to not set" do
    post login_path, params: { email: candidate.email, password: "password" }
    assert_redirected_to root_path
  end
end
