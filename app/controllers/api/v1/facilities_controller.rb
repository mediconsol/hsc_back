class Api::V1::FacilitiesController < ApplicationController
  before_action :authenticate_request
  before_action :set_facility, only: [:show, :update, :destroy]
  before_action :check_permission, only: [:update, :destroy]
  
  def index
    @facilities = Facility.includes(:manager).recent
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @facilities = @facilities.where(
        "name ILIKE ? OR description ILIKE ? OR building ILIKE ? OR room_number ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    # 필터링
    @facilities = @facilities.by_type(params[:facility_type]) if params[:facility_type].present?
    @facilities = @facilities.by_status(params[:status]) if params[:status].present?
    @facilities = @facilities.by_building(params[:building]) if params[:building].present?
    @facilities = @facilities.by_floor(params[:floor]) if params[:floor].present?
    
    # 관리자 필터
    if params[:manager_id].present?
      @facilities = @facilities.where(manager_id: params[:manager_id])
    end
    
    # 내가 관리하는 시설만
    if params[:my_facilities] == 'true'
      @facilities = @facilities.where(manager: @current_user)
    end
    
    render json: {
      status: 'success',
      data: @facilities.map do |facility|
        {
          id: facility.id,
          name: facility.name,
          facility_type: facility.facility_type,
          facility_type_text: facility.facility_type_text,
          building: facility.building,
          floor: facility.floor,
          room_number: facility.room_number,
          full_location: facility.full_location,
          capacity: facility.capacity,
          status: facility.status,
          status_text: facility.status_text,
          status_color: facility.status_color,
          manager: facility.manager&.name,
          manager_id: facility.manager_id,
          assets_count: facility.assets.count,
          description: facility.description,
          created_at: facility.created_at,
          updated_at: facility.updated_at
        }
      end
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @facility.id,
        name: @facility.name,
        facility_type: @facility.facility_type,
        facility_type_text: @facility.facility_type_text,
        building: @facility.building,
        floor: @facility.floor,
        room_number: @facility.room_number,
        full_location: @facility.full_location,
        capacity: @facility.capacity,
        status: @facility.status,
        status_text: @facility.status_text,
        status_color: @facility.status_color,
        manager: @facility.manager&.name,
        manager_id: @facility.manager_id,
        description: @facility.description,
        can_edit: @facility.can_edit?(@current_user),
        created_at: @facility.created_at,
        updated_at: @facility.updated_at,
        assets: @facility.assets.includes(:manager).map do |asset|
          {
            id: asset.id,
            name: asset.name,
            asset_type: asset.asset_type,
            asset_type_text: asset.asset_type_text,
            status: asset.status,
            status_text: asset.status_text,
            status_color: asset.status_color,
            serial_number: asset.serial_number,
            manager: asset.manager&.name
          }
        end
      }
    }
  end

  def create
    @facility = Facility.new(facility_params)
    
    if @facility.save
      render json: {
        status: 'success',
        message: '시설이 성공적으로 등록되었습니다.',
        data: {
          id: @facility.id,
          name: @facility.name
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '시설 등록에 실패했습니다.',
        errors: @facility.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @facility.update(facility_params)
      render json: {
        status: 'success',
        message: '시설 정보가 성공적으로 수정되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '시설 정보 수정에 실패했습니다.',
        errors: @facility.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @facility.destroy
      render json: {
        status: 'success',
        message: '시설이 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '시설 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end
  
  def statistics
    stats = {
      total_facilities: Facility.count,
      by_type: Facility.group(:facility_type).count.transform_keys { |key| 
        facility = Facility.new(facility_type: key)
        { key: key, text: facility.facility_type_text }
      },
      by_status: Facility.group(:status).count.transform_keys { |key|
        facility = Facility.new(status: key)
        { key: key, text: facility.status_text }
      },
      by_building: Facility.group(:building).count,
      active_facilities: Facility.active.count,
      maintenance_facilities: Facility.where(status: 'maintenance').count,
      repair_facilities: Facility.where(status: 'repair').count
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  private

  def set_facility
    @facility = Facility.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '시설을 찾을 수 없습니다.'
    }, status: :not_found
  end

  def check_permission
    unless @facility.can_edit?(@current_user)
      render json: {
        status: 'error',
        message: '시설 정보를 수정할 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def facility_params
    params.require(:facility).permit(:name, :facility_type, :building, :floor, :room_number, 
                                     :capacity, :status, :manager_id, :description)
  end
end
