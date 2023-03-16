class Api::V1::EntriesController < ApplicationController
  before_action :set_entry, only: %i[ show update destroy ]

  # GET /entries
  def index
    @direction = "ASC"
    if params[:direction]
      @direction = params[:direction]
    end

    @order_by = "id"
    if params[:order_by]
      @order_by = params[:order_by]
    end

    @page = 1
    if params[:page]
      @page = params[:page].to_i
    end

    @per_page = 25
    if params[:per_page]
      @per_page = params[:per_page].to_i
    end

    @search = params[:search]

    @result = Entry.order(@order_by + " " + @direction).page(@page).per(@per_page)

    if @search
      @result = @result.search_by_term(@search)
    end

    @total = @result.total_count

    @last_page = @total.fdiv(@per_page).ceil

    render json: {
      result: @result,
      direction: @direction,
      order_by: @order_by,
      page: @page,
      per_page: @per_page,
      search: @search,
      total: @total,
      last_page: @last_page,
    }
  end

  # GET /entries/1
  def show
    render json: @entry
  end

  # POST /entries
  def create
    @entry = Entry.new(entry_params)

    if @entry.save
      render json: @entry, status: :created
    else
      render json: @entry.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /entries/1
  def update
    if @entry.update(entry_params)
      render json: @entry
    else
      render json: @entry.errors, status: :unprocessable_entity
    end
  end

  # DELETE /entries/1
  def destroy
    @entry.destroy
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_entry
    @entry = Entry.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def entry_params
    params.require(:entry).permit(:name, :description, :date, :value)
  end
end
