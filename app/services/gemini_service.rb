require 'timeout'

class GeminiService
  include HTTParty
  
  class Error < StandardError; end
  class APIError < Error; end
  class RateLimitError < Error; end
  class AuthenticationError < Error; end

  base_uri 'https://generativelanguage.googleapis.com'
  
  def initialize
    @api_key = ENV['GEMINI_API_KEY']
    raise Error, 'GEMINI_API_KEY 환경 변수가 설정되지 않았습니다.' if @api_key.blank?
  end

  def generate_response(message, user = nil, persona = 'default', context_messages = [])
    # 병원 관리 시스템 컨텍스트를 포함한 프롬프트 구성
    system_prompt = build_system_prompt(user, persona)
    
    # 대화 컨텍스트 구성
    context_prompt = build_context_prompt(context_messages)
    
    full_prompt = "#{system_prompt}\n\n#{context_prompt}\n\n사용자 질문: #{message}"

    response = self.class.post(
      "/v1beta/models/gemini-2.0-flash:generateContent",
      query: { key: @api_key },
      headers: {
        'Content-Type' => 'application/json'
      },
      body: {
        contents: [{
          parts: [{
            text: full_prompt
          }]
        }],
        generationConfig: {
          temperature: 0.5,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048,
        },
        safetySettings: [
          {
            category: "HARM_CATEGORY_HARASSMENT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            category: "HARM_CATEGORY_HATE_SPEECH", 
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            category: "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            category: "HARM_CATEGORY_DANGEROUS_CONTENT",
            threshold: "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      }.to_json,
      timeout: 30
    )

    handle_response(response)
  end

  private

  def build_system_prompt(user, persona = 'default')
    user_info = user ? "현재 사용자: #{user.name} (#{get_role_name(user.role)})" : "현재 사용자: 게스트"
    base_info = get_base_system_info(user_info)
    persona_prompt = get_persona_prompt(persona)
    
    <<~PROMPT
      #{base_info}
      
      #{persona_prompt}
    PROMPT
  end
  
  def get_base_system_info(user_info)
    <<~BASE
      당신은 HSC1 병원 통합 관리 시스템의 AI 어시스턴트입니다.
      
      시스템 정보:
      - 병원 인트라넷 및 관리 시스템
      - 주요 기능: 환자 관리, 예약/접수, 인사/급여, 문서 결재, 공지사항 등
      - #{user_info}
      
      공통 제한사항:
      - 실제 환자 정보나 개인정보는 절대 생성하거나 추측하지 마세요.
      - 의학적 진단이나 치료 조언은 제공하지 마세요.
      - 시스템 보안과 관련된 민감한 정보는 제공하지 마세요.
      - 모든 답변은 한국어로 제공하고, 정중하고 전문적인 톤을 유지하세요.
    BASE
  end
  
  def build_context_prompt(context_messages)
    return "" if context_messages.empty?
    
    context_text = "최근 대화 내역:\n"
    context_messages.each do |msg|
      role = msg.message_type == 'user' ? '사용자' : 'AI'
      context_text += "#{role}: #{msg.content}\n"
    end
    context_text += "\n위 대화 맥락을 참고하여 답변해주세요."
    
    context_text
  end
  
  def get_persona_prompt(persona)
    case persona
    when 'doctor'
      <<~DOCTOR
        당신은 "닥터 김"이라는 페르소나로 활동합니다.
        
        성격과 말투:
        - 친근하면서도 전문적인 의사
        - "환자분들을 위해서라면~", "의학적으로 보면요~" 같은 표현 사용
        - 의료진의 관점에서 조언 제공
        - 따뜻하고 신뢰감 있는 톤
        
        전문 분야:
        - 진료 프로세스 가이드
        - 의학 정보 제공 (일반적인 내용)
        - 환자 상담 방법론
        - 의료진 간 협업 방안
        
        응답 스타일:
        - "안녕하세요, 닥터 김입니다."로 시작
        - 의료진의 경험과 관점을 반영
        - 환자 안전과 의료 품질을 최우선으로 고려
      DOCTOR
    when 'nurse'
      <<~NURSE
        당신은 "간호사 이"라는 페르소나로 활동합니다.
        
        성격과 말투:
        - 따뜻하고 세심한 간호사
        - "걱정하지 마세요~", "제가 도와드릴게요!" 같은 표현 사용
        - 배려심 깊고 친근한 말투
        - 실무적이고 현실적인 조언
        
        전문 분야:
        - 환자 케어 및 간호 업무
        - 일정 관리 및 업무 조율
        - 응급 상황 대처법
        - 간호 체크리스트 및 프로토콜
        
        응답 스타일:
        - "안녕하세요, 간호사 이입니다."로 시작
        - 실용적이고 단계별 가이드 제공
        - 환자와 동료들을 위한 따뜻한 마음 표현
      NURSE
    when 'manager'
      <<~MANAGER
        당신은 "매니저 박"이라는 페르소나로 활동합니다.
        
        성격과 말투:
        - 효율적이고 체계적인 관리자
        - "업무 효율을 위해", "시스템적으로 접근하면" 같은 표현 사용
        - 논리적이고 구조화된 설명
        - 성과와 결과를 중시하는 톤
        
        전문 분야:
        - 업무 관리 및 프로세스 개선
        - 통계 분석 및 성과 측정
        - 시스템 운영 및 최적화
        - 직원 관리 및 조직 운영
        
        응답 스타일:
        - "안녕하세요, 매니저 박입니다."로 시작
        - 데이터와 수치를 활용한 설명
        - 체계적이고 논리적인 해결책 제시
      MANAGER
    when 'tech'
      <<~TECH
        당신은 "테키"라는 페르소나로 활동합니다.
        
        성격과 말투:
        - 똑똑하고 논리적인 IT 전문가
        - "기술적으로는", "데이터를 보면" 같은 표현 사용
        - 정확하고 명확한 설명
        - 문제 해결 중심의 접근
        
        전문 분야:
        - 시스템 사용법 및 기술 지원
        - 문제 진단 및 해결
        - 데이터 분석 및 보고서
        - IT 인프라 및 보안
        
        응답 스타일:
        - "안녕하세요, 테키입니다."로 시작
        - 단계별 기술 가이드 제공
        - 논리적이고 체계적인 문제 해결
      TECH
    else # default
      <<~DEFAULT
        당신은 일반 AI 어시스턴트로 활동합니다.
        
        역할 및 지침:
        1. 병원 업무와 관련된 질문에 대해 전문적이고 도움이 되는 답변을 제공하세요.
        2. 환자 정보나 민감한 의료 데이터에 대한 직접적인 질문에는 보안상의 이유로 답변을 거절하세요.
        3. 시스템 사용법, 업무 프로세스, 일반적인 병원 관리 질문에 대해 친근하게 도움을 주세요.
        4. 답변은 간결하고 실용적이어야 하며, 필요시 단계별 안내를 제공하세요.
        
        응답 스타일:
        - 친근하면서도 전문적인 톤
        - 사용자의 요청에 맞는 적절한 정보 제공
        - 명확하고 이해하기 쉬운 설명
      DEFAULT
    end
  end

  def get_role_name(role)
    case role
    when 0 then "열람 전용"
    when 1 then "직원"  
    when 2 then "관리자"
    when 3 then "시스템 관리자"
    else "사용자"
    end
  end

  def handle_response(response)
    case response.code
    when 200
      parse_successful_response(response)
    when 400
      raise APIError, "잘못된 요청입니다: #{response.body}"
    when 401
      raise AuthenticationError, "API 키가 유효하지 않습니다."
    when 403
      raise AuthenticationError, "API 접근이 거부되었습니다."
    when 429
      raise RateLimitError, "API 호출 한도를 초과했습니다. 잠시 후 다시 시도해주세요."
    when 500..599
      raise APIError, "Gemini API 서버 오류가 발생했습니다."
    else
      raise Error, "예상치 못한 응답입니다: #{response.code}"
    end
  rescue JSON::ParserError => e
    raise Error, "응답 파싱 오류: #{e.message}"
  rescue Timeout::Error, Net::ReadTimeout => e
    raise Error, "API 호출 시간 초과: #{e.message}"
  rescue => e
    raise Error, "알 수 없는 오류: #{e.message}"
  end

  def parse_successful_response(response)
    parsed_response = JSON.parse(response.body)
    
    # Gemini API 응답 구조 확인
    if parsed_response['candidates']&.any? && 
       parsed_response['candidates'][0]['content']&.dig('parts')&.any?
      
      text = parsed_response['candidates'][0]['content']['parts'][0]['text']
      return text.strip if text.present?
    end
    
    # 안전 필터링으로 인한 차단 확인
    if parsed_response['candidates']&.any? && 
       parsed_response['candidates'][0]['finishReason'] == 'SAFETY'
      return "죄송합니다. 안전상의 이유로 해당 질문에 대한 답변을 제공할 수 없습니다."
    end
    
    # 기본 오류 응답
    "죄송합니다. 현재 응답을 생성할 수 없습니다. 잠시 후 다시 시도해주세요."
  end
end