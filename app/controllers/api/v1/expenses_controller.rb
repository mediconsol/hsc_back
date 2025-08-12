class Api::V1::ExpensesController < ApplicationController
  before_action :authenticate_request
  before_action :set_expense, only: [:show, :update, :destroy, :approve, :reject]
  before_action :check_expense_permissions, only: [:show, :update, :destroy]

  def index
    expenses = Expense.includes(:requester, :approver, :budget)
    
    # 권한 기반 필터링
    unless current_user.admin?
      # 본인이 요청한 지출 또는 본인이 승인할 수 있는 지출
      expenses = expenses.where(requester: current_user)
        .or(expenses.where(status: :pending).where.not(requester: current_user))
      
      # 같은 부서 관리자는 해당 부서 지출 조회 가능
      if current_user.manager? && current_user.respond_to?(:department)
        expenses = expenses.or(expenses.where(department: current_user.department))
      end
    end
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      expenses = expenses.left_joins(:requester, :approver).where(
        "expenses.title ILIKE ? OR expenses.description ILIKE ? OR expenses.vendor ILIKE ? OR 
         expenses.receipt_number ILIKE ? OR users.name ILIKE ? OR approvers_expenses.name ILIKE ?",
        search_term, search_term, search_term, search_term, search_term, search_term
      )
    end
    
    # 필터링
    expenses = expenses.by_department(params[:department]) if params[:department].present?
    expenses = expenses.by_category(params[:category]) if params[:category].present?
    expenses = expenses.by_status(params[:status]) if params[:status].present?
    expenses = expenses.by_requester(params[:requester_id]) if params[:requester_id].present?
    
    # 날짜 범위 필터링
    if params[:start_date].present? && params[:end_date].present?
      expenses = expenses.by_date_range(params[:start_date], params[:end_date])
    elsif params[:period] == 'current_month'
      expenses = expenses.current_month
    end
    
    # 정렬
    expenses = expenses.recent
    
    expense_data = expenses.map do |expense|
      {
        id: expense.id,
        title: expense.title,
        description: expense.description,
        amount: expense.amount,
        formatted_amount: expense.formatted_amount,
        expense_date: expense.expense_date,
        category: expense.category,
        category_text: expense.category_text,
        department: expense.department,
        department_text: expense.department_text,
        vendor: expense.vendor,
        payment_method: expense.payment_method,
        payment_method_text: expense.payment_method_text,
        receipt_number: expense.receipt_number,
        status: expense.status,
        status_text: expense.status_text,
        status_color: expense.status_color,
        requester: {
          id: expense.requester.id,
          name: expense.requester.name,
          email: expense.requester.email
        },
        approver: expense.approver ? {
          id: expense.approver.id,
          name: expense.approver.name,
          email: expense.approver.email
        } : nil,
        budget: expense.budget ? {
          id: expense.budget.id,
          department_text: expense.budget.department_text,
          category_text: expense.budget.category_text,
          fiscal_year: expense.budget.fiscal_year
        } : nil,
        is_urgent: expense.is_urgent?,
        days_since_request: expense.days_since_request,
        can_approve: expense.can_approve?(current_user),
        can_edit: expense.can_edit?(current_user),
        created_at: expense.created_at,
        updated_at: expense.updated_at
      }
    end
    
    render json: {
      status: 'success',
      data: expense_data,
      meta: {
        total: expenses.count,
        pending_approval: expenses.pending_approval.count,
        current_month_total: expenses.current_month.count
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @expense.id,
        title: @expense.title,
        description: @expense.description,
        amount: @expense.amount,
        formatted_amount: @expense.formatted_amount,
        expense_date: @expense.expense_date,
        category: @expense.category,
        category_text: @expense.category_text,
        department: @expense.department,
        department_text: @expense.department_text,
        vendor: @expense.vendor,
        payment_method: @expense.payment_method,
        payment_method_text: @expense.payment_method_text,
        receipt_number: @expense.receipt_number,
        status: @expense.status,
        status_text: @expense.status_text,
        status_color: @expense.status_color,
        requester: {
          id: @expense.requester.id,
          name: @expense.requester.name,
          email: @expense.requester.email,
          department: @expense.requester.respond_to?(:department) ? @expense.requester.department : nil
        },
        approver: @expense.approver ? {
          id: @expense.approver.id,
          name: @expense.approver.name,
          email: @expense.approver.email,
          department: @expense.approver.respond_to?(:department) ? @expense.approver.department : nil
        } : nil,
        budget: @expense.budget ? {
          id: @expense.budget.id,
          department: @expense.budget.department,
          department_text: @expense.budget.department_text,
          category: @expense.budget.category,
          category_text: @expense.budget.category_text,
          fiscal_year: @expense.budget.fiscal_year,
          allocated_amount: @expense.budget.allocated_amount,
          used_amount: @expense.budget.used_amount,
          remaining_amount: @expense.budget.remaining_amount,
          usage_percentage: @expense.budget.usage_percentage
        } : nil,
        notes: @expense.notes,
        is_urgent: @expense.is_urgent?,
        days_since_request: @expense.days_since_request,
        can_approve: @expense.can_approve?(current_user),
        can_edit: @expense.can_edit?(current_user),
        created_at: @expense.created_at,
        updated_at: @expense.updated_at
      }
    }
  end

  def create
    expense = Expense.new(expense_params)
    expense.requester = current_user
    
    # 예산 자동 매핑
    if expense.department && expense.category
      budget = Budget.active
                    .where(department: expense.department, category: expense.category)
                    .where(fiscal_year: Date.current.year)
                    .first
      expense.budget = budget if budget
    end
    
    if expense.save
      render json: {
        status: 'success',
        message: '지출 요청이 성공적으로 생성되었습니다.',
        data: {
          id: expense.id,
          title: expense.title,
          amount: expense.amount,
          formatted_amount: expense.formatted_amount,
          expense_date: expense.expense_date,
          status_text: expense.status_text
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '지출 요청 생성에 실패했습니다.',
        errors: expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @expense.update(expense_params)
      render json: {
        status: 'success',
        message: '지출 정보가 성공적으로 수정되었습니다.',
        data: {
          id: @expense.id,
          title: @expense.title,
          amount: @expense.amount,
          formatted_amount: @expense.formatted_amount,
          status_text: @expense.status_text
        }
      }
    else
      render json: {
        status: 'error',
        message: '지출 정보 수정에 실패했습니다.',
        errors: @expense.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    title = @expense.title
    
    if @expense.destroy
      render json: {
        status: 'success',
        message: "지출 요청 '#{title}'이 삭제되었습니다."
      }
    else
      render json: {
        status: 'error',
        message: '지출 요청 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def approve
    unless @expense.can_approve?(current_user)
      render json: {
        status: 'error',
        message: '해당 지출을 승인할 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    if @expense.approve!(current_user)
      render json: {
        status: 'success',
        message: '지출이 승인되었습니다.',
        data: {
          id: @expense.id,
          title: @expense.title,
          status_text: @expense.status_text,
          approver_name: current_user.name
        }
      }
    else
      render json: {
        status: 'error',
        message: '지출 승인에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def reject
    unless @expense.can_approve?(current_user)
      render json: {
        status: 'error',
        message: '해당 지출을 반려할 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    reason = params[:reason]
    
    if @expense.reject!(current_user, reason)
      render json: {
        status: 'success',
        message: '지출이 반려되었습니다.',
        data: {
          id: @expense.id,
          title: @expense.title,
          status_text: @expense.status_text,
          approver_name: current_user.name,
          reason: reason
        }
      }
    else
      render json: {
        status: 'error',
        message: '지출 반려에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def mark_as_paid
    unless @expense.can_edit?(current_user) || current_user.admin?
      render json: {
        status: 'error',
        message: '지급 처리 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    if @expense.mark_as_paid!
      render json: {
        status: 'success',
        message: '지출이 지급 완료 처리되었습니다.',
        data: {
          id: @expense.id,
          title: @expense.title,
          status_text: @expense.status_text
        }
      }
    else
      render json: {
        status: 'error',
        message: '지급 처리에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def statistics
    # 기본 통계
    stats = {
      total_expenses: Expense.count,
      pending_approval: Expense.pending_approval.count,
      approved_this_month: Expense.current_month.approved.count,
      total_amount_this_month: Expense.current_month.approved.sum(:amount)
    }
    
    # 상태별 통계
    stats[:by_status] = Expense.group(:status).count.transform_keys do |key|
      expense = Expense.new(status: key)
      { key: key, text: expense.status_text }
    end
    
    # 부서별 통계
    stats[:by_department] = Expense.approved.group(:department).sum(:amount).map do |dept, amount|
      expense = Expense.new(department: dept)
      {
        department: dept,
        department_text: expense.department_text,
        total_amount: amount,
        count: Expense.approved.where(department: dept).count
      }
    end
    
    # 카테고리별 통계
    stats[:by_category] = Expense.approved.group(:category).sum(:amount).map do |category, amount|
      expense = Expense.new(category: category)
      {
        category: category,
        category_text: expense.category_text,
        total_amount: amount,
        count: Expense.approved.where(category: category).count
      }
    end
    
    # 긴급 처리 필요한 지출
    stats[:urgent_expenses] = Expense.pending_approval.select(&:is_urgent?).count
    
    # 월별 지출 추이 (최근 12개월)
    stats[:monthly_trend] = (0..11).map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime('%Y-%m'),
        month_text: month.strftime('%Y년 %m월'),
        total_amount: Expense.where(
          expense_date: month.beginning_of_month..month.end_of_month,
          status: [:approved, :paid]
        ).sum(:amount),
        count: Expense.where(
          expense_date: month.beginning_of_month..month.end_of_month,
          status: [:approved, :paid]
        ).count
      }
    end.reverse
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  private

  def set_expense
    @expense = Expense.find(params[:id])
  end

  def check_expense_permissions
    unless @expense.can_view?(current_user)
      render json: {
        status: 'error',
        message: '해당 지출을 조회할 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def expense_params
    params.require(:expense).permit(
      :title, :description, :amount, :expense_date, :category,
      :department, :vendor, :payment_method, :receipt_number,
      :budget_id, :notes
    )
  end
end