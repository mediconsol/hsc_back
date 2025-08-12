class Api::V1::InvoicesController < ApplicationController
  before_action :authenticate_request
  before_action :set_invoice, only: [:show, :update, :destroy, :approve, :reject, :mark_as_paid, :start_review]
  before_action :check_invoice_permissions, only: [:show, :update, :destroy]

  def index
    invoices = Invoice.includes(:processor)
    
    # 권한 기반 필터링
    unless current_user.admin?
      if current_user.manager?
        # 관리자는 모든 청구서 조회 가능
        invoices = invoices.all
      else
        # 일반 사용자는 본인이 처리 중인 청구서만 조회 가능
        invoices = invoices.where(processor: current_user)
      end
    end
    
    # 검색
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      invoices = invoices.left_joins(:processor).where(
        "invoice_number ILIKE ? OR vendor ILIKE ? OR notes ILIKE ? OR users.name ILIKE ?",
        search_term, search_term, search_term, search_term
      )
    end
    
    # 필터링
    invoices = invoices.by_vendor(params[:vendor]) if params[:vendor].present?
    invoices = invoices.by_status(params[:status]) if params[:status].present?
    
    # 날짜 범위 필터링
    if params[:start_date].present? && params[:end_date].present?
      invoices = invoices.by_date_range(params[:start_date], params[:end_date])
    elsif params[:period] == 'current_month'
      invoices = invoices.current_month
    elsif params[:period] == 'due_soon'
      invoices = invoices.due_soon(7)
    elsif params[:period] == 'overdue'
      invoices = invoices.overdue_bills
    end
    
    # 정렬
    invoices = invoices.recent
    
    invoice_data = invoices.map do |invoice|
      {
        id: invoice.id,
        invoice_number: invoice.invoice_number,
        vendor: invoice.vendor,
        issue_date: invoice.issue_date,
        due_date: invoice.due_date,
        total_amount: invoice.total_amount,
        tax_amount: invoice.tax_amount,
        net_amount: invoice.net_amount,
        formatted_total_amount: invoice.formatted_total_amount,
        formatted_tax_amount: invoice.formatted_tax_amount,
        formatted_net_amount: invoice.formatted_net_amount,
        tax_rate: invoice.tax_rate,
        status: invoice.status,
        status_text: invoice.status_text,
        status_color: invoice.status_color,
        payment_date: invoice.payment_date,
        processor: invoice.processor ? {
          id: invoice.processor.id,
          name: invoice.processor.name,
          email: invoice.processor.email
        } : nil,
        notes: invoice.notes,
        is_overdue: invoice.is_overdue?,
        is_urgent: invoice.is_urgent?,
        days_until_due: invoice.days_until_due,
        days_overdue: invoice.days_overdue,
        processing_days: invoice.processing_days,
        can_process: invoice.can_process?(current_user),
        can_edit: invoice.can_edit?(current_user),
        created_at: invoice.created_at,
        updated_at: invoice.updated_at
      }
    end
    
    render json: {
      status: 'success',
      data: invoice_data,
      meta: {
        total: invoices.count,
        pending_payment: invoices.pending_payment.count,
        overdue_count: invoices.overdue_bills.count,
        due_soon_count: invoices.due_soon(7).count
      }
    }
  end

  def show
    render json: {
      status: 'success',
      data: {
        id: @invoice.id,
        invoice_number: @invoice.invoice_number,
        vendor: @invoice.vendor,
        issue_date: @invoice.issue_date,
        due_date: @invoice.due_date,
        total_amount: @invoice.total_amount,
        tax_amount: @invoice.tax_amount,
        net_amount: @invoice.net_amount,
        formatted_total_amount: @invoice.formatted_total_amount,
        formatted_tax_amount: @invoice.formatted_tax_amount,
        formatted_net_amount: @invoice.formatted_net_amount,
        tax_rate: @invoice.tax_rate,
        status: @invoice.status,
        status_text: @invoice.status_text,
        status_color: @invoice.status_color,
        payment_date: @invoice.payment_date,
        processor: @invoice.processor ? {
          id: @invoice.processor.id,
          name: @invoice.processor.name,
          email: @invoice.processor.email,
          department: @invoice.processor.respond_to?(:department) ? @invoice.processor.department : nil
        } : nil,
        notes: @invoice.notes,
        is_overdue: @invoice.is_overdue?,
        is_urgent: @invoice.is_urgent?,
        days_until_due: @invoice.days_until_due,
        days_overdue: @invoice.days_overdue,
        processing_days: @invoice.processing_days,
        can_process: @invoice.can_process?(current_user),
        can_edit: @invoice.can_edit?(current_user),
        created_at: @invoice.created_at,
        updated_at: @invoice.updated_at
      }
    }
  end

  def create
    invoice = Invoice.new(invoice_params)
    
    if invoice.save
      render json: {
        status: 'success',
        message: '청구서가 성공적으로 등록되었습니다.',
        data: {
          id: invoice.id,
          invoice_number: invoice.invoice_number,
          vendor: invoice.vendor,
          total_amount: invoice.total_amount,
          formatted_total_amount: invoice.formatted_total_amount,
          due_date: invoice.due_date,
          status_text: invoice.status_text
        }
      }, status: :created
    else
      render json: {
        status: 'error',
        message: '청구서 등록에 실패했습니다.',
        errors: invoice.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update
    if @invoice.update(invoice_params)
      render json: {
        status: 'success',
        message: '청구서 정보가 성공적으로 수정되었습니다.',
        data: {
          id: @invoice.id,
          invoice_number: @invoice.invoice_number,
          vendor: @invoice.vendor,
          total_amount: @invoice.total_amount,
          formatted_total_amount: @invoice.formatted_total_amount,
          status_text: @invoice.status_text
        }
      }
    else
      render json: {
        status: 'error',
        message: '청구서 정보 수정에 실패했습니다.',
        errors: @invoice.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    invoice_number = @invoice.invoice_number
    vendor = @invoice.vendor
    
    if @invoice.destroy
      render json: {
        status: 'success',
        message: "#{vendor}의 청구서 #{invoice_number}이 삭제되었습니다."
      }
    else
      render json: {
        status: 'error',
        message: '청구서 삭제에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def start_review
    unless @invoice.can_process?(current_user)
      render json: {
        status: 'error',
        message: '해당 청구서를 검토할 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    if @invoice.start_review!(current_user)
      render json: {
        status: 'success',
        message: '청구서 검토를 시작했습니다.',
        data: {
          id: @invoice.id,
          invoice_number: @invoice.invoice_number,
          status_text: @invoice.status_text,
          processor_name: current_user.name
        }
      }
    else
      render json: {
        status: 'error',
        message: '청구서 검토 시작에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def approve
    unless @invoice.can_process?(current_user)
      render json: {
        status: 'error',
        message: '해당 청구서를 승인할 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    if @invoice.approve!(current_user)
      render json: {
        status: 'success',
        message: '청구서가 승인되었습니다.',
        data: {
          id: @invoice.id,
          invoice_number: @invoice.invoice_number,
          vendor: @invoice.vendor,
          status_text: @invoice.status_text,
          processor_name: current_user.name
        }
      }
    else
      render json: {
        status: 'error',
        message: '청구서 승인에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def reject
    unless @invoice.can_process?(current_user)
      render json: {
        status: 'error',
        message: '해당 청구서를 반려할 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    reason = params[:reason]
    
    if @invoice.reject!(current_user, reason)
      render json: {
        status: 'success',
        message: '청구서가 반려되었습니다.',
        data: {
          id: @invoice.id,
          invoice_number: @invoice.invoice_number,
          vendor: @invoice.vendor,
          status_text: @invoice.status_text,
          processor_name: current_user.name,
          reason: reason
        }
      }
    else
      render json: {
        status: 'error',
        message: '청구서 반려에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def mark_as_paid
    unless @invoice.can_process?(current_user) || current_user.admin?
      render json: {
        status: 'error',
        message: '지급 처리 권한이 없습니다.'
      }, status: :forbidden
      return
    end
    
    payment_date = params[:payment_date]&.to_date || Date.current
    
    if @invoice.mark_as_paid!(payment_date)
      render json: {
        status: 'success',
        message: '청구서가 지급 완료 처리되었습니다.',
        data: {
          id: @invoice.id,
          invoice_number: @invoice.invoice_number,
          vendor: @invoice.vendor,
          status_text: @invoice.status_text,
          payment_date: @invoice.payment_date
        }
      }
    else
      render json: {
        status: 'error',
        message: '지급 처리에 실패했습니다.'
      }, status: :unprocessable_entity
    end
  end

  def statistics
    # 기본 통계
    stats = {
      total_invoices: Invoice.count,
      pending_payment: Invoice.pending_payment.count,
      overdue_count: Invoice.overdue_bills.count,
      due_soon_count: Invoice.due_soon(7).count,
      total_amount_pending: Invoice.pending_payment.sum(:total_amount),
      total_amount_paid_this_month: Invoice.where(
        payment_date: Date.current.beginning_of_month..Date.current.end_of_month
      ).sum(:total_amount)
    }
    
    # 상태별 통계
    stats[:by_status] = Invoice.group(:status).count.transform_keys do |key|
      invoice = Invoice.new(status: key)
      { key: key, text: invoice.status_text }
    end
    
    # 공급업체별 통계
    stats[:by_vendor] = Invoice.group(:vendor).sum(:total_amount).map do |vendor, amount|
      {
        vendor: vendor,
        total_amount: amount,
        count: Invoice.where(vendor: vendor).count,
        pending_amount: Invoice.where(vendor: vendor).pending_payment.sum(:total_amount)
      }
    end.sort_by { |item| -item[:total_amount] }.first(10)
    
    # 월별 지급 추이 (최근 12개월)
    stats[:monthly_payments] = (0..11).map do |i|
      month = i.months.ago.beginning_of_month
      {
        month: month.strftime('%Y-%m'),
        month_text: month.strftime('%Y년 %m월'),
        total_amount: Invoice.where(
          payment_date: month.beginning_of_month..month.end_of_month
        ).sum(:total_amount),
        count: Invoice.where(
          payment_date: month.beginning_of_month..month.end_of_month
        ).count
      }
    end.reverse
    
    # 연체 분석
    overdue_invoices = Invoice.overdue_bills.to_a
    avg_days_overdue = overdue_invoices.any? ? 
      (overdue_invoices.sum(&:days_overdue).to_f / overdue_invoices.count).round(1) : 0
    
    stats[:overdue_analysis] = {
      total_count: overdue_invoices.count,
      total_amount: overdue_invoices.sum(&:total_amount),
      avg_days_overdue: avg_days_overdue,
      by_days_range: {
        '1-7_days': overdue_invoices.select { |inv| inv.days_overdue.between?(1, 7) }.count,
        '8-30_days': overdue_invoices.select { |inv| inv.days_overdue.between?(8, 30) }.count,
        'over_30_days': overdue_invoices.select { |inv| inv.days_overdue > 30 }.count
      }
    }
    
    render json: {
      status: 'success',
      data: stats
    }
  end

  def vendors
    # 최근 등록된 공급업체 목록
    vendors = Invoice.distinct.pluck(:vendor).compact.sort
    
    vendor_data = vendors.map do |vendor|
      invoices = Invoice.where(vendor: vendor)
      {
        name: vendor,
        total_invoices: invoices.count,
        total_amount: invoices.sum(:total_amount),
        pending_amount: invoices.pending_payment.sum(:total_amount),
        last_invoice_date: invoices.maximum(:issue_date)
      }
    end
    
    render json: {
      status: 'success',
      data: vendor_data
    }
  end

  private

  def set_invoice
    @invoice = Invoice.find(params[:id])
  end

  def check_invoice_permissions
    unless @invoice.can_view?(current_user)
      render json: {
        status: 'error',
        message: '해당 청구서를 조회할 권한이 없습니다.'
      }, status: :forbidden
    end
  end

  def invoice_params
    params.require(:invoice).permit(
      :invoice_number, :vendor, :issue_date, :due_date,
      :total_amount, :tax_amount, :notes
    )
  end
end