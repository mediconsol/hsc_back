class Api::V1::PatientsController < ApplicationController
  before_action :set_patient, only: [:show, :update, :destroy]
  
  def index
    @patients = Patient.includes(:appointments)
    
    # 검색 필터링
    @patients = @patients.by_name(params[:search]) if params[:search].present?
    @patients = @patients.by_phone(params[:phone]) if params[:phone].present?
    
    # 상태 필터링
    @patients = @patients.where(status: params[:status]) if params[:status].present?
    
    # 보험 유형 필터링
    @patients = @patients.where(insurance_type: params[:insurance_type]) if params[:insurance_type].present?
    
    @patients = @patients.order(:name)
    
    render json: {
      status: 'success',
      data: {
        patients: @patients.map { |patient| patient_json(patient) },
        total: @patients.count
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        patient: patient_detailed_json(@patient)
      }
    }
  end

  def create
    @patient = Patient.new(patient_params)
    
    if @patient.save
      render json: {
        status: 'success',
        message: '환자 정보가 등록되었습니다.',
        data: {
          patient: patient_json(@patient)
        }
      }
    else
      render_error('환자 등록에 실패했습니다.', :unprocessable_entity, @patient.errors.full_messages)
    end
  end

  def update
    if @patient.update(patient_params)
      render json: {
        status: 'success',
        message: '환자 정보가 수정되었습니다.',
        data: {
          patient: patient_json(@patient)
        }
      }
    else
      render_error('환자 정보 수정에 실패했습니다.', :unprocessable_entity, @patient.errors.full_messages)
    end
  end

  def destroy
    if @patient.destroy
      render json: {
        status: 'success',
        message: '환자 정보가 삭제되었습니다.'
      }
    else
      render_error('환자 정보 삭제에 실패했습니다.', :unprocessable_entity)
    end
  end

  # 환자 검색 (자동완성용)
  def search
    query = params[:q]
    
    if query.blank?
      return render json: {
        status: 'success',
        data: { patients: [] }
      }
    end
    
    patients = Patient.active
                     .where('name ILIKE ? OR phone LIKE ?', "%#{query}%", "%#{query}%")
                     .limit(10)
                     .order(:name)
    
    render json: {
      status: 'success',
      data: {
        patients: patients.map { |p| patient_simple_json(p) }
      }
    }
  end

  private

  def set_patient
    @patient = Patient.find(params[:id])
  end

  def patient_params
    params.require(:patient).permit(
      :name, :birth_date, :gender, :phone, :email, :address,
      :insurance_type, :insurance_number, :emergency_contact_name,
      :emergency_contact_phone, :notes, :status
    )
  end

  def patient_json(patient)
    {
      id: patient.id,
      name: patient.name,
      age: patient.age,
      gender: patient.gender,
      gender_text: patient.gender_text,
      phone: patient.phone,
      email: patient.email,
      insurance_type: patient.insurance_type,
      insurance_type_text: patient.insurance_type_text,
      status: patient.status,
      status_text: patient.status_text,
      status_color: patient.status_color,
      appointments_count: patient.appointments.count,
      next_appointment: patient.next_appointment&.appointment_date,
      created_at: patient.created_at,
      updated_at: patient.updated_at
    }
  end

  def patient_detailed_json(patient)
    base_json = patient_json(patient)
    base_json.merge({
      birth_date: patient.birth_date,
      address: patient.address,
      insurance_number: patient.insurance_number,
      emergency_contact_name: patient.emergency_contact_name,
      emergency_contact_phone: patient.emergency_contact_phone,
      notes: patient.notes,
      recent_appointments: patient.recent_appointments.map { |apt| appointment_simple_json(apt) }
    })
  end

  def patient_simple_json(patient)
    {
      id: patient.id,
      name: patient.name,
      phone: patient.phone,
      age: patient.age,
      gender_text: patient.gender_text
    }
  end

  def appointment_simple_json(appointment)
    {
      id: appointment.id,
      appointment_date: appointment.formatted_appointment_date,
      appointment_type_text: appointment.appointment_type_text,
      department: appointment.department,
      status_text: appointment.status_text,
      status_color: appointment.status_color,
      doctor_name: appointment.employee&.name
    }
  end
end