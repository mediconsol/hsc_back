class Api::V1::ConversationHistoriesController < ApplicationController
  before_action :set_conversation_history, only: [:show, :destroy]
  
  # GET /api/v1/conversation_histories
  # 사용자별 대화 기록 목록 조회 (페이지네이션 포함)
  def index
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 50
    persona = params[:persona]
    
    histories = current_user.conversation_histories.recent
    histories = histories.by_persona(persona) if persona.present?
    
    total_count = histories.count
    histories = histories.offset((page - 1) * per_page).limit(per_page)
    
    render json: {
      status: 'success',
      data: histories.map(&method(:format_conversation_history)),
      pagination: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil
      }
    }
  end

  # GET /api/v1/conversation_histories/:id
  # 특정 대화 기록 조회
  def show
    render json: {
      status: 'success',
      data: format_conversation_history(@conversation_history)
    }
  end

  # POST /api/v1/conversation_histories
  # 대화 기록 저장
  def create
    conversation_history = current_user.conversation_histories.build(conversation_history_params)
    conversation_history.timestamp = Time.current
    
    if conversation_history.save
      render json: {
        status: 'success',
        data: format_conversation_history(conversation_history)
      }, status: :created
    else
      render json: {
        status: 'error',
        message: 'Failed to save conversation history',
        errors: conversation_history.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/conversation_histories/:id
  # 대화 기록 삭제
  def destroy
    if @conversation_history.destroy
      render json: {
        status: 'success',
        message: 'Conversation history deleted successfully'
      }
    else
      render json: {
        status: 'error',
        message: 'Failed to delete conversation history'
      }, status: :unprocessable_entity
    end
  end
  
  # GET /api/v1/conversation_histories/recent_context
  # 컨텍스트용 최근 대화 기록 조회
  def recent_context
    persona = params[:persona] || 'default'
    limit = params[:limit]&.to_i || 10
    
    context_messages = ConversationHistory.recent_context_for_user(
      current_user.id, 
      persona, 
      limit
    )
    
    render json: {
      status: 'success',
      data: context_messages.map(&method(:format_conversation_history))
    }
  end
  
  # GET /api/v1/conversation_histories/session_messages
  # 세션별 대화 기록 조회
  def session_messages
    session_id = params[:session_id]
    
    if session_id.blank?
      return render json: {
        status: 'error',
        message: 'Session ID is required'
      }, status: :bad_request
    end
    
    messages = ConversationHistory.session_messages(session_id)
    
    render json: {
      status: 'success',
      data: messages.map(&method(:format_conversation_history))
    }
  end
  
  # GET /api/v1/conversation_histories/stats
  # 사용자별 대화 통계
  def stats
    user_stats = ConversationHistory.user_stats(current_user.id)
    
    render json: {
      status: 'success',
      data: {
        total_conversations: current_user.conversation_histories.count,
        persona_breakdown: user_stats,
        recent_activity: {
          today: current_user.conversation_histories.where(
            timestamp: Date.current.beginning_of_day..Date.current.end_of_day
          ).count,
          this_week: current_user.conversation_histories.where(
            timestamp: 1.week.ago..Time.current
          ).count,
          this_month: current_user.conversation_histories.where(
            timestamp: 1.month.ago..Time.current
          ).count
        }
      }
    }
  end

  private

  def set_conversation_history
    @conversation_history = current_user.conversation_histories.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: 'Conversation history not found'
    }, status: :not_found
  end

  def conversation_history_params
    params.require(:conversation_history).permit(
      :persona, :message_type, :content, :session_id
    )
  end
  
  def format_conversation_history(history)
    {
      id: history.id,
      persona: history.persona,
      message_type: history.message_type,
      content: history.content,
      timestamp: history.timestamp.iso8601,
      session_id: history.session_id,
      created_at: history.created_at.iso8601
    }
  end
end
