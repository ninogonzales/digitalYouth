include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :job_posting_skill do
    
  end
  factory :user do
    first_name	"John"
    last_name	"Smith"
    email		"john@example.com"
    password	"password"
    password_confirmation	"password"
  end

  factory :employer, class: User do
    first_name  "John"
    last_name "Doe"
    email   "johnd@example.com"
    password  "password"
    password_confirmation "password"
    company_name "Yahoo"
    company_address "123 Fake Street"
    company_city "Kelowna"
    company_province "BC"
    company_postal_code "V1V 1V1"
  end

  factory :user2, class: User do
    first_name	"Foo"
    last_name	"Bar"
    email		"foo@example.com"
    password	"password"
    password_confirmation	"password"
  end

  factory :project do
  	title		"A project title"
  	description	"Description of the project"
    image { fixture_file_upload( File.join(Rails.root, 'spec', 'photos', 'apple.png'), 'image/png') }
    user
  end

  factory :skill do
    name "Twitter posting"
  end

  factory :skill_2, class: Skill do
    name  "Facebook posting"
  end

  factory :reference1, class: Reference do
    first_name  "Suzan"
    last_name "Smith"
    email   "Suzan@example.com"
    company "Apple Picking Co"
    position "Manager"
    phone_number "1(250)867-5309"
    reference_body "John Smith was a wonderful employee"
  end

  factory :reference2, class: Reference do
    first_name  "Ronald"
    last_name "McDonald"
    email   "McDonalds@example.com"
    company "Canadian Tire"
    position "Manager"
    phone_number "1(250)555-5555"
    reference_body "John Smith was a wonderful employee"
    confirmed true
  end

  factory :reference_redirection1, class: ReferenceRedirection do
    reference_url "chDXcg5FJFdG_w"
    first_name  "James"
    last_name "Andrew"
    email   "James@example.com"
  end

  factory :reference_email1, class: ReferenceEmail do
    first_name  "James"
    last_name "Andrew"
    email   "James@example.com"
    reference_url "chDXcg5FJFdG_w"
  end

  factory :response1, class: Response do
    scores [0,1,2,3]
    question_ids [1,2,3,4]
    survey_id 1
  end

  factory :response2, class: Response do
    scores [3,2,1,0]
    question_ids [1,2,3,4]
    survey_id 1
  end

  factory :job_posting do
    title "Social Media Expert"
    description "Handling SM sites"
    open_date Date.new(2016,1,1)
    close_date Date.new(2016, 3, 1)
    user
  end
end