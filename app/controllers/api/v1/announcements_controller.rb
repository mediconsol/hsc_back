class Api::V1::AnnouncementsController < ApplicationController
  before_action :authenticate_request
  before_action :set_announcement, only: [:show, :update, :destroy, :toggle_pin, :read_status]
  
  def index
    # 고정된 공지사항과 일반 공지사항 분리
    pinned_announcements = Announcement.published.pinned.includes(:author, :announcement_reads)
    regular_announcements = Announcement.published.unpinned.includes(:author, :announcement_reads)
    
    # 검색 및 필터링 적용 (일반 공지사항에만)
    regular_announcements = regular_announcements.search(params[:search]) if params[:search].present?
    regular_announcements = regular_announcements.by_department(params[:department]) if params[:department].present?
    regular_announcements = regular_announcements.by_author(params[:author]) if params[:author].present?
    regular_announcements = regular_announcements.by_date_range(params[:start_date], params[:end_date]) if params[:start_date].present? && params[:end_date].present?
    regular_announcements = regular_announcements.by_priority(params[:priority]) if params[:priority].present?
    
    # 읽음 상태 필터링
    if params[:read_status] == 'unread' && @current_user
      regular_announcements = regular_announcements.unread_by_user(@current_user)
    elsif params[:read_status] == 'read' && @current_user
      regular_announcements = regular_announcements.read_by_user(@current_user)
    end
    
    # 정렬 적용
    regular_announcements = case params[:sort]
                           when 'priority'
                             regular_announcements.by_priority_order
                           when 'views'
                             regular_announcements.by_view_count
                           when 'latest'
                             regular_announcements.by_latest
                           else
                             regular_announcements.recent
                           end
    
    # 페이지네이션 (일반 공지사항에만)
    page = params[:page]&.to_i || 1
    per_page = params[:per_page]&.to_i || 20
    regular_announcements = regular_announcements.limit(per_page).offset((page - 1) * per_page)
    
    # 고정된 공지사항과 일반 공지사항 합치기 (고정된 것이 먼저)
    all_announcements = (pinned_announcements + regular_announcements)
    
    render json: {
      status: 'success',
      data: all_announcements.map do |announcement|
        announcement_json(announcement, @current_user)
      end,
      pinned_count: pinned_announcements.count,
      unread_count: @current_user ? Announcement.published.unread_by_user(@current_user).count : 0,
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: regular_announcements.count,
        total_pinned: pinned_announcements.count
      }
    }
  end

  def show
    # 조회수 증가 및 읽음 상태 기록
    @announcement.increment_view_count!(@current_user)
    
    render json: {
      status: 'success',
      data: announcement_detailed_json(@announcement, @current_user)
    }
  end

  def create
    @announcement = Announcement.new(announcement_params)
    @announcement.author = @current_user
    @announcement.published_at = Time.current if @announcement.is_published
    
    if @announcement.save
      render json: {
        status: 'success',
        message: '공지사항이 성공적으로 등록되었습니다.',
        data: {
          id: @announcement.id,
          title: @announcement.title
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '공지사항 등록에 실패했습니다.',
        errors: @announcement.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @announcement.author != @current_user && !@current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @announcement.update(announcement_params)
      @announcement.update(published_at: Time.current) if @announcement.is_published && @announcement.published_at.nil?
      
      render json: {
        status: 'success',
        message: '공지사항이 성공적으로 수정되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '공지사항 수정에 실패했습니다.',
        errors: @announcement.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @announcement.author != @current_user && !@current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @announcement.destroy
      render json: {
        status: 'success',
        message: '공지사항이 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '공지사항 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end
  
  # 공지사항 고정/고정해제
  def toggle_pin
    unless @current_user.admin?
      return render json: {
        status: 'error',
        message: '관리자 권한이 필요합니다.'
      }, status: :forbidden
    end
    
    @announcement.toggle_pin!
    
    render json: {
      status: 'success',
      message: @announcement.is_pinned? ? '공지사항이 고정되었습니다.' : '공지사항 고정이 해제되었습니다.',
      data: {
        is_pinned: @announcement.is_pinned?,
        pinned_at: @announcement.pinned_at
      }
    }
  end
  
  # 읽음 상태 표시 (관리자용)
  def read_status
    unless @current_user.admin?
      return render json: {
        status: 'error',
        message: '관리자 권한이 필요합니다.'
      }, status: :forbidden
    end
    
    readers = @announcement.announcement_reads.includes(:user).order(:read_at)
    
    render json: {
      status: 'success',
      data: {
        total_users: User.count,
        read_count: readers.count,
        unread_count: @announcement.unread_count,
        read_percentage: @announcement.read_percentage,
        readers: readers.map do |read|
          {
            user_name: read.user.name,
            user_department: read.user.department || '미정',
            read_at: read.read_at.strftime('%Y-%m-%d %H:%M')
          }
        end
      }
    }
  end

  private

  def set_announcement
    @announcement = Announcement.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '공지사항을 찾을 수 없습니다.'
    }, status: :not_found
  end

  def announcement_params
    params.require(:announcement).permit(:title, :content, :priority, :department, :is_published)
  end
  
  # JSON 응답 헬퍼 메서드들
  def announcement_json(announcement, user = nil)
    {
      id: announcement.id,
      title: announcement.title,
      content: announcement.content.truncate(100),
      priority: announcement.priority,
      priority_text: announcement.priority_text,
      priority_color: announcement.priority_color,
      department: announcement.department,
      author: announcement.author.name,
      author_id: announcement.author.id,
      view_count: announcement.view_count,
      time_ago_text: announcement.time_ago_text,
      is_pinned: announcement.is_pinned?,
      pinned_at: announcement.pinned_at,
      is_read: user ? announcement.read_by?(user) : false,
      published_at: announcement.published_at,
      created_at: announcement.created_at
    }
  end
  
  def announcement_detailed_json(announcement, user = nil)
    base_json = announcement_json(announcement, user)
    base_json.merge({
      content: announcement.content, # 전체 내용
      updated_at: announcement.updated_at,
      can_edit: can_edit_announcement?(announcement),
      can_delete: can_delete_announcement?(announcement),
      can_pin: can_pin_announcement?(announcement),
      read_percentage: @current_user&.admin? ? announcement.read_percentage : nil,
      unread_count: @current_user&.admin? ? announcement.unread_count : nil
    })
  end
  
  # 권한 확인 메서드들
  def can_edit_announcement?(announcement)
    return false unless @current_user
    announcement.author == @current_user || @current_user.admin?
  end
  
  def can_delete_announcement?(announcement)
    return false unless @current_user
    announcement.author == @current_user || @current_user.admin?
  end
  
  def can_pin_announcement?(announcement)
    return false unless @current_user
    @current_user.admin?
  end
end
