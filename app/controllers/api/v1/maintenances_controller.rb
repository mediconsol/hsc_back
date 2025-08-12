class Api::V1::MaintenancesController < ApplicationController
  before_action :authenticate_request
  before_action :set_maintenance, only: [:show, :update, :destroy]

  def index
    maintenances = Maintenance.includes(:asset)
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      maintenances = maintenances.joins(:asset).where(
        "maintenances.description ILIKE ? OR maintenances.technician ILIKE ? OR maintenances.notes ILIKE ? OR assets.name ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    # 필터링
    maintenances = maintenances.where(status: params[:status]) if params[:status].present?
    maintenances = maintenances.where(maintenance_type: params[:type]) if params[:type].present?
    maintenances = maintenances.joins(:asset).where(assets: { id: params[:asset_id] }) if params[:asset_id].present?
    
    # 날짜 범위 필터링
    if params[:start_date].present? && params[:end_date].present?
      maintenances = maintenances.where(scheduled_date: params[:start_date]..params[:end_date])
    end
    
    # 정렬
    maintenances = maintenances.order(:scheduled_date)
    
    maintenance_data = maintenances.map do |maintenance|
      {
        id: maintenance.id,
        asset_name: maintenance.asset.name,
        asset_id: maintenance.asset.id,
        maintenance_type: maintenance.maintenance_type,
        maintenance_type_text: maintenance.maintenance_type_text,
        scheduled_date: maintenance.scheduled_date,
        completed_date: maintenance.completed_date,
        status: maintenance.status,
        status_text: maintenance.status_text,
        status_color: maintenance.status_color,
        cost: maintenance.cost,
        description: maintenance.description,
        technician: maintenance.technician,
        notes: maintenance.notes,
        is_overdue: maintenance.overdue?,
        days_until_due: maintenance.days_until_due,
        created_at: maintenance.created_at,
        updated_at: maintenance.updated_at
      }
    end
    
    render json: {
      status: 'success',
      data: maintenance_data,
      meta: {
        total: maintenances.count
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @maintenance.id,
        asset: {
          id: @maintenance.asset.id,
          name: @maintenance.asset.name,
          serial_number: @maintenance.asset.serial_number,
          asset_type_text: @maintenance.asset.asset_type_text,
          facility: @maintenance.asset.facility&.name
        },
        maintenance_type: @maintenance.maintenance_type,
        maintenance_type_text: @maintenance.maintenance_type_text,
        scheduled_date: @maintenance.scheduled_date,
        completed_date: @maintenance.completed_date,
        status: @maintenance.status,
        status_text: @maintenance.status_text,
        status_color: @maintenance.status_color,
        cost: @maintenance.cost,
        description: @maintenance.description,
        technician: @maintenance.technician,
        notes: @maintenance.notes,
        is_overdue: @maintenance.overdue?,
        days_until_due: @maintenance.days_until_due,
        created_at: @maintenance.created_at,
        updated_at: @maintenance.updated_at
      }
    }
  end

  def create
    maintenance = Maintenance.new(maintenance_params)
    
    if maintenance.save
      render json: {
        status: 'success',
        message: '점검/보수 일정이 생성되었습니다.',
        data: {
          id: maintenance.id,
          asset_name: maintenance.asset.name,
          maintenance_type_text: maintenance.maintenance_type_text,
          scheduled_date: maintenance.scheduled_date,
          status_text: maintenance.status_text
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '점검/보수 일정 생성에 실패했습니다.',
        errors: maintenance.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @maintenance.update(maintenance_params)
      render json: {
        status: 'success',
        message: '점검/보수 정보가 수정되었습니다.',
        data: {
          id: @maintenance.id,
          asset_name: @maintenance.asset.name,
          maintenance_type_text: @maintenance.maintenance_type_text,
          scheduled_date: @maintenance.scheduled_date,
          status_text: @maintenance.status_text
        }
      }
    else
      render json: {
        status: 'error',
        message: '점검/보수 정보 수정에 실패했습니다.',
        errors: @maintenance.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    asset_name = @maintenance.asset.name
    
    if @maintenance.destroy
      render json: {
        status: 'success',
        message: "#{asset_name}의 점검/보수 일정이 삭제되었습니다."
      }
    else
      render json: {
        status: 'error',
        message: '점검/보수 일정 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def statistics
    stats = {
      total_maintenances: Maintenance.count,
      by_status: Maintenance.group(:status).count.transform_keys { |key|
        maintenance = Maintenance.new(status: key)
        { key: key, text: maintenance.status_text }
      },
      by_type: Maintenance.group(:maintenance_type).count.transform_keys { |key|
        maintenance = Maintenance.new(maintenance_type: key)
        { key: key, text: maintenance.maintenance_type_text }
      },
      overdue_count: Maintenance.where('scheduled_date < ? AND status IN (?)', Date.current, ['scheduled']).count,
      this_week: Maintenance.where(scheduled_date: Date.current.beginning_of_week..Date.current.end_of_week).count,
      next_week: Maintenance.where(scheduled_date: (Date.current + 1.week).beginning_of_week..(Date.current + 1.week).end_of_week).count,
      total_cost: Maintenance.where.not(cost: nil).sum(:cost)
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  private

  def set_maintenance
    @maintenance = Maintenance.find(params[:id])
  end

  def maintenance_params
    params.require(:maintenance).permit(
      :asset_id, :maintenance_type, :scheduled_date, :completed_date,
      :status, :cost, :description, :technician, :notes
    )
  end
end