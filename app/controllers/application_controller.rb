class ApplicationController < ActionController::Base
  include JwtToken
  include ActionController::Cookies
  after_action :set_csrf_cookie

  helper_method :current_user, :logged_in?, :authenticate_user

  def current_user
    # memoized current_user, if available it will return directly
    @current_user ||= User.find(session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_user
    # byebug
    return if logged_in?

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    render json: { errors: 'You are not allowed to perform this action!' }, status: :unauthorized
  end

  def authenticate_user
    header = request.headers['Authorization']
    header = header.split(' ').last if header
    # byebug
    begin
      @decoded = JwtToken.decode(header)
      @current_user = User.find(@decoded[:user_id])
    rescue ActiveRecord::RecordNotFound => e
      render json: { errors: e.message }, status: :unauthorized
    rescue JWT::DecodeError => e
      render json: { errors: e.message }, status: :unauthorized
    end
  end

  private

  def set_csrf_cookie
    # puts "auth #{form_authenticity_token}"
    # cookies["CSRF-TOKEN"] = {
    #   value: form_authenticity_token
    # }
  end
end
