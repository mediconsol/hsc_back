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

ActiveRecord::Schema[8.0].define(version: 2025_08_05_115947) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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
    t.index ["author_id"], name: "index_announcements_on_author_id"
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
    t.index ["employee_id"], name: "index_attendances_on_employee_id"
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
    t.index ["employee_id"], name: "index_leave_requests_on_employee_id"
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
    t.index ["employee_id"], name: "index_payrolls_on_employee_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "announcements", "users", column: "author_id"
  add_foreign_key "approval_workflows", "documents"
  add_foreign_key "approvals", "documents"
  add_foreign_key "approvals", "users", column: "approver_id"
  add_foreign_key "attendances", "employees"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "department_posts"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "department_posts", "users", column: "author_id"
  add_foreign_key "documents", "users", column: "author_id"
  add_foreign_key "leave_requests", "employees"
  add_foreign_key "leave_requests", "users", column: "approver_id"
  add_foreign_key "payrolls", "employees"
end
