# frozen_string_literal: true

class BookAssistantController < ApplicationController
  before_action :initialize_service

  def index
    @recent_queries = BookQuery.recent.limit(5)
  end

  def query
    @response = @assistant_service.process_query(params[:message])
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.append("messages", partial: "message",
                                                  locals: { message: params[:message], response: @response })
      end
      format.html do
        redirect_to book_assistant_index_path
      end
      format.json { render json: @response }
    end
  end

  private

  def initialize_service
    @assistant_service = BookAssistantService.new
  end
end
