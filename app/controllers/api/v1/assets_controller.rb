class Api::V1::AssetsController < ApplicationController
  before_action :authenticate_request
  before_action :set_asset, only: [:show, :update, :destroy, :change_status, :change_location]
  before_action :check_permission, only: [:update, :destroy, :change_status, :change_location]
  
  def index
    @assets = Asset.includes(:facility, :manager).recent
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @assets = @assets.where(
        "name ILIKE ? OR description ILIKE ? OR model ILIKE ? OR serial_number ILIKE ? OR vendor ILIKE ?",
        search_term, search_term, search_term, search_term, search_term
      )
    end
    
    # 필터링
    @assets = @assets.by_type(params[:asset_type]) if params[:asset_type].present?
    @assets = @assets.by_category(params[:category]) if params[:category].present?
    @assets = @assets.by_status(params[:status]) if params[:status].present?
    @assets = @assets.by_facility(params[:facility_id]) if params[:facility_id].present?
    
    # 관리자 필터
    if params[:manager_id].present?
      @assets = @assets.where(manager_id: params[:manager_id])
    end
    
    # 내가 관리하는 자산만
    if params[:my_assets] == 'true'
      @assets = @assets.where(manager: @current_user)
    end
    
    # 보증기간 만료 임박
    if params[:warranty_expiring] == 'true'
      @assets = @assets.warranty_expiring(30)
    end
    
    render json: {
      status: 'success',
      data: @assets.map do |asset|
        {
          id: asset.id,
          name: asset.name,
          asset_type: asset.asset_type,
          asset_type_text: asset.asset_type_text,
          category: asset.category,
          category_text: asset.category_text,
          model: asset.model,
          serial_number: asset.serial_number,
          purchase_date: asset.purchase_date,
          purchase_price: asset.purchase_price,
          vendor: asset.vendor,
          warranty_expiry: asset.warranty_expiry,
          warranty_status: asset.warranty_status,
          warranty_color: asset.warranty_color,
          status: asset.status,
          status_text: asset.status_text,
          status_color: asset.status_color,
          facility: asset.facility&.name,
          facility_id: asset.facility_id,
          manager: asset.manager&.name,
          manager_id: asset.manager_id,
          depreciation_value: asset.depreciation_value,
          requires_maintenance: asset.requires_maintenance?,
          description: asset.description,
          created_at: asset.created_at,
          updated_at: asset.updated_at
        }
      end
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @asset.id,
        name: @asset.name,
        asset_type: @asset.asset_type,
        asset_type_text: @asset.asset_type_text,
        category: @asset.category,
        category_text: @asset.category_text,
        model: @asset.model,
        serial_number: @asset.serial_number,
        purchase_date: @asset.purchase_date,
        purchase_price: @asset.purchase_price,
        vendor: @asset.vendor,
        warranty_expiry: @asset.warranty_expiry,
        warranty_status: @asset.warranty_status,
        warranty_color: @asset.warranty_color,
        status: @asset.status,
        status_text: @asset.status_text,
        status_color: @asset.status_color,
        facility: @asset.facility&.name,
        facility_id: @asset.facility_id,
        facility_full_location: @asset.facility&.full_location,
        manager: @asset.manager&.name,
        manager_id: @asset.manager_id,
        depreciation_value: @asset.depreciation_value,
        requires_maintenance: @asset.requires_maintenance?,
        description: @asset.description,
        can_edit: @asset.can_edit?(@current_user),
        created_at: @asset.created_at,
        updated_at: @asset.updated_at,
        maintenances: @asset.maintenances.recent.limit(5).map do |maintenance|
          {
            id: maintenance.id,
            maintenance_type: maintenance.maintenance_type,
            maintenance_type_text: maintenance.maintenance_type_text,
            scheduled_date: maintenance.scheduled_date,
            completed_date: maintenance.completed_date,
            status: maintenance.status,
            status_text: maintenance.status_text,
            status_color: maintenance.status_color,
            cost: maintenance.cost,
            technician: maintenance.technician,
            description: maintenance.description
          }
        end
      }
    }
  end

  def create
    @asset = Asset.new(asset_params)
    
    if @asset.save
      render json: {
        status: 'success',
        message: '자산이 성공적으로 등록되었습니다.',
        data: {
          id: @asset.id,
          name: @asset.name
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '자산 등록에 실패했습니다.',
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @asset.update(asset_params)
      render json: {
        status: 'success',
        message: '자산 정보가 성공적으로 수정되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '자산 정보 수정에 실패했습니다.',
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @asset.destroy
      render json: {
        status: 'success',
        message: '자산이 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '자산 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end
  
  def change_status
    if @asset.update(status: params[:status])
      render json: {
        status: 'success',
        message: '자산 상태가 성공적으로 변경되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '자산 상태 변경에 실패했습니다.',
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def change_location
    if @asset.update(facility_id: params[:facility_id])
      render json: {
        status: 'success',
        message: '자산 위치가 성공적으로 변경되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '자산 위치 변경에 실패했습니다.',
        errors: @asset.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def statistics
    stats = {
      total_assets: Asset.count,
      by_type: Asset.group(:asset_type).count.transform_keys { |key| 
        asset = Asset.new(asset_type: key)
        { key: key, text: asset.asset_type_text }
      },
      by_status: Asset.group(:status).count.transform_keys { |key|
        asset = Asset.new(status: key)
        { key: key, text: asset.status_text }
      },
      active_assets: Asset.active.count,
      maintenance_assets: Asset.where(status: 'maintenance').count,
      broken_assets: Asset.where(status: 'broken').count,
      warranty_expiring_soon: Asset.warranty_expiring(30).count,
      total_value: Asset.sum(:purchase_price),
      requires_maintenance: Asset.all.select(&:requires_maintenance?).count
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end
  
  def warranty_expiring
    @assets = Asset.warranty_expiring(params[:days] || 30).includes(:facility, :manager)
    
    render json: {
      status: 'success',
      data: @assets.map do |asset|
        {
          id: asset.id,
          name: asset.name,
          asset_type_text: asset.asset_type_text,
          serial_number: asset.serial_number,
          warranty_expiry: asset.warranty_expiry,
          warranty_status: asset.warranty_status,
          facility: asset.facility&.name,
          manager: asset.manager&.name
        }
      end
    }
  end

  private

  def set_asset
    @asset = Asset.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '자산을 찾을 수 없습니다.'
    }, status: :not_found
  end

  def check_permission
    unless @asset.can_edit?(@current_user)
      render json: {
        status: 'error',
        message: '자산 정보를 수정할 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def asset_params
    params.require(:asset).permit(:name, :asset_type, :category, :model, :serial_number, 
                                  :purchase_date, :purchase_price, :vendor, :warranty_expiry,
                                  :status, :facility_id, :manager_id, :description)
  end
end