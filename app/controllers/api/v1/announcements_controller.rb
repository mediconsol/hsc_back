class Api::V1::AnnouncementsController < ApplicationController
  before_action :authenticate_request
  before_action :set_announcement, only: [:show, :update, :destroy]
  
  def index
    @announcements = Announcement.published.recent
    @announcements = @announcements.by_department(params[:department]) if params[:department].present?
    
    render json: {
      status: 'success',
      data: @announcements.map do |announcement|
        {
          id: announcement.id,
          title: announcement.title,
          content: announcement.content,
          priority: announcement.priority,
          priority_text: announcement.priority_text,
          priority_color: announcement.priority_color,
          department: announcement.department,
          author: announcement.author.name,
          published_at: announcement.published_at,
          created_at: announcement.created_at
        }
      end
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @announcement.id,
        title: @announcement.title,
        content: @announcement.content,
        priority: @announcement.priority,
        priority_text: @announcement.priority_text,
        priority_color: @announcement.priority_color,
        department: @announcement.department,
        author: @announcement.author.name,
        published_at: @announcement.published_at,
        created_at: @announcement.created_at
      }
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
end
