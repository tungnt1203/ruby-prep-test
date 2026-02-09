# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :require_host

  def index
    @rooms = current_user.created_exam_rooms
      .includes(:exam_session)
      .order(starts_at: :desc)
      .limit(50)
  end
end
