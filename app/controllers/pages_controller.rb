class PagesController < ApplicationController
  def home
    redirect_to articles_path if logged_in?
  end

  def about
  end

  def search
    # byebug
    search_term = params[:search_term].downcase
    @users_results = User.where("lower(username) like :search or lower(email) like :search", search: "%#{search_term}%")
    @articles_results = Article.where("lower(title) like ?", "%#{search_term}%")
    @categories_results = Category.where("lower(name) like ?", "%#{search_term}%")

    render json: {
      users: @users_results,
      articles: @articles_results,
      categories: @categories_results
    }
  end
end
