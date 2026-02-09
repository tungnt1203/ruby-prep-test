# frozen_string_literal: true

class HomeController < ApplicationController

  def index
    # Show home for everyone (host sees Dashboard / Create exam / Schedule room; others see Join / Sign in).
  end

  def join
    if params[:room_code].present?
      redirect_to room_path(params[:room_code].strip)
    end
  end
end
