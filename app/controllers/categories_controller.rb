class CategoriesController < ApplicationController
  before_action :authenticate_user
  before_action :set_category, only: %i[show edit update destroy]
  # before_action :require_admin, except: %i[index show]

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = 'Category created successfully!'
      redirect_to @category
    else
      render 'new'
    end
  end

  def index
    # @categories = Category.paginate(page: params[:page], per_page: 6)
    @categories = Category.all.map do |category|
      category.attributes.merge(
        {
          articlesCount: category.articles.count
        }
      )
    end
    render json: @categories
  end

  def show
    @category = Category.find(params[:id])
    @articles = @category.articles.map do |article|
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
    @users_count = @category.articles.select('distinct(user_id)').count
    render json: { category: @category, articles: @articles, usersCount: @users_count }
    # @articles = @category.articles.paginate(page: params[:page], per_page: 5)
    # @total_articles = @category.articles.count
  end

  def edit
  end

  def update
    if @category.update(category_params)
      flash[:notice] = 'Category name has been updated successfully!'
      redirect_to @category
    else
      render 'edit'
    end
  end

  def destroy
    @category.destroy
    flash[:notice] = 'Category deleted successfully!'
    redirect_to categories_path
  end

  def top_categories
    @top_categories = Category.all.sort_by { |c| c.articles.count }.reverse[0..4]
    render json: @top_categories
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end

  def require_user
    return if logged_in?

    flash[:alert_fail] = 'You are not allowed to perform this action!'
    redirect_to login_path
  end

  def require_admin
    return if logged_in? and current_user.admin?

    flash[:alert_fail] = 'This action can only be performed by admin'
    redirect_to categories_path
  end
end
