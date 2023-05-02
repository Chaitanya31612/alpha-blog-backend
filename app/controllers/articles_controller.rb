class ArticlesController < ApplicationController
  # before_action :require_user, except: %i[index show]
  before_action :authenticate_user, except: [:featured_articles]
  before_action :set_article, only: %i[show edit update destroy]
  before_action :require_same_user, only: [:destroy]
  before_action :require_same_or_admin_user, only: %i[edit update]

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
    # this is strong param passing
    @article = Article.new(article_params)
    @article.user = current_user
    # render plain: @article
    if @article.save
      flash[:notice] = 'Article was saved successfully'
      redirect_to @article
    else
      # flash[:notice] = 'Error saving the article, Try again'
      render 'new'
    end
  end

  def update
    if @article.update(article_params)
      flash[:notice] = 'Article Updated Successfully'
      redirect_to @article
    else
      # flash[:notice] = "Error Updating Article"
      render 'edit'
    end
  end

  def destroy
    @article.destroy
    redirect_to articles_path
  end

  def upvote
    article = Article.find(params[:id])
    if article
      article.upvote
      article.save
      redirect_back fallback_location: articles_path
    else
      redirect_back fallback_location: articles_path
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
    return if @article.user == current_user

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    redirect_to @article
  end

  def require_same_or_admin_user
    return if @article.user == current_user || current_user.admin?

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    redirect_to @article
  end
end
