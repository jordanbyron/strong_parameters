require 'test_helper'
require 'active_record/forbidden_attributes_protection'

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => ":memory:"
)

ActiveRecord::Schema.define(:version => 1) do
  create_table :people do |t|
    t.string :a
  end
end

class Person < ActiveRecord::Base
  include ActiveRecord::ForbiddenAttributesProtection
  public :assign_attributes_with_permitted
end

class ActiveModelMassUpdateProtectionTest < ActiveSupport::TestCase
  test "forbidden attributes cannot be used for mass updating via new" do
    assert_raises(ActiveRecord::ForbiddenAttributes) do
      Person.new(ActionController::Parameters.new(:a => "b"))
    end
  end

  test "forbidden attributes cannot be used for mass updating via update_attributes" do
    person = Person.create!
    assert_raises(ActiveRecord::ForbiddenAttributes) do
      person.update_attributes(ActionController::Parameters.new(:a => "b"))
    end
  end

  test "forbidden attributes cannot be used for mass updating via attributes=" do
    person = Person.new
    assert_raises(ActiveRecord::ForbiddenAttributes) do
      person.attributes = ActionController::Parameters.new(:a => "b")
    end
  end

  test "permitted attributes can be used for mass updating" do
    person = Person.new(ActionController::Parameters.new(:a => "b").permit(:a))
    assert_equal({ "a" => "b" }, person.attributes.slice("a"))
  end

  test "regular attributes should still be allowed" do
    person = Person.new(:a => "b")
    assert_equal({ "a" => "b" }, person.attributes.slice("a"))
  end
end
