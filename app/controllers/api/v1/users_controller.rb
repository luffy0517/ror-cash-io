class Api::V1::UsersController < ApplicationController
  before_action :authorize_request, except: :create
  before_action :set_user, only: %i[ show update destroy ]

  def index
    direction = "ASC"
    if params[:direction]
      direction = params[:direction]
    end

    order_by = "id"
    if params[:order_by]
      order_by = params[:order_by]
    end

    page = 1
    if params[:page]
      page = params[:page].to_i
    end

    per_page = 25
    if params[:per_page]
      per_page = params[:per_page].to_i
    end

    search = params[:search]

    @users = User.order(order_by + " " + direction).page(page).per(per_page)

    if search
      @users = @users.search_by_term(search)
    end

    total = @users.total_count

    last_page = total.fdiv(per_page).ceil

    render json: {
      result: @users,
      direction: direction,
      order_by: order_by,
      page: page,
      per_page: per_page,
      search: search,
      total: total,
      last_page: last_page,
    }, except: [:password_digest]
  end

  def show
    render json: @user, except: [:password_digest]
  end

  def create
    @user = User.new(user_params)

    if @user.save
      render json: @user, except: [:password_digest], status: :created
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def update
    if @user.update(user_params)
      render json: @user, except: [:password_digest]
    else
      render json: @user.errors, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.permit(:first_name, :last_name, :avatar, :username, :email, :password, :password_confirmation)
  end
end
