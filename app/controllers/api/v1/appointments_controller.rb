class Api::V1::AppointmentsController < ApplicationController
  before_action :set_appointment, only: [:show, :update, :destroy, :confirm, :cancel, :arrive, :complete]
  
  def index
    @appointments = Appointment.includes(:patient, :employee)
    
    # 날짜 필터링
    if params[:date].present?
      date = Date.parse(params[:date])
      @appointments = @appointments.by_date(date)
    elsif params[:start_date].present? && params[:end_date].present?
      @appointments = @appointments.where(
        appointment_date: params[:start_date]..params[:end_date]
      )
    else
      # 기본값: 오늘부터 일주일
      @appointments = @appointments.where(
        appointment_date: Date.current.beginning_of_day..(Date.current + 7.days).end_of_day
      )
    end
    
    # 상태 필터링
    @appointments = @appointments.where(status: params[:status]) if params[:status].present?
    
    # 부서 필터링
    @appointments = @appointments.by_department(params[:department]) if params[:department].present?
    
    # 환자별 필터링
    @appointments = @appointments.by_patient(params[:patient_id]) if params[:patient_id].present?
    
    # 온라인 예약만 필터링
    @appointments = @appointments.online_requests if params[:online_only] == 'true'
    
    @appointments = @appointments.by_date_asc
    
    render json: {
      status: 'success',
      data: {
        appointments: @appointments.map { |appointment| appointment_json(appointment) },
        summary: calculate_summary(@appointments)
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        appointment: appointment_detailed_json(@appointment)
      }
    }
  end

  def create
    @appointment = Appointment.new(appointment_params)
    @appointment.created_by_patient = params[:created_by_patient] || false
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '예약이 생성되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('예약 생성에 실패했습니다.', :unprocessable_entity, @appointment.errors.full_messages)
    end
  end

  def update
    if @appointment.update(appointment_params)
      render json: {
        status: 'success',
        message: '예약 정보가 수정되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('예약 수정에 실패했습니다.', :unprocessable_entity, @appointment.errors.full_messages)
    end
  end

  def destroy
    if @appointment.destroy
      render json: {
        status: 'success',
        message: '예약이 삭제되었습니다.'
      }
    else
      render_error('예약 삭제에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 예약 확정
  def confirm
    unless @appointment.can_confirm?
      return render_error('예약을 확정할 수 없는 상태입니다.', :unprocessable_entity)
    end
    
    # 담당의 배정
    if params[:employee_id].present?
      employee = Employee.find(params[:employee_id])
      @appointment.employee = employee
    end
    
    @appointment.status = 'confirmed'
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '예약이 확정되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('예약 확정에 실패했습니다.', :unprocessable_entity, @appointment.errors.full_messages)
    end
  end

  # 예약 취소
  def cancel
    unless @appointment.can_cancel?
      return render_error('예약을 취소할 수 없는 상태입니다.', :unprocessable_entity)
    end
    
    @appointment.status = 'cancelled'
    @appointment.notes = params[:reason] if params[:reason].present?
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '예약이 취소되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('예약 취소에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 내원 확인
  def arrive
    unless @appointment.can_arrive?
      return render_error('내원 확인을 할 수 없는 상태입니다.', :unprocessable_entity)
    end
    
    @appointment.status = 'arrived'
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '내원이 확인되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('내원 확인에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 진료 완료
  def complete
    if @appointment.status != 'in_progress'
      return render_error('진료 완료할 수 없는 상태입니다.', :unprocessable_entity)
    end
    
    @appointment.status = 'completed'
    @appointment.notes = params[:notes] if params[:notes].present?
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '진료가 완료되었습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('진료 완료 처리에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 대시보드 데이터
  def dashboard
    today = Date.current
    
    # 오늘의 예약 현황
    today_appointments = Appointment.today.includes(:patient, :employee)
    
    # 예약 대기 목록 (온라인 신청)
    pending_appointments = Appointment.pending
                                     .online_requests
                                     .upcoming
                                     .includes(:patient)
                                     .order(:appointment_date)
                                     .limit(10)
    
    # 통계 데이터
    stats = {
      today: {
        total: today_appointments.count,
        confirmed: today_appointments.confirmed.count,
        pending: today_appointments.pending.count,
        completed: today_appointments.where(status: 'completed').count,
        cancelled: today_appointments.where(status: 'cancelled').count
      },
      pending_online: pending_appointments.count,
      upcoming_week: Appointment.upcoming
                               .where(appointment_date: Date.current..Date.current + 7.days)
                               .count
    }
    
    render json: {
      status: 'success',
      data: {
        today_appointments: today_appointments.map { |apt| appointment_json(apt) },
        pending_appointments: pending_appointments.map { |apt| appointment_json(apt) },
        statistics: stats
      }
    }
  end

  # 온라인 예약 신청 (환자용)
  def create_online
    # 환자 정보 확인 또는 생성
    patient = find_or_create_patient(online_patient_params)
    
    if patient.nil?
      return render_error('환자 정보 처리에 실패했습니다.', :unprocessable_entity)
    end
    
    @appointment = patient.appointments.build(online_appointment_params)
    @appointment.created_by_patient = true
    @appointment.status = 'pending'
    
    if @appointment.save
      render json: {
        status: 'success',
        message: '온라인 예약 신청이 완료되었습니다. 병원에서 확인 후 연락드리겠습니다.',
        data: {
          appointment: appointment_json(@appointment)
        }
      }
    else
      render_error('예약 신청에 실패했습니다.', :unprocessable_entity, @appointment.errors.full_messages)
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:id])
  end

  def appointment_params
    params.require(:appointment).permit(
      :patient_id, :employee_id, :appointment_date, :appointment_type,
      :department, :chief_complaint, :notes
    )
  end

  def online_appointment_params
    params.require(:appointment).permit(
      :appointment_date, :appointment_type, :department, :chief_complaint
    )
  end

  def online_patient_params
    params.require(:patient).permit(
      :name, :birth_date, :gender, :phone, :email, :insurance_type
    )
  end

  def appointment_json(appointment)
    {
      id: appointment.id,
      patient_id: appointment.patient_id,
      patient_name: appointment.patient.name,
      patient_phone: appointment.patient.phone,
      patient_age: appointment.patient.age,
      employee_id: appointment.employee_id,
      doctor_name: appointment.employee&.name,
      appointment_date: appointment.appointment_date.iso8601,
      formatted_appointment_date: appointment.formatted_appointment_date,
      formatted_appointment_time: appointment.formatted_appointment_time,
      appointment_type: appointment.appointment_type,
      appointment_type_text: appointment.appointment_type_text,
      department: appointment.department,
      chief_complaint: appointment.chief_complaint,
      status: appointment.status,
      status_text: appointment.status_text,
      status_color: appointment.status_color,
      created_by_patient: appointment.online_request?,
      time_until_appointment: appointment.time_until_appointment,
      can_confirm: appointment.can_confirm?,
      can_cancel: appointment.can_cancel?,
      can_arrive: appointment.can_arrive?,
      created_at: appointment.created_at,
      updated_at: appointment.updated_at
    }
  end

  def appointment_detailed_json(appointment)
    base_json = appointment_json(appointment)
    base_json.merge({
      notes: appointment.notes,
      patient_info: {
        name: appointment.patient.name,
        age: appointment.patient.age,
        gender_text: appointment.patient.gender_text,
        phone: appointment.patient.phone,
        email: appointment.patient.email,
        insurance_type_text: appointment.patient.insurance_type_text
      }
    })
  end

  def calculate_summary(appointments)
    {
      total_count: appointments.count,
      pending_count: appointments.pending.count,
      confirmed_count: appointments.confirmed.count,
      completed_count: appointments.where(status: 'completed').count,
      cancelled_count: appointments.where(status: 'cancelled').count,
      online_requests_count: appointments.online_requests.count
    }
  end

  def find_or_create_patient(patient_params)
    # 전화번호로 기존 환자 찾기
    existing_patient = Patient.find_by(phone: patient_params[:phone])
    
    if existing_patient
      # 기존 환자 정보 업데이트 (필요한 경우)
      existing_patient.update(patient_params)
      return existing_patient
    else
      # 새 환자 생성
      patient = Patient.new(patient_params)
      patient.status = 'active'
      patient.save ? patient : nil
    end
  end
end