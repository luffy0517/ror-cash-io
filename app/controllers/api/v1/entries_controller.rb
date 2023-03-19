module Api
  module V1
    # Handles Entry entity API actions
    class EntriesController < ApplicationController
      before_action :authorize_request
      before_action :set_entry, only: %i[show update destroy]
      before_action :set_direction, :set_order_by, :set_page, :set_per_page, :set_search, only: %i[index]

      def index
        result = @current_user.entries.order("#{@order_by} #{@direction}").page(@page).per(@per_page)
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
        render json: @entry
      end

      def create
        @entry = @current_user.entries.new(entry_params)

        if @entry.save
          render json: @entry, status: :created
        else
          render json: @entry.errors, status: :unprocessable_entity
        end
      end

      def update
        if @entry.update(entry_params)
          render json: @entry
        else
          render json: @entry.errors, status: :unprocessable_entity
        end
      end

      def destroy
        @entry.destroy
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

      def set_entry
        @entry = @current_user.entries.find(params[:id])
      end

      def entry_params
        params.permit(:name, :description, :date, :value)
      end
    end
  end
end
