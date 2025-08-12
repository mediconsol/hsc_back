class Api::V1::AiController < ApplicationController

  # POST /api/v1/ai/chat
  def chat
    begin
      message = params[:message]
      persona = params[:persona] || 'default'
      session_id = params[:session_id] || generate_session_id
      
      if message.blank?
        render json: { error: '메시지를 입력해주세요.' }, status: :bad_request
        return
      end

      # 사용자 메시지 저장
      user_history = save_conversation_history(
        message_type: 'user',
        content: message,
        persona: persona,
        session_id: session_id
      )

      # 최근 대화 컨텍스트 가져오기
      context_messages = ConversationHistory.recent_context_for_user(
        current_user.id, 
        persona, 
        8 # 최근 8개 메시지
      )

      # Gemini API 서비스 호출 (컨텍스트 포함)
      gemini_service = GeminiService.new
      response = gemini_service.generate_response(
        message, 
        current_user, 
        persona, 
        context_messages
      )

      # AI 응답 저장
      ai_history = save_conversation_history(
        message_type: 'ai',
        content: response,
        persona: persona,
        session_id: session_id
      )

      render json: { 
        response: response,
        session_id: session_id,
        timestamp: Time.current.iso8601,
        context_used: context_messages.any?
      }

    rescue GeminiService::Error => e
      Rails.logger.error "Gemini API Error: #{e.message}"
      render json: { 
        error: 'AI 서비스에 일시적인 문제가 발생했습니다. 잠시 후 다시 시도해주세요.',
        details: e.message
      }, status: :service_unavailable

    rescue StandardError => e
      Rails.logger.error "AI Controller Error: #{e.message}"
      render json: { 
        error: '서버 오류가 발생했습니다.',
        details: e.message
      }, status: :internal_server_error
    end
  end

  private

  def ai_params
    params.permit(:message, :persona, :session_id)
  end
  
  def save_conversation_history(message_type:, content:, persona:, session_id:)
    current_user.conversation_histories.create!(
      message_type: message_type,
      content: content,
      persona: persona,
      session_id: session_id,
      timestamp: Time.current
    )
  end
  
  def generate_session_id
    "session_#{current_user.id}_#{Time.current.to_i}_#{SecureRandom.hex(4)}"
  end
end