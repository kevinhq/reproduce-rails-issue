# frozen_string_literal: true

require "bundler/inline"

gemfile(true) do
  source "https://rubygems.org"

  git_source(:github) { |repo| "https://github.com/#{repo}.git" }

  # Activate the gem you are reporting the issue against.
  gem "activerecord", "5.1.4"
  gem "sqlite3"
end

require "active_record"
require "minitest/autorun"
require "logger"

# This connection will do for database-independent bug reports.
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
ActiveRecord::Base.logger = Logger.new(STDOUT)

ActiveRecord::Schema.define do
  create_table :proposals, force: true do |t|
    t.string :name
  end
  create_table :products, force: true do |t|
    t.string :name
  end
  create_join_table :proposals, :products, table_name: :assignments, column_options: {type: :uuid} do |t|
    t.index [:proposal_id, :product_id]
    t.timestamps
  end
end

class Proposal < ActiveRecord::Base
  has_many :assignments#, dependent: :destroy
  has_many :products, through: :assignments, dependent: :destroy
end

class Product < ActiveRecord::Base
  has_many :assignmentsi#, dependent: :destroy
  has_many :proposals, through: :assignments, dependent: :destroy
end

class Assignment < ActiveRecord::Base
  belongs_to :product
  belongs_to :proposal
end

class BugTest < Minitest::Test
  def test_association_stuff
    proposal = Proposal.create!(name: 'Test Proposal 1')
    proposal.products << Product.create!(name: 'Test Product 1')
    
    assert_equal 1, proposal.products.count
    assert_equal 1, Product.count
    assert_equal 1, Assignment.count
    proposal.update_attributes(name: 'Test Proposal 2')
    updated_proposal = Proposal.last
    assert_equal 'Test Proposal 2', updated_proposal.name
    updated_proposal.destroy
    assert_equal 0, Proposal.count
    assert_equal 0, Assignment.count
  end
end
