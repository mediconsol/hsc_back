class Api::V1::ApprovalsController < ApplicationController
  before_action :authenticate_request
  before_action :set_document
  before_action :set_approval, only: [:approve, :reject]
  before_action :check_approval_permission, only: [:approve, :reject]
  
  # 결재 승인
  def approve
    ActiveRecord::Base.transaction do
      @approval.update!(
        status: 'approved',
        comments: params[:comments] || '',
        approved_at: Time.current
      )
      
      # 다음 결재자가 있는지 확인
      next_approval = @document.approvals
                               .where('order_index > ?', @approval.order_index)
                               .where(status: 'pending')
                               .order(:order_index)
                               .first
      
      # 모든 결재가 완료되면 문서 상태를 승인완료로 변경
      if next_approval.nil?
        @document.update!(status: 'approved')
      end
    end
    
    render json: {
      status: 'success',
      message: '결재가 승인되었습니다.',
      data: {
        document_status: @document.status,
        approval_progress: @document.approval_progress,
        next_approver: @document.current_approver&.name
      }
    }
  end
  
  # 결재 반려
  def reject
    ActiveRecord::Base.transaction do
      @approval.update!(
        status: 'rejected',
        comments: params[:comments] || '반려사유 없음',
        approved_at: Time.current
      )
      
      # 문서 상태를 반려로 변경
      @document.update!(status: 'rejected')
    end
    
    render json: {
      status: 'success',
      message: '결재가 반려되었습니다.',
      data: {
        document_status: @document.status,
        approval_progress: @document.approval_progress
      }
    }
  end
  
  # 결재 취소 (결재 요청자가 결재를 취소)
  def cancel
    unless @document.author == @current_user || @current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    unless @document.status == 'pending'
      return render json: {
        status: 'error',
        message: '결재 대기 상태인 문서만 취소할 수 있습니다.'
      }, status: :unprocessable_entity
    end
    
    ActiveRecord::Base.transaction do
      @document.approvals.where(status: 'pending').update_all(status: 'skipped')
      @document.update!(status: 'cancelled')
    end
    
    render json: {
      status: 'success',
      message: '결재가 취소되었습니다.'
    }
  end
  
  # 결재 회수 (다시 작성중 상태로)
  def recall
    unless @document.author == @current_user || @current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    unless @document.status == 'pending'
      return render json: {
        status: 'error',
        message: '결재 대기 상태인 문서만 회수할 수 있습니다.'
      }, status: :unprocessable_entity
    end
    
    # 아직 결재하지 않은 승인건만 있는지 확인
    if @document.approvals.where.not(status: 'pending').exists?
      return render json: {
        status: 'error',
        message: '이미 결재가 진행된 문서는 회수할 수 없습니다.'
      }, status: :unprocessable_entity
    end
    
    ActiveRecord::Base.transaction do
      @document.approvals.destroy_all
      @document.update!(status: 'draft')
    end
    
    render json: {
      status: 'success',
      message: '결재가 회수되었습니다. 문서를 다시 수정할 수 있습니다.'
    }
  end
  
  # 결재 위임 (결재 권한을 다른 사용자에게 위임)
  def delegate
    unless @approval.can_approve?(@current_user)
      return render json: {
        status: 'error',
        message: '결재 권한이 없습니다.'
      }, status: :forbidden
    end
    
    delegate_user = User.find(params[:delegate_user_id])
    
    @approval.update!(
      approver: delegate_user,
      comments: "#{@current_user.name}님이 #{delegate_user.name}님에게 결재 위임"
    )
    
    render json: {
      status: 'success',
      message: "#{delegate_user.name}님에게 결재가 위임되었습니다."
    }
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '위임받을 사용자를 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  private
  
  def set_document
    @document = Document.find(params[:document_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '문서를 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  def set_approval
    @approval = @document.approvals.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '결재 정보를 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  def check_approval_permission
    unless @approval.can_approve?(@current_user)
      render json: {
        status: 'error',
        message: '결재 권한이 없습니다.'
      }, status: :forbidden
    end
  end
end