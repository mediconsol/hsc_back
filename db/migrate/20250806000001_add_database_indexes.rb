class AddDatabaseIndexes < ActiveRecord::Migration[8.0]
  def change
    # Employee 테이블 인덱스
    add_index :employees, :email, unique: true unless index_exists?(:employees, :email)
    add_index :employees, :department unless index_exists?(:employees, :department)
    add_index :employees, :employment_type unless index_exists?(:employees, :employment_type)
    add_index :employees, :status unless index_exists?(:employees, :status)
    add_index :employees, :hire_date unless index_exists?(:employees, :hire_date)
    add_index :employees, [:department, :status] unless index_exists?(:employees, [:department, :status])
    
    # User 테이블 인덱스
    add_index :users, :email, unique: true unless index_exists?(:users, :email)
    add_index :users, :role unless index_exists?(:users, :role)
    
    # Attendance 테이블 인덱스 (있다면)
    if table_exists?(:attendances)
      add_index :attendances, :employee_id unless index_exists?(:attendances, :employee_id)
      add_index :attendances, :work_date unless index_exists?(:attendances, :work_date)
      add_index :attendances, [:employee_id, :work_date], unique: true unless index_exists?(:attendances, [:employee_id, :work_date])
    end
    
    # Leave_requests 테이블 인덱스 (있다면)
    if table_exists?(:leave_requests)
      add_index :leave_requests, :employee_id unless index_exists?(:leave_requests, :employee_id)
      add_index :leave_requests, :status unless index_exists?(:leave_requests, :status)
      add_index :leave_requests, :start_date unless index_exists?(:leave_requests, :start_date)
      add_index :leave_requests, [:employee_id, :status] unless index_exists?(:leave_requests, [:employee_id, :status])
    end
    
    # Payrolls 테이블 인덱스 (있다면)
    if table_exists?(:payrolls)
      add_index :payrolls, :employee_id unless index_exists?(:payrolls, :employee_id)
      add_index :payrolls, :pay_period_start unless index_exists?(:payrolls, :pay_period_start)
      add_index :payrolls, :status unless index_exists?(:payrolls, :status)
      add_index :payrolls, [:employee_id, :pay_period_start] unless index_exists?(:payrolls, [:employee_id, :pay_period_start])
    end
  end
end