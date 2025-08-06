class Api::V1::DepartmentPostsController < ApplicationController
  before_action :authenticate_request
  before_action :set_department_post, only: [:show, :update, :destroy]
  
  def index
    @posts = DepartmentPost.includes(:author, :comments).recent
    @posts = @posts.by_department(params[:department]) if params[:department].present?
    @posts = @posts.by_category(params[:category]) if params[:category].present?
    
    render json: {
      status: 'success',
      data: @posts.map do |post|
        {
          id: post.id,
          title: post.title,
          content: post.content.truncate(100),
          department: post.department,
          category: post.category,
          category_text: post.category_text,
          priority: post.priority,
          priority_text: post.priority_text,
          priority_color: post.priority_color,
          author: post.author.name,
          views_count: post.views_count || 0,
          comments_count: post.comments.count,
          created_at: post.created_at,
          is_public: post.is_public
        }
      end
    }
  end

  def show
    @department_post.increment_views!
    
    render json: {
      status: 'success',
      data: {
        id: @department_post.id,
        title: @department_post.title,
        content: @department_post.content,
        department: @department_post.department,
        category: @department_post.category,
        category_text: @department_post.category_text,
        priority: @department_post.priority,
        priority_text: @department_post.priority_text,
        priority_color: @department_post.priority_color,
        author: @department_post.author.name,
        author_id: @department_post.author.id,
        views_count: @department_post.views_count,
        created_at: @department_post.created_at,
        updated_at: @department_post.updated_at,
        is_public: @department_post.is_public,
        comments: @department_post.comments.top_level.includes(:author, :replies).recent.map do |comment|
          {
            id: comment.id,
            content: comment.content,
            author: comment.author.name,
            author_id: comment.author.id,
            created_at: comment.created_at,
            replies: comment.replies.includes(:author).recent.map do |reply|
              {
                id: reply.id,
                content: reply.content,
                author: reply.author.name,
                author_id: reply.author.id,
                created_at: reply.created_at
              }
            end
          }
        end
      }
    }
  end

  def create
    @department_post = DepartmentPost.new(department_post_params)
    @department_post.author = @current_user
    @department_post.views_count = 0
    
    if @department_post.save
      render json: {
        status: 'success',
        message: '게시글이 성공적으로 등록되었습니다.',
        data: {
          id: @department_post.id,
          title: @department_post.title
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '게시글 등록에 실패했습니다.',
        errors: @department_post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @department_post.author != @current_user && !@current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @department_post.update(department_post_params)
      render json: {
        status: 'success',
        message: '게시글이 성공적으로 수정되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '게시글 수정에 실패했습니다.',
        errors: @department_post.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @department_post.author != @current_user && !@current_user.admin?
      return render json: {
        status: 'error',
        message: '권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @department_post.destroy
      render json: {
        status: 'success',
        message: '게시글이 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '게시글 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  private

  def set_department_post
    @department_post = DepartmentPost.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '게시글을 찾을 수 없습니다.'
    }, status: :not_found
  end

  def department_post_params
    params.require(:department_post).permit(:title, :content, :department, :category, :priority, :is_public)
  end
end
