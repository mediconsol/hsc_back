# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_08_12_042241) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_reads", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.bigint "user_id", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id", "user_id"], name: "index_announcement_reads_on_announcement_id_and_user_id", unique: true
    t.index ["announcement_id"], name: "index_announcement_reads_on_announcement_id"
    t.index ["user_id"], name: "index_announcement_reads_on_user_id"
  end

  create_table "announcements", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.integer "priority"
    t.bigint "author_id", null: false
    t.string "department"
    t.datetime "published_at"
    t.boolean "is_published"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "view_count", default: 0, null: false
    t.boolean "is_pinned", default: false, null: false
    t.datetime "pinned_at"
    t.index ["author_id"], name: "index_announcements_on_author_id"
    t.index ["is_pinned", "pinned_at"], name: "index_announcements_on_is_pinned_and_pinned_at"
    t.index ["view_count"], name: "index_announcements_on_view_count"
  end

  create_table "appointments", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "employee_id"
    t.datetime "appointment_date"
    t.string "appointment_type"
    t.string "department"
    t.text "chief_complaint"
    t.string "status"
    t.text "notes"
    t.boolean "created_by_patient"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_appointments_on_employee_id"
    t.index ["patient_id"], name: "index_appointments_on_patient_id"
  end

  create_table "approval_workflows", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.string "workflow_name"
    t.text "approvers_data"
    t.string "workflow_type"
    t.boolean "is_sequential"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_approval_workflows_on_document_id"
  end

  create_table "approvals", force: :cascade do |t|
    t.bigint "document_id", null: false
    t.bigint "approver_id", null: false
    t.string "status"
    t.text "comments"
    t.datetime "approved_at"
    t.integer "order_index"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_approvals_on_approver_id"
    t.index ["document_id"], name: "index_approvals_on_document_id"
  end

  create_table "assets", force: :cascade do |t|
    t.string "name", null: false
    t.string "asset_type", null: false
    t.string "category"
    t.string "model"
    t.string "serial_number", null: false
    t.date "purchase_date"
    t.decimal "purchase_price", precision: 12, scale: 2
    t.string "vendor"
    t.date "warranty_expiry"
    t.string "status", default: "active"
    t.bigint "facility_id"
    t.bigint "manager_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_type"], name: "index_assets_on_asset_type"
    t.index ["category"], name: "index_assets_on_category"
    t.index ["facility_id"], name: "index_assets_on_facility_id"
    t.index ["manager_id"], name: "index_assets_on_manager_id"
    t.index ["purchase_date"], name: "index_assets_on_purchase_date"
    t.index ["serial_number"], name: "index_assets_on_serial_number", unique: true
    t.index ["status"], name: "index_assets_on_status"
    t.index ["warranty_expiry"], name: "index_assets_on_warranty_expiry"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.datetime "check_in"
    t.datetime "check_out"
    t.date "work_date"
    t.decimal "regular_hours"
    t.decimal "overtime_hours"
    t.decimal "night_hours"
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "work_date"], name: "index_attendances_on_employee_id_and_work_date", unique: true
    t.index ["employee_id"], name: "index_attendances_on_employee_id"
    t.index ["work_date"], name: "index_attendances_on_work_date"
  end

  create_table "budgets", force: :cascade do |t|
    t.string "department", null: false
    t.string "category", null: false
    t.integer "fiscal_year", null: false
    t.string "period_type", default: "annual", null: false
    t.decimal "allocated_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "used_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.bigint "manager_id", null: false
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department", "category", "fiscal_year"], name: "index_budgets_on_department_and_category_and_fiscal_year", unique: true
    t.index ["fiscal_year"], name: "index_budgets_on_fiscal_year"
    t.index ["manager_id"], name: "index_budgets_on_manager_id"
    t.index ["status"], name: "index_budgets_on_status"
  end

  create_table "checkup_results", force: :cascade do |t|
    t.bigint "health_checkup_id", null: false
    t.string "test_category"
    t.string "test_name"
    t.string "result_value"
    t.string "reference_range"
    t.string "result_status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["health_checkup_id"], name: "index_checkup_results_on_health_checkup_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.bigint "author_id", null: false
    t.bigint "department_post_id", null: false
    t.bigint "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["department_post_id"], name: "index_comments_on_department_post_id"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
  end

  create_table "conversation_histories", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "persona", default: "default", null: false
    t.string "message_type", null: false
    t.text "content", null: false
    t.datetime "timestamp", null: false
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_conversation_histories_on_session_id"
    t.index ["user_id", "persona"], name: "index_conversation_histories_on_user_id_and_persona"
    t.index ["user_id", "timestamp"], name: "index_conversation_histories_on_user_id_and_timestamp"
    t.index ["user_id"], name: "index_conversation_histories_on_user_id"
  end

  create_table "department_posts", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.bigint "author_id", null: false
    t.string "department"
    t.string "category"
    t.integer "priority"
    t.boolean "is_public"
    t.integer "views_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_department_posts_on_author_id"
  end

  create_table "documents", force: :cascade do |t|
    t.string "title"
    t.text "content"
    t.string "document_type"
    t.bigint "author_id", null: false
    t.string "department"
    t.integer "security_level"
    t.string "status"
    t.integer "version"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_documents_on_author_id"
  end

  create_table "employees", force: :cascade do |t|
    t.string "name"
    t.string "department"
    t.string "position"
    t.string "employment_type"
    t.date "hire_date"
    t.string "phone"
    t.string "email"
    t.decimal "base_salary"
    t.decimal "hourly_rate"
    t.string "salary_type"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["department", "status"], name: "index_employees_on_department_and_status"
    t.index ["department"], name: "index_employees_on_department"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employment_type"], name: "index_employees_on_employment_type"
    t.index ["hire_date"], name: "index_employees_on_hire_date"
    t.index ["status"], name: "index_employees_on_status"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.date "expense_date", null: false
    t.string "category", null: false
    t.string "department", null: false
    t.string "vendor"
    t.string "payment_method", default: "card", null: false
    t.string "receipt_number"
    t.string "status", default: "pending", null: false
    t.bigint "budget_id"
    t.bigint "requester_id", null: false
    t.bigint "approver_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_expenses_on_approver_id"
    t.index ["budget_id"], name: "index_expenses_on_budget_id"
    t.index ["category"], name: "index_expenses_on_category"
    t.index ["department"], name: "index_expenses_on_department"
    t.index ["expense_date"], name: "index_expenses_on_expense_date"
    t.index ["requester_id"], name: "index_expenses_on_requester_id"
    t.index ["status"], name: "index_expenses_on_status"
  end

  create_table "facilities", force: :cascade do |t|
    t.string "name", null: false
    t.string "facility_type", null: false
    t.string "building"
    t.integer "floor"
    t.string "room_number"
    t.integer "capacity"
    t.string "status", default: "active"
    t.bigint "manager_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["building", "floor", "room_number"], name: "index_facilities_on_building_and_floor_and_room_number", unique: true
    t.index ["facility_type"], name: "index_facilities_on_facility_type"
    t.index ["manager_id"], name: "index_facilities_on_manager_id"
    t.index ["status"], name: "index_facilities_on_status"
  end

  create_table "family_histories", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "relationship"
    t.string "disease_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_family_histories_on_patient_id"
  end

  create_table "health_checkups", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.bigint "appointment_id"
    t.datetime "checkup_date"
    t.string "checkup_type"
    t.string "package_name"
    t.string "status"
    t.decimal "total_cost", precision: 10, scale: 2
    t.boolean "insurance_covered", default: false
    t.bigint "assigned_doctor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["appointment_id"], name: "index_health_checkups_on_appointment_id"
    t.index ["assigned_doctor_id"], name: "index_health_checkups_on_assigned_doctor_id"
    t.index ["checkup_date"], name: "index_health_checkups_on_checkup_date"
    t.index ["checkup_type"], name: "index_health_checkups_on_checkup_type"
    t.index ["patient_id"], name: "index_health_checkups_on_patient_id"
    t.index ["status"], name: "index_health_checkups_on_status"
  end

  create_table "invoices", force: :cascade do |t|
    t.string "invoice_number", null: false
    t.string "vendor", null: false
    t.date "issue_date", null: false
    t.date "due_date", null: false
    t.decimal "total_amount", precision: 15, scale: 2, null: false
    t.decimal "tax_amount", precision: 15, scale: 2, default: "0.0", null: false
    t.decimal "net_amount", precision: 15, scale: 2, null: false
    t.string "status", default: "received", null: false
    t.date "payment_date"
    t.text "notes"
    t.bigint "processor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["due_date"], name: "index_invoices_on_due_date"
    t.index ["invoice_number"], name: "index_invoices_on_invoice_number", unique: true
    t.index ["issue_date"], name: "index_invoices_on_issue_date"
    t.index ["processor_id"], name: "index_invoices_on_processor_id"
    t.index ["status"], name: "index_invoices_on_status"
    t.index ["vendor"], name: "index_invoices_on_vendor"
  end

  create_table "leave_requests", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.string "leave_type"
    t.date "start_date"
    t.date "end_date"
    t.integer "days_requested"
    t.text "reason"
    t.string "status"
    t.bigint "approver_id"
    t.datetime "approved_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["approver_id"], name: "index_leave_requests_on_approver_id"
    t.index ["employee_id", "status"], name: "index_leave_requests_on_employee_id_and_status"
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
    t.index ["start_date"], name: "index_leave_requests_on_start_date"
    t.index ["status"], name: "index_leave_requests_on_status"
  end

  create_table "maintenances", force: :cascade do |t|
    t.bigint "asset_id", null: false
    t.string "maintenance_type", null: false
    t.date "scheduled_date", null: false
    t.date "completed_date"
    t.text "description"
    t.decimal "cost", precision: 10, scale: 2
    t.string "technician"
    t.string "status", default: "scheduled"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["asset_id"], name: "index_maintenances_on_asset_id"
    t.index ["completed_date"], name: "index_maintenances_on_completed_date"
    t.index ["maintenance_type"], name: "index_maintenances_on_maintenance_type"
    t.index ["scheduled_date"], name: "index_maintenances_on_scheduled_date"
    t.index ["status"], name: "index_maintenances_on_status"
  end

  create_table "medical_histories", force: :cascade do |t|
    t.bigint "patient_id", null: false
    t.string "disease_name"
    t.date "diagnosis_date"
    t.string "treatment_status"
    t.text "medication"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["patient_id"], name: "index_medical_histories_on_patient_id"
  end

  create_table "patients", force: :cascade do |t|
    t.string "name"
    t.date "birth_date"
    t.string "gender"
    t.string "phone"
    t.string "email"
    t.text "address"
    t.string "insurance_type"
    t.string "insurance_number"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "notes"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "patient_number"
    t.string "occupation"
    t.string "blood_type"
    t.decimal "height"
    t.decimal "weight"
    t.string "smoking_status"
    t.string "drinking_status"
    t.string "exercise_status"
    t.date "last_checkup_date"
    t.integer "checkup_cycle"
  end

  create_table "payrolls", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.date "pay_period_start"
    t.date "pay_period_end"
    t.decimal "base_pay"
    t.decimal "overtime_pay"
    t.decimal "night_pay"
    t.decimal "allowances"
    t.decimal "deductions"
    t.decimal "tax"
    t.decimal "net_pay"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "pay_period_start"], name: "index_payrolls_on_employee_id_and_pay_period_start"
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
    t.index ["pay_period_start"], name: "index_payrolls_on_pay_period_start"
    t.index ["status"], name: "index_payrolls_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  add_foreign_key "announcement_reads", "announcements"
  add_foreign_key "announcement_reads", "users"
  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "appointments", "employees"
  add_foreign_key "appointments", "patients"
  add_foreign_key "approval_workflows", "documents"
  add_foreign_key "approvals", "documents"
  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "assets", "facilities"
  add_foreign_key "assets", "users", column: "manager_id"
  add_foreign_key "attendances", "employees"
  add_foreign_key "budgets", "users", column: "manager_id"
  add_foreign_key "checkup_results", "health_checkups"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "department_posts"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "conversation_histories", "users"
  add_foreign_key "department_posts", "users", column: "author_id"
  add_foreign_key "documents", "users", column: "author_id"
  add_foreign_key "expenses", "budgets"
  add_foreign_key "expenses", "users", column: "approver_id"
  add_foreign_key "expenses", "users", column: "requester_id"
  add_foreign_key "facilities", "users", column: "manager_id"
  add_foreign_key "family_histories", "patients"
  add_foreign_key "health_checkups", "appointments"
  add_foreign_key "health_checkups", "employees", column: "assigned_doctor_id"
  add_foreign_key "health_checkups", "patients"
  add_foreign_key "invoices", "users", column: "processor_id"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "leave_requests", "users", column: "approver_id"
  add_foreign_key "maintenances", "assets"
  add_foreign_key "medical_histories", "patients"
  add_foreign_key "payrolls", "employees"
end
