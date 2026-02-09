# frozen_string_literal: true

class HomeController < ApplicationController

  def index
    if current_user&.host?
      redirect_to pre_exams_path
    end
  end

  def join
    if params[:room_code].present?
      redirect_to room_path(params[:room_code].strip)
    end
  end
end
