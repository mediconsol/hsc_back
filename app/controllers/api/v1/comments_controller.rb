class Api::V1::CommentsController < ApplicationController
  before_action :authenticate_request
  before_action :set_department_post
  before_action :set_comment, only: [:destroy]
  
  def create
    @comment = @department_post.comments.build(comment_params)
    @comment.author = @current_user
    
    if @comment.save
      render json: {
        status: 'success',
        message: '댓글이 성공적으로 등록되었습니다.',
        data: {
          id: @comment.id,
          content: @comment.content,
          author: @comment.author.name,
          author_id: @comment.author.id,
          created_at: @comment.created_at,
          is_reply: @comment.is_reply?,
          parent_id: @comment.parent_id
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '댓글 등록에 실패했습니다.',
        errors: @comment.errors.full_messages
      }, status: :unprocessable_entity
    end
  end
  
  def destroy
    if @comment.author != @current_user && @current_user.role < 2
      return render json: {
        status: 'error',
        message: '댓글을 삭제할 권한이 없습니다.'
      }, status: :forbidden
    end
    
    if @comment.destroy
      render json: {
        status: 'success',
        message: '댓글이 성공적으로 삭제되었습니다.'
      }
    else
      render json: {
        status: 'error',
        message: '댓글 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end
  
  # 답글 생성
  def create_reply
    @parent_comment = @department_post.comments.find(params[:comment_id])
    @reply = @parent_comment.replies.build(comment_params)
    @reply.author = @current_user
    @reply.department_post = @department_post
    
    if @reply.save
      render json: {
        status: 'success',
        message: '답글이 성공적으로 등록되었습니다.',
        data: {
          id: @reply.id,
          content: @reply.content,
          author: @reply.author.name,
          author_id: @reply.author.id,
          created_at: @reply.created_at,
          parent_id: @reply.parent_id
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '답글 등록에 실패했습니다.',
        errors: @reply.errors.full_messages
      }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '원댓글을 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  private
  
  def set_department_post
    @department_post = DepartmentPost.find(params[:department_post_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '게시글을 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  def set_comment
    @comment = @department_post.comments.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      status: 'error',
      message: '댓글을 찾을 수 없습니다.'
    }, status: :not_found
  end
  
  def comment_params
    params.require(:comment).permit(:content, :parent_id)
  end
end