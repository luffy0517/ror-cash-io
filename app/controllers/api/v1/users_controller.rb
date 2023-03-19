module Api
  module V1
    # Handles User entity API actions
    class UsersController < ApplicationController
      before_action :authorize_request, except: :create
      before_action :set_user, only: %i[show update destroy]
      before_action :set_page_params, :set_order_params, :set_search_params, only: :index

      def index
        result = User.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search
        total = result.total_count
        last_page = total.fdiv(@per_page).ceil

        render json: {
          result:,
          direction: @direction,
          order_by: @order_by,
          page: @page,
          per_page: @per_page,
          search: @search,
          total:,
          last_page:
        }
      end

      def show
        render json: @user, except: :password_digest
      end

      def create
        @user = User.new(user_params)

        if @user.save
          render json: @user, except: :password_digest, status: :created
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def update
        if @user.update(user_params)
          render json: @user, except: :password_digest
        else
          render json: @user.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @user.destroy
      end

      private

      def set_page_params
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_order_params
        @direction = params[:direction] || 'ASC'
        @order_by = params[:order_by] || 'id'
      end

      def set_search_params
        @search = params[:search]
      end

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.permit(:first_name, :last_name, :avatar, :username, :email, :password, :password_confirmation)
      end
    end
  end
end
