class Api::V1::DocumentsController < ApplicationController
  before_action :authenticate_request
  before_action :set_document, only: [:show, :update, :destroy]
  before_action :check_view_permission, only: [:show]
  before_action :check_edit_permission, only: [:update, :destroy]
  
  def index
    @documents = Document.includes(:author, :approvals).recent
    
    # 필터링
    @documents = @documents.by_author(@current_user) if params[:my_documents] == 'true'
    @documents = @documents.by_status(params[:status]) if params[:status].present?
    @documents = @documents.by_type(params[:document_type]) if params[:document_type].present?
    @documents = @documents.by_department(params[:department]) if params[:department].present?
    
    # 결재 대기 문서 (내가 결재해야 할 문서)
    if params[:pending_approval] == 'true'
      @documents = @documents.joins(:approvals)
                             .where(approvals: { approver: @current_user, status: 'pending' })
    end
    
    render json: {
      status: 'success',
      data: @documents.map do |document|
        {
          id: document.id,
          title: document.title,
          document_type: document.document_type,
          document_type_text: document.document_type_text,
          department: document.department,
          status: document.status,
          status_text: document.status_text,
          status_color: document.status_color,
          security_level: document.security_level,
          security_level_text: document.security_level_text,
          author: document.author.name,
          version: document.version,
          approval_progress: document.approval_progress,
          current_approver: document.current_approver&.name,
          created_at: document.created_at,
          updated_at: document.updated_at
        }
      end
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @document.id,
        title: @document.title,
        content: @document.content,
        document_type: @document.document_type,
        document_type_text: @document.document_type_text,
        department: @document.department,
        status: @document.status,
        status_text: @document.status_text,
        status_color: @document.status_color,
        security_level: @document.security_level,
        security_level_text: @document.security_level_text,
        author: @document.author.name,
        author_id: @document.author.id,
        version: @document.version,
        approval_progress: @document.approval_progress,
        current_approver: @document.current_approver&.name,
        can_edit: @document.can_edit?(@current_user),
        created_at: @document.created_at,
        updated_at: @document.updated_at,
        approvals: @document.approvals.includes(:approver).ordered.map do |approval|
          {
            id: approval.id,
            approver: approval.approver.name,
            approver_id: approval.approver.id,
            status: approval.status,
            status_text: approval.status_text,
            status_color: approval.status_color,
            comments: approval.comments,
            approved_at: approval.approved_at,
            order_index: approval.order_index,
            can_approve: approval.can_approve?(@current_user)
          }
        end
      }
    }
  end

  def create
    @document = Document.new(document_params)
    @document.author = @current_user
    @document.status = 'draft'
    @document.version = 1
    
    if @document.save
      # 결재선이 있으면 결재자 설정
      if params[:approvers].present?
        create_approvals(params[:approvers])
      end
      
      render json: {
        status: 'success',
        message: '문서가 성공적으로 생성되었습니다.',
        data: {
          id: @document.id,
          title: @document.title
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '문서 생성에 실패했습니다.',
        errors: @document.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @document.update(document_params)
      # 결재선 업데이트
      if params[:approvers].present?
        @document.approvals.destroy_all
        create_approvals(params[:approvers])
      end
      
      render json: {
        status: 'success',
        message: '문서가 성공적으로 수정되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '문서 수정에 실패했습니다.',
        errors: @document.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @document.destroy
      render json: {
        status: 'success',
        message: '문서가 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '문서 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end
  
  # 결재 요청
  def request_approval
    @document = Document.find(params[:id])
    
    unless @document.can_edit?(@current_user)
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @document.approvals.empty?
      return render json: {
        status: 'error',
        message: '결재선이 설정되지 않았습니다.'
      }, status: :unprocessable_entity
    end
    
    @document.update(status: 'pending')
    
    render json: {
      status: 'success',
      message: '결재 요청이 완료되었습니다.'
    }
  end

  private

  def set_document
    @document = Document.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '문서를 찾을 수 없습니다.'
    }, status: :not_found
  end

  def check_view_permission
    unless @document.can_view?(@current_user)
      render json: {
        status: 'error',
        message: '문서 열람 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def check_edit_permission
    unless @document.can_edit?(@current_user)
      render json: {
        status: 'error',
        message: '문서 수정 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def document_params
    params.require(:document).permit(:title, :content, :document_type, :department, :security_level)
  end
  
  def create_approvals(approvers_data)
    approvers_data.each_with_index do |approver_data, index|
      user = User.find(approver_data[:user_id])
      @document.approvals.create!(
        approver: user,
        status: 'pending',
        order_index: index,
        comments: ''
      )
    end
  end
end
