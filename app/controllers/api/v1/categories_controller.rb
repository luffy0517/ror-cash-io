module Api
  module V1
    # Handles Category entity API actions
    class CategoriesController < ApplicationController
      before_action :authorize_request
      before_action :set_category, only: %i[show update destroy]
      before_action :set_page_params, :set_order_params, :set_search_params, only: :index

      def index
        result = @current_user.categories.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
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
        render json: @category
      end

      def create
        @category = @current_user.categories.new(category_params)

        if @category.save
          render json: @category, status: :created
        else
          render json: @category.errors, status: :unprocessable_entity
        end
      end

      def update
        if @category.update(category_params)
          render json: @category
        else
          render json: @category.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @category.destroy
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

      def set_category
        @category = @current_user.categories.find(params[:id])
      end

      def category_params
        params.permit(:name, :image)
      end
    end
  end
end
