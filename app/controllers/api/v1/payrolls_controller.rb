class Api::V1::PayrollsController < ApplicationController
  before_action :set_payroll, only: [:show]
  
  def index
    @payrolls = Payroll.includes(:employee)
    
    # 급여 기간 필터링
    if params[:year].present? && params[:month].present?
      year = params[:year].to_i
      month = params[:month].to_i
      start_date = Date.new(year, month, 1)
      end_date = start_date.end_of_month
      @payrolls = @payrolls.where(pay_period_start: start_date..end_date)
    end
    
    # 직원별 필터링
    @payrolls = @payrolls.where(employee_id: params[:employee_id]) if params[:employee_id].present?
    
    # 상태별 필터링
    @payrolls = @payrolls.where(status: params[:status]) if params[:status].present?
    
    @payrolls = @payrolls.order('pay_period_start DESC, employees.name')
    
    render json: {
      status: 'success',
      data: {
        payrolls: @payrolls.map { |payroll| payroll_json(payroll) },
        summary: calculate_summary(@payrolls)
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        payroll: payroll_json(@payroll)
      }
    }
  end

  # 월별 급여 현황 (상세)
  def monthly_summary
    year = params[:year]&.to_i || Date.current.year
    month = params[:month]&.to_i
    
    if !month
      return render_error('월 정보가 필요합니다.', :bad_request)
    end
    
    start_date = Date.new(year, month, 1)
    end_date = start_date.end_of_month
    
    payrolls = Payroll.includes(:employee)
                     .where(pay_period_start: start_date..end_date)
                     .order('employees.department, employees.name')
    
    department_summary = calculate_department_summary(payrolls)
    
    render json: {
      status: 'success',
      data: {
        year: year,
        month: month,
        month_name: "#{year}년 #{month}월",
        payrolls: payrolls.map { |payroll| payroll_detailed_json(payroll) },
        department_summary: department_summary,
        total: {
          employee_count: payrolls.count,
          total_base_pay: payrolls.sum(:base_pay),
          total_overtime_pay: payrolls.sum(:overtime_pay),
          total_night_pay: payrolls.sum(:night_pay),
          total_allowances: payrolls.sum(:allowances),
          total_deductions: payrolls.sum(:deductions),
          total_tax: payrolls.sum(:tax),
          total_net_pay: payrolls.sum(:net_pay)
        }
      }
    }
  end

  private

  def set_payroll
    @payroll = Payroll.find(params[:id])
  end

  def payroll_params
    params.require(:payroll).permit(
      :employee_id, :pay_period_start, :pay_period_end, :base_pay, 
      :overtime_pay, :night_pay, :allowances, :deductions, :tax, :net_pay, :status
    )
  end

  def payroll_json(payroll)
    {
      id: payroll.id,
      employee_id: payroll.employee_id,
      employee_name: payroll.employee.name,
      employee_department: payroll.employee.department,
      employee_position: payroll.employee.position,
      pay_period_start: payroll.pay_period_start,
      pay_period_end: payroll.pay_period_end,
      base_pay: payroll.base_pay || 0,
      overtime_pay: payroll.overtime_pay || 0,
      night_pay: payroll.night_pay || 0,
      allowances: payroll.allowances || 0,
      deductions: payroll.deductions || 0,
      tax: payroll.tax || 0,
      net_pay: payroll.net_pay || 0,
      status: payroll.status,
      created_at: payroll.created_at,
      updated_at: payroll.updated_at
    }
  end

  def payroll_detailed_json(payroll)
    base_json = payroll_json(payroll)
    
    # 급여 세부 계산
    gross_pay = (payroll.base_pay || 0) + 
                (payroll.overtime_pay || 0) + 
                (payroll.night_pay || 0) + 
                (payroll.allowances || 0)
    
    total_deductions = (payroll.deductions || 0) + (payroll.tax || 0)
    
    base_json.merge({
      salary_breakdown: {
        base_pay: payroll.base_pay || 0,
        overtime_pay: payroll.overtime_pay || 0,
        night_pay: payroll.night_pay || 0,
        allowances: payroll.allowances || 0,
        gross_pay: gross_pay,
        deductions: payroll.deductions || 0,
        tax: payroll.tax || 0,
        total_deductions: total_deductions,
        net_pay: payroll.net_pay || 0
      }
    })
  end

  def calculate_summary(payrolls)
    {
      total_count: payrolls.count,
      total_base_pay: payrolls.sum(:base_pay),
      total_overtime_pay: payrolls.sum(:overtime_pay),
      total_night_pay: payrolls.sum(:night_pay),
      total_allowances: payrolls.sum(:allowances),
      total_deductions: payrolls.sum(:deductions),
      total_tax: payrolls.sum(:tax),
      total_net_pay: payrolls.sum(:net_pay)
    }
  end

  def calculate_department_summary(payrolls)
    departments = {}
    
    payrolls.each do |payroll|
      dept = payroll.employee.department
      departments[dept] ||= {
        department: dept,
        employee_count: 0,
        total_base_pay: 0,
        total_overtime_pay: 0,
        total_night_pay: 0,
        total_allowances: 0,
        total_deductions: 0,
        total_tax: 0,
        total_net_pay: 0
      }
      
      departments[dept][:employee_count] += 1
      departments[dept][:total_base_pay] += payroll.base_pay || 0
      departments[dept][:total_overtime_pay] += payroll.overtime_pay || 0
      departments[dept][:total_night_pay] += payroll.night_pay || 0
      departments[dept][:total_allowances] += payroll.allowances || 0
      departments[dept][:total_deductions] += payroll.deductions || 0
      departments[dept][:total_tax] += payroll.tax || 0
      departments[dept][:total_net_pay] += payroll.net_pay || 0
    end
    
    departments.values.map do |dept_data|
      dept_data[:average_net_pay] = dept_data[:employee_count] > 0 ? 
        (dept_data[:total_net_pay].to_f / dept_data[:employee_count]).round : 0
      dept_data
    end
  end
end