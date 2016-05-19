FactoryGirl.define do
  factory :user do
    first_name	"John"
    last_name	"Smith"
    email		"john@example.com"
    password	"password"
    password_confirmation	"password"
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
  end

end