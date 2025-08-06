class Api::V1::AttendancesController < ApplicationController
  before_action :set_attendance, only: [:show, :update, :destroy]
  
  def index
    @attendances = Attendance.includes(:employee)
    
    # 날짜 필터링
    if params[:date].present?
      target_date = Date.parse(params[:date])
      @attendances = @attendances.where(work_date: target_date)
    elsif params[:start_date].present? && params[:end_date].present?
      @attendances = @attendances.where(work_date: params[:start_date]..params[:end_date])
    else
      # 기본값: 이번 달
      @attendances = @attendances.this_month
    end
    
    # 직원 필터링
    @attendances = @attendances.where(employee_id: params[:employee_id]) if params[:employee_id].present?
    
    # 상태 필터링
    @attendances = @attendances.by_status(params[:status]) if params[:status].present?
    
    @attendances = @attendances.order(:work_date, :employee_id)
    
    render json: {
      status: 'success',
      data: {
        attendances: @attendances.map do |attendance|
          {
            id: attendance.id,
            employee_id: attendance.employee_id,
            employee_name: attendance.employee.name,
            employee_department: attendance.employee.department,
            work_date: attendance.work_date,
            status: attendance.status,
            status_text: attendance.status_text,
            status_color: attendance.status_color,
            check_in: attendance.check_in,
            check_out: attendance.check_out,
            regular_hours: attendance.regular_hours,
            overtime_hours: attendance.overtime_hours,
            night_hours: attendance.night_hours,
            total_hours: attendance.total_hours,
            notes: attendance.notes,
            created_at: attendance.created_at,
            updated_at: attendance.updated_at
          }
        end,
        summary: calculate_summary(@attendances)
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        attendance: attendance_json(@attendance)
      }
    }
  end

  # 출근 체크인
  def check_in
    employee = Employee.find(params[:employee_id])
    today = Date.current
    
    # 오늘 출근 기록이 이미 있는지 확인
    existing_attendance = employee.attendances.find_by(work_date: today)
    
    if existing_attendance && existing_attendance.check_in.present?
      return render_error('이미 출근 처리되었습니다.', :unprocessable_entity)
    end
    
    # 출근 기록 생성 또는 업데이트
    attendance = existing_attendance || employee.attendances.build(work_date: today)
    attendance.check_in = Time.current
    
    # 지각 여부 확인
    if attendance.is_late?
      attendance.status = 'late'
    else
      attendance.status = 'present'
    end
    
    if attendance.save
      render json: {
        status: 'success',
        message: '출근 처리되었습니다.',
        data: {
          attendance: attendance_json(attendance)
        }
      }
    else
      render_error('출근 처리에 실패했습니다.', :unprocessable_entity, attendance.errors.full_messages)
    end
  end

  # 퇴근 체크아웃
  def check_out
    employee = Employee.find(params[:employee_id])
    today = Date.current
    
    attendance = employee.attendances.find_by(work_date: today)
    
    if !attendance
      return render_error('출근 기록이 없습니다. 먼저 출근 처리를 해주세요.', :unprocessable_entity)
    end
    
    if attendance.check_out.present?
      return render_error('이미 퇴근 처리되었습니다.', :unprocessable_entity)
    end
    
    attendance.check_out = Time.current
    
    # 조퇴 여부 확인 (지각이 아닌 경우만)
    if attendance.status != 'late' && attendance.is_early_leave?
      attendance.status = 'early_leave'
    end
    
    # 근무 시간 계산
    attendance.calculate_hours!
    
    render json: {
      status: 'success',
      message: '퇴근 처리되었습니다.',
      data: {
        attendance: attendance_json(attendance.reload)
      }
    }
  end

  def create
    employee = Employee.find(params[:employee_id])
    
    @attendance = employee.attendances.build(attendance_params)
    
    if @attendance.save
      render json: {
        status: 'success',
        message: '근태 기록이 생성되었습니다.',
        data: {
          attendance: attendance_json(@attendance)
        }
      }
    else
      render_error('근태 기록 생성에 실패했습니다.', :unprocessable_entity, @attendance.errors.full_messages)
    end
  end

  def update
    if @attendance.update(attendance_params)
      render json: {
        status: 'success',
        message: '근태 기록이 수정되었습니다.',
        data: {
          attendance: attendance_json(@attendance)
        }
      }
    else
      render_error('근태 기록 수정에 실패했습니다.', :unprocessable_entity, @attendance.errors.full_messages)
    end
  end

  def destroy
    if @attendance.destroy
      render json: {
        status: 'success',
        message: '근태 기록이 삭제되었습니다.'
      }
    else
      render_error('근태 기록 삭제에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 근태 통계
  def statistics
    start_date = params[:start_date] || Date.current.beginning_of_month
    end_date = params[:end_date] || Date.current.end_of_month
    
    attendances = Attendance.includes(:employee).where(work_date: start_date..end_date)
    
    stats = {
      total_employees: Employee.count,
      total_work_days: (start_date..end_date).count,
      attendance_summary: {
        present: attendances.where(status: 'present').count,
        late: attendances.where(status: 'late').count,
        early_leave: attendances.where(status: 'early_leave').count,
        absent: attendances.where(status: 'absent').count,
        leave: attendances.where(status: 'leave').count
      },
      department_stats: calculate_department_stats(attendances),
      daily_stats: calculate_daily_stats(attendances, start_date, end_date)
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  # 오늘의 근태 현황
  def today_status
    today = Date.current
    attendances = Attendance.includes(:employee).where(work_date: today)
    
    render json: {
      status: 'success',
      data: {
        date: today,
        summary: calculate_summary(attendances),
        attendances: attendances.map { |a| attendance_json(a) }
      }
    }
  end

  private

  def set_attendance
    @attendance = Attendance.find(params[:id])
  end

  def attendance_params
    params.require(:attendance).permit(
      :work_date, :status, :check_in, :check_out, 
      :regular_hours, :overtime_hours, :night_hours, :notes
    )
  end

  def attendance_json(attendance)
    {
      id: attendance.id,
      employee_id: attendance.employee_id,
      employee_name: attendance.employee.name,
      employee_department: attendance.employee.department,
      work_date: attendance.work_date,
      status: attendance.status,
      status_text: attendance.status_text,
      status_color: attendance.status_color,
      check_in: attendance.check_in,
      check_out: attendance.check_out,
      regular_hours: attendance.regular_hours,
      overtime_hours: attendance.overtime_hours,
      night_hours: attendance.night_hours,
      total_hours: attendance.total_hours,
      notes: attendance.notes,
      created_at: attendance.created_at,
      updated_at: attendance.updated_at
    }
  end

  def calculate_summary(attendances)
    {
      total_count: attendances.count,
      present_count: attendances.where(status: 'present').count,
      late_count: attendances.where(status: 'late').count,
      early_leave_count: attendances.where(status: 'early_leave').count,
      absent_count: attendances.where(status: 'absent').count,
      leave_count: attendances.where(status: 'leave').count,
      total_regular_hours: attendances.sum(:regular_hours),
      total_overtime_hours: attendances.sum(:overtime_hours),
      total_night_hours: attendances.sum(:night_hours)
    }
  end

  def calculate_department_stats(attendances)
    Employee.distinct.pluck(:department).map do |dept|
      dept_attendances = attendances.joins(:employee).where(employees: { department: dept })
      {
        department: dept,
        total: dept_attendances.count,
        present: dept_attendances.where(status: 'present').count,
        late: dept_attendances.where(status: 'late').count,
        absent: dept_attendances.where(status: 'absent').count
      }
    end
  end

  def calculate_daily_stats(attendances, start_date, end_date)
    (start_date..end_date).map do |date|
      daily_attendances = attendances.where(work_date: date)
      {
        date: date,
        total: daily_attendances.count,
        present: daily_attendances.where(status: 'present').count,
        late: daily_attendances.where(status: 'late').count,
        absent: daily_attendances.where(status: 'absent').count
      }
    end
  end
end