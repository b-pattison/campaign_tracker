class ApplicationController < ActionController::Base
  rescue_from ActiveRecord::RecordNotFound do
    render json: { error: "Not Found" }, status: :not_found
  end
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
end
