module Api
  module V1
    # Handles Category entity API actions
    class CategoriesController < ApplicationController
      before_action :authorize_request
      before_action :set_category, only: %i[show update destroy]
      before_action :set_direction, :set_order_by, :set_page, :set_per_page, :set_search, :set_category_id,
                    only: %i[index]

      def index
        result = @current_user.categories.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
        result = result.search_by_term(@search) if @search
        result = result.search_by_category_id(@category_id) if @category_id
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

      def set_direction
        @direction = params[:direction] || 'ASC'
      end

      def set_order_by
        @order_by = params[:order_by] || 'id'
      end

      def set_page
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
      end

      def set_per_page
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 25
      end

      def set_search
        @search = params[:search]
      end

      def set_category_id
        @category_id = params[:category_id]
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
