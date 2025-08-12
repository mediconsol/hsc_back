user = User.first

post = DepartmentPost.create!(
  title: "의료진 회의 안내",
  content: "다음 주 월요일 오전 9시에 의료진 전체 회의가 있습니다.\n\n회의 안건:\n1. 환자 안전 관리 개선방안\n2. 새로운 의료장비 사용법 교육\n3. Q&A 시간\n\n많은 참석 부탁드립니다.",
  department: "의료진",
  category: "notice",
  priority: "important",
  is_public: true,
  author: user,
  views_count: 0
)

comment1 = Comment.create!(
  content: "참석하겠습니다. 감사합니다!",
  author: user,
  department_post: post
)

Comment.create!(
  content: "의료장비 교육 자료는 미리 받아볼 수 있나요?",
  author: user,
  department_post: post,
  parent: comment1
)

puts "샘플 게시글과 댓글이 생성되었습니다!"
puts "게시글 ID: #{post.id}"
puts "댓글 수: #{post.comments.count}"