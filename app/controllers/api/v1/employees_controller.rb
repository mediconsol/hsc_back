class Api::V1::EmployeesController < ApplicationController
  # 인증 필요 (보안)
  # skip_before_action :authenticate_request, only: [:index, :show]
  before_action :set_employee, only: [:show, :update, :destroy]
  
  def index
    # N+1 쿼리 방지를 위한 includes
    @employees = Employee.includes(:attendances, :leave_requests, :payrolls)
    
    # 필터링
    @employees = @employees.where(department: params[:department]) if params[:department].present?
    @employees = @employees.where(status: params[:status]) if params[:status].present?
    @employees = @employees.where(employment_type: params[:employment_type]) if params[:employment_type].present?
    
    # 검색
    if params[:search].present?
      @employees = @employees.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    
    @employees = @employees.order(:name)
    
    render json: {
      employees: @employees.map do |employee|
        {
          id: employee.id,
          name: employee.name,
          department: employee.department,
          position: employee.position,
          employment_type: employee.employment_type,
          employment_type_text: employee.employment_type_text,
          hire_date: employee.hire_date,
          phone: employee.phone,
          email: employee.email,
          status: employee.status,
          status_text: employee.status_text,
          years_of_service: employee.years_of_service,
          base_salary: employee.base_salary,
          hourly_rate: employee.hourly_rate,
          salary_type: employee.salary_type,
          salary_type_text: employee.salary_type_text,
          annual_leave_balance: employee.annual_leave_balance,
          created_at: employee.created_at,
          updated_at: employee.updated_at
        }
      end,
      total: @employees.count
    }
  end

  def show
    render json: {
      employee: {
        id: @employee.id,
        name: @employee.name,
        department: @employee.department,
        position: @employee.position,
        employment_type: @employee.employment_type,
        employment_type_text: @employee.employment_type_text,
        hire_date: @employee.hire_date,
        phone: @employee.phone,
        email: @employee.email,
        status: @employee.status,
        status_text: @employee.status_text,
        years_of_service: @employee.years_of_service,
        base_salary: @employee.base_salary,
        hourly_rate: @employee.hourly_rate,
        salary_type: @employee.salary_type,
        salary_type_text: @employee.salary_type_text,
        annual_leave_balance: @employee.annual_leave_balance,
        created_at: @employee.created_at,
        updated_at: @employee.updated_at
      }
    }
  end

  def create
    @employee = Employee.new(employee_params)
    @employee.status = 'active' # 기본값 설정
    
    if @employee.save
      employee_data = {
        id: @employee.id,
        name: @employee.name,
        department: @employee.department,
        position: @employee.position,
        employment_type_text: @employee.employment_type_text,
        status_text: @employee.status_text
      }
      render_success(employee_data, '직원이 성공적으로 등록되었습니다.')
    else
      render_error('직원 등록에 실패했습니다.', :unprocessable_entity, @employee.errors.full_messages)
    end
  end

  def update
    if @employee.update(employee_params)
      employee_data = {
        id: @employee.id,
        name: @employee.name,
        department: @employee.department,
        position: @employee.position,
        employment_type_text: @employee.employment_type_text,
        status_text: @employee.status_text
      }
      render_success(employee_data, '직원 정보가 성공적으로 수정되었습니다.')
    else
      render_error('직원 정보 수정에 실패했습니다.', :unprocessable_entity, @employee.errors.full_messages)
    end
  end

  def destroy
    if @employee.destroy
      render_success(nil, '직원이 성공적으로 삭제되었습니다.')
    else
      render_error('직원 삭제에 실패했습니다.', :unprocessable_entity, @employee.errors.full_messages)
    end
  end

  private

  def set_employee
    @employee = Employee.find(params[:id])
  end

  def employee_params
    params.require(:employee).permit(
      :name, :department, :position, :employment_type,
      :hire_date, :phone, :email, :base_salary, :hourly_rate,
      :salary_type, :status
    )
  end
end
