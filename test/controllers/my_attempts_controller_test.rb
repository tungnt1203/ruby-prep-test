# frozen_string_literal: true

require "test_helper"

class MyAttemptsControllerTest < ActionDispatch::IntegrationTest
  def candidate
    users(:one)
  end

  test "get index without login redirects to login and stores return_to" do
    get my_attempts_path
    assert_redirected_to login_path
    assert_equal "/my_attempts", session[:return_to]
  end

  test "get index with login only shows attempts of current user" do
    post login_path, params: { email: candidate.email, password: "password" }
    assert_redirected_to root_path

    get my_attempts_path
    assert_response :success

    assert_select "h1", /my attempts/i
    assert_select "tbody tr", 2
    assert_match(/RoomCode01/, response.body)
    assert_match(/No room/, response.body)
  end
end

