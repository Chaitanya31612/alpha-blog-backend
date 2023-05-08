class UsersController < ApplicationController
  before_action :authenticate_user
  before_action :set_user, only: %i[show edit update destroy]
  # before_action :require_same_user, only: %i[edit update destroy]
  before_action :set_follow_user, only: %i[follow unfollow]

  # TODO implement csrf protection
  protect_from_forgery with: :null_session, only: [:follow, :unfollow]


  def index
    # @users = User.paginate(page: params[:page], per_page: 6)
    @users = User.all.map do |user|
      user.attributes.merge(
        {
          followingsCount: user.followings.count,
          followersCount: user.followers.count,
          articlesCount: user.articles.count,
        }
      ).except('password_digest')
    end
    render json: @users
  end

  def show
    @user = User.find(params[:id]).attributes.merge(
      articles: @user.articles.map do |article|
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
      followings: @user.followings.map do |following|
        following.attributes.except('password_digest')
      end,
      followers: @user.followers.map do |follower|
        follower.attributes.except('password_digest')
      end
    ).except('password_digest')

    render json: @user
  end

  def new
    @user = User.new
  end

  def edit
  end

  def update
    if @user.update(user_params)
      flash[:notice] = 'Your account has been updated successfully!'
      redirect_to @user
    else
      render 'edit'
    end
  end

  def create
    # byebug
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      flash[:notice] = "Welcome to Alpha Blog #{@user.username}!"
      redirect_to @user
    else
      render 'new'
    end
  end

  def destroy
    # byebug
    @user.destroy
    render json: { message: 'User deleted successfully' }
  end

  def follow
    if @follow_user
      @current_user.follow(@follow_user)

      followings = @current_user.followings.map do |following|
        following.attributes.except('password_digest')
      end

      render json: { message: 'Followed Successfully', followings: followings }
    else
      render json: { errors: 'User not found' }, status: :unprocessable_entity
    end
  end

  def unfollow
    if @follow_user
      @current_user.unfollow(@follow_user)

      followings = @current_user.followings.map do |following|
        following.attributes.except('password_digest')
      end

      render json: { message: 'Unfollowed Successfully', followings: followings }
    else
      render json: { errors: 'User not found' }, status: :unprocessable_entity
    end
  end

  # /GET /users/top
  def top_users
    @top_users = User.all.sort_by { |c| c.articles.count }.reverse[0..2]
    render json: @top_users
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_follow_user
    @follow_user = User.find(params[:user_id])
  end

  def user_params
    params.require(:user).permit(:username, :email, :password)
  end

  def require_same_user
    return if @user == current_user

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    redirect_to @user
  end
end
