require "test_helper"

class DocumentComprehensiveTest < ActiveSupport::TestCase
  def setup
    @admin_user = create(:user, :admin)
  end

  test "should create valid document with factory" do
    document = build(:document)
    assert document.valid?, "Document should be valid: #{document.errors.full_messages}"
  end

  test "should validate required fields" do
    document = Document.new
    assert_not document.valid?
    
    assert_includes document.errors[:title], "can't be blank"
    assert_includes document.errors[:category], "can't be blank"
    assert_includes document.errors[:created_by], "can't be blank"
  end

  test "should validate title length" do
    # Too short
    document = build(:document, title: "a")
    assert_not document.valid?
    assert_includes document.errors[:title], "is too short (minimum is 2 characters)"
    
    # Too long
    long_title = "a" * 256
    document = build(:document, title: long_title)
    assert_not document.valid?
    assert_includes document.errors[:title], "is too long (maximum is 255 characters)"
    
    # Just right
    document = build(:document, title: "Valid Document Title")
    assert document.valid?
  end

  test "should validate category inclusion" do
    valid_categories = %w[policy procedure form manual guideline]
    
    valid_categories.each do |category|
      document = build(:document, category: category)
      assert document.valid?, "Category #{category} should be valid"
    end
    
    document = build(:document, category: 'invalid_category')
    assert_not document.valid?
    assert_includes document.errors[:category], "is not included in the list"
  end

  test "should validate file size" do
    # Negative file size
    document = build(:document, file_size: -1)
    assert_not document.valid?
    assert_includes document.errors[:file_size], "must be greater than 0"
    
    # Too large file size (over 100MB)
    document = build(:document, file_size: 105_000_000)
    assert_not document.valid?
    assert_includes document.errors[:file_size], "must be less than 100MB"
    
    # Valid file size
    document = build(:document, file_size: 5_000_000)
    assert document.valid?
  end

  test "should validate version format" do
    valid_versions = ['v1.0', 'v2.1', 'v10.5', 'v1.0.1']
    invalid_versions = ['1.0', 'version1', 'v1', 'v1.0.0.1']
    
    valid_versions.each do |version|
      document = build(:document, version: version)
      assert document.valid?, "Version #{version} should be valid"
    end
    
    invalid_versions.each do |version|
      document = build(:document, version: version)
      assert_not document.valid?, "Version #{version} should be invalid"
    end
  end

  test "should validate mime type inclusion" do
    valid_mime_types = [
      'application/pdf',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'application/msword',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
    
    valid_mime_types.each do |mime_type|
      document = build(:document, mime_type: mime_type)
      assert document.valid?, "MIME type #{mime_type} should be valid"
    end
    
    document = build(:document, mime_type: 'text/html')
    assert_not document.valid?
    assert_includes document.errors[:mime_type], "is not included in the list"
  end

  test "should scope active documents" do
    active1 = create(:document, :active)
    active2 = create(:document, :active)
    inactive = create(:document, :inactive)
    
    active_documents = Document.where(is_active: true)
    
    assert_includes active_documents, active1
    assert_includes active_documents, active2
    assert_not_includes active_documents, inactive
  end

  test "should scope by category" do
    policy = create(:document, :policy)
    procedure = create(:document, :procedure)
    form = create(:document, :form)
    manual = create(:document, :manual)
    
    policy_docs = Document.where(category: 'policy')
    procedure_docs = Document.where(category: 'procedure')
    
    assert_includes policy_docs, policy
    assert_not_includes policy_docs, procedure
    
    assert_includes procedure_docs, procedure
    assert_not_includes procedure_docs, form
  end

  test "should handle different document types with traits" do
    policy = create(:document, :policy)
    procedure = create(:document, :procedure)
    form = create(:document, :form)
    manual = create(:document, :manual)
    guideline = create(:document, :guideline)
    
    assert_equal 'policy', policy.category
    assert policy.title.start_with?('[정책]')
    assert_equal 'application/pdf', policy.mime_type
    
    assert_equal 'procedure', procedure.category
    assert procedure.title.start_with?('[절차서]')
    
    assert_equal 'form', form.category
    assert form.title.start_with?('[양식]')
    assert_equal 'application/vnd.ms-excel', form.mime_type
    
    assert_equal 'manual', manual.category
    assert manual.title.start_with?('[매뉴얼]')
    
    assert_equal 'guideline', guideline.category
    assert guideline.title.start_with?('[가이드라인]')
  end

  test "should handle file size categories" do
    small = create(:document, :small_file)
    large = create(:document, :large_file)
    
    assert small.file_size <= 102_400  # <= 100KB
    assert large.file_size >= 10_485_760  # >= 10MB
  end

  test "should search by title and content" do
    doc1 = create(:document, title: "HR Policy Manual", content: "Employee handbook policies")
    doc2 = create(:document, title: "Safety Procedure", content: "Emergency manual guidelines")
    doc3 = create(:document, title: "IT Guidelines", content: "Computer usage policy")
    
    # Search should find documents containing "policy" in title or content
    policy_related = Document.where(
      "title ILIKE ? OR content ILIKE ?", 
      "%policy%", "%policy%"
    )
    
    assert_includes policy_related, doc1
    assert_not_includes policy_related, doc2
    assert_includes policy_related, doc3
    
    # Search for "manual"
    manual_related = Document.where(
      "title ILIKE ? OR content ILIKE ?", 
      "%manual%", "%manual%"
    )
    
    assert_includes manual_related, doc1
    assert_includes manual_related, doc2
    assert_not_includes manual_related, doc3
  end

  test "should validate unique title per category and version" do
    doc1 = create(:document, title: "Safety Policy", category: 'policy', version: 'v1.0')
    
    # Same title, category, different version - should be valid
    doc2 = build(:document, title: "Safety Policy", category: 'policy', version: 'v2.0')
    assert doc2.valid?
    
    # Same title, different category, same version - should be valid
    doc3 = build(:document, title: "Safety Policy", category: 'procedure', version: 'v1.0')
    assert doc3.valid?
    
    # Same title, category, and version - should be invalid
    doc4 = build(:document, title: "Safety Policy", category: 'policy', version: 'v1.0')
    assert_not doc4.valid?
  end

  test "should calculate document statistics by category" do
    create_list(:document, 3, :policy, :active)
    create_list(:document, 2, :procedure, :active)
    create_list(:document, 4, :form, :active)
    create_list(:document, 1, :manual, :inactive)
    
    policy_count = Document.where(category: 'policy', is_active: true).count
    procedure_count = Document.where(category: 'procedure', is_active: true).count
    form_count = Document.where(category: 'form', is_active: true).count
    active_count = Document.where(is_active: true).count
    total_count = Document.count
    
    assert_equal 3, policy_count
    assert_equal 2, procedure_count
    assert_equal 4, form_count
    assert_equal 9, active_count
    assert_equal 10, total_count
  end

  test "should track file size statistics" do
    create(:document, :small_file)
    create(:document, :large_file)
    create(:document, file_size: 5_000_000) # 5MB
    
    total_size = Document.sum(:file_size)
    avg_size = Document.average(:file_size)
    max_size = Document.maximum(:file_size)
    min_size = Document.minimum(:file_size)
    
    assert total_size > 0
    assert avg_size > 0
    assert max_size >= 10_485_760  # Large file
    assert min_size <= 102_400     # Small file
  end

  test "should handle version comparison" do
    v1_0 = create(:document, version: 'v1.0')
    v1_1 = create(:document, version: 'v1.1')
    v2_0 = create(:document, version: 'v2.0')
    
    # Simple version comparison (would need custom method for proper semantic versioning)
    versions = [v1_0, v1_1, v2_0].map(&:version).sort
    assert_equal ['v1.0', 'v1.1', 'v2.0'], versions
  end
end