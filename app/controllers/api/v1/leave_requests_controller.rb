class Api::V1::LeaveRequestsController < ApplicationController
  before_action :set_leave_request, only: [:show, :update, :destroy, :approve, :reject, :cancel]
  
  def index
    @leave_requests = LeaveRequest.includes(:employee, :approver)
    
    # 직원 필터링
    @leave_requests = @leave_requests.where(employee_id: params[:employee_id]) if params[:employee_id].present?
    
    # 상태 필터링
    @leave_requests = @leave_requests.by_status(params[:status]) if params[:status].present?
    
    # 날짜 범위 필터링
    if params[:start_date].present? && params[:end_date].present?
      @leave_requests = @leave_requests.where(
        "(start_date BETWEEN ? AND ?) OR (end_date BETWEEN ? AND ?) OR (start_date <= ? AND end_date >= ?)",
        params[:start_date], params[:end_date],
        params[:start_date], params[:end_date],
        params[:start_date], params[:end_date]
      )
    elsif params[:year].present?
      year = params[:year].to_i
      @leave_requests = @leave_requests.where(start_date: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
    else
      # 기본값: 현재 연도
      @leave_requests = @leave_requests.current_year
    end
    
    # 승인 대기 우선 정렬
    @leave_requests = @leave_requests.order(:status, :start_date)
    
    render json: {
      status: 'success',
      data: {
        leave_requests: @leave_requests.map { |lr| leave_request_json(lr) },
        summary: calculate_summary(@leave_requests)
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        leave_request: leave_request_json(@leave_request)
      }
    }
  end

  def create
    employee = Employee.find(params[:employee_id])
    @leave_request = employee.leave_requests.build(leave_request_params)
    @leave_request.status = 'pending'
    
    # 연차인 경우 잔여 일수 확인
    if @leave_request.annual_leave?
      remaining_balance = calculate_remaining_balance(employee, @leave_request.days_requested)
      if remaining_balance < 0
        return render_error("잔여 연차가 부족합니다 (잔여: #{employee.annual_leave_balance}일)", :unprocessable_entity)
      end
    end
    
    if @leave_request.save
      # 연차인 경우 잔여 일수 차감
      if @leave_request.annual_leave? && @leave_request.approved?
        employee.update(annual_leave_balance: remaining_balance)
      end
      
      render json: {
        status: 'success',
        message: '휴가 신청이 완료되었습니다.',
        data: {
          leave_request: leave_request_json(@leave_request)
        }
      }
    else
      render_error('휴가 신청에 실패했습니다.', :unprocessable_entity, @leave_request.errors.full_messages)
    end
  end

  def update
    if @leave_request.update(leave_request_params)
      render json: {
        status: 'success',
        message: '휴가 신청이 수정되었습니다.',
        data: {
          leave_request: leave_request_json(@leave_request)
        }
      }
    else
      render_error('휴가 신청 수정에 실패했습니다.', :unprocessable_entity, @leave_request.errors.full_messages)
    end
  end

  def destroy
    if @leave_request.destroy
      render json: {
        status: 'success',
        message: '휴가 신청이 삭제되었습니다.'
      }
    else
      render_error('휴가 신청 삭제에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 휴가 승인
  def approve
    if !@leave_request.pending?
      return render_error('이미 처리된 신청입니다.', :unprocessable_entity)
    end
    
    @leave_request.status = 'approved'
    @leave_request.approver = current_user
    @leave_request.approved_at = Time.current
    
    if @leave_request.save
      # 연차인 경우 잔여 일수 차감
      if @leave_request.annual_leave?
        employee = @leave_request.employee
        new_balance = employee.annual_leave_balance - @leave_request.days_requested
        employee.update(annual_leave_balance: [new_balance, 0].max)
      end
      
      render json: {
        status: 'success',
        message: '휴가 신청이 승인되었습니다.',
        data: {
          leave_request: leave_request_json(@leave_request.reload)
        }
      }
    else
      render_error('휴가 승인에 실패했습니다.', :unprocessable_entity, @leave_request.errors.full_messages)
    end
  end

  # 휴가 반려
  def reject
    if !@leave_request.pending?
      return render_error('이미 처리된 신청입니다.', :unprocessable_entity)
    end
    
    @leave_request.status = 'rejected'
    @leave_request.approver = current_user
    # Note: rejected_at과 rejection_reason 필드는 현재 테이블에 없음
    
    if @leave_request.save
      render json: {
        status: 'success',
        message: '휴가 신청이 반려되었습니다.',
        data: {
          leave_request: leave_request_json(@leave_request)
        }
      }
    else
      render_error('휴가 반려에 실패했습니다.', :unprocessable_entity, @leave_request.errors.full_messages)
    end
  end

  # 휴가 신청 취소
  def cancel
    if !@leave_request.can_cancel?
      return render_error('취소할 수 없는 상태입니다.', :unprocessable_entity)
    end
    
    @leave_request.status = 'cancelled'
    
    if @leave_request.save
      # 이미 승인되어 차감된 연차가 있다면 복구
      if @leave_request.annual_leave? && @leave_request.approved?
        employee = @leave_request.employee
        employee.update(annual_leave_balance: employee.annual_leave_balance + @leave_request.days_requested)
      end
      
      render json: {
        status: 'success',
        message: '휴가 신청이 취소되었습니다.',
        data: {
          leave_request: leave_request_json(@leave_request)
        }
      }
    else
      render_error('휴가 취소에 실패했습니다.', :unprocessable_entity, @leave_request.errors.full_messages)
    end
  end

  # 승인 대기 목록
  def pending_approvals
    @pending_requests = LeaveRequest.includes(:employee)
                                   .pending_approval
                                   .order(:start_date)
    
    render json: {
      status: 'success',
      data: {
        pending_requests: @pending_requests.map { |lr| leave_request_json(lr) },
        count: @pending_requests.count
      }
    }
  end

  # 휴가 통계
  def statistics
    year = params[:year]&.to_i || Date.current.year
    employee_id = params[:employee_id]
    
    leave_requests = LeaveRequest.includes(:employee)
                                .where(start_date: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
    
    leave_requests = leave_requests.where(employee_id: employee_id) if employee_id.present?
    
    stats = {
      year: year,
      total_requests: leave_requests.count,
      approved_requests: leave_requests.approved.count,
      pending_requests: leave_requests.pending.count,
      rejected_requests: leave_requests.rejected.count,
      total_days_requested: leave_requests.approved.sum(:days_requested),
      leave_type_breakdown: calculate_leave_type_stats(leave_requests.approved),
      monthly_breakdown: calculate_monthly_stats(leave_requests.approved, year),
      department_breakdown: calculate_department_stats(leave_requests.approved)
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  # 직원 연차 현황
  def annual_leave_status
    employee_id = params[:employee_id]
    year = params[:year]&.to_i || Date.current.year
    
    if employee_id
      employee = Employee.find(employee_id)
      used_annual_leave = employee.leave_requests
                                 .where(leave_type: 'annual', status: 'approved')
                                 .where(start_date: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
                                 .sum(:days_requested)
      
      render json: {
        status: 'success',
        data: {
          employee_id: employee.id,
          employee_name: employee.name,
          total_annual_leave: employee.annual_leave_balance + used_annual_leave,
          used_annual_leave: used_annual_leave,
          remaining_annual_leave: employee.annual_leave_balance,
          year: year
        }
      }
    else
      # 전체 직원 연차 현황
      employees = Employee.all
      annual_leave_data = employees.map do |emp|
        used_days = emp.leave_requests
                       .where(leave_type: 'annual', status: 'approved')
                       .where(start_date: Date.new(year).beginning_of_year..Date.new(year).end_of_year)
                       .sum(:days_requested)
        
        {
          employee_id: emp.id,
          employee_name: emp.name,
          department: emp.department,
          total_annual_leave: emp.annual_leave_balance + used_days,
          used_annual_leave: used_days,
          remaining_annual_leave: emp.annual_leave_balance
        }
      end
      
      render json: {
        status: 'success',
        data: {
          year: year,
          employees: annual_leave_data,
          summary: {
            total_employees: employees.count,
            total_annual_leave: annual_leave_data.sum { |emp| emp[:total_annual_leave] },
            total_used: annual_leave_data.sum { |emp| emp[:used_annual_leave] },
            total_remaining: annual_leave_data.sum { |emp| emp[:remaining_annual_leave] }
          }
        }
      }
    end
  end

  private

  def set_leave_request
    @leave_request = LeaveRequest.find(params[:id])
  end

  def leave_request_params
    params.require(:leave_request).permit(
      :leave_type, :start_date, :end_date, :days_requested, 
      :reason
    )
  end

  def leave_request_json(leave_request)
    {
      id: leave_request.id,
      employee_id: leave_request.employee_id,
      employee_name: leave_request.employee.name,
      employee_department: leave_request.employee.department,
      leave_type: leave_request.leave_type,
      leave_type_text: leave_request.leave_type_text,
      start_date: leave_request.start_date,
      end_date: leave_request.end_date,
      days_requested: leave_request.days_requested,
      reason: leave_request.reason,
      status: leave_request.status,
      status_text: leave_request.status_text,
      status_color: leave_request.status_color,
      approver_name: leave_request.approver&.name,
      approved_at: leave_request.approved_at,
      # rejected_at, rejection_reason, emergency_contact, replacement_employee 필드는 현재 테이블에 없음
      can_cancel: leave_request.can_cancel?,
      created_at: leave_request.created_at,
      updated_at: leave_request.updated_at
    }
  end

  def calculate_summary(leave_requests)
    {
      total_count: leave_requests.count,
      pending_count: leave_requests.where(status: 'pending').count,
      approved_count: leave_requests.where(status: 'approved').count,
      rejected_count: leave_requests.where(status: 'rejected').count,
      cancelled_count: leave_requests.where(status: 'cancelled').count,
      total_days: leave_requests.where(status: 'approved').sum(:days_requested)
    }
  end

  def calculate_remaining_balance(employee, days_requested)
    employee.annual_leave_balance - days_requested
  end

  def calculate_leave_type_stats(leave_requests)
    LeaveRequest.leave_types.keys.map do |type|
      requests = leave_requests.where(leave_type: type)
      {
        leave_type: type,
        leave_type_text: LeaveRequest.new(leave_type: type).leave_type_text,
        count: requests.count,
        total_days: requests.sum(:days_requested)
      }
    end.select { |stat| stat[:count] > 0 }
  end

  def calculate_monthly_stats(leave_requests, year)
    (1..12).map do |month|
      month_requests = leave_requests.where(
        start_date: Date.new(year, month).beginning_of_month..Date.new(year, month).end_of_month
      )
      {
        month: month,
        month_name: Date::MONTHNAMES[month],
        count: month_requests.count,
        total_days: month_requests.sum(:days_requested)
      }
    end
  end

  def calculate_department_stats(leave_requests)
    Employee.distinct.pluck(:department).map do |dept|
      dept_requests = leave_requests.joins(:employee).where(employees: { department: dept })
      {
        department: dept,
        count: dept_requests.count,
        total_days: dept_requests.sum(:days_requested)
      }
    end.select { |stat| stat[:count] > 0 }
  end
end