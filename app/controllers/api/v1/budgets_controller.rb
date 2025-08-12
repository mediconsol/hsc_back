class Api::V1::BudgetsController < ApplicationController
  before_action :authenticate_request
  before_action :set_budget, only: [:show, :update, :destroy]
  before_action :check_budget_permissions, only: [:show, :update, :destroy]

  def index
    budgets = Budget.includes(:manager)
    
    # 권한 기반 필터링
    unless current_user.admin?
      budgets = budgets.where(manager: current_user)
      # 같은 부서 예산도 조회 가능
      if current_user.respond_to?(:department)
        budgets = budgets.or(Budget.where(department: current_user.department))
      end
    end
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      budgets = budgets.where(
        "department ILIKE ? OR category ILIKE ? OR description ILIKE ?",
        search_term, search_term, search_term
      )
    end
    
    # 필터링
    budgets = budgets.by_department(params[:department]) if params[:department].present?
    budgets = budgets.by_category(params[:category]) if params[:category].present?
    budgets = budgets.by_fiscal_year(params[:fiscal_year]) if params[:fiscal_year].present?
    budgets = budgets.by_status(params[:status]) if params[:status].present?
    
    # 정렬
    budgets = budgets.recent
    
    budget_data = budgets.map do |budget|
      {
        id: budget.id,
        department: budget.department,
        department_text: budget.department_text,
        category: budget.category,
        category_text: budget.category_text,
        fiscal_year: budget.fiscal_year,
        period_type: budget.period_type,
        period_type_text: budget.period_type_text,
        allocated_amount: budget.allocated_amount,
        used_amount: budget.used_amount,
        remaining_amount: budget.remaining_amount,
        usage_percentage: budget.usage_percentage,
        status: budget.status,
        status_text: budget.status_text,
        status_color: budget.status_color,
        manager: {
          id: budget.manager.id,
          name: budget.manager.name,
          email: budget.manager.email
        },
        description: budget.description,
        is_over_budget: budget.is_over_budget?,
        is_nearly_exhausted: budget.is_nearly_exhausted?,
        can_edit: budget.can_edit?(current_user),
        created_at: budget.created_at,
        updated_at: budget.updated_at
      }
    end
    
    render json: {
      status: 'success',
      data: budget_data,
      meta: {
        total: budgets.count,
        current_year_total: Budget.current_year.count,
        active_budgets: Budget.by_status(:active).count
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @budget.id,
        department: @budget.department,
        department_text: @budget.department_text,
        category: @budget.category,
        category_text: @budget.category_text,
        fiscal_year: @budget.fiscal_year,
        period_type: @budget.period_type,
        period_type_text: @budget.period_type_text,
        allocated_amount: @budget.allocated_amount,
        used_amount: @budget.used_amount,
        remaining_amount: @budget.remaining_amount,
        usage_percentage: @budget.usage_percentage,
        status: @budget.status,
        status_text: @budget.status_text,
        status_color: @budget.status_color,
        manager: {
          id: @budget.manager.id,
          name: @budget.manager.name,
          email: @budget.manager.email,
          department: @budget.manager.respond_to?(:department) ? @budget.manager.department : nil
        },
        description: @budget.description,
        is_over_budget: @budget.is_over_budget?,
        is_nearly_exhausted: @budget.is_nearly_exhausted?,
        can_edit: @budget.can_edit?(current_user),
        expenses_count: @budget.expenses.count,
        recent_expenses: @budget.expenses.recent.limit(5).map do |expense|
          {
            id: expense.id,
            title: expense.title,
            amount: expense.amount,
            expense_date: expense.expense_date,
            status: expense.status,
            status_text: expense.status_text
          }
        end,
        created_at: @budget.created_at,
        updated_at: @budget.updated_at
      }
    }
  end

  def create
    budget = Budget.new(budget_params)
    budget.manager = current_user
    
    if budget.save
      render json: {
        status: 'success',
        message: '예산이 성공적으로 생성되었습니다.',
        data: {
          id: budget.id,
          department_text: budget.department_text,
          category_text: budget.category_text,
          fiscal_year: budget.fiscal_year,
          allocated_amount: budget.allocated_amount,
          status_text: budget.status_text
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '예산 생성에 실패했습니다.',
        errors: budget.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @budget.update(budget_params)
      render json: {
        status: 'success',
        message: '예산 정보가 성공적으로 수정되었습니다.',
        data: {
          id: @budget.id,
          department_text: @budget.department_text,
          category_text: @budget.category_text,
          fiscal_year: @budget.fiscal_year,
          allocated_amount: @budget.allocated_amount,
          status_text: @budget.status_text
        }
      }
    else
      render json: {
        status: 'error',
        message: '예산 정보 수정에 실패했습니다.',
        errors: @budget.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    # 연관된 지출이 있는지 확인
    if @budget.expenses.any?
      render json: {
        status: 'error',
        message: '연관된 지출 내역이 있어 예산을 삭제할 수 없습니다.'
      }, status: :unprocessable_entity
      return
    end
    
    department_text = @budget.department_text
    category_text = @budget.category_text
    
    if @budget.destroy
      render json: {
        status: 'success',
        message: "#{department_text} - #{category_text} 예산이 삭제되었습니다."
      }
    else
      render json: {
        status: 'error',
        message: '예산 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def statistics
    # 기본 통계
    stats = {
      total_budgets: Budget.count,
      active_budgets: Budget.by_status(:active).count,
      current_year_budgets: Budget.current_year.count,
      total_allocated: Budget.by_status(:active).sum(:allocated_amount),
      total_used: Budget.by_status(:active).sum(:used_amount)
    }
    
    # 부서별 통계
    stats[:by_department] = Budget.group(:department).group(:status).sum(:allocated_amount).map do |(dept, status), amount|
      budget = Budget.new(department: dept, status: status)
      {
        department: dept,
        department_text: budget.department_text,
        status: status,
        status_text: budget.status_text,
        allocated_amount: amount
      }
    end
    
    # 카테고리별 통계  
    stats[:by_category] = Budget.group(:category).sum(:allocated_amount).map do |category, amount|
      budget = Budget.new(category: category)
      {
        category: category,
        category_text: budget.category_text,
        allocated_amount: amount,
        used_amount: Budget.where(category: category).sum(:used_amount)
      }
    end
    
    # 예산 초과 및 거의 소진된 예산
    stats[:over_budget] = Budget.active.select(&:is_over_budget?).count
    stats[:nearly_exhausted] = Budget.active.select(&:is_nearly_exhausted?).count
    
    # 월별 사용 추이 (최근 12개월)
    stats[:monthly_usage] = (0..11).map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime('%Y-%m'),
        month_text: month.strftime('%Y년 %m월'),
        total_expenses: Expense.where(
          expense_date: month.beginning_of_month..month.end_of_month,
          status: [:approved, :paid]
        ).sum(:amount)
      }
    end.reverse
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  def departments
    departments = [
      { value: 'medical', text: '의료진' },
      { value: 'nursing', text: '간호부' },
      { value: 'administration', text: '행정부' },
      { value: 'it', text: 'IT부서' },
      { value: 'facility', text: '시설관리' },
      { value: 'finance', text: '재무부' },
      { value: 'hr', text: '인사부' },
      { value: 'pharmacy', text: '약제부' },
      { value: 'laboratory', text: '검사실' },
      { value: 'radiology', text: '영상의학과' }
    ]
    
    render json: {
      status: 'success',
      data: departments
    }
  end

  def categories
    categories = [
      { value: 'personnel', text: '인건비' },
      { value: 'medical_equipment', text: '의료장비' },
      { value: 'it_equipment', text: 'IT장비' },
      { value: 'facility_management', text: '시설관리' },
      { value: 'supplies', text: '소모품' },
      { value: 'education', text: '교육훈련' },
      { value: 'research', text: '연구개발' },
      { value: 'maintenance', text: '유지보수' },
      { value: 'utilities', text: '공과금' },
      { value: 'marketing', text: '마케팅' },
      { value: 'other', text: '기타' }
    ]
    
    render json: {
      status: 'success',
      data: categories
    }
  end

  private

  def set_budget
    @budget = Budget.find(params[:id])
  end

  def check_budget_permissions
    unless @budget.can_view?(current_user)
      render json: {
        status: 'error',
        message: '해당 예산을 조회할 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def budget_params
    params.require(:budget).permit(
      :department, :category, :fiscal_year, :period_type,
      :allocated_amount, :status, :description
    )
  end
end