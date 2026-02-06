class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  # allow_browser versions: :modern

  helper_method :current_user, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    return if current_user.present?
    redirect_to login_path, alert: "Please sign in."
  end

  def require_host
    require_login
    return if performed?
    return if current_user&.host?
    redirect_to root_path, alert: "Only hosts can create exams and rooms."
  end
end
