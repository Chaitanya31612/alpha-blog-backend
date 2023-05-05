class AuthenticationController < ApplicationController
  include JwtToken
  # skip_before_action :authenticate_user
  protect_from_forgery with: :null_session

  def login
    @user = User.find_by(username: params[:email])
    @user ||= User.find_by(email: params[:email].downcase) # if username not found, try email

    if @user&.authenticate(params[:password])
      puts "user #{@user.username}"
      token = JwtToken.encode(user_id: @user.id)
      render json: { token: token, csrf_token: form_authenticity_token, user: @user.attributes.except('password_digest') }, status: :ok
    else
      render json: { message: 'Invalid login credentials' }, status: :unauthorized
    end
  end

  def signup
    @user = User.new(user_params)
    if @user.save
      token = JwtToken.encode(user_id: @user.id)
      render json: { token:, user: @user.attributes.except('password_digest') }, status: :ok
    else
      render json: { message: @user.errors.full_messages || 'Unable to save user details' }, status: :unauthorized
    end
  end

  def update
    # byebug
    authenticate_user

    if @current_user.update(user_params)
      render json: { message: 'User Updated Successfully', user: @current_user.attributes.except('password_digest') }
    else
      render json: { errors: @current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def get_current_user
    authenticate_user

    user = @current_user.attributes.merge(
      articles: @current_user.articles.map do |article|
        article.attributes.merge(
          {
            categories: article.categories,
            user: {
              id: article.user.id,
              username: article.user.username,
              email: article.user.email
            }
          }
        )
      end,
      followings: @current_user.followings.map do |following|
        following.attributes.except('password_digest')
      end,
      followers: @current_user.followers.map do |follower|
        follower.attributes.except('password_digest')
      end
    ).except('password_digest')

    render json: { user: user, csrf_token: form_authenticity_token }
  end

  private

  def user_params
    params.require(:authentication).permit(:username, :email, :password)
  end
end
