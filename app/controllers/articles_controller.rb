class ArticlesController < ApplicationController
  # before_action :require_user, except: %i[index show]
  before_action :authenticate_user
  before_action :set_article, only: %i[show edit update destroy]
  # after_action :require_same_user
  # before_action :require_same_or_admin_user, only: %i[edit update]
  # protect_from_forgery with: :exception

  # ?BOTH of these prevent CSRF attacks
  # skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session

  def index
    # byebug
    # current_user ||= User.find(params[:user_id]) if params[:user_id]
    # @articles = Article.where(user_id: current_user.followings).paginate(page: params[:page], per_page: 5)
    # @total_articles = Article.where(user_id: current_user.followings).count

    @articles = Article.where(user_id: @current_user.followings).map do |article|
      article.attributes.merge(
        {
          categories: article.categories,
          user: {
            id: article.user.id,
            username: article.user.username,
            email: article.user.email
          }
        }
      ).except('password_digest')
    end
    # @articles = Article.all
    render json: @articles
  end

  def show
    @article = Article.find(params[:id]).attributes.merge(
      categories: @article.categories,
      user: @article.user.attributes.except('password_digest')
    )
    render json: @article
  end

  def new
    @article = Article.new
  end

  def edit
  end

  def create
    @article = Article.new(article_params)
    @article.user = @current_user
    @article.categories << Category.find(params[:category_ids]) if params[:category_ids]

    if @article.save
      render json: { message: 'Article Created Successfully', article: @article }
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    @article.categories = []
    @article.categories << Category.find(params[:category_ids]) if params[:category_ids]

    if @article.update(article_params)
      render json: { message: 'Article Updated Successfully', article: @article }
    else
      render json: { errors: @article.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @article.destroy

    render json: { message: 'Article Deleted Successfully' }
  end

  def upvote
    article = Article.find(params[:id])
    if article
      article.upvote
      article.save

      render json: { message: 'Article Upvoted Successfully', article: article }
    else
      render json: { errors: 'Article Not Found' }, status: :not_found
    end
  end

  def featured_articles
    @featured_articles = Article.where(featured: true).map do |article|
      article.attributes.merge(
        {
          categories: article.categories,
          user: {
            id: article.user.id,
            username: article.user.username,
            email: article.user.email
          }
        }
      ).except('password_digest')
    end

    return render json: @featured_articles[0..params[:limit].to_i - 1] if params[:limit]

    render json: @featured_articles
  end

  private

  def set_article
    @article = Article.find(params[:id])
  end

  def article_params
    params.require(:article).permit(:title, :description, :featured, category_ids: [])
  end

  def require_same_user
    return if @article.user == @current_user

    render json: { message: 'You are not allowed to perform this action!' }, status: :unauthorized
  end

  def require_same_or_admin_user
    return if @article.user == current_user || current_user.admin?

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    redirect_to @article
  end
end
